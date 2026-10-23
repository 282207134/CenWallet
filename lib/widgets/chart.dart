import 'package:flutter/material.dart';
import '../core/theme.dart';

class WalletChart extends StatelessWidget {
  const WalletChart({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext c) => SizedBox(
    height: compact ? 38 : 210,
    width: double.infinity,
    child: CustomPaint(
      painter: _ChartPainter(compact),
      child: compact
          ? null
          : Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug']
                          .map(
                            (month) => Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(month),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
    ),
  );
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.compact);
  final bool compact;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = compact ? size.height : size.height - 38;
    final red = Path()
      ..moveTo(0, h * .8)
      ..cubicTo(w * .16, h * .78, w * .23, h * .1, w * .38, h * .38)
      ..cubicTo(w * .58, h * .9, w * .72, h * 1.04, w, h * .08);
    final blue = Path()
      ..moveTo(0, h * .45)
      ..cubicTo(w * .17, h * .42, w * .23, h * .66, w * .4, h * .66)
      ..cubicTo(w * .68, h * .78, w * .74, h * .32, w, h * .26);
    for (final pair in [(red, AppColors.coral), (blue, AppColors.cyan)]) {
      canvas.drawPath(
        pair.$1,
        Paint()
          ..color = pair.$2
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    if (!compact) {
      final x = w * .36;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, h),
        Paint()
          ..color = const Color(0xffd5d5d8)
          ..strokeWidth = 1,
      );
      for (final p in [
        (Offset(x, h * .38), AppColors.coral),
        (Offset(x, h * .64), AppColors.cyan),
      ]) {
        canvas.drawCircle(p.$1, 5, Paint()..color = Colors.white);
        canvas.drawCircle(p.$1, 3.5, Paint()..color = p.$2);
      }
      final text = TextPainter(
        text: const TextSpan(
          text: '\$1,000',
          style: TextStyle(
            color: AppColors.coral,
            fontFamily: 'Poppins',
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(x + 8, h * .25));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      compact != oldDelegate.compact;
}
