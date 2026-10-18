import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';

import '../core/theme.dart';
import 'motion.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Entrance(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          Spacing.xl,
          Spacing.xl,
          Spacing.xl,
          Spacing.lg,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x33F97316),
              AppColors.primarySoft,
              AppColors.background,
            ],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing case final Widget action) Flexible(child: action),
            ],
          ),
        ),
      ),
    );
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({
    super.key,
    this.showTagline = true,
    this.centered = false,
    this.iconSize = 60,
    this.nameSize = 30,
  });

  final bool showTagline;
  final bool centered;
  final double iconSize;
  final double nameSize;

  @override
  Widget build(BuildContext context) {
    final crossAxisAlignment = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    final wordmark = ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFA253), AppColors.primary, AppColors.primaryDark],
        stops: [0, 0.55, 1],
      ).createShader(bounds),
      child: Text(
        'BuildTrack',
        style: GoogleFonts.poppins(
          fontSize: nameSize,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -1.1,
          height: 1,
          shadows: const [
            Shadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: iconSize,
              height: iconSize,
              gaplessPlayback: true,
            ),
            const SizedBox(width: Spacing.md),
            wordmark,
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: Spacing.md),
          Text(
            'Build smarter.\nManage better.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: const Color(0xF2F8FAFC),
              letterSpacing: 0.1,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.title,
    this.onPressed,
    this.icon,
    this.height = 54,
    this.loading = false,
  });

  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleTo: 0.97,
      onPressed: loading ? null : onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [Shadows.float],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: Spacing.sm),
                    Icon(icon, size: 20, color: Colors.white),
                  ],
                ],
              ),
      ),
    );
  }
}

enum AppButtonVariant { outline, light, glass, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.title,
    this.onPressed,
    this.variant = AppButtonVariant.outline,
    this.icon,
    this.height = 54,
    this.expand = true,
  });

  final String title;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final foreground = switch (variant) {
      AppButtonVariant.outline => AppColors.text,
      AppButtonVariant.light => AppColors.text,
      AppButtonVariant.glass => Colors.white,
      AppButtonVariant.danger => AppColors.danger,
    };

    final background = switch (variant) {
      AppButtonVariant.outline => Colors.white,
      AppButtonVariant.light => AppColors.background,
      AppButtonVariant.glass => const Color(0x1FFFFFFF),
      AppButtonVariant.danger => AppColors.white,
    };

    final border = switch (variant) {
      AppButtonVariant.outline => AppColors.border,
      AppButtonVariant.light => AppColors.border,
      AppButtonVariant.glass => const Color(0x3DFFFFFF),
      AppButtonVariant.danger => AppColors.danger,
    };

    final pressTint = switch (variant) {
      AppButtonVariant.outline => AppColors.primary.withValues(alpha: 0.10),
      AppButtonVariant.light => AppColors.primary.withValues(alpha: 0.10),
      AppButtonVariant.glass => Colors.white.withValues(alpha: 0.12),
      AppButtonVariant.danger => AppColors.danger.withValues(alpha: 0.10),
    };

    final button = PressableScale(
      scaleTo: 0.97,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      highlightColor: pressTint,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: foreground),
              const SizedBox(width: Spacing.sm),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppField extends StatefulWidget {
  const AppField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.glass = false,
    this.suffix,
    this.textInputAction,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool glass;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  State<AppField> createState() => _AppFieldState();
}

