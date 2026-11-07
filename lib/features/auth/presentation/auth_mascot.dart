import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AuthMascotMood {
  idle,
  shy,
  thinking,
  focused,
  happy,
  sad,
  facepalm,
  celebrate,
}

/// A small animated companion used only on authentication and password screens.
/// It is deliberately not part of the signed-in learning experience.
class AuthMascot extends StatefulWidget {
  const AuthMascot({
    super.key,
    required this.mood,
    this.passwordVisible,
    this.compact = false,
    this.caption,
  });

  final AuthMascotMood mood;
  final bool? passwordVisible;
  final bool compact;
  final String? caption;

  @override
  State<AuthMascot> createState() => _AuthMascotState();
}

class _AuthMascotState extends State<AuthMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  String get _defaultCaption {
    switch (widget.mood) {
      case AuthMascotMood.shy:
        return 'لا تنظر إلى كلمة السر 🙈';
      case AuthMascotMood.thinking:
        return 'أفكر… أين وصلنا؟';
      case AuthMascotMood.focused:
        return 'أنا أراقب الرمز معك';
      case AuthMascotMood.happy:
        return 'رائع! أحسنت 🎉';
      case AuthMascotMood.sad:
        return 'أوه… لم تنجح هذه المرة';
      case AuthMascotMood.facepalm:
        return 'نسيت كلمة المرور؟ يا لذكائي!';
      case AuthMascotMood.celebrate:
        return 'نجحنا! أهلًا بك 💙';
      case AuthMascotMood.idle:
        return 'أنا هنا لمساعدتك';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.compact ? 74.0 : 142.0;
    final height = widget.compact ? 74.0 : 142.0;
    return Semantics(
      label: widget.caption ?? _defaultCaption,
      image: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _motion,
            builder: (context, _) {
              return SizedBox(
                width: width,
                height: height,
                child: CustomPaint(
                  painter: _AuthMascotPainter(
                    mood: widget.passwordVisible == false &&
                            widget.mood == AuthMascotMood.shy
                        ? AuthMascotMood.shy
                        : widget.mood,
                    coverEyes: widget.passwordVisible == false &&
                        widget.mood == AuthMascotMood.shy,
                    phase: _motion.value,
                  ),
                ),
              );
            },
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 5),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                widget.caption ?? _defaultCaption,
                key: ValueKey('${widget.mood}:${widget.caption}'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF536985),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AuthMascotPainter extends CustomPainter {
  const _AuthMascotPainter({
    required this.mood,
    required this.coverEyes,
    required this.phase,
  });

  final AuthMascotMood mood;
  final bool coverEyes;
  final double phase;

  static const _navy = Color(0xFF142B55);
  static const _blue = Color(0xFF2878E8);
  static const _skin = Color(0xFFFFDFC9);
  static const _skinShadow = Color(0xFFE8B99F);
  static const _ink = Color(0xFF20324D);
  static const _pink = Color(0xFFF18F9A);

  Paint _paint(Color color, {PaintingStyle style = PaintingStyle.fill, double stroke = 1}) =>
      Paint()
        ..color = color
        ..style = style
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 160, size.height / 170).toDouble();
    canvas.save();
    canvas.translate((size.width - 160 * scale) / 2, (size.height - 170 * scale) / 2);
    canvas.scale(scale);

    final floatY = math.sin(phase * math.pi * 2) * 2.1;
    final tilt = math.sin(phase * math.pi * 2) * 0.018;
    final blinkWave = (phase * 1.15) % 1.0;
    final blink = blinkWave > 0.92 &&
        mood != AuthMascotMood.sad &&
        mood != AuthMascotMood.facepalm &&
        mood != AuthMascotMood.shy;

    // Soft floating halo and a subtle ground shadow.
    canvas.drawOval(
      const Rect.fromLTWH(15, 5, 130, 145),
      _paint(const Color(0xFF8DBAF5).withOpacity(.12)),
    );
    canvas.drawOval(
      Rect.fromLTWH(42, 158 + floatY * .15, 76, 8),
      _paint(const Color(0xFF193B6B).withOpacity(.10)),
    );

    canvas.save();
    canvas.translate(80, 86 + floatY);
    canvas.rotate(tilt + (mood == AuthMascotMood.sad ? -.025 : 0));
    canvas.translate(-80, -86);

    // Hoodie and shoulders.
    final body = Path()
      ..moveTo(48, 126)
      ..quadraticBezierTo(29, 135, 24, 166)
      ..quadraticBezierTo(80, 184, 136, 166)
      ..quadraticBezierTo(131, 135, 112, 126)
      ..close();
    canvas.drawPath(body, _paint(_navy));
    canvas.drawPath(
      Path()
        ..moveTo(61, 132)
        ..quadraticBezierTo(80, 151, 99, 132),
      _paint(const Color(0xFF4B91E8), style: PaintingStyle.stroke, stroke: 3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(73, 146, 14, 22), const Radius.circular(5)),
      _paint(const Color(0xFF244A7C)),
    );

    // Ears, hair silhouette, face and neck.
    canvas.drawOval(const Rect.fromLTWH(28, 69, 19, 27), _paint(_skinShadow));
    canvas.drawOval(const Rect.fromLTWH(113, 69, 19, 27), _paint(_skinShadow));
    canvas.drawOval(const Rect.fromLTWH(32, 18, 96, 125), _paint(_navy));
    canvas.drawOval(const Rect.fromLTWH(42, 28, 76, 101), _paint(_skin));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(69, 119, 22, 24), const Radius.circular(8)),
      _paint(_skinShadow),
    );

    // Hair side locks and fringe.
    final leftLock = Path()
      ..moveTo(43, 42)
      ..quadraticBezierTo(20, 67, 40, 125)
      ..quadraticBezierTo(51, 111, 51, 91)
      ..close();
    final rightLock = Path()
      ..moveTo(117, 42)
      ..quadraticBezierTo(140, 67, 120, 125)
      ..quadraticBezierTo(109, 111, 109, 91)
      ..close();
    canvas.drawPath(leftLock, _paint(_navy));
    canvas.drawPath(rightLock, _paint(_navy));
    final fringe = Path()
      ..moveTo(34, 69)
      ..quadraticBezierTo(29, 23, 69, 20)
      ..quadraticBezierTo(111, 9, 128, 55)
      ..quadraticBezierTo(109, 47, 96, 65)
      ..quadraticBezierTo(83, 49, 70, 68)
      ..quadraticBezierTo(53, 54, 34, 69)
      ..close();
    canvas.drawPath(fringe, _paint(_navy));
    canvas.drawPath(
      Path()
        ..moveTo(52, 39)
        ..quadraticBezierTo(76, 20, 105, 39),
      _paint(const Color(0xFF4779B7), style: PaintingStyle.stroke, stroke: 3),
    );

    // Blush and facial expression.
    canvas.drawOval(const Rect.fromLTWH(47, 98, 17, 8), _paint(_pink.withOpacity(.34)));
    canvas.drawOval(const Rect.fromLTWH(96, 98, 17, 8), _paint(_pink.withOpacity(.34)));

    if (coverEyes || mood == AuthMascotMood.shy) {
      // A bashful pose: little hands cover the eyes.
      _drawEyeCover(canvas);
    } else if (mood == AuthMascotMood.facepalm) {
      _drawEyes(canvas, blink: true, look: 0);
      _drawFacepalm(canvas);
    } else if (mood == AuthMascotMood.sad) {
      _drawSadEyes(canvas);
    } else if (mood == AuthMascotMood.happy || mood == AuthMascotMood.celebrate) {
      _drawHappyEyes(canvas, sparkle: mood == AuthMascotMood.celebrate);
    } else if (mood == AuthMascotMood.thinking) {
      _drawEyes(canvas, blink: blink, look: 1);
      _drawThinkingHand(canvas);
    } else {
      _drawEyes(canvas, blink: blink, look: mood == AuthMascotMood.focused ? -1 : 0);
    }

    // Nose and mouth.
    canvas.drawCircle(const Offset(80, 103), 2.1, _paint(_skinShadow));
    _drawMouth(canvas, mood);

    if (mood == AuthMascotMood.sad) {
      canvas.drawPath(
        Path()
          ..moveTo(109, 83)
          ..quadraticBezierTo(118, 94, 109, 105)
          ..quadraticBezierTo(100, 94, 109, 83)
          ..close(),
        _paint(const Color(0xFF70BDF4)),
      );
    }

    if (mood == AuthMascotMood.celebrate) {
      _drawSparkle(canvas, const Offset(27, 53), 8);
      _drawSparkle(canvas, const Offset(133, 77), 7);
      _drawSparkle(canvas, const Offset(126, 23), 5);
      _drawRaisedHands(canvas);
    }

    canvas.restore();
    canvas.restore();
  }

  void _drawEyes(Canvas canvas, {required bool blink, required int look}) {
    final leftX = 62.0 + (look == 1 ? 2.0 : look == -1 ? -1.5 : 0.0);
    final rightX = 98.0 + (look == 1 ? 2.0 : look == -1 ? -1.5 : 0.0);
    if (blink) {
      canvas.drawPath(
        Path()
          ..moveTo(53, 84)
          ..quadraticBezierTo(62, 91, 70, 84)
          ..moveTo(89, 84)
          ..quadraticBezierTo(98, 91, 107, 84),
        _paint(_ink, style: PaintingStyle.stroke, stroke: 3),
      );
      return;
    }
    for (final x in [leftX, rightX]) {
      canvas.drawOval(Rect.fromCenter(center: Offset(x, 82), width: 13, height: 18), _paint(Colors.white));
      canvas.drawOval(Rect.fromCenter(center: Offset(x + (look == 1 ? 2.0 : 0.0), 84), width: 7, height: 11), _paint(const Color(0xFF4C9D88)));
      canvas.drawCircle(Offset(x + (look == 1 ? 2.0 : 0.0), 84), 3.1, _paint(_ink));
      canvas.drawCircle(Offset(x - 1, 80), 2, _paint(Colors.white));
    }
    canvas.drawPath(
      Path()
        ..moveTo(52, 69)
        ..quadraticBezierTo(62, 65, 71, 70)
        ..moveTo(89, 70)
        ..quadraticBezierTo(99, 65, 108, 69),
      _paint(_navy, style: PaintingStyle.stroke, stroke: 3),
    );
  }

  void _drawSadEyes(Canvas canvas) {
    canvas.drawPath(
      Path()
        ..moveTo(52, 72)
        ..quadraticBezierTo(62, 80, 71, 78)
        ..moveTo(89, 78)
        ..quadraticBezierTo(99, 80, 108, 72),
      _paint(_navy, style: PaintingStyle.stroke, stroke: 3),
    );
    canvas.drawPath(
      Path()
        ..moveTo(54, 85)
        ..quadraticBezierTo(62, 90, 70, 85)
        ..moveTo(90, 85)
        ..quadraticBezierTo(98, 90, 106, 85),
      _paint(_ink, style: PaintingStyle.stroke, stroke: 2.5),
    );
  }

  void _drawHappyEyes(Canvas canvas, {required bool sparkle}) {
    if (sparkle) {
      _drawSparkle(canvas, const Offset(62, 83), 7);
      _drawSparkle(canvas, const Offset(98, 83), 7);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(53, 85)
          ..quadraticBezierTo(62, 72, 71, 85)
          ..moveTo(89, 85)
          ..quadraticBezierTo(98, 72, 107, 85),
        _paint(_ink, style: PaintingStyle.stroke, stroke: 3),
      );
    }
  }

  void _drawEyeCover(Canvas canvas) {
    final handPaint = _paint(const Color(0xFFFFC8AE));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(47, 75, 31, 17), const Radius.circular(9)),
      handPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(82, 75, 31, 17), const Radius.circular(9)),
      handPaint,
    );
    for (final x in [53.0, 61.0, 69.0, 88.0, 96.0, 104.0]) {
      canvas.drawLine(Offset(x, 78), Offset(x + 1, 86), _paint(_skinShadow, style: PaintingStyle.stroke, stroke: 1.2));
    }
    canvas.drawPath(
      Path()
        ..moveTo(48, 74)
        ..quadraticBezierTo(62, 68, 77, 76)
        ..moveTo(83, 76)
        ..quadraticBezierTo(98, 68, 112, 74),
      _paint(_navy, style: PaintingStyle.stroke, stroke: 2.5),
    );
  }

  void _drawThinkingHand(Canvas canvas) {
    final arm = Path()
      ..moveTo(112, 145)
      ..quadraticBezierTo(125, 129, 105, 116)
      ..lineTo(94, 111);
    canvas.drawPath(arm, _paint(_navy, style: PaintingStyle.stroke, stroke: 10));
    canvas.drawCircle(const Offset(91, 109), 8, _paint(const Color(0xFFFFC8AE)));
    canvas.drawPath(
      Path()
        ..moveTo(51, 67)
        ..quadraticBezierTo(62, 61, 71, 68),
      _paint(_navy, style: PaintingStyle.stroke, stroke: 2.5),
    );
  }

  void _drawFacepalm(Canvas canvas) {
    // A soft cartoon hand patting the forehead: "How did I forget?"
    final arm = Path()
      ..moveTo(111, 151)
      ..quadraticBezierTo(137, 112, 111, 57);
    canvas.drawPath(arm, _paint(_navy, style: PaintingStyle.stroke, stroke: 11));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(93, 43, 30, 17), const Radius.circular(9)),
      _paint(const Color(0xFFFFC8AE)),
    );
    for (final x in [100.0, 108.0, 116.0]) {
      canvas.drawLine(Offset(x, 45), Offset(x + 1, 56), _paint(_skinShadow, style: PaintingStyle.stroke, stroke: 1.2));
    }
    _drawSparkle(canvas, const Offset(127, 31), 5);
  }

  void _drawRaisedHands(Canvas canvas) {
    final hand = _paint(const Color(0xFFFFC8AE));
    canvas.drawPath(
      Path()
        ..moveTo(40, 144)
        ..quadraticBezierTo(16, 125, 25, 105),
      _paint(_navy, style: PaintingStyle.stroke, stroke: 10),
    );
    canvas.drawPath(
      Path()
        ..moveTo(120, 144)
        ..quadraticBezierTo(144, 125, 135, 105),
      _paint(_navy, style: PaintingStyle.stroke, stroke: 10),
    );
    canvas.drawCircle(const Offset(25, 103), 7, hand);
    canvas.drawCircle(const Offset(135, 103), 7, hand);
  }

  void _drawMouth(Canvas canvas, AuthMascotMood mood) {
    final mouth = _paint(const Color(0xFFB45E70), style: PaintingStyle.stroke, stroke: 2.8);
    switch (mood) {
      case AuthMascotMood.happy:
      case AuthMascotMood.celebrate:
        canvas.drawPath(
          Path()
            ..moveTo(69, 111)
            ..quadraticBezierTo(80, 128, 92, 111),
          mouth,
        );
        break;
      case AuthMascotMood.sad:
      case AuthMascotMood.facepalm:
        canvas.drawPath(
          Path()
            ..moveTo(70, 119)
            ..quadraticBezierTo(80, 108, 91, 119),
          mouth,
        );
        break;
      case AuthMascotMood.thinking:
        canvas.drawOval(const Rect.fromLTWH(76, 111, 8, 10), _paint(const Color(0xFFB45E70)));
        break;
      case AuthMascotMood.idle:
      case AuthMascotMood.shy:
      case AuthMascotMood.focused:
        canvas.drawPath(
          Path()
            ..moveTo(73, 115)
            ..quadraticBezierTo(80, 120, 88, 115),
          mouth,
        );
        break;
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..quadraticBezierTo(center.dx + radius * .22, center.dy - radius * .22, center.dx + radius, center.dy)
      ..quadraticBezierTo(center.dx + radius * .22, center.dy + radius * .22, center.dx, center.dy + radius)
      ..quadraticBezierTo(center.dx - radius * .22, center.dy + radius * .22, center.dx - radius, center.dy)
      ..quadraticBezierTo(center.dx - radius * .22, center.dy - radius * .22, center.dx, center.dy - radius)
      ..close();
    canvas.drawPath(path, _paint(const Color(0xFFFFC857)));
  }

  @override
  bool shouldRepaint(covariant _AuthMascotPainter oldDelegate) =>
      oldDelegate.mood != mood ||
      oldDelegate.coverEyes != coverEyes ||
      oldDelegate.phase != phase;
}
