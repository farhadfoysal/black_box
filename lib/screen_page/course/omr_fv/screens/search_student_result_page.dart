import 'package:black_box/screen_page/course/omr_fv/screens/student_result_page.dart';
import 'package:black_box/screen_page/course/omr_fv/screens/student_result_page_1.dart';
import 'package:flutter/material.dart';

class SearchStudentResultPage extends StatefulWidget {
  const SearchStudentResultPage({Key? key}) : super(key: key);

  @override
  State<SearchStudentResultPage> createState() =>
      _SearchStudentResultPageState();
}

class _SearchStudentResultPageState extends State<SearchStudentResultPage> {

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _schoolIdController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void _openResults() {

    if (!_formKey.currentState!.validate()) return;

    final studentId = _studentIdController.text.trim();
    final schoolId = _schoolIdController.text.trim();

    /// CONDITION ROUTING
    if (schoolId.isNotEmpty) {

      /// OPEN StudentResultsPage1
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentResultsPage(
            studentId: studentId,
            schoolId: schoolId,
          ),
        ),
      );

    } else {

      /// OPEN StudentResultsPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentResultsPage1(
            studentId: studentId,
          ),
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Search Student Result"),
        backgroundColor: const Color(0xFF2C3E50),
      ),

      body: Center(

        child: SingleChildScrollView(

          padding: const EdgeInsets.all(20),

          child: Card(

            elevation: 4,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            child: Padding(

              padding: const EdgeInsets.all(20),

              child: Form(

                key: _formKey,

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    const Icon(
                      Icons.person_search,
                      size: 70,
                      color: Colors.blue,
                    ),

                    const SizedBox(height: 20),

                    /// STUDENT ID
                    TextFormField(
                      controller: _studentIdController,
                      decoration: InputDecoration(
                        labelText: "Student ID",
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value){
                        if(value == null || value.trim().isEmpty){
                          return "Enter Student ID";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    /// SCHOOL ID
                    TextFormField(
                      controller: _schoolIdController,
                      decoration: InputDecoration(
                        labelText: "Course ID (Optional)",
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 50,

                      child: ElevatedButton(

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                        ),

                        onPressed: _openResults,

                        child: const Text(
                          "View Results",
                          style: TextStyle(fontSize: 16),
                        ),

                      ),
                    )

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}