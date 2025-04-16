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
  static const int sequence1End = 28;
  static const int frameDurationMs = 50;

  int _stage = 0;
  int _currentFrame = 1;
  bool _isLoading = true;
  bool _isAnimating = false;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    setState(() => _isAnimating = true);

    for (int i = 1; i <= sequence1End; i++) {
      final assetPath = 'assets/frames/frame_$i.png';

      try {
        await precacheImage(AssetImage(assetPath), context);
      } catch (e) {
        debugPrint('⚠️ Failed to load image: $assetPath');
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
    final imagePath = 'assets/frames/frame_$_currentFrame.png';

    return Scaffold(
      body: Center(
        child: _isLoading
            ? Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Text(
            '이미지를 불러올 수 없습니다.',
            style: TextStyle(color: Colors.red),
          ),
        )
            : const Text('애니메이션 종료'),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