class _AppFieldState extends State<AppField> {
  late final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labelColor = widget.glass
        ? const Color(0xE6FFFFFF)
        : AppColors.textSecondary;
    final fill = widget.glass ? const Color(0x14FFFFFF) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              left: Spacing.xs,
              bottom: Spacing.sm,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _focused ? AppColors.primary : AppColors.border,
              width: _focused ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              if (widget.prefixIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: Spacing.md),
                  child: Icon(
                    widget.prefixIcon,
                    size: 18,
                    color: widget.glass
                        ? const Color(0xCCFFFFFF)
                        : AppColors.textMuted,
                  ),
                ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  onChanged: widget.onChanged,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  maxLines: widget.maxLines,
                  validator: widget.validator,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: widget.glass ? Colors.white : AppColors.text,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: widget.glass
                          ? const Color(0x8CFFFFFF)
                          : AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.md + 2,
                    ),
                  ),
                ),
              ),
              if (widget.suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.sm),
                  child: widget.suffix,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.compact = false,
    this.pulse,
  });

  final String label;
  final Color color;
  final bool compact;
  final bool? pulse;

  @override
  Widget build(BuildContext context) {
    final shouldPulse = pulse ??
        (label == 'Active' ||
            label == 'In Progress' ||
            label == 'Critical' ||
            label == 'Delayed');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? Spacing.sm : Spacing.md,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shouldPulse) ...[
            StatusGlowDot(color: color, size: compact ? 5 : 6),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleTo: 0.94,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class SegmentedControl extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<String> items;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;
          return SizedBox(
            height: 38,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: itemWidth * activeIndex,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: PressableScale(
                          scaleTo: 0.94,
                          onPressed: () => onChanged(i),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          highlightColor: AppColors.primary.withValues(
                            alpha: 0.08,
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: activeIndex == i
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              child: Text(items[i]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<String> items;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: PressableScale(
                scaleTo: 0.94,
                onPressed: () => onChanged(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.md - 2),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: activeIndex == i
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: activeIndex == i
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        child: Text(items[i], textAlign: TextAlign.center),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, 2),
                      child: IntrinsicWidth(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: activeIndex == i
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Opacity(
                            opacity: 0,
                            child: Text(
                              items[i],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.initials,
    this.avatarUrl,
    this.size = 44,
    this.tone = AppColors.primary,
    this.onTap,
  });

  final String initials;
  final String? avatarUrl;
  final double size;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content;
    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        try {
          final comma = url.indexOf(',');
          final base64Str = comma >= 0 ? url.substring(comma + 1) : url;
          final bytes = base64Decode(base64Str);
          content = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => _initialsWidget(),
          );
        } catch (_) {
          content = _initialsWidget();
        }
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        content = Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _initialsWidget(),
        );
      } else if (url.startsWith('assets/')) {
        content = Image.asset(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _initialsWidget(),
        );
      } else {
        content = _initialsWidget();
      }
    } else {
      content = _initialsWidget();
    }

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tone, Color.lerp(tone, Colors.black, 0.15)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: ClipOval(child: content),
    );

    if (onTap == null) return avatar;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: PressableScale(
        scaleTo: 0.92,
        borderRadius: BorderRadius.circular(size / 2),
        onPressed: onTap,
        child: avatar,
      ),
    );
  }

  Widget _initialsWidget() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.onPressed,
    this.badge = 0,
    this.tone = AppColors.textSecondary,
    this.background = Colors.white,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final int badge;
  final Color tone;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleTo: 0.9,
      onPressed: onPressed,
      borderRadius: BorderRadius.circular(22),
      highlightColor: AppColors.primary.withValues(alpha: 0.10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: tone),
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badge > 9 ? '9+' : '$badge',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.xxxl,
        horizontal: Spacing.xl,
      ),
      child: Column(
        children: [
          Entrance(
            style: EntranceStyle.popIn,
            child: Pulse(
              min: 0.985,
              max: 1.015,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primarySoft, AppColors.card],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 32, color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          Entrance(
            delay: const Duration(milliseconds: 120),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Entrance(
            delay: const Duration(milliseconds: 180),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Spacing.xl),
            Entrance(
              delay: const Duration(milliseconds: 260),
              child: GradientButton(title: actionLabel!, onPressed: onAction),
            ),
          ],
        ],
      ),
    );
  }
}

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.lg),
    this.onTap,
    this.color = AppColors.card,
    this.gradient,
    this.hoverEffect = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final Gradient? gradient;
  final bool hoverEffect;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.onTap != null;
    final hovered = _hovered && isInteractive && widget.hoverEffect;

    Widget card = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.gradient == null ? widget.color : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: hovered
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
          width: hovered ? 1.2 : 1.0,
        ),
        boxShadow: hovered
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                Shadows.card,
              ]
            : const [Shadows.card],
      ),
      child: widget.child,
    );

    if (isInteractive) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedSlide(
          offset: hovered ? const Offset(0, -0.015) : Offset.zero,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: PressableScale(
            scaleTo: 0.98,
            onPressed: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            highlightColor: AppColors.primary.withValues(alpha: 0.07),
            child: card,
          ),
        ),
      );
    }

    return card;
  }
}

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.overlay,
    builder: (context) => _SheetShell(title: title, child: child),
  );
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      padding: EdgeInsets.only(
        left: Spacing.xl,
        right: Spacing.xl,
        top: Spacing.lg,
        bottom: Spacing.xl + insets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
                IconBadge(
                  icon: Ionicons.close,
                  background: AppColors.background,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const SizedBox(height: Spacing.xl),
            child,
          ],
        ),
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: error ? AppColors.danger : AppColors.dark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.all(Spacing.lg),
      ),
    );
}
