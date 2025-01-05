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
    final TextEditingController userNameController = TextEditingController();
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
            bool isAdding = false;
            String message = '';

            showDialog(
              context: context,
              builder: (context) => StatefulBuilder(
                builder: (context, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: Text(
                    'Add Week Day',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Message TextField at the top
                        if (message.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              message,
                              style: TextStyle(
                                color: message.startsWith('Please') ? Colors.red : Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        // Dropdown for Day
                        DropdownButtonFormField<String>(
                          value: selectedDay,
                          decoration: InputDecoration(
                            labelText: 'Day',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: [
                            'Monday', 'Tuesday', 'Wednesday', 'Thursday',
                            'Friday', 'Saturday', 'Sunday',
                          ].map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedDay = value;
                              message = ''; // Clear any previous message
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: timeController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Time',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onTap: () async {
                                  TimeOfDay? selectedTime = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (selectedTime != null) {
                                    setDialogState(() {
                                      timeController.text = selectedTime.format(context);
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: minutesController,
                                decoration: InputDecoration(
                                  labelText: 'Minutes',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Close',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onPressed: isAdding
                          ? null
                          : () {
                        if (selectedDay != null) {
                          setDialogState(() {
                            isAdding = true;
                            message = ''; // Clear previous message
                          });
                          TutorWeekDay day = TutorWeekDay(
                            uniqueId: DateTime.now().toIso8601String(),
                            studentId: uniqueIdController.text,
                            userId: userNameController.text,
                            day: selectedDay!,
                            time: timeController.text,
                            minutes: int.tryParse(minutesController.text) ?? 0,
                          );
                          setModalState(() {
                            weekDays.add(day);  // Add the day to the parent list
                          });
                          Future.delayed(Duration(seconds: 2), () {
                            setDialogState(() {
                              isAdding = false;
                              message = 'Week Day added successfully!'; // Success message
                            });
                          });
                          Future.delayed(Duration(seconds: 3), () {
                            // Navigator.pop(context);
                          });
                        } else {
                          setDialogState(() {
                            message = 'Please select a day'; // Error message
                          });
                        }
                      },
                      child: isAdding
                          ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        'Add',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 10,
              right: 10,
              top: 20,
            ),
            child: Card(
              color: Colors.white,
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 50,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                        color: Colors.pinkAccent,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(Icons.face_retouching_natural_outlined, color: Colors.white),
                          const SizedBox(width: 12),
                          const Text(
                            "Add Student",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();  // Close the dialog or screen
                            },
                            icon: Icon(Icons.close, color: Colors.white),
                          ),
                          const SizedBox(width: 12), // Optional, adds a little padding from the edge
                        ],
                      ),
                    ),
                
                    _buildTextField(userNameController, 'Name', Icons.person),
                    _buildTextField(phoneController, 'Phone', Icons.phone),
                    _buildTextField(guardianPhoneController, 'Guardian Phone', Icons.phone_in_talk),
                    _buildTextField(phonePassController, 'Email', Icons.email),
                    _buildTextField(educationController, 'Education', Icons.school),
                    _buildTextField(addressController, 'Address', Icons.home),
                    _buildTextField(imgController, 'Image URL', Icons.image),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight, // Aligns the button to the right
                      child: ElevatedButton(
                        onPressed: _addWeekDay,
                        style: ElevatedButton.styleFrom(
                          elevation: 5, // Adds shadow
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Rounded corners
                          ),
                          backgroundColor: Colors.pinkAccent, // Button color
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Keeps the button compact
                          children: [
                            const Icon(Icons.add, color: Colors.white), // Icon on the left
                            const SizedBox(width: 8),
                            const Text(
                              'Add Day',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                
                    // ListView.builder(
                    //   shrinkWrap: true,
                    //   itemCount: weekDays.length,
                    //   itemBuilder: (context, index) {
                    //     return Padding(
                    //       padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
                    //       child: Card(
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(12),
                    //         ),
                    //         elevation: 4,
                    //         child: ListTile(
                    //           contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 5),
                    //           title: Text(
                    //             'Day: ${weekDays[index].day}',
                    //             style: TextStyle(
                    //               fontWeight: FontWeight.bold,
                    //               fontSize: 16,
                    //             ),
                    //           ),
                    //           subtitle: Text(
                    //             'Time: ${weekDays[index].time}, Minutes: ${weekDays[index].minutes}',
                    //             style: TextStyle(
                    //               color: Colors.grey[600],
                    //               fontSize: 14,
                    //             ),
                    //           ),
                    //           trailing: IconButton(
                    //             onPressed: () {
                    //               setModalState(() {
                    //                 weekDays.removeAt(index);
                    //               });
                    //
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 SnackBar(
                    //                   content: Text('Item deleted successfully'),
                    //                   backgroundColor: Colors.redAccent,
                    //                 ),
                    //               );
                    //             },
                    //             icon: Icon(
                    //               Icons.delete,
                    //               color: Colors.redAccent,
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),

                    Wrap(
                      spacing: 8.0, // Horizontal space between items
                      runSpacing: 6.0, // Vertical space between lines
                      children: weekDays.map((weekDay) {
                        return Chip(
                          label: Row(
                            children: [
                              Text(
                                'Day: ${weekDay.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Time: ${weekDay.time}, Minutes: ${weekDay.minutes}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          deleteIcon: Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onDeleted: () {
                            setModalState(() {
                              weekDays.removeAt(weekDays.indexOf(weekDay));
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Item deleted successfully'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),

                    // GridView.builder(
                    //   shrinkWrap: true,
                    //   physics: NeverScrollableScrollPhysics(), // Prevents nested scroll behavior
                    //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    //     crossAxisCount: 2, // Number of columns in the grid
                    //     crossAxisSpacing: 8, // Space between columns
                    //     mainAxisSpacing: 8, // Space between rows
                    //   ),
                    //   itemCount: weekDays.length,
                    //   itemBuilder: (context, index) {
                    //     return Padding(
                    //       padding: const EdgeInsets.all(8),
                    //       child: Card(
                    //         shape: RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(12),
                    //         ),
                    //         elevation: 4,
                    //         child: Column(
                    //           mainAxisAlignment: MainAxisAlignment.center,
                    //           children: [
                    //             Text(
                    //               'Day: ${weekDays[index].day}',
                    //               style: TextStyle(
                    //                 fontWeight: FontWeight.bold,
                    //                 fontSize: 16,
                    //               ),
                    //             ),
                    //             SizedBox(height: 8),
                    //             Text(
                    //               'Time: ${weekDays[index].time}, Minutes: ${weekDays[index].minutes}',
                    //               style: TextStyle(
                    //                 color: Colors.grey[600],
                    //                 fontSize: 14,
                    //               ),
                    //             ),
                    //             IconButton(
                    //               onPressed: () {
                    //                 setModalState(() {
                    //                   weekDays.removeAt(index);
                    //                 });
                    //                 ScaffoldMessenger.of(context).showSnackBar(
                    //                   SnackBar(
                    //                     content: Text('Item deleted successfully'),
                    //                     backgroundColor: Colors.redAccent,
                    //                   ),
                    //                 );
                    //               },
                    //               icon: Icon(
                    //                 Icons.delete,
                    //                 color: Colors.redAccent,
                    //               ),
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     );
                    //   },
                    // ),


                    SizedBox(height: 10), // Adds some space between form and button
                    // Container(
                    //   alignment: Alignment.center,
                    //   margin: const EdgeInsets.all(10),
                    //   child: Material(
                    //     elevation: 3,
                    //     borderRadius: BorderRadius.circular(20),
                    //     child: Container(
                    //       width: MediaQuery.of(context).size.width,
                    //       height: 50,
                    //       decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(20),
                    //         color: Colors.white,
                    //       ),
                    //       child: Material(
                    //         borderRadius: BorderRadius.circular(20),
                    //         color: Colors.pinkAccent,
                    //         child: InkWell(
                    //           splashColor: Colors.pink,
                    //           borderRadius: BorderRadius.circular(20),
                    //           onTap: () {
                    //             setState(() {
                    //               students.add(TutorStudent(
                    //                 uniqueId: uniqueIdController.text,
                    //                 userId: userNameController.text,
                    //                 phone: phoneController.text,
                    //                 gaurdianPhone: guardianPhoneController.text,
                    //                 phonePass: phonePassController.text,
                    //                 dob: dobController.text,
                    //                 education: educationController.text,
                    //                 address: addressController.text,
                    //                 activeStatus: 1,
                    //                 admittedDate: DateTime.now(),
                    //                 img: imgController.text,
                    //                 days: weekDays,
                    //               ));
                    //             });
                    //             Navigator.pop(context);
                    //             ScaffoldMessenger.of(context).showSnackBar(
                    //               const SnackBar(
                    //                 content: Row(
                    //                   children: [
                    //                     Icon(
                    //                       Icons.info_outline,
                    //                       color: Colors.white,
                    //                     ),
                    //                     SizedBox(width: 10),
                    //                     Text(
                    //                       "Ups, foto dan inputan tidak boleh kosong!",
                    //                       style: TextStyle(color: Colors.white),
                    //                     ),
                    //                   ],
                    //                 ),
                    //                 backgroundColor: Colors.redAccent,
                    //                 shape: StadiumBorder(),
                    //                 behavior: SnackBarBehavior.floating,
                    //               ),
                    //             );
                    //           },
                    //           child: const Center(
                    //             child: Text(
                    //               " Save Student",
                    //               style: TextStyle(
                    //                 color: Colors.white,
                    //                 fontWeight: FontWeight.bold,
                    //               ),
                    //             ),
                    //           ),
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.all(10),
                      child: Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.white,
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.pinkAccent,
                            child: InkWell(
                              splashColor: Colors.pink,
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                setState(() {
                                  students.add(TutorStudent(
                                    uniqueId: uniqueIdController.text,
                                    userId: userNameController.text,
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          "Ups, foto dan inputan tidak boleh kosong!",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    shape: StadiumBorder(),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: const Center(
                                child: Text(
                                  " Save Student",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content that can scroll
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    SizedBox(height: 1),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return GestureDetector(
                          onTap: () {

                          },
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 5,
                            margin: const EdgeInsets.all(10),
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 14),
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        fit: BoxFit.cover,
                                        image: NetworkImage(
                                            "https://gratisography.com/wp-content/uploads/2024/11/gratisography-augmented-reality-800x525.jpg"
                                          // items[index].img.toString(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          student.userId.toString(),
                                          style: const TextStyle(color: Colors.black, fontSize: 18),
                                          maxLines: 2,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          student.phone.toString(),
                                          style: const TextStyle(color: Colors.black, fontSize: 14),
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        // Implement edit logic
                                      } else if (value == 'delete') {
                                        setState(() {
                                          students.remove(student); // Assuming `students` is your list
                                        });
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                        );

                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Positioned button at the bottom-right corner
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => _addStudent(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, // Text color
                backgroundColor: Colors.blue, // Button color
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25), // Rounded edges
                ),
                elevation: 5, // Shadow effect
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 10),
                  Text(
                    "Add Student",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.pinkAccent),
          prefixIcon: Icon(icon, color: Colors.pinkAccent),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.pinkAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.pinkAccent, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        ),
      ),
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: Stack(
  //       children: [
  //         SingleChildScrollView(
  //           child: Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Column(
  //               children: [
  //                 // ElevatedButton(
  //                 //   onPressed: () => _addStudent(context),
  //                 //   style: ElevatedButton.styleFrom(
  //                 //     foregroundColor: Colors.white, backgroundColor: Colors.blue, // Text color
  //                 //     padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
  //                 //     shape: RoundedRectangleBorder(
  //                 //       borderRadius: BorderRadius.circular(25), // Rounded edges
  //                 //     ),
  //                 //     elevation: 5, // Shadow effect
  //                 //   ),
  //                 //   child: Row(
  //                 //     mainAxisSize: MainAxisSize.min,
  //                 //     children: [
  //                 //       Icon(Icons.person, size: 20),
  //                 //       SizedBox(width: 10),
  //                 //       Text(
  //                 //         "Click to Add Student",
  //                 //         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                 //       ),
  //                 //     ],
  //                 //   ),
  //                 // ),
  //                 SizedBox(height: 10),
  //                 ListView.builder(
  //                   shrinkWrap: true,
  //                   physics: NeverScrollableScrollPhysics(),
  //                   itemCount: students.length,
  //                   itemBuilder: (context, index) {
  //                     final student = students[index];
  //                     return Card(
  //                       margin: EdgeInsets.symmetric(vertical: 8),
  //                       child: ListTile(
  //                         title: Text(student.userId),
  //                         subtitle: Text('Phone: ${student.phone}'),
  //                         trailing: PopupMenuButton<String>(
  //                           onSelected: (value) {
  //                             if (value == 'edit') {
  //                               // Implement edit logic
  //                             } else if (value == 'delete') {
  //                               setState(() {
  //                                 students.removeAt(index);
  //                               });
  //                             }
  //                           },
  //                           itemBuilder: (context) => [
  //                             PopupMenuItem(value: 'edit', child: Text('Edit')),
  //                             PopupMenuItem(value: 'delete', child: Text('Delete')),
  //                           ],
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //
  //
  //         Positioned(
  //           bottom: 20,
  //           right: 20,
  //           child: ElevatedButton(
  //             onPressed: () => _addStudent(context),
  //             style: ElevatedButton.styleFrom(
  //               foregroundColor: Colors.white, // Text color
  //               backgroundColor: Colors.blue, // Button color
  //               padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(25), // Rounded edges
  //               ),
  //               elevation: 5, // Shadow effect
  //             ),
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Icon(Icons.person, size: 20),
  //                 SizedBox(width: 10),
  //                 Text(
  //                   "Click to Add Student",
  //                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //
  //       ],
  //     ),
  //   );
  // }
}
