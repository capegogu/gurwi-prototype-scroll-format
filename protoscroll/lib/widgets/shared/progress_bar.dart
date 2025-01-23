import 'package:flutter/material.dart';

class CustomProgressBar extends StatefulWidget {
  const CustomProgressBar({
    super.key,
    this.width,
    this.height,
    required this.progressValue,
    required this.isLight,
  });

  final double? width;
  final double? height;
  final double progressValue;
  final bool isLight;

  @override
  State<CustomProgressBar> createState() => _FFCustomLinearProgressBarState();
}

class _FFCustomLinearProgressBarState extends State<CustomProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: 0, end: widget.progressValue)
        .animate(_animationController);
    _animationController.forward();
  }

  @override
  void didUpdateWidget(CustomProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressValue != widget.progressValue) {
      _animation = Tween<double>(
        begin: oldWidget.progressValue,
        end: widget.progressValue,
      ).animate(_animationController);
      _animationController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? 100,
      height: widget.height ?? 12,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return CustomPaint(
            painter: _ProgressBarPainter(
              progress: _animation.value,
              backgroundColor: widget.isLight
                  ? const Color(0xFFE5E5E5)
                  : const Color(0xFFC1C1C1),
              progressColor: const Color(0xFFF7C325),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _ProgressBarPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final rRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );

    canvas.drawRRect(rRect, paint);

    paint.color = progressColor;
    final progressRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width * progress, size.height),
      const Radius.circular(4),
    );

    canvas.drawRRect(progressRRect, paint);
  }

  @override
  bool shouldRepaint(_ProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}