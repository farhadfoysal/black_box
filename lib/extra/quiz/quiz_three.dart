import 'package:flutter/material.dart';

class QuizThree extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: Icon(Icons.person, color: Colors.white),
        title: Text(
          'mff85855075@gmail.com',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          Icon(Icons.notifications, color: Colors.white),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '১৭তম বিসিএস (প্রিলি)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCard('মোট প্রশ্ন', '100', Colors.teal),
                    _infoCard('সময়', '60 মি.', Colors.orange),
                    _infoCard('সময় বাকি', '-59:41 মি.', Colors.green),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _questionCard(
                  context,
                  '১. বাংলাদেশে প্রথম চায়ের চাষ আরম্ভ হয় -',
                  ['সিলেটের মালনীছড়ায়', 'সিলেটের তামাবিলে', 'পার্বত্য চট্টগ্রামের খাগড়াছড়িতে', 'সিলেটের জাফলং এ'],
                ),
                _questionCard(
                  context,
                  '২. \u2018স্টেপাস\u2019 ডাকঘাটি সিঙ্গেল অলিম্পিকের পার্কে স্থান পেয়েছিল। এর ভাস্করের নাম -',
                  ['নভেরা আহমেদ', 'হামিদুজ্জামান খান', 'আবদুল্লাহ খালেদ', 'সুলতানুল ইসলাম'],
                ),
                _questionCard(
                  context,
                  '৩. রাশিয়ার যে শহরে হাসপাতালে আক্রমণ করার পর বাধ্য হয়ে রাশিয়া চেচেনিয়ার সাথে শান্তি বৈঠকে বসতে রাজি হয়েছে তার নাম-',
                  ['মস্কো', 'গ্রোজনি', 'সেন্ট পিটার্সবার্গ', 'কাজান'],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
                'সাবমিট করুন',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'চাকরি'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'এডুকেশন'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'হোম'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'সার্চ করুন'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'আরও'),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
    );
  }

  Widget _infoCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _questionCard(BuildContext context, String question, List<String> options) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ...options.map((option) {
              return RadioListTile(
                value: option,
                groupValue: null,
                onChanged: (value) {},
                title: Text(option),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
