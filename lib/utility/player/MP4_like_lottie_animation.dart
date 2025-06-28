import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MP4LikeLottieAnimation extends StatefulWidget {
  final String assetPath;
  const MP4LikeLottieAnimation({super.key, required this.assetPath});

  @override
  State<MP4LikeLottieAnimation> createState() => _MP4LikeLottieAnimationState();
}

class _MP4LikeLottieAnimationState extends State<MP4LikeLottieAnimation> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0); // mute it
        _controller.play(); // auto-play
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _controller.value.isInitialized
          ? SizedBox(
        height: 300,
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      )
          : const CircularProgressIndicator(),
    );
  }
}
