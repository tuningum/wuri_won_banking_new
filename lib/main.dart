import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        colorScheme: const ColorScheme.light(
          background: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const int totalFrames = 175;
  static const int frameDurationMs = 40;

  int _currentFrame = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _playAnimation();
  }

  void _playAnimation() async {
    for (int i = 1; i <= totalFrames; i++) {
      final path = 'assets/frames/frame_$i.png';

      try {
        await precacheImage(AssetImage(path), context);
      } catch (e) {
        debugPrint('❌ 이미지 실패: $path');
      }

      await Future.delayed(const Duration(milliseconds: frameDurationMs));

      if (!mounted) return;
      setState(() {
        _currentFrame = i;
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final path = 'assets/frames/frame_$_currentFrame.png';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              '이미지를 불러올 수 없습니다.',
              style: TextStyle(color: Colors.red, fontSize: 16),
            );
          },
        ),
      ),
    );
  }
}
