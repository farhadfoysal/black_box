import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class EdpuzzleVideoWidget extends StatefulWidget {
  final String videoUrl;

  const EdpuzzleVideoWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  State<EdpuzzleVideoWidget> createState() => _EdpuzzleVideoWidgetState();
}

class _EdpuzzleVideoWidgetState extends State<EdpuzzleVideoWidget> {
  late YoutubePlayerController _youtubeController;
  late VideoPlayerController _videoController;
  bool _isYoutube = false;
  bool _isLoading = true;
  bool _isFullScreen = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  Future<void> _initializePlayer() async {
    try {
      _isYoutube = _isYouTubeUrl(widget.videoUrl);

      if (_isYoutube) {
        final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
        if (videoId == null) throw 'Invalid YouTube URL';

        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            controlsVisibleAtStart: true,
            forceHD: true,
          ),
        );
      } else {
        _videoController = VideoPlayerController.network(widget.videoUrl)
          ..addListener(() {
            if (mounted) setState(() {});
          });
        await _videoController.initialize();
        await _videoController.play();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load video:\n${e.toString()}';
      });
    }
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    setState(() => _isFullScreen = !_isFullScreen);
  }

  @override
  void dispose() {
    _youtubeController.dispose();
    _videoController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen && !_isYoutube) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _videoController,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Colors.red,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.grey[700]!,
                  ),
                ),
              ),
              _PlayPauseOverlay(controller: _videoController),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 30),
                  onPressed: _toggleFullScreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _isLoading
              ? _buildLoading()
              : (_error != null
              ? _buildError()
              : (_isYoutube ? _buildYouTubePlayer() : _buildNetworkPlayer())),
        ),
      ),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildError() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 50),
              const SizedBox(height: 10),
              Text(
                _error ?? 'Failed to load video',
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initializePlayer,
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYouTubePlayer() {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController,
        aspectRatio: 16 / 9,
        onEnded: (metaData) {
          // Handle video end
        },
      ),
      builder: (context, player) => player,
    );
  }

  Widget _buildNetworkPlayer() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        VideoPlayer(_videoController),
        VideoProgressIndicator(
          _videoController,
          allowScrubbing: true,
          colors: VideoProgressColors(
            playedColor: Colors.red,
            bufferedColor: Colors.grey,
            backgroundColor: Colors.grey[700]!,
          ),
        ),
        _PlayPauseOverlay(controller: _videoController),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white),
            onPressed: _toggleFullScreen,
          ),
        ),
      ],
    );
  }
}

class _PlayPauseOverlay extends StatelessWidget {
  final VideoPlayerController controller;

