import 'package:flutter/material.dart';

enum EntranceStyle { fadeUp, popIn, slideInRight, fadeIn }

class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 480),
    this.style = EntranceStyle.fadeUp,
    this.distance = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final EntranceStyle style;
  final double distance;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _start();
  }

  Future<void> _start() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
      if (!mounted) return;
    }
    if (!mounted) return;
    _controller.forward();
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        switch (widget.style) {
          case EntranceStyle.fadeIn:
            return Opacity(opacity: _curve.value, child: child);
          case EntranceStyle.popIn:
            return Opacity(
              opacity: _curve.value,
              child: Transform.scale(
                scale: 0.85 + 0.15 * _curve.value,
                child: child,
              ),
            );
          case EntranceStyle.slideInRight:
            return Opacity(
              opacity: _curve.value,
              child: Transform.translate(
                offset: Offset(-widget.distance * (1 - _curve.value), 0),
                child: child,
              ),
            );
          case EntranceStyle.fadeUp:
            return Opacity(
              opacity: _curve.value,
              child: Transform.translate(
                offset: Offset(0, widget.distance * (1 - _curve.value)),
                child: child,
              ),
            );
        }
      },
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleTo = 0.96,
    this.borderRadius,
    this.highlightColor,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final double scaleTo;
  final BorderRadius? borderRadius;
  final Color? highlightColor;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? widget.scaleTo : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: Stack(
            children: [
              widget.child,
              if (_down && widget.highlightColor != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.highlightColor,
                        borderRadius: widget.borderRadius,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class Pulse extends StatefulWidget {
  const Pulse({
    super.key,
    required this.child,
    this.min = 0.97,
    this.max = 1.03,
    this.duration = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final double min;
  final double max;
  final Duration duration;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) => Transform.scale(
        scale: widget.min + (widget.max - widget.min) * curved.value,
        child: child,
      ),
    );
  }
}

class KenBurns extends StatefulWidget {
  const KenBurns({
    super.key,
    required this.child,
    this.from = 1.04,
    this.to = 1.16,
    this.duration = const Duration(seconds: 14),
  });

  final Widget child;
  final double from;
  final double to;
  final Duration duration;

  @override
  State<KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<KenBurns>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: curved,
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale: widget.from + (widget.to - widget.from) * curved.value,
          child: child,
        ),
      ),
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.color = const Color(0xFFF97316),
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 900),
  });

  final int value;
  final double height;
  final Color color;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final target = (value.clamp(0, 100)) / 100;
    final total = duration + delay;
    final start = total <= Duration.zero ? 0.0 : delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: total,
      curve: Interval(
        start,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, animated, _) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Stack(
          children: [
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE7E9EE),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: animated,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      Color.lerp(color, Colors.white, 0.20) ?? color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CountUpNumber extends StatelessWidget {
  const CountUpNumber(
    this.value, {
    super.key,
    this.duration = const Duration(milliseconds: 900),
    this.suffix = '',
    this.prefix = '',
    this.style,
  });

  final num value;
  final Duration duration;
  final String suffix;
  final String prefix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) =>
          Text('$prefix${animated.round()}$suffix', style: style),
    );
  }
}

/// Subtle breathing glowing dot for status pills and indicators.
class StatusGlowDot extends StatefulWidget {
  const StatusGlowDot({
    super.key,
    required this.color,
    this.size = 6,
    this.duration = const Duration(milliseconds: 1600),
  });

  final Color color;
  final double size;
  final Duration duration;

  @override
  State<StatusGlowDot> createState() => _StatusGlowDotState();
}

class _StatusGlowDotState extends State<StatusGlowDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final glow = 2.0 + 4.0 * curved.value;
        final alpha = 0.3 + 0.35 * curved.value;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: alpha),
                blurRadius: glow,
                spreadRadius: 1.0 * curved.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Spring-bouncing animated checkbox for tasks.
class BouncingCheckmark extends StatefulWidget {
  const BouncingCheckmark({
    super.key,
    required this.checked,
    this.onTap,
    this.size = 24,
    this.activeColor = const Color(0xFF10B981),
  });

  final bool checked;
  final VoidCallback? onTap;
  final double size;
  final Color activeColor;

  @override
  State<BouncingCheckmark> createState() => _BouncingCheckmarkState();
}

class _BouncingCheckmarkState extends State<BouncingCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _scaleAnimation = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.0, end: 1.25)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: 1.25, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant BouncingCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checked && !oldWidget.checked) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!widget.checked) {
          _controller.forward(from: 0);
        }
        widget.onTap?.call();
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.checked ? widget.activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: widget.checked
                    ? widget.activeColor
                    : const Color(0xFFCBD5E1),
                width: 1.6,
              ),
              boxShadow: widget.checked
                  ? [
                      BoxShadow(
                        color: widget.activeColor.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: widget.checked
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('checked'),
                      size: 16,
                      color: Colors.white,
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ),
        ),
      ),
    );
  }
}

/// Provides smooth hover elevation and slight scale up on web/desktop.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.child,
    this.liftY = -3.0,
    this.scale = 1.01,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final double liftY;
  final double scale;
  final Duration duration;
  final Curve curve;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        offset: _hovered ? Offset(0, widget.liftY / 100) : Offset.zero,
        duration: widget.duration,
        curve: widget.curve,
        child: AnimatedScale(
          scale: _hovered ? widget.scale : 1.0,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}

class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  FadeThroughPageRoute({required this.page})
    : super(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );

  final Widget page;
}

/// Shimmering placeholder block used while data loads.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 3 - 1;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: const [
                Color(0xFFE9ECF1),
                Color(0xFFF6F7F9),
                Color(0xFFE9ECF1),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A column of card-shaped skeletons shown while a list loads.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.itemHeight = 104});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Skeleton(height: itemHeight, radius: 16),
          ),
      ],
    );
  }
}
