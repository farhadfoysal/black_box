import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ExamAttemptPagee extends StatefulWidget {
  @override
  _ExamAttemptPageState createState() => _ExamAttemptPageState();
}

class _ExamAttemptPageState extends State<ExamAttemptPagee> {
  Map<int, dynamic> selectedAnswers = {};
  Map<int, bool> markedQuestions = {};
  int _currentIndex = 0;
  bool _showAllQuestions = false;
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

    // Initialize marked questions
    for (int i = 0; i < 4; i++) {
      markedQuestions[i] = false;
    }
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
          _showAllQuestions ? "All Questions" : "BCS Preliminary Exam",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [
          if (!_showAllQuestions)
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
          IconButton(
            icon: Icon(_showAllQuestions ? Icons.question_answer : Icons.list),
            onPressed: () {
              setState(() {
                _showAllQuestions = !_showAllQuestions;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_showAllQuestions) ...[
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
          ],

          // Main content area
          Expanded(
            child: _showAllQuestions ? _buildAllQuestionsView() : _buildPagedView(),
          ),

          // Navigation buttons
          if (!_showAllQuestions)
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
    );
  }

  Widget _buildAllQuestionsView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "All Questions",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final isAnswered = selectedAnswers.containsKey(index);
              final isMarked = markedQuestions[index] ?? false;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                    _showAllQuestions = false;
                    _pageController.jumpToPage(index);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isAnswered
                        ? Colors.green[100]
                        : isMarked
                        ? Colors.orange[100]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentIndex == index
                          ? Colors.deepPurple
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${index + 1}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isAnswered
                                ? Colors.green[800]
                                : isMarked
                                ? Colors.orange[800]
                                : Colors.grey[800],
                          ),
                        ),
                        if (isMarked)
                          Icon(Icons.bookmark, size: 12, color: Colors.orange[800]),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green),
                ),
              ),
              SizedBox(width: 8),
              Text("Answered"),
              SizedBox(width: 16),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange),
                ),
              ),
              SizedBox(width: 8),
              Text("Marked"),
              SizedBox(width: 16),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey),
                ),
              ),
              SizedBox(width: 8),
              Text("Unanswered"),
            ],
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showAllQuestions = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Back to Questions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildAllQuestionsView() {
  //   return ListView(
  //     padding: EdgeInsets.all(16),
  //     children: [
  //       Text(
  //         "All Questions",
  //         style: TextStyle(
  //           fontSize: 20,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.deepPurple,
  //         ),
  //       ),
  //       SizedBox(height: 16),
  //
  //       // Render each question below
  //       _buildTextQuestion(
  //         question: "বাংলাদেশে প্রথম চায়ের চাষ আরম্ভ হয় -",
  //         options: [
  //           "A. সিলেটের মালনীছড়ায়",
  //           "B. সিলেটের তামাবিলে",
  //           "C. পার্বত্য চট্টগ্রামের খাগড়াছড়িতে",
  //           "D. সিলেটের জাফলং এ",
  //         ],
  //         questionIndex: 0,
  //       ),
  //       Divider(thickness: 1),
  //
  //       _buildImageQuestion(
  //         question: "এই ভাস্কর্যটি কোথায় অবস্থিত?",
  //         imageUrl: "https://via.placeholder.com/600x400?text=Sample+Question+Image",
  //         options: [
  //           "A. ঢাকা বিশ্ববিদ্যালয়",
  //           "B. চট্টগ্রাম বন্দর",
  //           "C. সোনারগাঁও",
  //           "D. মহাস্থানগড়",
  //         ],
  //         questionIndex: 1,
  //       ),
  //       Divider(thickness: 1),
  //
  //       _buildVideoQuestion(
  //         question: "এই ভিডিওতে প্রদর্শিত স্থানটি কোথায়?",
  //         videoType: 'youtube',
  //         videoUrl: 'dQw4w9WgXcQ',
  //         options: [
  //           "A. সুন্দরবন",
  //           "B. কক্সবাজার",
  //           "C. সেন্ট মার্টিন",
  //           "D. কাপ্তাই লেক",
  //         ],
  //         questionIndex: 2,
  //       ),
  //       Divider(thickness: 1),
  //
  //       _buildWrittenQuestion(
  //         question: "বাংলাদেশের সংবিধানের প্রথম সংশোধনী সম্পর্কে লিখুন",
  //         questionIndex: 3,
  //       ),
  //
  //       SizedBox(height: 24),
  //       ElevatedButton(
  //         onPressed: () {
  //           setState(() {
  //             _showAllQuestions = false;
  //           });
  //         },
  //         style: ElevatedButton.styleFrom(
  //           backgroundColor: Colors.deepPurple,
  //           padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //         ),
  //         child: Text(
  //           "Back to Paged View",
  //           style: TextStyle(
  //             color: Colors.white,
  //             fontSize: 16,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }


  Widget _buildPagedView() {
    return PageView(
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
          Row(
            children: [
              Expanded(
                child: Card(
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
              ),
              IconButton(
                icon: Icon(
                  markedQuestions[questionIndex]! ? Icons.bookmark : Icons.bookmark_border,
                  color: markedQuestions[questionIndex]! ? Colors.orange : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    markedQuestions[questionIndex] = !markedQuestions[questionIndex]!;
                  });
                },
              ),
            ],
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
                // child: RadioListTile<String>(
                //   value: option,
                //   groupValue: selectedAnswers[questionIndex],
                //   onChanged: (value) {
                //     setState(() {
                //       // Unmark if selecting the same option again
                //       if (selectedAnswers[questionIndex] == value) {
                //         selectedAnswers.remove(questionIndex);
                //       } else {
                //         selectedAnswers[questionIndex] = value;
                //       }
                //     });
                //   },
                //   title: Text(
                //     option,
                //     style: TextStyle(fontSize: 16),
                //   ),
                //   activeColor: Colors.deepPurple,
                //   tileColor: Colors.white,
                //   dense: true,
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                // ),
                child: // Update the RadioListTile in _buildTextQuestion, _buildImageQuestion, and _buildVideoQuestion
                RadioListTile<String>(
                  value: option,
                  groupValue: selectedAnswers[questionIndex],
                  onChanged: (value) {
                    setState(() {
                      if (selectedAnswers[questionIndex] == value) {
                        selectedAnswers.remove(questionIndex); // Remove if same option clicked
                      } else {
                        selectedAnswers[questionIndex] = value; // Set new value
                      }
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
          Row(
            children: [
              Expanded(
                child: Card(
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
              ),
              IconButton(
                icon: Icon(
                  markedQuestions[questionIndex]! ? Icons.bookmark : Icons.bookmark_border,
                  color: markedQuestions[questionIndex]! ? Colors.orange : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    markedQuestions[questionIndex] = !markedQuestions[questionIndex]!;
                  });
                },
              ),
            ],
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
                // child: RadioListTile<String>(
                //   value: option,
                //   groupValue: selectedAnswers[questionIndex],
                //   onChanged: (value) {
                //     setState(() {
                //       // Unmark if selecting the same option again
                //       if (selectedAnswers[questionIndex] == value) {
                //         selectedAnswers.remove(questionIndex);
                //       } else {
                //         selectedAnswers[questionIndex] = value;
                //       }
                //     });
                //   },
                //   title: Text(
                //     option,
                //     style: TextStyle(fontSize: 16),
                //   ),
                //   activeColor: Colors.deepPurple,
                //   tileColor: Colors.white,
                //   dense: true,
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(10),
                //   ),
                // ),
                child: // Update the RadioListTile in _buildTextQuestion, _buildImageQuestion, and _buildVideoQuestion
                RadioListTile<String>(
                  value: option,
                  groupValue: selectedAnswers[questionIndex],
                  onChanged: (value) {
                    setState(() {
                      if (selectedAnswers[questionIndex] == value) {
                        selectedAnswers.remove(questionIndex); // Remove if same option clicked
                      } else {
                        selectedAnswers[questionIndex] = value; // Set new value
                      }
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
          Row(
            children: [
              Expanded(
                child: Card(
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
              ),
              IconButton(
                icon: Icon(
                  markedQuestions[questionIndex]! ? Icons.bookmark : Icons.bookmark_border,
                  color: markedQuestions[questionIndex]! ? Colors.orange : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    markedQuestions[questionIndex] = !markedQuestions[questionIndex]!;
                  });
                },
              ),
            ],
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
                child: // Update the RadioListTile in _buildTextQuestion, _buildImageQuestion, and _buildVideoQuestion
                RadioListTile<String>(
                  value: option,
                  groupValue: selectedAnswers[questionIndex],
                  onChanged: (value) {
                    setState(() {
                      if (selectedAnswers[questionIndex] == value) {
                        selectedAnswers.remove(questionIndex); // Remove if same option clicked
                      } else {
                        selectedAnswers[questionIndex] = value; // Set new value
                      }
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
          Row(
            children: [
              Expanded(
                child: Card(
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
              ),
              IconButton(
                icon: Icon(
                  markedQuestions[questionIndex]! ? Icons.bookmark : Icons.bookmark_border,
                  color: markedQuestions[questionIndex]! ? Colors.orange : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    markedQuestions[questionIndex] = !markedQuestions[questionIndex]!;
                  });
                },
              ),
            ],
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
                    if (value.isEmpty) {
                      selectedAnswers.remove(questionIndex);
                    } else {
                      selectedAnswers[questionIndex] = value;
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// import 'package:flutter/material.dart';
//
// class ExamAttemptPage extends StatefulWidget {
//   @override
//   _ExamAttemptPageState createState() => _ExamAttemptPageState();
// }
//
// class _ExamAttemptPageState extends State<ExamAttemptPage> {
//   Map<int, String?> selectedAnswers = {};
//   int _currentIndex = 0;
//   final PageController _pageController = PageController();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.deepPurple,
//         title: Text(
//           "Exam: 17th BCS Preliminary",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundColor: Colors.amber[700],
//               child: Text(
//                 '0',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.deepPurple,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(20),
//                 bottomRight: Radius.circular(20),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.deepPurple.withOpacity(0.2),
//                   blurRadius: 10,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Text(
//                   "17th BCS Preliminary Exam",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20,
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildInfoCard(Icons.help_outline, "Total Questions", "100"),
//                     _buildInfoCard(Icons.timer, "Time", "60 min"),
//                     _buildInfoCard(Icons.alarm, "Time Left", "59:41"),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   "Question ${_currentIndex + 1} of 3",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Colors.deepPurple,
//                   ),
//                 ),
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.deepPurple.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     "General Knowledge",
//                     style: TextStyle(
//                       color: Colors.deepPurple,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: PageView(
//               controller: _pageController,
//               onPageChanged: (index) {
//                 setState(() {
//                   _currentIndex = index;
//                 });
//               },
//               children: [
//                 _buildQuestionPage(
//                   question: "বাংলাদেশে প্রথম চায়ের চাষ আরম্ভ হয় -",
//                   options: [
//                     "A. সিলেটের মালনীছড়ায়",
//                     "B. সিলেটের তামাবিলে",
//                     "C. পার্বত্য চট্টগ্রামের খাগড়াছড়িতে",
//                     "D. সিলেটের জাফলং এ",
//                   ],
//                   questionIndex: 0,
//                 ),
//                 _buildQuestionPage(
//                   question: "‘স্টেপাস’ ভাস্কর্যটি সিঙ্গেল অলিম্পিকের পার্কে স্থান পেয়েছিল। এর ভাস্করের নাম -",
//                   options: [
//                     "A. নোভেরা আহমেদ",
//                     "B. হামিদুজ্জামান খান",
//                     "C. আবদুল্লাহ খালেদ",
//                     "D. সুলতানুল ইসলাম",
//                   ],
//                   questionIndex: 1,
//                 ),
//                 _buildQuestionPage(
//                   question: "রাশিয়ার যে শহরে হাসপাতালে আক্রমণ করার পর বাধ্য হয়ে রাশিয়া চেচনিয়ার সাথে শান্তি বৈঠকে বসতে রাজি হয়েছে তার নাম-",
//                   options: [
//                     "Option 1",
//                     "Option 2",
//                     "Option 3",
//                     "Option 4",
//                   ],
//                   questionIndex: 2,
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _currentIndex > 0
//                         ? () {
//                       _pageController.previousPage(
//                         duration: Duration(milliseconds: 300),
//                         curve: Curves.easeInOut,
//                       );
//                     }
//                         : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.grey[300],
//                       padding: EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       "Previous",
//                       style: TextStyle(
//                         color: Colors.black87,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 16),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       if (_currentIndex < 2) {
//                         _pageController.nextPage(
//                           duration: Duration(milliseconds: 300),
//                           curve: Curves.easeInOut,
//                         );
//                       } else {
//                         // Submit the exam
//                         print(selectedAnswers);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text("Exam submitted successfully!"),
//                             backgroundColor: Colors.green,
//                           ),
//                         );
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.deepPurple,
//                       padding: EdgeInsets.symmetric(vertical: 12),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     child: Text(
//                       _currentIndex < 2 ? "Next" : "Submit",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       bottomNavigationBar: _buildBottomNavBar(),
//     );
//   }
//
//   Widget _buildInfoCard(IconData icon, String title, String value) {
//     return Column(
//       children: [
//         Icon(icon, color: Colors.white, size: 28),
//         SizedBox(height: 4),
//         Text(
//           title,
//           style: TextStyle(color: Colors.white70, fontSize: 12),
//         ),
//         Text(
//           value,
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 14,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildQuestionPage({
//     required String question,
//     required List<String> options,
//     required int questionIndex,
//   }) {
//     return SingleChildScrollView(
//       padding: EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Card(
//             elevation: 2,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 question,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: Colors.deepPurple[800],
//                 ),
//               ),
//             ),
//           ),
//           SizedBox(height: 16),
//           ...options.map(
//                 (option) => Padding(
//               padding: const EdgeInsets.only(bottom: 8.0),
//               child: Card(
//                 elevation: 1,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: RadioListTile<String>(
//                   value: option,
//                   groupValue: selectedAnswers[questionIndex],
//                   onChanged: (value) {
//                     setState(() {
//                       selectedAnswers[questionIndex] = value;
//                     });
//                   },
//                   title: Text(
//                     option,
//                     style: TextStyle(fontSize: 16),
//                   ),
//                   activeColor: Colors.deepPurple,
//                   tileColor: Colors.white,
//                   dense: true,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   BottomNavigationBar _buildBottomNavBar() {
//     return BottomNavigationBar(
//       currentIndex: 2, // Home is selected
//       type: BottomNavigationBarType.fixed,
//       selectedItemColor: Colors.deepPurple,
//       unselectedItemColor: Colors.grey,
//       selectedLabelStyle: TextStyle(fontSize: 12),
//       items: [
//         BottomNavigationBarItem(
//           icon: Icon(Icons.work),
//           label: "Jobs",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.school),
//           label: "Education",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.home),
//           label: "Home",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.search),
//           label: "Search",
//         ),
//         BottomNavigationBarItem(
//           icon: Icon(Icons.menu),
//           label: "More",
//         ),
//       ],
//     );
//   }
// }


// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//
// class ExamAttemptPagee extends StatefulWidget {
//   @override
//   _ExamAttemptPageState createState() => _ExamAttemptPageState();
// }
//
// class _ExamAttemptPageState extends State<ExamAttemptPagee> {
//   Map<int, dynamic> selectedAnswers = {};
//   Map<int, bool> markedQuestions = {};
//   late VideoPlayerController _videoController;
//   late YoutubePlayerController _youtubeController;
//
//   @override
//   void initState() {
//     super.initState();
//     // Initialize video controllers
//     _videoController = VideoPlayerController.network(
//         'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4')
//       ..initialize().then((_) {
//         setState(() {});
//       });
//
//     _youtubeController = YoutubePlayerController(
//       initialVideoId: 'dQw4w9WgXcQ',
//       flags: YoutubePlayerFlags(
//         autoPlay: false,
//         mute: false,
//       ),
//     );
//
//     // Initialize marked questions
//     for (int i = 0; i < 4; i++) {
//       markedQuestions[i] = false;
//     }
//   }
//
//   @override
//   void dispose() {
//     _videoController.dispose();
//     _youtubeController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.deepPurple,
//         title: Text(
//           "BCS Preliminary Exam",
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//         ),
//         actions: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: CircleAvatar(
//               backgroundColor: Colors.amber[700],
//               child: Text(
//                 '${selectedAnswers.length}',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Exam header with info
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.deepPurple,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(20),
//                 bottomRight: Radius.circular(20),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.deepPurple.withOpacity(0.2),
//                   blurRadius: 10,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Text(
//                   "BCS Preliminary Exam - 2023",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20,
//                   ),
//                 ),
//                 SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     _buildInfoCard(Icons.help_outline, "Questions", "100"),
//                     _buildInfoCard(Icons.timer, "Time", "60 min"),
//                     _buildInfoCard(Icons.alarm, "Remaining", "59:41"),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//
//           // Main content area with all questions
//           Expanded(
//             child: SingleChildScrollView(
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   // Question 1 - Text question
//                   _buildTextQuestion(
//                     question: "১. বাংলাদেশে প্রথম চায়ের চাষ আরম্ভ হয় -",
//                     options: [
//                       "ক. সিলেটের মালনীছড়ায়",
//                       "খ. সিলেটের তামাবিলে",
//                       "গ. পার্বত্য চট্টগ্রামের খাগড়াছড়িতে",
//                       "ঘ. সিলেটের জাফলং এ",
//                     ],
//                     questionIndex: 0,
//                   ),
//                   SizedBox(height: 24),
//
//                   // Question 2 - Image question
//                   _buildImageQuestion(
//                     question: "২. এই ভাস্কর্যটি কোথায় অবস্থিত?",
//                     imageUrl: "https://via.placeholder.com/600x400?text=Sample+Question+Image",
//                     options: [
//                       "ক. ঢাকা বিশ্ববিদ্যালয়",
//                       "খ. চট্টগ্রাম বন্দর",
//                       "গ. সোনারগাঁও",
//                       "ঘ. মহাস্থানগড়",
//                     ],
//                     questionIndex: 1,
//                   ),
//                   SizedBox(height: 24),
//
//                   // Question 3 - Video question
//                   _buildVideoQuestion(
//                     question: "৩. এই ভিডিওতে প্রদর্শিত স্থানটি কোথায়?",
//                     videoType: 'youtube',
//                     videoUrl: 'dQw4w9WgXcQ',
//                     options: [
//                       "ক. সুন্দরবন",
//                       "খ. কক্সবাজার",
//                       "গ. সেন্ট মার্টিন",
//                       "ঘ. কাপ্তাই লেক",
//                     ],
//                     questionIndex: 2,
//                   ),
//                   SizedBox(height: 24),
//
//                   // Question 4 - Written answer question
//                   _buildWrittenQuestion(
//                     question: "৪. বাংলাদেশের সংবিধানের প্রথম সংশোধনী সম্পর্কে লিখুন",
//                     questionIndex: 3,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Submit button
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: ElevatedButton(
//               onPressed: _submitExam,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepPurple,
//                 minimumSize: Size(double.infinity, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               child: Text(
//                 "Submit Exam",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//   void _submitExam() {
//     print(selectedAnswers);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text("Exam submitted successfully!"),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//   Widget _buildInfoCard(IconData icon, String title, String value) {
//     return Column(
//       children: [
//         Icon(icon, color: Colors.white, size: 28),
//         SizedBox(height: 4),
//         Text(
//           title,
//           style: TextStyle(color: Colors.white70, fontSize: 12),
//         ),
//         Text(
//           value,
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 14,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTextQuestion({
//     required String question,
//     required List<String> options,
//     required int questionIndex,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Text(
//                 question,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: Colors.deepPurple[800],
//                 ),
//               ),
//             ),
//             IconButton(
//               icon: Icon(
//                 markedQuestions[questionIndex]! ? Icons.bookmark : Icons.bookmark_border,
//                 color: markedQuestions[questionIndex]! ? Colors.orange : Colors.grey,
//               ),
//               onPressed: () {
//                 setState(() {
//                   markedQuestions[questionIndex] = !markedQuestions[questionIndex]!;
//                 });
//               },
//             ),
//           ],
//         ),
//         SizedBox(height: 8),
//         ...options.map(
//               (option) => Padding(
//             padding: const EdgeInsets.only(bottom: 8.0),
//             child: Card(
//               elevation: 1,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: RadioListTile<String>(
//                 value: option,
//                 groupValue: selectedAnswers[questionIndex],
//                 onChanged: (value) {
//                   setState(() {
//                     if (selectedAnswers[questionIndex] == value) {
//                       selectedAnswers.remove(questionIndex); // Unmark if same option selected
//                     } else {
//                       selectedAnswers[questionIndex] = value;
//                     }
//                   });
//                 },
//                 title: Text(
//                   option,
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 activeColor: Colors.deepPurple,
//                 tileColor: Colors.white,
//                 dense: true,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildImageQuestion({
//     required String question,
//     required String imageUrl,
//     required List<String> options,
//     required int questionIndex,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     question,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                       color: Colors.deepPurple[800],
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.network(
//                       imageUrl,
//                       width: double.infinity,
//                       height: 200,
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return Container(
//                           height: 200,
//                           child: Center(
//                             child: CircularProgressIndicator(
//                               value: loadingProgress.expectedTotalBytes != null
//                                   ? loadingProgress.cumulativeBytesLoaded /
//                                   loadingProgress.expectedTotalBytes!
//                                   : null,
//                             ),
//                           ),
//                         );
//                       },
//                       errorBuilder: (context, error, stackTrace) {
//                         return Container(
//                           height: 200,
//                           color: Colors.grey[200],
//                           child: Center(
//                             child: Icon(Icons.error, color: Colors.red),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             IconButton(
//               icon: Icon(
//                 markedQuestions[questionIndex]! ? Icons.bookmark : Icons.bookmark_border,
//                 color: markedQuestions[questionIndex]! ? Colors.orange : Colors.grey,
//               ),
//               onPressed: () {
//                 setState(() {
//                   markedQuestions[questionIndex] = !markedQuestions[questionIndex]!;
//                 });
//               },
//             ),
//           ],
//         ),
//         SizedBox(height: 8),
//         ...options.map(
//               (option) => Padding(
//             padding: const EdgeInsets.only(bottom: 8.0),
//             child: Card(
//               elevation: 1,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: RadioListTile<String>(
//                 value: option,
//                 groupValue: selectedAnswers[questionIndex],
//                 onChanged: (value) {
//                   setState(() {
//                     if (selectedAnswers[questionIndex] == value) {
//                       selectedAnswers.remove(questionIndex);
//                     } else {
//                       selectedAnswers[questionIndex] = value;
//                     }
//                   });
//                 },
//                 title: Text(
//                   option,
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 activeColor: Colors.deepPurple,
//                 tileColor: Colors.white,
//                 dense: true,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildVideoQuestion({
//     required String question,
//     required String videoType,
//     required String videoUrl,
//     required List<String> options,
//     required int questionIndex,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     question,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                       color: Colors.deepPurple[800],
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   if (videoType == 'youtube')
//                     Container(
//                       height: 200,
//                       child: YoutubePlayer(
//                         controller: _youtubeController,
//                         showVideoProgressIndicator: true,
//                         progressIndicatorColor: Colors.deepPurple,
//                       ),
//                     )
//                   else
//                     Container(
//                       height: 200,
//                       child: _videoController.value.isInitialized
//                           ? AspectRatio(
//                         aspectRatio: _videoController.value.aspectRatio,
//                         child: VideoPlayer(_videoController),
//                       )
//                           : Center(child: CircularProgressIndicator()),
//                     ),
//                 ],
//               ),
//             ),
//             IconButton(
//               icon: Icon(
//                 markedQuestions[questionIndex]! ? Icons.bookmark : Icons.bookmark_border,
//                 color: markedQuestions[questionIndex]! ? Colors.orange : Colors.grey,
//               ),
//               onPressed: () {
//                 setState(() {
//                   markedQuestions[questionIndex] = !markedQuestions[questionIndex]!;
//                 });
//               },
//             ),
//           ],
//         ),
//         SizedBox(height: 8),
//         ...options.map(
//               (option) => Padding(
//             padding: const EdgeInsets.only(bottom: 8.0),
//             child: Card(
//               elevation: 1,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: RadioListTile<String>(
//                 value: option,
//                 groupValue: selectedAnswers[questionIndex],
//                 onChanged: (value) {
//                   setState(() {
//                     if (selectedAnswers[questionIndex] == value) {
//                       selectedAnswers.remove(questionIndex);
//                     } else {
//                       selectedAnswers[questionIndex] = value;
//                     }
//                   });
//                 },
//                 title: Text(
//                   option,
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 activeColor: Colors.deepPurple,
//                 tileColor: Colors.white,
//                 dense: true,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildWrittenQuestion({
//     required String question,
//     required int questionIndex,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Expanded(
//               child: Text(
//                 question,
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: Colors.deepPurple[800],
//                 ),
//               ),
//             ),
//             IconButton(
//               icon: Icon(
//                 markedQuestions[questionIndex]! ? Icons.bookmark : Icons.bookmark_border,
//                 color: markedQuestions[questionIndex]! ? Colors.orange : Colors.grey,
//               ),
//               onPressed: () {
//                 setState(() {
//                   markedQuestions[questionIndex] = !markedQuestions[questionIndex]!;
//                 });
//               },
//             ),
//           ],
//         ),
//         SizedBox(height: 8),
//         Card(
//           elevation: 1,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               maxLines: 10,
//               decoration: InputDecoration(
//                 border: InputBorder.none,
//                 hintText: "Type your answer here...",
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   if (value.isEmpty) {
//                     selectedAnswers.remove(questionIndex);
//                   } else {
//                     selectedAnswers[questionIndex] = value;
//                   }
//                 });
//               },
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
