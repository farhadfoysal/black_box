import 'package:flutter/material.dart';
import 'package:black_box/model/tutor/tutor_week_day.dart';
import 'package:black_box/model/tutor/tutor_student.dart';

class TutorView extends StatefulWidget {
  @override
  _TutorViewState createState() => _TutorViewState();
}

class _TutorViewState extends State<TutorView> {
  final List<TutorStudent> students = [];

  void _addStudent(BuildContext context) {
    final TextEditingController uniqueIdController = TextEditingController();
    final TextEditingController userIdController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    final TextEditingController guardianPhoneController = TextEditingController();
    final TextEditingController phonePassController = TextEditingController();
    final TextEditingController dobController = TextEditingController();
    final TextEditingController educationController = TextEditingController();
    final TextEditingController addressController = TextEditingController();
    final TextEditingController imgController = TextEditingController();
    final List<TutorWeekDay> weekDays = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          void _addWeekDay() {
            final TextEditingController timeController = TextEditingController();
            final TextEditingController minutesController = TextEditingController();
            String? selectedDay;

            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Add Week Day'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedDay,
                      decoration: InputDecoration(labelText: 'Day'),
                      items: [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday',
                      ].map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedDay = value;
                        });
                      },
                    ),
                    TextField(
                      controller: timeController,
                      readOnly: true,
                      decoration: InputDecoration(labelText: 'Time'),
                      onTap: () async {
                        TimeOfDay? selectedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (selectedTime != null) {
                          setState(() {
                            timeController.text = selectedTime.format(context);
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: minutesController,
                      decoration: InputDecoration(labelText: 'Minutes'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (selectedDay != null) {
                        setModalState(() {
                          weekDays.add(TutorWeekDay(
                            uniqueId: DateTime.now().toIso8601String(),
                            studentId: uniqueIdController.text,
                            userId: userIdController.text,
                            day: selectedDay!,
                            time: timeController.text,
                            minutes: int.tryParse(minutesController.text) ?? 0,
                          ));
                        });
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please select a day')),
                        );
                      }
                    },
                    child: Text('Add'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Add Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextField(controller: uniqueIdController, decoration: InputDecoration(labelText: 'Unique ID')),
                  TextField(controller: userIdController, decoration: InputDecoration(labelText: 'User ID')),
                  TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone')),
                  TextField(controller: guardianPhoneController, decoration: InputDecoration(labelText: 'Guardian Phone')),
                  TextField(controller: phonePassController, decoration: InputDecoration(labelText: 'Phone Pass')),
                  TextField(controller: dobController, decoration: InputDecoration(labelText: 'Date of Birth')),
                  TextField(controller: educationController, decoration: InputDecoration(labelText: 'Education')),
                  TextField(controller: addressController, decoration: InputDecoration(labelText: 'Address')),
                  TextField(controller: imgController, decoration: InputDecoration(labelText: 'Image URL')),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addWeekDay,
                    child: Text('Add Week Day'),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: weekDays.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text('Day: ${weekDays[index].day}'),
                      subtitle: Text('Time: ${weekDays[index].time}, Minutes: ${weekDays[index].minutes}'),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        students.add(TutorStudent(
                          uniqueId: uniqueIdController.text,
                          userId: userIdController.text,
                          phone: phoneController.text,
                          gaurdianPhone: guardianPhoneController.text,
                          phonePass: phonePassController.text,
                          dob: dobController.text,
                          education: educationController.text,
                          address: addressController.text,
                          activeStatus: 1,
                          admittedDate: DateTime.now(),
                          img: imgController.text,
                          days: weekDays,
                        ));
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Add Student'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _addStudent(context),
              child: Text('Add Student'),
            ),
            SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(student.userId),
                    subtitle: Text('Phone: ${student.phone}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          // Implement edit logic
                        } else if (value == 'delete') {
                          setState(() {
                            students.removeAt(index);
                          });
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}