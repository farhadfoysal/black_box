import 'package:flutter/material.dart';

class QuizFour extends StatefulWidget {
  @override
  _QuizFourState createState() => _QuizFourState();
}

class _QuizFourState extends State<QuizFour> {
  // Map to track the selected answers for each question
  Map<int, String?> selectedAnswers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueAccent,
        title: Text(
          "mff85855075@gmail.com",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.red,
              child: Text(
                '0',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blueAccent,
            child: Column(
              children: [
                Text(
                  "১৭তম বিসিএস (প্রিলি)",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.help_outline, color: Colors.white),
                        Text(
                          "মোট প্রশ্ন",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "100",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.timer, color: Colors.white),
                        Text(
                          "সময়",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "60 মি.",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.alarm, color: Colors.white),
                        Text(
                          "সময় বাকি",
                          style: TextStyle(color: Colors.white),
                        ),
                        Text(
                          "-59:41 মি.",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildQuestion(
                  question: "বাংলাদেশে প্রথম চায়ের চাষ আরম্ভ হয় -",
                  options: [
                    "A. সিলেটের মালনীছড়ায়",
                    "B. সিলেটের তামাবিলে",
                    "C. পার্বত্য চট্টগ্রামের খাগড়াছড়িতে",
                    "D. সিলেটের জাফলং এ",
                  ],
                  questionIndex: 0,
                ),
                _buildQuestion(
                  question: "‘স্টেপাস’ ভাস্কর্যটি সিঙ্গেল অলিম্পিকের পার্কে স্থান পেয়েছিল। এর ভাস্করের নাম -",
                  options: [
                    "A. নোভেরা আহমেদ",
                    "B. হামিদুজ্জামান খান",
                    "C. আবদুল্লাহ খালেদ",
                    "D. সুলতানুল ইসলাম",
                  ],
                  questionIndex: 1,
                ),
                _buildQuestion(
                  question: "রাশিয়ার যে শহরে হাসপাতালে আক্রমণ করার পর বাধ্য হয়ে রাশিয়া চেচনিয়ার সাথে শান্তি বৈঠকে বসতে রাজি হয়েছে তার নাম-",
                  options: [
                    "Option 1",
                    "Option 2",
                    "Option 3",
                    "Option 4",
                  ],
                  questionIndex: 2,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Handle the submit logic here
                print(selectedAnswers);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                "সাবমিট করুন",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.work),
            label: "চাকরি",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: "এডুকেশন",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "হোম",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "সার্চ করুন",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: "আরও",
          ),
        ],
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  Widget _buildQuestion({
    required String question,
    required List<String> options,
    required int questionIndex,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 8),
        ...options.map(
              (option) => RadioListTile<String>(
            value: option,
            groupValue: selectedAnswers[questionIndex],
            onChanged: (value) {
              setState(() {
                selectedAnswers[questionIndex] = value;
              });
            },
            title: Text(option),
          ),
        ),
        Divider(),
      ],
    );
  }
}
