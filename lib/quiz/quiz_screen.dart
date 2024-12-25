import 'package:flutter/material.dart';

class QuizScreen extends StatelessWidget {
  final List<Map<String, dynamic>> questions = [
    {
      "question": "There are two tragedies in life. One is to lose your heart's desire. The other is to gain it. - This quote is by -",
      "options": ["Thomas Hardy", "Emily Bronte", "Jane Austen", "G.B Shaw"]
    },
    {
      "question": "Who wrote 'The Jew of Malta'?",
      "options": ["Ben Jonson", "Christopher Marlowe", "Nicolas Udall", "William Shakespeare"]
    },
    {
      "question": "What is 'Melodrama'?",
      "options": ["A tragic play", "A sensational play", "A comic play", "A historical play"]
    },
    {
      "question": "Which kind of literary work is 'Gerontion'?",
      "options": ["Poem", "Novel", "Play", "Essay"]
    },
    {
      "question": "Who of the following authors is not a Metaphysical poet?",
      "options": ["John Cleveland", "George Herbert", "Thomas Carew", "Richard Crashaw"]
    },
    {
      "question": "In 'Romeo and Juliet,' what is Juliet's family name?",
      "options": ["Montague", "Capulet", "Escalus", "Tybalt"]
    },
    {
      "question": "'The Way of the World' is written by -",
      "options": ["Samuel Butler", "John Bunyan", "John Dryden", "William Congreve"]
    },
    {
      "question": "Who wrote the poem 'Rosalind and Helen'?",
      "options": [
        "Percy Bysshe Shelley",
        "Emily Dickinson",
        "Walt Whitman",
        "Elizabeth Barrett Browning"
      ]
    },
    {
      "question": "In the poem 'The Solitary Reaper,' Wordsworth writes about -",
      "options": ["", "", "", ""]
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz"),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: questions.length,
        itemBuilder: (context, index) {
          final question = questions[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Title
                  Text(
                    "${index + 1}) ${question['question']}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Options
                  ...List.generate(
                    question['options'].length,
                        (i) => ListTile(
                      leading: const Icon(Icons.radio_button_off),
                      title: Text(
                        question['options'][i],
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        // Handle option selection
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// void main() {
//   runApp(MaterialApp(
//     home: QuizScreen(),
//     theme: ThemeData(primarySwatch: Colors.green),
//   ));
// }