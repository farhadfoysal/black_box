import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../modules/widget/date_selector.dart';
import '../modules/widget/task_card.dart';
import 'add_new_task_page.dart';

class TaskHomePage extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const TaskHomePage(),
  );
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> {
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tasks"),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, AddNewTaskPage.route());
            },
            icon: const Icon(
              CupertinoIcons.add,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          DateSelector(
            selectedDate: selectedDate,
            onTap: (date) {
              setState(() {
                selectedDate = date;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 2, // Replace with your task list length
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Expanded(
                      child: TaskCard(
                        color: Colors.blue, // Replace with dynamic task color
                        headerText: 'Task Title', // Replace with dynamic task title
                        descriptionText: 'Task Description', // Replace with dynamic description
                      ),
                    ),
                    Container(
                      height: 10,
                      width: 10,
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.69), // Replace with dynamic color
                        shape: BoxShape.circle,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        DateFormat.jm().format(selectedDate), // Replace with task's due time
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
