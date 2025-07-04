import 'package:flutter/material.dart';

class NoticePage extends StatelessWidget {
  const NoticePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notices = <String>[
      'Exam on May 10th',
      'Holiday declared next week'
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Notice Board')),
      body: ListView.separated(
        itemCount: notices.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          return ListTile(
            title: Text(notices[i]),
            onTap: () {
              // TODO: show full notice
            },
          );
        },
      ),
    );
  }
}
