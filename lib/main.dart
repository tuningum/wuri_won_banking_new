import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // 앱 초기화 설정
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // iOS 시스템 UI 설정
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
  // 시퀀스 정의 - 첫 번째 시퀀스만
  static const int sequence1End = 28;    // frame_1 ~ frame_28

  // 프레임당 지속 시간 (애니메이션 속도 조절)
  static const int frameDurationMs = 50;

  int _stage = 0;
  int _currentFrame = 1;
  bool _isLoading = true;
  bool _isAnimating = false;

  // 애니메이션 컨트롤러
  late AnimationController _animationController;

  // ValueNotifier
  final ValueNotifier<int> _frameNotifier = ValueNotifier<int>(1);

  @override
  void initState() {
    super.initState();

    // 중요: 직접 호출하지 않고 WidgetsBinding.instance.addPostFrameCallback 사용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadInitialImages();
    });
  }

  Future<void> _preloadInitialImages() async {
    try {
      print('첫 프레임 로드 시작');

      // 처음 몇 개의 이미지만 미리 로드
      for (int i = 1; i <= 5; i++) {
        final image = AssetImage('assets/frames/frame_$i.png');
        await precacheImage(image, context);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentFrame = 1;
          _frameNotifier.value = 1;
        });

        // 첫 시퀀스 애니메이션 설정
        _setupSequenceAnimation(1, sequence1End, () {
          setState(() {
            _stage = 1;
          });
        });

        // 첫 시퀀스 자동 시작
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            _animationController.forward();
          }
        });
      }
    } catch (e) {
      print('이미지 프리로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupSequenceAnimation(int start, int end, VoidCallback onComplete) {
    // 이전 컨트롤러 정리
    if (_isAnimating && _animationController.isAnimating) {
      _animationController.stop();
      _animationController.dispose();
    }

    // 애니메이션 컨트롤러 설정
    _animationController = AnimationController(
      duration: Duration(milliseconds: (end - start + 1) * frameDurationMs),
      vsync: this,
    );

    // 애니메이션 리스너 추가
    _animationController.addListener(() {
      final frame = start +
          (_animationController.value * (end - start)).round();

      if (frame != _currentFrame && frame >= start && frame <= end) {
        _currentFrame = frame;
        _frameNotifier.value = frame;
      }
    });

    // 애니메이션 완료 리스너
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isAnimating = false;
        onComplete();
      } else if (status == AnimationStatus.forward) {
        _isAnimating = true;
      }
    });
  }

  // 터치 이벤트 처리 - 첫 번째 시퀀스에서는 아무 동작 없음
  void _handleTap() {
    print('터치 감지: 스테이지=$_stage');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.white,
          child: ValueListenableBuilder<int>(
            valueListenable: _frameNotifier,
            builder: (context, frameNumber, _) {
              return RepaintBoundary(
                child: Image.asset(
                  'assets/frames/frame_$frameNumber.png',
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (context, error, stackTrace) {
                    print('이미지 로드 실패: $frameNumber, 오류: $error');
                    return Container(
                      color: Colors.white,
                      child: Center(
                        child: Text(
                          '이미지 로드 실패: $frameNumber\n$error',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _frameNotifier.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
