import 'package:flutter/material.dart';
import '../../model/quiz/question.dart';

// Sample questions list with proper named parameters
var questions = [
  Question(
    questionTitle: 'What are the main building blocks of Flutter UIs?',
    questionAnswers: [
      'Widgets',
      'Components',
      'Blocks',
      'Functions',
    ],
    explanation: '',
    source: '', quizId: '',
    type: '',
    url: '',
  ),
  Question(
    questionTitle: 'How are Flutter UIs built?',
    questionAnswers: [
      'By combining widgets in code',
      'By combining widgets in a visual editor',
      'By defining widgets in config files',
      'By using XCode for iOS and Android Studio for Android',
    ],
    explanation: '',
    source: '', quizId: '',
      type: '',
      url: ''
  ),
  Question(
    questionTitle: 'What\'s the purpose of a StatefulWidget?',
    questionAnswers: [
      'Update UI as data changes',
      'Update data as UI changes',
      'Ignore data changes',
      'Render UI that does not depend on data',
    ],
    explanation: '',
    source: '', quizId: '',
      type: '',
      url: ''
  ),
  Question(
    questionTitle: 'Which widget should you try to use more often: StatelessWidget or StatefulWidget?',
    questionAnswers: [
      'StatelessWidget',
      'StatefulWidget',
      'Both are equally good',
      'None of the above',
    ],
    explanation: '',
    source: '', quizId: '',
      type: '',
      url: ''
  ),
  Question(
    questionTitle: 'What happens if you change data in a StatelessWidget?',
    questionAnswers: [
      'The UI is not updated',
      'The UI is updated',
      'The closest StatefulWidget is updated',
      'Any nested StatefulWidgets are updated',
    ],
    explanation: '',
    source: '', quizId: '',
      type: '',
      url: ''
  ),
  Question(
    questionTitle: 'How should you update data inside of StatefulWidgets?',
    questionAnswers: [
      'By calling setState()',
      'By calling updateData()',
      'By calling updateUI()',
      'By calling updateState()',
    ],
    explanation: '',
    source: '', quizId: '',
      type: '',
      url: ''
  ),
];


// import 'package:flutter/material.dart';
//
// import '../../model/quiz/question.dart';
//
// const questions = [
//   Question(
//     'What are the main building blocks of Flutter UIs?',
//     [
//       'Widgets',
//       'Components',
//       'Blocks',
//       'Functions',
//     ],
//     '',
//     '',
//   ),
//   Question('How are Flutter UIs built?', [
//     'By combining widgets in code',
//     'By combining widgets in a visual editor',
//     'By defining widgets in config files',
//     'By using XCode for iOS and Android Studio for Android',
//   ],    '',
//     '',),
//   Question(
//     'What\'s the purpose of a StatefulWidget?',
//     [
//       'Update UI as data changes',
//       'Update data as UI changes',
//       'Ignore data changes',
//       'Render UI that does not depend on data',
//     ],
//     '',
//     '',
//   ),
//   Question(
//     'Which widget should you try to use more often: StatelessWidget or StatefulWidget?',
//     [
//       'StatelessWidget',
//       'StatefulWidget',
//       'Both are equally good',
//       'None of the above',
//     ],
//     '',
//     '',
//   ),
//   Question(
//     'What happens if you change data in a StatelessWidget?',
//     [
//       'The UI is not updated',
//       'The UI is updated',
//       'The closest StatefulWidget is updated',
//       'Any nested StatefulWidgets are updated',
//     ],
//     '',
//     '',
//   ),
//   Question(
//     'How should you update data inside of StatefulWidgets?',
//     [
//       'By calling setState()',
//       'By calling updateData()',
//       'By calling updateUI()',
//       'By calling updateState()',
//     ],
//     '',
//     '',
//   ),
// ];
