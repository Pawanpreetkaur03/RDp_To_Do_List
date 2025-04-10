// Importing Flutter material design library
import 'package:flutter/material.dart';
// Importing Firebase Core for initializing Firebase
import 'package:firebase_core/firebase_core.dart';
// Importing Firestore to store and retrieve tasks
import 'package:cloud_firestore/cloud_firestore.dart';
// Importing Table Calendar for the calendar view
import 'package:table_calendar/table_calendar.dart';

// Main screen widget
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// State class for HomePage
class _HomePageState extends State<HomePage> {
  // Firestore instance to interact with the database
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Controller to get input text from the user
  final TextEditingController nameController = TextEditingController();

  // List to store all tasks from the database
  final List<Map<String, dynamic>> tasks = [];

  // Called when the widget is first created
  @override
  void initState() {
    super.initState();
    fetchTasks(); // Load tasks from Firestore
  }

  // Function to get tasks from Firestore
  Future<void> fetchTasks() async {
    final snapshot = await db.collection('tasks').orderBy('timestamp').get(); // Get all tasks ordered by time

    setState(() {
      tasks.clear(); // Clear old tasks
      tasks.addAll( // Add new tasks from Firestore
        snapshot.docs.map(
          (doc) => {
            'id': doc.id, // Task ID
            'name': doc.get('name'), // Task name
            'completed': doc.get('completed') ?? false, // Task status
          },
        ),
      );
    });
  }

  // Function to add a new task
  Future<void> addTask() async {
    final taskName = nameController.text.trim(); // Get text and remove spaces

    if (taskName.isNotEmpty) {
      final newTask = {
        'name': taskName, // Set task name
        'completed': false, // New task is not completed
        'timestamp': FieldValue.serverTimestamp(), // Add current time
      };

      // Add new task to Firestore and get reference
      final docRef = await db.collection('tasks').add(newTask);

      // Add task to local list
      setState(() {
        tasks.add({'id': docRef.id, ...newTask});
      });

      nameController.clear(); // Clear input field
    }
  }

  // Function to update task completion status
  Future<void> updateTask(int index, bool completed) async {
    final task = tasks[index]; // Get task by index

    // Update task status in Firestore
    await db.collection('tasks').doc(task['id']).update({
      'completed': completed,
    });

    // Update task in local list
    setState(() {
      tasks[index]['completed'] = completed;
    });
  }

  // Function to remove a task
  Future<void> removeTasks(int index) async {
    final task = tasks[index]; // Get task to remove

    // Delete task from Firestore
    await db.collection('tasks').doc(task['id']).delete();

    // Remove task from local list
    setState(() {
      tasks.removeAt(index);
    });
  }

  // Build the user interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top bar with title and logo
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Display logo image
            Expanded(child: Image.asset('assets/rdplogo.png', height: 80)),

            // Display app title
            const Text(
              'Daily Planner',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),

      // Main content of the app
      body: Column(
        children: [
          // Expandable area for tasks and calendar
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Display calendar view
                  TableCalendar(
                    calendarFormat: CalendarFormat.month,
                    focusedDay: DateTime.now(), // Show current month
                    firstDay: DateTime(2025), // Calendar starts from 2025
                    lastDay: DateTime(2026), // Calendar ends at 2026
                  ),

                  // Show the list of tasks
                  buildTaskList(tasks, removeTasks, updateTask),
                ],
              ),
            ),
          ),

          // Section to add new task
          buildAddTaskSection(nameController, addTask),
        ],
      ),

      // Side drawer (empty for now)
      drawer: Drawer(),
    );
  }
}

// Widget to build the add task section
Widget buildAddTaskSection(nameController, addTask) {
  return Container(
    decoration: const BoxDecoration(color: Colors.white), // White background
    child: Padding(
      padding: const EdgeInsets.all(12.0), // Padding around content
      child: Row(
        children: [
          // Input field to enter task
          Expanded(
            child: Container(
              child: TextField(
                maxLength: 32, // Limit input to 32 characters
                controller: nameController, // Connect controller
                decoration: const InputDecoration(
                  labelText: 'Add Task', // Label for input
                  border: OutlineInputBorder(), // Border style
                ),
              ),
            ),
          ),

          // Button to add the task
          ElevatedButton(
            onPressed: addTask, // Call addTask when clicked
            child: Text('Add Task'), // Button text
          ),
        ],
      ),
    ),
  );
}

// Widget to build the task list
Widget buildTaskList(tasks, removeTasks, updateTask) {
  return ListView.builder(
    shrinkWrap: true, // Use minimum space
    physics: const NeverScrollableScrollPhysics(), // Disable scroll inside scroll
    itemCount: tasks.length, // Total number of tasks
    itemBuilder: (context, index) {
      final task = tasks[index]; // Get task data
      final isEven = index % 2 == 0; // Alternate background color

      return Padding(
        padding: EdgeInsets.all(1.0), // Space around each task
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Rounded corners
          tileColor: isEven ? Colors.blue : Colors.green, // Alternate colors

          // Icon for completed/incomplete
          leading: Icon(
            task['completed'] ? Icons.check_circle : Icons.circle_outlined,
          ),

          // Show task name with line-through if done
          title: Text(
            task['name'],
            style: TextStyle(
              decoration: task['completed'] ? TextDecoration.lineThrough : null,
              fontSize: 22,
            ),
          ),

          // Buttons to update or delete task
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkbox to mark task done/undone
              Checkbox(
                value: task['completed'], // Current value
                onChanged: (value) => updateTask(index, value!), // Update on change
              ),

              // Delete button
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => removeTasks(index), // Call delete
              ),
            ],
          ),
        ),
      );
    },
  );
}
