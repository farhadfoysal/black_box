import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class EdpuzzleVideoWidget extends StatefulWidget {
  final String videoUrl;

  const EdpuzzleVideoWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _EdpuzzleVideoWidgetState createState() => _EdpuzzleVideoWidgetState();
}

class _EdpuzzleVideoWidgetState extends State<EdpuzzleVideoWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.network(
        widget.videoUrl,
        // Explicit format hint for better format detection
        formatHint: VideoFormat.dash,
      )
        ..addListener(_updateState)
        ..setLooping(false)
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
          }
        }).catchError((error) {
          if (mounted) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Unsupported video format';
            });
          }
        });
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize video player';
        });
      }
    }
  }

  void _updateState() {
    if (mounted) {
      setState(() => _isPlaying = _controller.value.isPlaying);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16/9,
          child: _buildPlayerContent(),
        ),
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (_hasError) {
      return _buildErrorState();
    }

    if (!_isInitialized) {
      return _buildLoadingState();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(_controller),
        _buildPlayPauseOverlay(),
        _buildProgressBar(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Video playback error',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryInitialization,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(
              Theme.of(context).primaryColor),
        ),
      ),
    );
  }

  Widget _buildPlayPauseOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _togglePlay,
        child: AnimatedOpacity(
          opacity: _isPlaying ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          child: Container(
            color: Colors.black26,
            child: Center(
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: VideoProgressIndicator(
        _controller,
        allowScrubbing: true,
        colors: VideoProgressColors(
          playedColor: Theme.of(context).primaryColor,
          bufferedColor: Colors.grey[300]!,
          backgroundColor: Colors.grey[600]!,
        ),
      ),
    );
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _hasError = false;
      _errorMessage = null;
      _isInitialized = false;
    });
    await _initializePlayer();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateState);
    _controller.dispose();
    super.dispose();
  }
}