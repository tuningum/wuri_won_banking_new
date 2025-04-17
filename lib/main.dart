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

  int _currentFrame = 0;
  bool _isLoading = true;
  final Map<int, Image> _frameCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheInitialFrame();
    });
  }

  Future<void> _precacheInitialFrame() async {
    final first = Image.asset('assets/frames/frame_0001.png');
    try {
      await precacheImage(first.image, context);
      setState(() {
        _frameCache[1] = first;
        _currentFrame = 1;
        _isLoading = false;
      });
      _playFrames(2, totalFrames);
    } catch (e) {
      debugPrint('❌ 프리캐시 실패: frame_0001.png');
    }
  }

  Future<void> _playFrames(int start, int end) async {
    for (int i = start; i <= end; i++) {
      final path = 'assets/frames/frame_${i.toString().padLeft(4, '0')}.png';
      final img = Image.asset(path);
      try {
        await precacheImage(img.image, context);
      } catch (e) {
        debugPrint('❌ 이미지 실패: $path');
      }
      _frameCache[i] = img;
      await Future.delayed(const Duration(milliseconds: frameDurationMs));
      if (!mounted) return;
      setState(() => _currentFrame = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = 'assets/frames/frame_${_currentFrame.toString().padLeft(4, '0')}.png';
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _frameCache[_currentFrame] ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '❌ 이미지 불러오기 실패',
                  style: TextStyle(color: Colors.red, fontSize: 18),
                ),
                Text(
                  path,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
      ),
    );
  }
}
