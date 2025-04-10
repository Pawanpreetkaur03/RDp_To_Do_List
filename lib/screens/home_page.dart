import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:table_calendar/table_calendar.dart';

// HomePage is the main screen of the app
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// This class holds the state of the HomePage
class _HomePageState extends State<HomePage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  //Create an empty list of maps which represent our tasks
  final List<Map<String, dynamic>> tasks = [];

  //Create a variable that captures the input of a text input
  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  //Fetch tasks  from the db and also update the tasks list in memory
  Future<void> fetchTasks() async {
    final snapshots = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      tasks.clear();
      tasks.addAll(
        snapshots.docs.map(
          (doc) => {
            'id': doc.id,
            'name': doc['name'],
            'completed': doc.get('completed') ?? false,
          },
        ),
      );
    });
  }

  //function add new task to local state & firestore database
  Future<void> addTask() async {
    final taskName = nameController.text.trim();

    if (taskName.isNotEmpty) {
      final newTask = {
        'name': taskName,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
      };

      //docRef gives us the insertion id from the document

      final docRef = await db.collection('tasks').add(newTask);

      //add the tasks locally
      setState(() {
        tasks.add({'id': docRef.id, ...newTask});
      });

      // Clear the input field after adding
      nameController.clear();
    }
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Display the logo image
            Expanded(child: Image.asset('assets/rdplogo.png', height: 80)),
            // App title
            Text(
              'RDP Daily Planner',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar widget at the top of the screen
            SizedBox(
              height: 340,
              child: TableCalendar(
                calendarFormat: CalendarFormat.month,
                focusedDay: DateTime.now(),
                firstDay: DateTime(2025),
                lastDay: DateTime(2026),
              ),
            ),

            // Input field and "Add Task" button
            Expanded(
              child: Container(
                child: buildAddTaskSection(nameController, addTask),
              ),
            ),

            // (Optional) You could uncomment this to show the task list
            // Expanded(child: buildTaskList(tasks)),
          ],
        ),
      ),
      drawer: Drawer(),
    );
  }
}

//Build the section for adding tasks
Widget buildAddTaskSection(nameController, addTask) {
  return Padding(
    padding: const EdgeInsets.all(12.0),
    child: Row(
      children: [
        // Text input field for task name
        Expanded(
          child: TextField(
            maxLength: 32,
            controller: nameController,
            decoration: InputDecoration(
              labelText: ' Add Task',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        ElevatedButton(onPressed: addTask, child: Text('Add Task')),
      ],
    ),
  );
}

// Widget for displaying the list of tasks
Widget buildTaskList(tasks) {
  return ListView.builder(
    physics: NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: tasks.length,
    itemBuilder: (context, index) {
      // Each task displayed in a styled ListTile
      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
      // Task data (name, etc.) could be added here
    },
  );
}
