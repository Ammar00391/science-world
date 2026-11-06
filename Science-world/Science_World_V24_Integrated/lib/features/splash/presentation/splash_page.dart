import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  static const _navy = Color(0xFF04142D);
  static const _blue = Color(0xFF1677FF);
  static const _cyan = Color(0xFF43D7FF);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..forward();
  late final AnimationController _orbit = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.08, 0.52, curve: Curves.elasticOut),
  );
  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.34, 0.62, curve: Curves.easeOut),
  );
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.56, 0.78, curve: Curves.easeOut),
  );
  final AudioPlayer _player = AudioPlayer();
  Timer? _routeTimer;

  @override
  void initState() {
    super.initState();
    _playIntroSound();
    _routeTimer = Timer(const Duration(milliseconds: 4700), () {
      if (!mounted) return;
      final destination = AuthService().currentUser == null ? '/intro' : '/home';
      context.go(destination);
    });
  }

  Future<void> _playIntroSound() async {
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setVolume(0.48);
      await _player.play(AssetSource('audio/intro_chime.wav'));
    } catch (_) {
      // The intro must continue normally if audio is unavailable or muted.
    }
  }

  @override
  void dispose() {
    _routeTimer?.cancel();
    _intro.dispose();
    _orbit.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _orbit]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/science_hero_background.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: _navy),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xB804142D), Color(0xDA04142D), _navy],
                    stops: [0, .48, 1],
                  ),
                ),
              ),
              CustomPaint(painter: _StarPainter(_orbit.value)),
              SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(flex: 3),
                        Transform.scale(
                          scale: 0.72 + (_logoScale.value * 0.28),
                          child: Opacity(
                            opacity: _intro.value.clamp(0.0, 1.0).toDouble(),
                            child: SizedBox(
                              width: 184,
                              height: 184,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _cyan.withOpacity(.38),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _blue.withOpacity(.25),
                                          blurRadius: 46,
                                          spreadRadius: 9,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Transform.rotate(
                                    angle: _orbit.value * math.pi * 2,
                                    child: Container(
                                      width: 148,
                                      height: 148,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _cyan.withOpacity(.48),
                                          width: 1.1,
                                        ),
                                      ),
                                      child: const Align(
                                        alignment: Alignment.topCenter,
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 5),
                                          child: Icon(Icons.auto_awesome,
                                              color: _cyan, size: 17),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 128,
                                    height: 128,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          _blue.withOpacity(.32),
                                          _navy.withOpacity(.10),
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(13),
                                    child: Image.asset(
                                      'assets/images/science_world_logo.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 31),
                        Opacity(
                          opacity: _titleFade.value,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - _titleFade.value)),
                            child: const Column(
                              children: [
                                Text(
                                  'عالم العلوم',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'NotoSansArabic',
                                    fontSize: 34,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.4,
                                    shadows: [
                                      Shadow(color: _blue, blurRadius: 22),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'SCIENCE WORLD',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    letterSpacing: 4.2,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF9EDFFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Opacity(
                          opacity: _taglineFade.value,
                          child: const Text(
                            'مستقبلك يبدأ بالمعرفة',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'NotoSansArabic',
                              color: Color(0xFFE0F4FF),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                        const Spacer(flex: 3),
                        Opacity(
                          opacity: _taglineFade.value,
                          child: const Text(
                            'LEARN  •  DISCOVER  •  ACHIEVE',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              letterSpacing: 2.1,
                              color: Color(0xFF8BAED8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final double phase;
  const _StarPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 48; i++) {
      final x = ((i * 73.7) % 997) / 997 * size.width;
      final y = ((i * 137.3) % 991) / 991 * size.height;
      final twinkle = .25 + .65 * ((math.sin(phase * math.pi * 2 + i) + 1) / 2);
      paint.color = (i % 4 == 0 ? const Color(0xFF78E4FF) : Colors.white)
          .withOpacity(twinkle * .58);
      final radius = i % 9 == 0 ? 1.8 : .75 + (i % 3) * .25;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
