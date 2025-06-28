import 'package:black_box/routine/routine_importer.dart';
import 'package:flutter/material.dart';
import 'db_helper.dart';

class RoutineScreen extends StatefulWidget {
  @override
  _RoutineScreenState createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  List<Map<String, dynamic>> _routineList = [];

  @override
  void initState() {
    super.initState();
    _loadRoutine();
  }

  Future<void> _loadRoutine() async {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> routines = await dbHelper.getAllRoutines();
    setState(() {
      _routineList = routines;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Class Routine")),
      body: ListView.builder(
        itemCount: _routineList.length,
        itemBuilder: (context, index) {
          var routine = _routineList[index];
          return ListTile(
            title: Text("${routine['course_code']} - ${routine['time']}"),
            subtitle: Text("Room: ${routine['room']} | Instructor: ${routine['instructor']}"),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await RoutineImporter.pickAndImportRoutine();
          _loadRoutine();
        },
        child: Icon(Icons.upload_file),
      ),
    );
  }
}
