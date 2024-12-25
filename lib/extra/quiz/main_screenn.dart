import 'package:flutter/material.dart';
import 'quiz_screenn.dart';
import 'models/questionn.dart';
import 'models/quizz.dart';
import 'models/userr.dart';

class MainScreenn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dummy data for the user and quiz
    Userr user = Userr(
      email: 'mff85855075@gmail.com',
      name: 'Farhad Foysal',
      userId: 'user123',
      phoneNumber: '01770627875',
    );

    List<Questionn> questions = [
      Questionn(
        questionText: 'বাংলাদেশে প্রথম চায়ের চাষ আরম্ভ হয় -',
        options: [
          'A. সিলেটের মালনীছড়ায়',
          'B. সিলেটের তামাবিলে',
          'C. পার্বত্য চট্টগ্রামের খাগড়াছড়িতে',
          'D. সিলেটের জাফলং এ',
        ],
        correctAnswer: 'A. সিলেটের মালনীছড়ায়',
      ),
      Questionn(
        questionText: '‘স্টেপাস’ ভাস্কর্যটি সিঙ্গেল অলিম্পিকের পার্কে স্থান পেয়েছিল। এর ভাস্করের নাম -',
        options: [
          'A. নোভেরা আহমেদ',
          'B. হামিদুজ্জামান খান',
          'C. আবদুল্লাহ খালেদ',
          'D. সুলতানুল ইসলাম',
        ],
        correctAnswer: 'B. হামিদুজ্জামান খান',
      ),
      Questionn(
        questionText: 'রাশিয়ার যে শহরে হাসপাতালে আক্রমণ করার পর বাধ্য হয়ে রাশিয়া চেচনিয়ার সাথে শান্তি বৈঠকে বসতে রাজি হয়েছে তার নাম-',
        options: [
          'Option 1',
          'Option 2',
          'Option 3',
          'Option 4',
        ],
        correctAnswer: 'Option 1',
      ),
    ];

    Quizz quiz = Quizz(
      quizId: 'quiz123',
      title: '17th BCS Preliminary Exam',
      times: 60,
      schoolId: '123',
      questions: questions,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Select User and Quiz'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Navigate to the quiz screen with the user and quiz data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizScreenn(user: user, quiz: quiz),
              ),
            );
          },
          child: Text('Start Quiz'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            backgroundColor: Colors.blueAccent,
            textStyle: TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
