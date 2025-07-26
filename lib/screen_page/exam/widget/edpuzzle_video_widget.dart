import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// class EdpuzzleVideoWidget extends StatefulWidget {
//   final String url;
//   const EdpuzzleVideoWidget({super.key, required this.url});
//
//   @override
//   State<EdpuzzleVideoWidget> createState() => _EdpuzzleVideoWidgetState();
// }
//
// class _EdpuzzleVideoWidgetState extends State<EdpuzzleVideoWidget> {
//   late VideoPlayerController _controller;
//   bool _initialized = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = VideoPlayerController.network(widget.url)
//       ..initialize().then((_) {
//         setState(() {
//           _initialized = true;
//         });
//       });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return _initialized
//         ? AspectRatio(
//       aspectRatio: _controller.value.aspectRatio,
//       child: Stack(
//         alignment: Alignment.bottomCenter,
//         children: [
//           VideoPlayer(_controller),
//           VideoProgressIndicator(_controller, allowScrubbing: true),
//           IconButton(
//             icon: Icon(
//               _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
//               color: Colors.white,
//               size: 32,
//             ),
//             onPressed: () {
//               setState(() {
//                 _controller.value.isPlaying
//                     ? _controller.pause()
//                     : _controller.play();
//               });
//             },
//           ),
//         ],
//       ),
//     )
//         : Container(
//       height: 180,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: Colors.black12,
//       ),
//       child: const Center(child: CircularProgressIndicator()),
//     );
//   }
// }


class EdpuzzleVideoWidget extends StatefulWidget {
  final String videoUrl;

  const EdpuzzleVideoWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _EdpuzzleVideoWidgetState createState() => _EdpuzzleVideoWidgetState();
}

class _EdpuzzleVideoWidgetState extends State<EdpuzzleVideoWidget> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      placeholder: Container(
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      ),
      autoInitialize: true,
    );

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Container(
      height: 200,
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    )
        : Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Chewie(controller: _chewieController),
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }
}