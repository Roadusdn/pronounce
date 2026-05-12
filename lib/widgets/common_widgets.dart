import 'package:flutter/material.dart';

const Color bgColor = Color(0xFFFFFAF8);
const Color appBlue = Color(0xFFFF735C);
const Color appCoral = Color(0xFFFF6B57);
const Color appCoralLight = Color(0xFFFFE7E1);
const Color appCream = Color(0xFFFFF3DE);
const Color appLavender = Color(0xFFF0E9FF);
const Color appSky = Color(0xFFE7F0FF);
const Color appMint = Color(0xFFE7F8EE);
const Color appYellow = Color(0xFFFFF0C7);
const Color appText = Color(0xFF1F2A44);
const Color appSubText = Color(0xFF8B8794);
const Color appBorder = Color(0xFFE1E7F0);

const LinearGradient appSurfaceGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFFFFFF),
    Color(0xFFFFFFFF),
  ],
);

const Color appCardBg = Colors.white;
const Color appSoftPeach = Color(0xFFFFE9E2);
const Color appSoftBlue = Color(0xFFE5F0FF);
const Color appSoftGreen = Color(0xFFE3F8EC);
const Color appSoftPurple = Color(0xFFF0E8FF);

const LinearGradient appWarmGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFF7D66),
    Color(0xFFFF5F7E),
  ],
);

class AppCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final double radius;
  final bool animateOnBuild;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.backgroundColor,
    this.border,
    this.boxShadow,
    this.gradient,
    this.radius = 28,
    this.animateOnBuild = true,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  static int _appearOrder = 0;
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.012),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    if (widget.animateOnBuild) {
      final delay = (_appearOrder++ % 6) * 18;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(Duration(milliseconds: delay), () {
          if (mounted) _controller.forward();
        });
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      scale: _pressed ? 0.996 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        width: double.infinity,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.gradient == null ? (widget.backgroundColor ?? appCardBg) : null,
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.radius),
          border: widget.border ??
              Border.all(
                color: appBorder,
                width: 1.1,
              ),
          boxShadow: widget.boxShadow,
        ),
        child: widget.child,
      ),
    );

    final animatedCard = FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: card,
      ),
    );

    if (widget.onTap == null) {
      return animatedCard;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.radius),
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: animatedCard,
      ),
    );
  }
}

class PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.995 : 1.0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            height: 58,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: appWarmGradient,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SoftOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  const SoftOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color = appCoral,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null
            ? const SizedBox.shrink()
            : Icon(
                icon,
                color: color,
                size: 20,
              ),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(
            color: color.withOpacity(0.28),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  final String label;
  final String title;
  final VoidCallback? onBack;
  final bool showBack;
  final String? emoji;

  const AppHeader({
    super.key,
    required this.label,
    required this.title,
    this.onBack,
    this.showBack = true,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack) ...[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: appBorder),
            ),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(
                Icons.chevron_left,
                color: appText,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: appSubText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                emoji == null ? title : '$title $emoji',
                style: const TextStyle(
                  color: appText,
                  fontSize: 31,
                  height: 1.12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String emoji;

  const SectionTitle({
    super.key,
    required this.title,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: appText,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const Pill({
    super.key,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class CuteIconBubble extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final double iconSize;

  const CuteIconBubble({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 48,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Icon(
        icon,
        color: foreground,
        size: iconSize,
      ),
    );
  }
}

class SoftReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final double offsetY;

  const SoftReveal({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.offsetY = 14,
  });

  @override
  State<SoftReveal> createState() => _SoftRevealState();
}

class _SoftRevealState extends State<SoftReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _translateY = Tween<double>(
      begin: widget.offsetY,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0, _translateY.value),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

Future<bool?> showSoftConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String cancelText,
  required String confirmText,
  bool danger = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final confirmColor = danger ? const Color(0xFFE85D4D) : appCoral;

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: appBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: appText,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: appText,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: danger ? const Color(0xFFE85D4D) : appCoral,
                          side: BorderSide(
                            color: (danger ? const Color(0xFFE85D4D) : appCoral)
                                .withOpacity(.35),
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
