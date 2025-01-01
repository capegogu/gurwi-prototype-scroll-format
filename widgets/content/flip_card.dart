import 'package:flutter/material.dart';
import 'dart:math' as math;

class FlipCardWidget extends StatefulWidget {
  final List<Widget> front;
  final List<Widget> back;
  final double height;

  const FlipCardWidget({
    super.key,
    required this.front,
    required this.back,
    this.height = 400,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFront = true;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _controller.addListener(() {
      if (_controller.status == AnimationStatus.completed ||
          _controller.status == AnimationStatus.dismissed) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isAnimating) return;
    
    setState(() {
      _isAnimating = true;
    });

    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }

    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final angle = _controller.value * math.pi;
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(angle);

                  return Transform(
                    transform: transform,
                    alignment: Alignment.center,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      color: Colors.white,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        height: widget.height,
                        child: angle < math.pi / 2
                            ? SingleChildScrollView(
                                child: Column(
                                  children: widget.front,
                                ),
                              )
                            : Transform(
                                transform: Matrix4.identity()..rotateY(math.pi),
                                alignment: Alignment.center,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: widget.back,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _flip,
                    child: Container(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Indicador de volteo
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Toca para voltear',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 