  const _PlayPauseOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.value.isPlaying ? controller.pause() : controller.play();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: controller.value.isPlaying ? 0.0 : 0.8,
              duration: const Duration(milliseconds: 300),
              child: Container(color: Colors.black),
            ),
          ),
          if (!controller.value.isPlaying)
            const Center(
              child: Icon(Icons.play_arrow, color: Colors.white, size: 64),
            ),
        ],
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:video_player/video_player.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//
// class EdpuzzleVideoWidget extends StatefulWidget {
//   final String videoUrl;
//
//   const EdpuzzleVideoWidget({Key? key, required this.videoUrl}) : super(key: key);
//
//   @override
//   State<EdpuzzleVideoWidget> createState() => _EdpuzzleVideoWidgetState();
// }
//
// class _EdpuzzleVideoWidgetState extends State<EdpuzzleVideoWidget> {
//   YoutubePlayerController? _youtubeController;
//   VideoPlayerController? _networkController;
//   bool _isYoutube = false;
//   bool _isLoading = true;
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializePlayer();
//
//     // SystemChrome.setPreferredOrientations([
//     //   DeviceOrientation.landscapeLeft,
//     //   DeviceOrientation.landscapeRight,
//     // ]);
//
//   }
//
//   bool _isYouTubeUrl(String url) {
//     return url.contains('youtube.com') || url.contains('youtu.be');
//   }
//
//   Future<void> _initializePlayer() async {
//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });
//
//     try {
//       _isYoutube = _isYouTubeUrl(widget.videoUrl);
//
//       if (_isYoutube) {
//         final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
//         if (videoId == null) throw 'Invalid YouTube URL';
//
//         _youtubeController = YoutubePlayerController(
//           initialVideoId: videoId,
//           flags: const YoutubePlayerFlags(
//             autoPlay: true,
//             mute: false,
//             enableCaption: true,
//             controlsVisibleAtStart: true,
//             forceHD: true,
//           ),
//         );
//       } else {
//         _networkController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
//         await _networkController!.initialize();
//         _networkController!.setLooping(true);
//         _networkController!.play();
//       }
//
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//         _error = 'ভিডিও চালু করতে ব্যর্থ হয়েছে:\n${e.toString()}';
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _youtubeController?.dispose();
//     _networkController?.dispose();
//     // SystemChrome.setPreferredOrientations([
//     //   DeviceOrientation.portraitUp,
//     //   DeviceOrientation.portraitDown,
//     // ]);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 8,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(16),
//         child: AspectRatio(
//           aspectRatio: 16 / 9,
//           child: _isLoading
//               ? _buildLoading()
//               : (_error != null
//               ? _buildError()
//               : (_isYoutube ? _buildYouTubePlayer() : _buildNetworkPlayer())),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLoading() {
//     return const Center(child: CircularProgressIndicator());
//   }
//
//   Widget _buildError() {
//     return Container(
//       color: Colors.grey[100],
//       child: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error, color: Colors.red, size: 50),
//               const SizedBox(height: 10),
//               Text(
//                 _error ?? 'ভিডিও লোড করতে ব্যর্থ হয়েছে',
//                 style: const TextStyle(fontSize: 16, color: Colors.red),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 onPressed: _initializePlayer,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text("আবার চেষ্টা করুন"),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildYouTubePlayer() {
//     return YoutubePlayerBuilder(
//       player: YoutubePlayer(controller: _youtubeController!),
//       builder: (context, player) => player,
//     );
//   }
//
//   Widget _buildNetworkPlayer() {
//     return Stack(
//       alignment: Alignment.bottomCenter,
//       children: [
//         GestureDetector(
//           onTap: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (_) => FullScreenVideoPlayer(controller: _networkController!),
//               ),
//             );
//           },
//           child: VideoPlayer(_networkController!),
//         ),
//         VideoProgressIndicator(_networkController!, allowScrubbing: true),
//         _PlayPauseOverlay(controller: _networkController!),
//         Positioned(
//           top: 8,
//           right: 8,
//           child: IconButton(
//             icon: const Icon(Icons.fullscreen, color: Colors.white),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => FullScreenVideoPlayer(controller: _networkController!),
//                 ),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// class _PlayPauseOverlay extends StatelessWidget {
//   final VideoPlayerController controller;
//
//   const _PlayPauseOverlay({required this.controller});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         controller.value.isPlaying ? controller.pause() : controller.play();
//       },
//       child: Stack(
//         children: [
//           Positioned.fill(
//             child: AnimatedOpacity(
//               opacity: controller.value.isPlaying ? 0.0 : 0.8,
//               duration: const Duration(milliseconds: 300),
//               child: Container(color: Colors.black),
//             ),
//           ),
//           if (!controller.value.isPlaying)
//             const Center(
//               child: Icon(Icons.play_arrow, color: Colors.white, size: 64),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
// class FullScreenVideoPlayer extends StatefulWidget {
//   final VideoPlayerController controller;
//
//   const FullScreenVideoPlayer({Key? key, required this.controller}) : super(key: key);
//
//   @override
//   State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
// }
//
// class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//
//     // Lock to landscape mode on fullscreen entry
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.landscapeLeft,
//       DeviceOrientation.landscapeRight,
//     ]);
//
//     // Hide system overlays (like status bar and nav bar)
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//   }
//
//   @override
//   void dispose() {
//     // Re-enable portrait orientation when exiting fullscreen
//     SystemChrome.setPreferredOrientations([
//       DeviceOrientation.portraitUp,
//       DeviceOrientation.portraitDown,
//     ]);
//
//     // Restore system UI overlays
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = widget.controller;
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: controller.value.isInitialized
//             ? Stack(
//           alignment: Alignment.bottomCenter,
//           children: [
//             AspectRatio(
//               aspectRatio: controller.value.aspectRatio,
//               child: VideoPlayer(controller),
//             ),
//             _PlayPauseOverlay(controller: controller),
//             VideoProgressIndicator(controller, allowScrubbing: true),
//             Positioned(
//               top: 30,
//               right: 20,
//               child: IconButton(
//                 icon: const Icon(Icons.close, color: Colors.white, size: 30),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//           ],
//         )
//             : const Center(child: CircularProgressIndicator()),
//       ),
//     );
//   }
// }
