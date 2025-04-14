import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  // 앱 초기화 설정
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 전역 오류 핸들러 설정
  FlutterError.onError = (FlutterErrorDetails details) {
    print('Flutter 오류 발생: ${details.exception}');
    print('스택 트레이스: ${details.stack}');
  };

  print('앱 시작: ${DateTime.now()}');
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
        colorScheme: ColorScheme.light(
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

class _SplashScreenState extends State<SplashScreen> {
  // 시퀀스 정의
  static const int sequence1End = 28;    // frame_1 ~ frame_28
  static const int sequence2End = 71;    // frame_29 ~ frame_71
  static const int sequence3End = 82;    // frame_72 ~ frame_82
  static const int sequence4End = 88;    // frame_83 ~ frame_88
  static const int sequence5End = 175;   // frame_89 ~ frame_175

  int _stage = 0;
  int _currentFrame = 1;
  bool _isLoading = true;
  bool _isAnimating = false;

  // 최적화된 이미지 캐시
  final Map<int, ImageProvider> _frameCache = {};
  final int _maxCacheSize = 30; // 최대 캐시 크기 제한

  @override
  void initState() {
    super.initState();
    print('SplashScreen 초기화: ${DateTime.now()}');

    // 첫 이미지 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('첫 프레임 렌더링 완료, 이미지 로드 시작');
      _loadFirstFrame();
    });
  }

  Future<void> _loadFirstFrame() async {
    try {
      print('첫 프레임 로드 시작');

      final firstImagePath = 'assets/frames/frame_1.png';
      print('이미지 경로: $firstImagePath');

      final firstImage = AssetImage(firstImagePath);

      try {
        print('이미지 캐싱 시도 중...');
        await precacheImage(firstImage, context);
        print('첫 이미지 캐싱 성공');
      } catch (e) {
        print('이미지 캐싱 오류 (상세): $e');
        print('스택 트레이스: ${StackTrace.current}');
      }

      if (mounted) {
        setState(() {
          _frameCache[1] = firstImage;
          _isLoading = false;
          print('로딩 상태 업데이트: _isLoading=$_isLoading');
        });
      } else {
        print('위젯이 마운트되지 않음 - 상태 업데이트 불가');
      }

      // 첫 시퀀스 일부 이미지만 미리 로드
      _precacheFrameRange(2, 10);

      // 첫 시퀀스 자동 시작
      print('첫 시퀀스 시작 전 대기 중...');
      Future.delayed(const Duration(milliseconds: 700), () {
        print('첫 번째 시퀀스 시작');
        if (mounted) {
          _playFrames(1, sequence1End, () {
            print('첫 번째 시퀀스 완료');
            if (mounted) {
              setState(() {
                _stage = 1;
                print('스테이지 업데이트: _stage=$_stage');
              });
            }

            // 다음 시퀀스 일부 이미지만 미리 로드
            _precacheFrameRange(sequence1End + 1, sequence1End + 10);
          });
        } else {
          print('위젯이 마운트되지 않음 - 시퀀스 재생 불가');
        }
      });
    } catch (e) {
      print('loadFirstFrame 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 지정된 범위의 프레임 미리 로드
  void _precacheFrameRange(int start, int end) {
    print('프레임 범위 프리캐싱: $start-$end');
    for (int i = start; i <= end; i++) {
      if (!_frameCache.containsKey(i)) {
        // 캐시 크기 제한 확인
        if (_frameCache.length >= _maxCacheSize) {
          // 가장 멀리 있는 프레임 제거 (현재 프레임과 가장 차이가 큰 프레임)
          int furthestFrame = _findFurthestFrame(_currentFrame);
          if (furthestFrame > 0) {
            print('캐시 제한 도달: frame_$furthestFrame.png 제거');
            _frameCache.remove(furthestFrame);
          }
        }

        // 새 프레임 로드
        final imagePath = 'assets/frames/frame_$i.png';
        final image = AssetImage(imagePath);
        _frameCache[i] = image;

        precacheImage(image, context).then((_) {
          print('프레임 $i 로드 완료');
        }).catchError((error) {
          print('프레임 $i 로드 실패: $error');
        });
      }
    }
  }

  // 현재 프레임에서 가장 멀리 있는 캐시된 프레임 찾기
  int _findFurthestFrame(int currentFrame) {
    if (_frameCache.isEmpty) return -1;

    int furthestFrame = -1;
    int maxDistance = -1;

    for (int frame in _frameCache.keys) {
      int distance = (frame - currentFrame).abs();
      if (distance > maxDistance) {
        maxDistance = distance;
        furthestFrame = frame;
      }
    }

    return furthestFrame;
  }

  // 프레임 시퀀스 재생
  Future<void> _playFrames(int start, int end, VoidCallback onComplete) async {
    if (_isAnimating) {
      print('이미 애니메이션 실행 중');
      return;
    }

    print('시퀀스 재생 시작: $start-$end');
    setState(() {
      _isAnimating = true;
    });

    // 다음 몇 개 프레임 미리 로드
    int preloadEnd = start + 10 > end ? end : start + 10;
    _precacheFrameRange(start, preloadEnd);

    for (int i = start; i <= end; i++) {
      if (!mounted || !_isAnimating) {
        print('애니메이션 중단: mounted=$mounted, _isAnimating=$_isAnimating');
        break;
      }

      // 다음 프레임들 미리 로드 (슬라이딩 윈도우 방식)
      if (i + 10 <= end) {
        _precacheFrameRange(i + 5, i + 10);
      }

      // 현재 프레임 로드 확인
      if (!_frameCache.containsKey(i)) {
        print('프레임 $i 캐시에 없음, 로드 시도');
        final imagePath = 'assets/frames/frame_$i.png';
        final image = AssetImage(imagePath);

        try {
          await precacheImage(image, context);
          _frameCache[i] = image;
        } catch (e) {
          print('프레임 $i 로드 실패: $e');
        }
      }

      // 프레임 표시
      if (mounted && _isAnimating) {
        setState(() {
          _currentFrame = i;
        });
      }

      // 각 프레임 간 딜레이
      await Future.delayed(const Duration(milliseconds: 30));
    }

    if (mounted) {
      setState(() {
        _isAnimating = false;
      });
      print('시퀀스 재생 완료: $start-$end');
      onComplete();
    }
  }

  // 터치 이벤트 처리
  void _handleTap() async {
    print('화면 터치 감지: 스테이지=$_stage, 현재 프레임=$_currentFrame');

    if (_isAnimating) {
      print('애니메이션 중에는 터치 무시');
      return;
    }

    if (_stage == 1) {
      // 시퀀스 2 재생
      await _playFrames(sequence1End + 1, sequence2End, () {});

      // 시퀀스 간 딜레이
      await Future.delayed(const Duration(milliseconds: 125));

      // 시퀀스 3 재생
      await _playFrames(sequence2End + 1, sequence3End, () {
        if (mounted) {
          setState(() {
            _stage = 2;
            print('스테이지 업데이트: _stage=$_stage');
          });
        }

        // 다음 단계 이미지 미리 로드
        _precacheFrameRange(sequence3End + 1, sequence4End);
      });
    } else if (_stage == 2) {
      // 하얀색 화면 처리
      print('하얀색 화면 표시');
      setState(() {
        _currentFrame = -1; // 특수 값으로 하얀 화면 표시
      });

      // 하얀색 화면 표시 시간
      await Future.delayed(const Duration(milliseconds: 50));

      if (mounted) {
        setState(() {
          _stage = 3;
          _currentFrame = sequence3End + 1;
          print('스테이지 업데이트: _stage=$_stage, 현재 프레임=$_currentFrame');
        });
      }
    } else if (_stage == 3) {
      if (_currentFrame < sequence4End) {
        setState(() {
          _currentFrame++;
          print('프레임 수동 증가: $_currentFrame');
        });
      } else {
        // 마지막 시퀀스 일부 미리 로드
        _precacheFrameRange(sequence4End + 1, sequence4End + 10);

        // 마지막 시퀀스 재생
        await _playFrames(sequence4End + 1, sequence5End, () {
          if (mounted) {
            setState(() {
              _stage = 4;
              print('최종 스테이지 도달: _stage=$_stage');
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
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
          child: _currentFrame == -1
              ? Container(color: Colors.white) // 하얀색 화면
              : Center(
            child: Image(
              image: _frameCache[_currentFrame] ?? AssetImage('assets/frames/frame_$_currentFrame.png'),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                print('이미지 표시 실패: $_currentFrame, 오류: $error');
                return Container(
                  color: Colors.white,
                  child: Center(
                    child: Text(
                      '이미지 로드 실패: $_currentFrame\n$error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
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
    print('SplashScreen 종료');
    _isAnimating = false;
    _frameCache.clear();
    super.dispose();
  }
}
