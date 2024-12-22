import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_feed_manager.dart';

class VideoScreen extends StatefulWidget {
  final VideoFeedManager feedManager;

  const VideoScreen({Key? key, required this.feedManager}) : super(key: key);

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final masterUrl = await widget.feedManager.getCurrentVideoMasterUrl();
    _controller = VideoPlayerController.networkUrl(Uri.parse(masterUrl));
    await _controller?.setLooping(true);
    await _controller!.initialize();
    setState(() {
      _isLoading = false;
    });
    _controller!.play();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }
}
