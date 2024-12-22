import 'package:flutter/material.dart';
import 'hls_proxy.dart';
import 'video_feed_manager.dart';
import 'video_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final videoUrls = [
    "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-34f3cf1a-e830-4b76-b2c2-3069cbc17cae/master.m3u8",
    "https://media.tenets.gg/showcase/ArjuBalami/S-150e4b27-da15-4ae9-bb73-86a14ab1937b/master.m3u8",
    "https://media.tenets.gg/showcase/poison/S-c400199b-4ed6-4711-9a40-4fa472fbce7e/master.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-9ddb7ea6-f2ae-443b-bc8e-275946be2d6f/master.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-0f740a19-eaba-4ee5-9588-bb36caf137fa/master.m3u8",
    "https://media.tenets.gg/showcase/BeastOmago/S-addfd681-5caf-4ddf-9cf7-d693915dcba0/master.m3u8",
    "https://media.tenets.gg/showcase/mauu/S-16d04c9c-9cc6-4297-8408-e9317e335a64/master.m3u8",
    "https://media.tenets.gg/showcase/shuvam/S-be1cb4bc-7a00-4790-bb5f-c1711bbc7101/master.m3u8",
    "https://media.tenets.gg/showcase/abyss/S-1addbd42-c80f-4904-b62c-18eb0fa627d9/master.m3u8",
    "https://media.tenets.gg/showcase/shuvam/S-33dbd1c0-a3dc-478f-8980-b44072f25d55/master.m3u8",
    "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-34f3cf1a-e830-4b76-b2c2-3069cbc17cae/master.m3u8",
    "https://media.tenets.gg/showcase/ArjuBalami/S-150e4b27-da15-4ae9-bb73-86a14ab1937b/master.m3u8",
    "https://media.tenets.gg/showcase/poison/S-c400199b-4ed6-4711-9a40-4fa472fbce7e/master.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-9ddb7ea6-f2ae-443b-bc8e-275946be2d6f/master.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-0f740a19-eaba-4ee5-9588-bb36caf137fa/master.m3u8",
    "https://media.tenets.gg/showcase/BeastOmago/S-addfd681-5caf-4ddf-9cf7-d693915dcba0/master.m3u8",
    "https://media.tenets.gg/showcase/mauu/S-16d04c9c-9cc6-4297-8408-e9317e335a64/master.m3u8",
    "https://media.tenets.gg/showcase/shuvam/S-be1cb4bc-7a00-4790-bb5f-c1711bbc7101/master.m3u8",
    "https://media.tenets.gg/showcase/abyss/S-1addbd42-c80f-4904-b62c-18eb0fa627d9/master.m3u8",
    "https://media.tenets.gg/showcase/shuvam/S-33dbd1c0-a3dc-478f-8980-b44072f25d55/master.m3u8",
    "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-34f3cf1a-e830-4b76-b2c2-3069cbc17cae/master.m3u8",
    "https://media.tenets.gg/showcase/ArjuBalami/S-150e4b27-da15-4ae9-bb73-86a14ab1937b/master.m3u8",
    "https://media.tenets.gg/showcase/poison/S-c400199b-4ed6-4711-9a40-4fa472fbce7e/master.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-9ddb7ea6-f2ae-443b-bc8e-275946be2d6f/master.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-0f740a19-eaba-4ee5-9588-bb36caf137fa/master.m3u8",
    "https://media.tenets.gg/showcase/BeastOmago/S-addfd681-5caf-4ddf-9cf7-d693915dcba0/master.m3u8",
    "https://media.tenets.gg/showcase/mauu/S-16d04c9c-9cc6-4297-8408-e9317e335a64/master.m3u8",
    "https://media.tenets.gg/showcase/shuvam/S-be1cb4bc-7a00-4790-bb5f-c1711bbc7101/master.m3u8",
    "https://media.tenets.gg/showcase/abyss/S-1addbd42-c80f-4904-b62c-18eb0fa627d9/master.m3u8",
    "https://media.tenets.gg/showcase/shuvam/S-33dbd1c0-a3dc-478f-8980-b44072f25d55/master.m3u8",
    "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-34f3cf1a-e830-4b76-b2c2-3069cbc17cae/master.m3u8",
    "https://media.tenets.gg/showcase/ArjuBalami/S-150e4b27-da15-4ae9-bb73-86a14ab1937b/master.m3u8",
    "https://media.tenets.gg/showcase/poison/S-c400199b-4ed6-4711-9a40-4fa472fbce7e/master.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-9ddb7ea6-f2ae-443b-bc8e-275946be2d6f/master.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-0f740a19-eaba-4ee5-9588-bb36caf137fa/master.m3u8",
    "https://media.tenets.gg/showcase/BeastOmago/S-addfd681-5caf-4ddf-9cf7-d693915dcba0/master.m3u8",
    "https://media.tenets.gg/showcase/mauu/S-16d04c9c-9cc6-4297-8408-e9317e335a64/master.m3u8",
    "https://media.tenets.gg/showcase/shuvam/S-be1cb4bc-7a00-4790-bb5f-c1711bbc7101/master.m3u8",
    "https://media.tenets.gg/showcase/abyss/S-1addbd42-c80f-4904-b62c-18eb0fa627d9/master.m3u8",
    "https://media.tenets.gg/showcase/shuvam/S-33dbd1c0-a3dc-478f-8980-b44072f25d55/master.m3u8",
    "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-34f3cf1a-e830-4b76-b2c2-3069cbc17cae/master.m3u8",
    "https://media.tenets.gg/showcase/ArjuBalami/S-150e4b27-da15-4ae9-bb73-86a14ab1937b/master.m3u8",
    "https://media.tenets.gg/showcase/poison/S-c400199b-4ed6-4711-9a40-4fa472fbce7e/master.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-9ddb7ea6-f2ae-443b-bc8e-275946be2d6f/master.m3u8",
    "https://media.tenets.gg/showcase/rosan38/S-0f740a19-eaba-4ee5-9588-bb36caf137fa/master.m3u8",
    "https://media.tenets.gg/showcase/BeastOmago/S-addfd681-5caf-4ddf-9cf7-d693915dcba0/master.m3u8",
    "https://media.tenets.gg/showcase/mauu/S-16d04c9c-9cc6-4297-8408-e9317e335a64/master.m3u8",
    "https://media.tenets.gg/showcase/shuvam/S-be1cb4bc-7a00-4790-bb5f-c1711bbc7101/master.m3u8",
    "https://media.tenets.gg/showcase/abyss/S-1addbd42-c80f-4904-b62c-18eb0fa627d9/master.m3u8",
    "https://media.tenets.gg/showcase/shuvam/S-33dbd1c0-a3dc-478f-8980-b44072f25d55/master.m3u8",
  ];

  final proxy = HlsProxy();
  final feedManager = VideoFeedManager(proxy: proxy, videoUrls: videoUrls);
  await feedManager.initialize();

  runApp(MyApp(feedManager: feedManager));
}

class MyApp extends StatelessWidget {
  final VideoFeedManager feedManager;
  const MyApp({Key? key, required this.feedManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HLS TikTok-like Feed',
      home: Scaffold(
        body: PageView.builder(
          scrollDirection: Axis.vertical,
          itemCount: feedManager.videoUrls.length,
          onPageChanged: (index) {
            feedManager.updateCurrentIndex(index);
          },
          itemBuilder: (context, index) {
            feedManager.currentIndex = index;
            return VideoScreen(feedManager: feedManager);
          },
        ),
      ),
    );
  }
}
