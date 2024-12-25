import 'package:flutter/material.dart';

class QuizTwo extends StatelessWidget {
  final List<Map<String, Object>> questions = [
    {
      'questionText': 'There are two tragedies in life. One is to lose your heart\'s desire. The other is to gain it. - This quote is by:',
      'answers': ['Thomas Hardy', 'Emily Bronte', 'Jane Austen', 'G.B Shaw']
    },
    {
      'questionText': 'Who wrote \'The Jew of Malta\'?',
      'answers': ['Ben Jonson', 'Christopher Marlowe', 'Nicolas Udall', 'William Shakespeare']
    },
    {
      'questionText': 'What is \'Melodrama\'?',
      'answers': ['A tragic play', 'A sensational play', 'A comic play', 'A historical play']
    },
    {
      'questionText': 'Which kind of literary work is \'Gerontion\'?',
      'answers': ['Poem', 'Novel', 'Play', 'Essay']
    },
    {
      'questionText': 'Who of the following authors is not a Metaphysical poet?',
      'answers': ['John Cleveland', 'George Herbert', 'Thomas Carew', 'Richard Crashaw']
    },
    {
      'questionText': 'In "Romeo and Juliet," what is Juliet\'s family name?',
      'answers': ['Montague', 'Capulet', 'Escalus', 'Tybalt']
    },
    {
      'questionText': 'The Way of the World is written by:',
      'answers': ['Samuel Butler', 'John Bunyan', 'John Dryden', 'William Congreve']
    },
    {
      'questionText': 'Who wrote the poem \'Rosalind and Helen\'?',
      'answers': ['Percy Bysshe Shelley', 'Emily Dickinson', 'Walt Whitman', 'Elizabeth Barrett Browning']
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edubox Quiz'),
      ),
      body: ListView.builder(
        itemCount: questions.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(10),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questions[index]['questionText'] as String,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  ...((questions[index]['answers'] as List<String>).map((answer) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Text(answer),
                      ),
                    );
                  })).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
