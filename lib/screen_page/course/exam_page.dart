import 'package:flutter/material.dart';

class ExamsPage extends StatelessWidget {
  const ExamsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final exams = <String>['Midterm Exam', 'Final Exam'];

    return Scaffold(
      appBar: AppBar(title: const Text('Exams')),
      body: ListView.separated(
        itemCount: exams.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          return ListTile(
            title: Text(exams[i]),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // TODO: open exam details or start test
            },
          );
        },
      ),
    );
  }
}
