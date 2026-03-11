import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/omr_sheet_model.dart';
import 'student_omr_marking_page.dart';

class SearchOMRSheet extends StatefulWidget {
  // final String schoolId;
  //
  // const SearchOMRSheet({super.key, required this.schoolId});

  @override
  State<SearchOMRSheet> createState() => _SearchOMRSheetState();
}

class _SearchOMRSheetState extends State<SearchOMRSheet> {

  final TextEditingController _sheetIdController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;

  OMRSheet? _sheet;

  String? _error;

  /// Search OMR Sheet
  // Future<void> _searchSheet() async {
  //
  //   final sheetId = _sheetIdController.text.trim();
  //
  //   if(sheetId.isEmpty){
  //
  //     setState(() {
  //       _error = "Please enter Sheet ID";
  //     });
  //
  //     return;
  //   }
  //
  //   setState(() {
  //     _loading = true;
  //     _error = null;
  //     _sheet = null;
  //   });
  //
  //   try{
  //
  //     final doc = await _firestore
  //         .collection('courses')
  //         .doc(widget.schoolId)
  //         .collection('sheets')
  //         .doc(sheetId)
  //         .get();
  //
  //     if(!doc.exists){
  //
  //       setState(() {
  //         _error = "Sheet not found";
  //       });
  //
  //     }else{
  //
  //       final data = doc.data()!;
  //
  //       final sheet = OMRSheet.fromMap(data);
  //
  //       setState(() {
  //         _sheet = sheet;
  //       });
  //
  //     }
  //
  //   }catch(e){
  //
  //     // print('farhad foysal ${e}');
  //     setState(() {
  //       _error = "Error loading sheet";
  //     });
  //
  //   }
  //
  //   setState(() {
  //     _loading = false;
  //   });
  //
  // }

  // Future<void> _searchSheet() async {
  //
  //   final sheetId = _sheetIdController.text.trim();
  //
  //   if (sheetId.isEmpty) {
  //     setState(() {
  //       _error = "Please enter Sheet ID";
  //     });
  //     return;
  //   }
  //
  //   setState(() {
  //     _loading = true;
  //     _error = null;
  //     _sheet = null;
  //   });
  //
  //   try {
  //
  //     final query = await _firestore
  //         .collectionGroup('sheets')
  //         .where('uniqueId', isEqualTo: sheetId)
  //         .limit(1)
  //         .get();
  //     print('farhad foysal ${query}');
  //
  //     if (query.docs.isEmpty) {
  //
  //       setState(() {
  //         _error = "Sheet not found";
  //       });
  //
  //     } else {
  //
  //       final data = query.docs.first.data();
  //
  //       final sheet = OMRSheet.fromMap(data);
  //
  //       setState(() {
  //         _sheet = sheet;
  //       });
  //
  //     }
  //
  //   } catch (e) {
  //     print('farhad foysal ${e}');
  //     setState(() {
  //       _error = "Error loading sheet";
  //     });
  //
  //   }
  //
  //   setState(() {
  //     _loading = false;
  //   });
  //
  // }

  Future<void> _searchSheet() async {
    final sheetId = _sheetIdController.text.trim();

    if (sheetId.isEmpty) {
      setState(() {
        _error = "Please enter Sheet ID";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _sheet = null;
    });

    try {

      final query = await _firestore.collectionGroup('sheets').get();

      for (var doc in query.docs) {
        if (doc.id == sheetId) {
           _sheet = OMRSheet.fromMap(doc.data());
        }
      }

      if (query.docs.isEmpty) {

        setState(() {
          _error = "Sheet not found";
        });

      } else {

        // final doc = query.docs.first;
        //
        // final data = doc.data();
        //
        // final sheet = OMRSheet.fromMap({
        //   ...data,
        //   'uniqueId': doc.id,
        // });
        //
        // setState(() {
        //   _sheet = sheet;
        // });

      }

    } catch (e) {
      setState(() {
        _error = "Error loading sheet";
      });
    }

    setState(() {
      _loading = false;
    });
  }

  /// Navigate to marking page
  void _openSheet(){

    if(_sheet == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentOMRMarkingPage(sheet: _sheet!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Enter OMR Sheet"),
        centerTitle: true,
      ),

      body: Center(

        child: SingleChildScrollView(

          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(

              children: [

                /// Title
                const Text(
                  "Search OMR Sheet",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Enter Sheet ID to start marking",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                /// Search Box
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(16),

                    child: Column(

                      children: [

                        TextField(
                          controller: _sheetIdController,

                          decoration: InputDecoration(

                            labelText: "Sheet ID",

                            hintText: "Enter OMR Sheet ID",

                            prefixIcon: const Icon(Icons.qr_code),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,

                          height: 50,

                          child: ElevatedButton(

                            onPressed: _loading ? null : _searchSheet,

                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),

                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              "Search Sheet",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        )

                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// Error
                if(_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),

                /// Sheet Preview
                if(_sheet != null)

                  Card(
                    elevation: 5,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(20),

                      child: Column(

                        children: [

                          Text(
                            _sheet!.examName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Text("Subject: ${_sheet!.subjectName}"),

                              Text("Set: ${_sheet!.setNumber}"),

                            ],
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "Questions: ${_sheet!.numberOfQuestions}",
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 45,

                            child: ElevatedButton(

                              onPressed: _openSheet,

                              child: const Text("Start OMR Marking"),

                            ),
                          )

                        ],
                      ),
                    ),
                  )

              ],
            ),
          ),
        ),
      ),
    );
  }
}