// import 'package:flutter/material.dart';
// import 'professional_omr_generator.dart'; // your main generator file
//
// class OMRConfigPage extends StatefulWidget {
//   const OMRConfigPage({Key? key}) : super(key: key);
//
//   @override
//   State<OMRConfigPage> createState() => _OMRConfigPageState();
// }
//
// class _OMRConfigPageState extends State<OMRConfigPage> {
//   final _formKey = GlobalKey<FormState>();
//
//   final TextEditingController _examNameController = TextEditingController();
//   final TextEditingController _subjectController = TextEditingController();
//   final TextEditingController _departmentController = TextEditingController();
//   final TextEditingController _roomController = TextEditingController();
//   final TextEditingController _branchController = TextEditingController();
//
//   int _totalQuestions = 50;
//   int _columns = 3;
//
//   void _createConfig() {
//     if (_formKey.currentState!.validate()) {
//       final config = OMRExamConfigg(
//         examName: _examNameController.text.trim(),
//         subjectName: _subjectController.text.trim(),
//         department: _departmentController.text.trim(),
//         roomNumber: _roomController.text.trim(),
//         branch: _branchController.text.trim(),
//         totalQuestions: _totalQuestions,
//         columns: _columns,
//       );
//
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => ProfessionalOMRGenerator(config: config),
//         ),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Create OMR Config"),
//       ),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             _buildTextField("Exam Name", _examNameController),
//             _buildTextField("Subject Name", _subjectController),
//             _buildTextField("Department", _departmentController),
//             _buildTextField("Room Number", _roomController),
//             _buildTextField("Branch / Section", _branchController),
//
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text("Total Questions (max 50)"),
//                       Slider(
//                         min: 10,
//                         max: 50,
//                         divisions: 40,
//                         value: _totalQuestions.toDouble(),
//                         label: '$_totalQuestions',
//                         onChanged: (val) =>
//                             setState(() => _totalQuestions = val.round()),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             Row(
//               children: [
//                 const Text("Columns:"),
//                 const SizedBox(width: 10),
//                 DropdownButton<int>(
//                   value: _columns,
//                   items: const [
//                     DropdownMenuItem(value: 1, child: Text("1")),
//                     DropdownMenuItem(value: 2, child: Text("2")),
//                     DropdownMenuItem(value: 3, child: Text("3")),
//                   ],
//                   onChanged: (v) => setState(() => _columns = v ?? 3),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 30),
//             ElevatedButton.icon(
//               icon: const Icon(Icons.picture_as_pdf),
//               label: const Text("Generate OMR Sheet"),
//               onPressed: _createConfig,
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 textStyle: const TextStyle(fontSize: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//         ),
//         validator: (v) =>
//         v == null || v.trim().isEmpty ? 'Please enter $label' : null,
//       ),
//     );
//   }
// }
