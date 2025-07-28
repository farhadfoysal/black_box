import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ExamAttemptPage extends StatefulWidget {
  @override
  _ExamAttemptPageState createState() => _ExamAttemptPageState();
}

class _ExamAttemptPageState extends State<ExamAttemptPage> {
  Map<int, dynamic> selectedAnswers = {};
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late VideoPlayerController _videoController;
  late YoutubePlayerController _youtubeController;

  @override
  void initState() {
    super.initState();
    // Initialize video controllers
    _videoController = VideoPlayerController.network(
        'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4')
      ..initialize().then((_) {
        setState(() {});
      });

    _youtubeController = YoutubePlayerController(
      initialVideoId: 'dQw4w9WgXcQ',
      flags: YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        title: Text(
          "BCS Preliminary Exam",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.amber[700],
              child: Text(
                '${selectedAnswers.length}',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Exam header with info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "BCS Preliminary Exam - 2023",
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
                    _buildInfoCard(Icons.help_outline, "Questions", "100"),
                    _buildInfoCard(Icons.timer, "Time", "60 min"),
                    _buildInfoCard(Icons.alarm, "Remaining", "59:41"),
                  ],
                ),
              ],
            ),
          ),

          // Question progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Text(
                  "Question ${_currentIndex + 1} of 4",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "General Knowledge",
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Questions area
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                // Text question with multiple choice
                _buildTextQuestion(
                  question: "বাংলাদেশে প্রথম চায়ের চাষ আরম্ভ হয় -",
                  options: [
                    "A. সিলেটের মালনীছড়ায়",
                    "B. সিলেটের তামাবিলে",
                    "C. পার্বত্য চট্টগ্রামের খাগড়াছড়িতে",
                    "D. সিলেটের জাফলং এ",
                  ],
                  questionIndex: 0,
                ),

                // Image question
                _buildImageQuestion(
                  question: "এই ভাস্কর্যটি কোথায় অবস্থিত?",
                  imageUrl: "https://via.placeholder.com/600x400?text=Sample+Question+Image",
                  options: [
                    "A. ঢাকা বিশ্ববিদ্যালয়",
                    "B. চট্টগ্রাম বন্দর",
                    "C. সোনারগাঁও",
                    "D. মহাস্থানগড়",
                  ],
                  questionIndex: 1,
                ),

                // YouTube video question
                _buildVideoQuestion(
                  question: "এই ভিডিওতে প্রদর্শিত স্থানটি কোথায়?",
                  videoType: 'youtube',
                  videoUrl: 'dQw4w9WgXcQ',
                  options: [
                    "A. সুন্দরবন",
                    "B. কক্সবাজার",
                    "C. সেন্ট মার্টিন",
                    "D. কাপ্তাই লেক",
                  ],
                  questionIndex: 2,
                ),

                // Written answer question
                _buildWrittenQuestion(
                  question: "বাংলাদেশের সংবিধানের প্রথম সংশোধনী সম্পর্কে লিখুন",
                  questionIndex: 3,
                ),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentIndex > 0
                        ? () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Previous",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < 3) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        // Submit the exam
                        _submitExam();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentIndex < 3 ? "Next" : "Submit",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  void _submitExam() {
    print(selectedAnswers);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Exam submitted successfully!"),
        backgroundColor: Colors.green,
      ),
    );
    // Here you would typically navigate to results page
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTextQuestion({
    required String question,
    required List<String> options,
    required int questionIndex,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                question,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepPurple[800],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          ...options.map(
                (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: RadioListTile<String>(
                  value: option,
                  groupValue: selectedAnswers[questionIndex],
                  onChanged: (value) {
                    setState(() {
                      selectedAnswers[questionIndex] = value;
                    });
                  },
                  title: Text(
                    option,
                    style: TextStyle(fontSize: 16),
                  ),
                  activeColor: Colors.deepPurple,
                  tileColor: Colors.white,
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageQuestion({
    required String question,
    required String imageUrl,
    required List<String> options,
    required int questionIndex,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepPurple[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: Center(
                            child: Icon(Icons.error, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          ...options.map(
                (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: RadioListTile<String>(
                  value: option,
                  groupValue: selectedAnswers[questionIndex],
                  onChanged: (value) {
                    setState(() {
                      selectedAnswers[questionIndex] = value;
                    });
                  },
                  title: Text(
                    option,
                    style: TextStyle(fontSize: 16),
                  ),
                  activeColor: Colors.deepPurple,
                  tileColor: Colors.white,
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoQuestion({
    required String question,
    required String videoType,
    required String videoUrl,
    required List<String> options,
    required int questionIndex,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.deepPurple[800],
                    ),
                  ),
                  SizedBox(height: 16),
                  if (videoType == 'youtube')
                    Container(
                      height: 200,
                      child: YoutubePlayer(
                        controller: _youtubeController,
                        showVideoProgressIndicator: true,
                        progressIndicatorColor: Colors.deepPurple,
                      ),
                    )
                  else
                    Container(
                      height: 200,
                      child: _videoController.value.isInitialized
                          ? AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(_videoController),
                      )
                          : Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          ...options.map(
                (option) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: RadioListTile<String>(
                  value: option,
                  groupValue: selectedAnswers[questionIndex],
                  onChanged: (value) {
                    setState(() {
                      selectedAnswers[questionIndex] = value;
                    });
                  },
                  title: Text(
                    option,
                    style: TextStyle(fontSize: 16),
                  ),
                  activeColor: Colors.deepPurple,
                  tileColor: Colors.white,
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrittenQuestion({
    required String question,
    required int questionIndex,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                question,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepPurple[800],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                maxLines: 10,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Type your answer here...",
                ),
                onChanged: (value) {
                  setState(() {
                    selectedAnswers[questionIndex] = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(fontSize: 12),
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: "Jobs",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: "Education",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: "Home",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: "Search",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu),
          label: "More",
        ),
      ],
    );
  }
}