import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class HlsProxy {
  final Dio dio = Dio();
  HttpServer? _server;
  int _port = 0;

  bool get isRunning => _server != null;
  int get port => _port;

  /// Data structure for multiple videos:
  /// Key: videoId, Value: M3U8 data and segment cache
  final Map<String, VideoCache> _videoCaches = {};

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    print('Local HLS proxy running at http://localhost:$_port');
    _server?.listen(_handleRequest);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final uri = request.uri;
      final segments = uri.pathSegments;
      if (segments.isEmpty) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final videoId = segments.first;
      if (!_videoCaches.containsKey(videoId)) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      if (segments.length == 1 && segments[0] == videoId) {
        // Just a path to videoId without trailing file
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      final lastSegment = segments.length > 1 ? segments.last : '';
      switch (lastSegment) {
        case 'master.m3u8':
          _serveMaster(request, videoId);
          break;
        case 'index.m3u8':
          _serveIndex(request, videoId);
          break;
        default:
          if (lastSegment == 'segment') {
            await _serveSegment(request, videoId);
          } else {
            request.response.statusCode = HttpStatus.notFound;
            await request.response.close();
          }
          break;
      }
    } catch (e) {
      print('Error handling request: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  /// Prepare playlists for a given video URL and assign a videoId
  /// Returns the assigned videoId
  Future<String> preparePlaylists(String videoId, String masterUrl) async {
    // If already prepared, just return existing videoId
    if (_videoCaches.containsKey(videoId)) {
      return videoId;
    }

    final masterResponse = await dio.get(masterUrl, options: Options(responseType: ResponseType.plain));
    final masterContent = masterResponse.data as String;
    final lines = masterContent.split('\n');

    // Find variant line
    String? variantLine = lines.firstWhere((line) => line.endsWith('.m3u8'), orElse: () => '');
    if (variantLine.isEmpty) {
      throw Exception("No variant playlist found in master.m3u8");
    }

    final variantUrl = Uri.parse(masterUrl).resolve(variantLine).toString();
    final variantResponse = await dio.get(variantUrl, options: Options(responseType: ResponseType.plain));
    final variantContent = variantResponse.data as String;

    // Rewrite variant (index.m3u8)
    final variantLines = variantContent.split('\n');
    final rewrittenVariantLines = variantLines.map((line) {
      if (line.endsWith('.ts')) {
        final originalSegmentUrl = Uri.parse(variantUrl).resolve(line).toString();
        return 'http://localhost:$_port/$videoId/segment?original_url=${Uri.encodeComponent(originalSegmentUrl)}';
      }
      return line;
    }).toList();
    final rewrittenIndexM3U8 = rewrittenVariantLines.join('\n');

    // Rewrite master
    final rewrittenMasterLines = lines.map((line) {
      if (line.endsWith('.m3u8')) {
        return 'http://localhost:$_port/$videoId/index.m3u8';
      }
      return line;
    }).toList();
    final rewrittenMasterM3U8 = rewrittenMasterLines.join('\n');

    _videoCaches[videoId] = VideoCache(
      masterUrl: masterUrl,
      rewrittenMaster: rewrittenMasterM3U8,
      rewrittenIndex: rewrittenIndexM3U8,
    );

    return videoId;
  }

  void _serveMaster(HttpRequest request, String videoId) {
    final cache = _videoCaches[videoId]!;
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType('application', 'vnd.apple.mpegurl');
    request.response.write(cache.rewrittenMaster);
    request.response.close();
  }

  void _serveIndex(HttpRequest request, String videoId) {
    final cache = _videoCaches[videoId]!;
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType('application', 'vnd.apple.mpegurl');
    request.response.write(cache.rewrittenIndex);
    request.response.close();
  }

  Future<void> _serveSegment(HttpRequest request, String videoId) async {
    final queryParameters = request.uri.queryParameters;
    final originalUrl = queryParameters['original_url'];
    if (originalUrl == null) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    final cache = _videoCaches[videoId]!;

    // Check if cached
    if (!cache.segmentCache.containsKey(originalUrl)) {
      // Fetch from network and cache
      try {
        final response = await dio.get<List<int>>(originalUrl, options: Options(responseType: ResponseType.bytes));
        final bytes = response.data!;
        final tempDir = await getTemporaryDirectory();
        final fileName = Uri.parse(originalUrl).pathSegments.last;
        final file = File('${tempDir.path}/$videoId-$fileName');
        await file.writeAsBytes(bytes);
        cache.segmentCache[originalUrl] = file.path;
      } catch (e) {
        print('Segment fetch error: $e');
        request.response.statusCode = HttpStatus.serviceUnavailable;
        await request.response.close();
        return;
      }
    }

    final segmentPath = cache.segmentCache[originalUrl]!;
    final segmentFile = File(segmentPath);
    if (!segmentFile.existsSync()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    // Serve cached segment
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType('video', 'MP2T');
    await request.response.addStream(segmentFile.openRead());
    await request.response.close();
  }

  /// Prefetch the first few segments of a video to minimize initial latency.
  Future<void> prefetchInitialSegments(String videoId, {int count = 2}) async {
    final cache = _videoCaches[videoId]!;
    final lines = cache.rewrittenIndex.split('\n');
    final segmentLines = lines.where((l) => l.startsWith('http://localhost')).take(count);

    for (var line in segmentLines) {
      final uri = Uri.parse(line);
      final originalUrl = uri.queryParameters['original_url'];
      if (originalUrl != null && !cache.segmentCache.containsKey(originalUrl)) {
        try {
          final response = await dio.get<List<int>>(originalUrl, options: Options(responseType: ResponseType.bytes));
          final bytes = response.data!;
          final tempDir = await getTemporaryDirectory();
          final fileName = Uri.parse(originalUrl).pathSegments.last;
          final file = File('${tempDir.path}/$videoId-$fileName');
          await file.writeAsBytes(bytes);
          cache.segmentCache[originalUrl] = file.path;
          print('Prefetched segment: $originalUrl');
        } catch (e) {
          print('Prefetch error: $e');
        }
      }
    }
  }

  /// Remove a video's cache if desired
  void removeVideoCache(String videoId) {
    _videoCaches.remove(videoId);
  }

  bool hasVideo(String videoId) {
    return _videoCaches.containsKey(videoId);
  }

  String buildMasterUrl(String videoId) {
    return 'http://localhost:$_port/$videoId/master.m3u8';
  }
}

class VideoCache {
  final String masterUrl;
  final String rewrittenMaster;
  final String rewrittenIndex;
  final Map<String, String> segmentCache = {};

  VideoCache({
    required this.masterUrl,
    required this.rewrittenMaster,
    required this.rewrittenIndex,
  });
}
