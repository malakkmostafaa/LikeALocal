import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String url;
  final bool autoPlay;

  const VideoPlayerWidget({
    super.key,
    required this.url,
    this.autoPlay = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;

  bool _initialized = false;
  bool _hasError = false;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _disposeController();
      _initController();
    }
  }

  Future<void> _initController() async {
    if (widget.url.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _initialized = false;
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _initialized = false;
          _hasError = false;
        });
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );

      _controller = controller;

      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setLooping(true);

      if (widget.autoPlay) {
        await controller.play();
      }

      setState(() {
        _initialized = true;
        _hasError = false;
      });
    } catch (e) {
      debugPrint('Video player error: $e');

      if (mounted) {
        setState(() {
          _hasError = true;
          _initialized = false;
        });
      }
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;

    if (controller != null) {
      await controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _togglePlay() {
    final controller = _controller;

    if (controller == null || !_initialized) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
  }

  void _toggleMute() {
    final controller = _controller;

    if (controller == null || !_initialized) return;

    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE26D45);

    final controller = _controller;

    if (_hasError) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Icon(
            Icons.videocam_off_rounded,
            color: Colors.white54,
            size: 40,
          ),
        ),
      );
    }

    if (!_initialized || controller == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(color: Colors.black),
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
        GestureDetector(
          onTap: _togglePlay,
          child: AnimatedOpacity(
            opacity: controller.value.isPlaying ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: accent,
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white10,
            ),
          ),
        ),
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: _toggleMute,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(153),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
