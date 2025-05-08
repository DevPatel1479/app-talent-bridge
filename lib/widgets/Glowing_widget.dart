import 'package:flutter/material.dart';

class GlowingContainer extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  const GlowingContainer({
    Key? key,
    required this.child,
    this.borderRadius = 16.0,
  }) : super(key: key);

  @override
  _GlowingContainerState createState() => _GlowingContainerState();
}

class _GlowingContainerState extends State<GlowingContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 10).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withOpacity(0.6),
                blurRadius: _animation.value,
                spreadRadius: _animation.value / 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: widget.child,
          ),
        );
      },
    );
  }
}
