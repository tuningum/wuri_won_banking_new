import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // 앱 초기화 설정
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // iOS 시스템 UI 설정 (iOS에서 중요)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light, // iOS 상태바 설정
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
  // 시퀀스 정의
  static const int sequence1End = 28;    // frame_1 ~ frame_28
  static const int sequence2End = 71;    // frame_29 ~ frame_71
  static const int sequence3End = 82;    // frame_72 ~ frame_82
  static const int sequence4End = 88;    // frame_83 ~ frame_88
  static const int sequence5End = 175;   // frame_89 ~ frame_175

  // 프레임당 지속 시간 (애니메이션 속도 조절)
  static const int frameDurationMs = 50; // 값을 조절하여 애니메이션 속도 변경 (값이 클수록 느림)

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

    // 첫 프레임이 그려진 후에 이미지 로드 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadInitialImages();
    });
  }

  Future<void> _preloadInitialImages() async {
    try {
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
      duration: Duration(milliseconds: (end - start + 1) * frameDurationMs), // 속도 조절
      vsync: this,
    );

    // 애니메이션 리스너 추가
    _animationController.addListener(() {
      final frame = start +
          (_animationController.value * (end - start)).round();

      if (frame != _currentFrame && frame >= start && frame <= end) {
        _currentFrame = frame;
        _frameNotifier.value = frame; // ValueNotifier 업데이트
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

  // 터치 이벤트 처리
  void _handleTap() async {
    if (_isAnimating) {
      return;
    }

    if (_stage == 1) {
      // 시퀀스 2 설정 및 재생
      _setupSequenceAnimation(sequence1End + 1, sequence2End, () {
        // 시퀀스 완료 후 이미지 캐시 정리
        PaintingBinding.instance.imageCache.clear();
      });
      await _animationController.forward().orCancel;

      if (!mounted) return;

      // 시퀀스 간 딜레이
      await Future.delayed(const Duration(milliseconds: 125));

      if (!mounted) return;

      // 시퀀스 3 설정 및 재생
      _setupSequenceAnimation(sequence2End + 1, sequence3End, () {
        // 시퀀스 완료 후 이미지 캐시 정리
        PaintingBinding.instance.imageCache.clear();

        if (mounted) {
          setState(() {
            _stage = 2;
          });
        }
      });

      _animationController.forward();

    } else if (_stage == 2) {
      // 하얀색 화면 처리
      setState(() {
        _currentFrame = -1;
        _frameNotifier.value = -1;
      });

      // 하얀색 화면 표시 시간
      await Future.delayed(const Duration(milliseconds: 50));

      if (mounted) {
        setState(() {
          _stage = 3;
          _currentFrame = sequence3End + 1;
          _frameNotifier.value = sequence3End + 1;
        });
      }
    } else if (_stage == 3) {
      if (_currentFrame < sequence4End) {
        setState(() {
          _currentFrame++;
          _frameNotifier.value = _currentFrame;
        });
      } else {
        // 마지막 시퀀스 설정 및 재생
        _setupSequenceAnimation(sequence4End + 1, sequence5End, () {
          // 시퀀스 완료 후 이미지 캐시 정리
          PaintingBinding.instance.imageCache.clear();

          if (mounted) {
            setState(() {
              _stage = 4;
            });
          }
        });

        _animationController.forward();
      }
    }
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
      body: SafeArea(
        bottom: false, // 하단 안전 영역 무시 (전체 화면 사용)
        child: GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.white,
            child: _currentFrame == -1
                ? Container(color: Colors.white) // 하얀색 화면
                : ValueListenableBuilder<int>(
              valueListenable: _frameNotifier,
              builder: (context, frameNumber, _) {
                return RepaintBoundary(
                  child: Image.asset(
                    'assets/frames/frame_$frameNumber.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium, // 품질과 성능의 균형
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
      ),
    );
  }

  @override
  void dispose() {
    _frameNotifier.dispose();
    _animationController.dispose();
    PaintingBinding.instance.imageCache.clear(); // 앱 종료 시 이미지 캐시 정리
    super.dispose();
  }
}
