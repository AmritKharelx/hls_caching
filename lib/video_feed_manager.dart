import 'dart:async';
import 'dart:math';
import 'hls_proxy.dart';
import 'package:uuid/uuid.dart';

class VideoFeedManager {
  final HlsProxy proxy;
  final List<String> videoUrls;

  int currentIndex = 0;
  final Map<int, String> _videoIdMap = {};
  // Key: index in videoUrls, Value: videoId

  final int range = 10;

  // Prefetch queue
  List<int> _prefetchQueue = [];
  Future<void>? _currentPrefetchTask;
  bool _stopPrefetch = false; // Used to cancel ongoing prefetch when range changes

  VideoFeedManager({required this.proxy, required this.videoUrls});

  Future<void> initialize() async {
    if (!proxy.isRunning) {
      await proxy.start();
    }

    // Prepare the current video first
    await _ensurePrepared(currentIndex);
    await proxy.prefetchInitialSegments(_videoIdMap[currentIndex]!, count: 2);

    // Start background prefetch of surrounding videos
    _startPrefetchForRange(currentIndex);
  }

  Future<String> getCurrentVideoMasterUrl() async {
    // Ensure current video is prepared (on-demand)
    await _ensurePrepared(currentIndex);
    return proxy.buildMasterUrl(_videoIdMap[currentIndex]!);
  }

  Future<void> updateCurrentIndex(int newIndex) async {
    currentIndex = newIndex;
    // Update caching in the background
    _startPrefetchForRange(currentIndex);
  }

  void _startPrefetchForRange(int index) {
    // Build new prefetch queue
    _stopPrefetch = true; // stop old prefetch task
    _prefetchQueue = [];
    final start = index + 1;
    final end = min(index + range, videoUrls.length - 1);
    for (int i = start; i <= end; i++) {
      _prefetchQueue.add(i);
    }

    // Also consider backward range if desired (not requested by user, we skip it for simplicity)
    // If we wanted backward, we could add indexes from index-1 downto index-range

    // Start processing the new queue
    _processPrefetchQueue();
  }

  void _processPrefetchQueue() {
    _stopPrefetch = false;
    _currentPrefetchTask = _runPrefetchTasks();
  }

  Future<void> _runPrefetchTasks() async {
    for (final i in _prefetchQueue) {
      if (_stopPrefetch) break;
      await _ensurePrepared(i); // prepare playlists if not done
      await proxy.prefetchInitialSegments(_videoIdMap[i]!, count: 2);
    }

    // Optional: Remove old caches outside range
    _cleanupOutOfRangeCaches();
  }

  void _cleanupOutOfRangeCaches() {
    // Remove videos outside current range if we want to free memory
    final start = max(currentIndex - range, 0);
    final end = min(currentIndex + range, videoUrls.length - 1);

    _videoIdMap.keys
        .where((i) => i < start || i > end)
        .toList()
        .forEach((oldIndex) {
      final oldVideoId = _videoIdMap[oldIndex]!;
      proxy.removeVideoCache(oldVideoId);
      _videoIdMap.remove(oldIndex);
    });
  }

  Future<String> _ensurePrepared(int index) async {
    if (_videoIdMap.containsKey(index)) {
      return _videoIdMap[index]!;
    }

    final videoUrl = videoUrls[index];
    final videoId = const Uuid().v4();
    await proxy.preparePlaylists(videoId, videoUrl);
    _videoIdMap[index] = videoId;
    return videoId;
  }
}
