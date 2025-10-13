import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;

  const AnimatedBackground({super.key, required this.child, this.colors});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.colors ??
        [
          Theme.of(context).colorScheme.primary.withOpacity(0.1),
          Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
        ];

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(colors[0], colors[1], _animation.value)!,
                Color.lerp(colors[1], colors[2], _animation.value)!,
                Color.lerp(colors[2], colors[0], _animation.value)!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}


