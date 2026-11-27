import 'package:flutter/material.dart';

import '../theme/bunny_theme.dart';

class BunnyCard extends StatelessWidget {
  const BunnyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accentColor,
    this.onTap,
    this.gradient,
    this.borderRadius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final borderColor = accentColor != null
        ? accentColor!.withValues(alpha: 0.45)
        : BunnyColors.border;

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? BunnyColors.surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: accentColor != null
            ? [
                BoxShadow(
                  color: accentColor!.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      ),
    );
  }
}

class BunnyHeroBanner extends StatelessWidget {
  const BunnyHeroBanner({
    super.key,
    required this.imageAsset,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.height = 205,
    this.trailingBadge,
    this.bottomChild,
  });

  final String imageAsset;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color accentColor;
  final double height;
  final Widget? trailingBadge;
  final Widget? bottomChild;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        constraints: BoxConstraints(minHeight: height),
        decoration: BoxDecoration(
          color: BunnyColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      BunnyColors.bg.withValues(alpha: 0.94),
                      BunnyColors.bg.withValues(alpha: 0.72),
                      BunnyColors.bg.withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      BunnyColors.bg.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      BunnyPillBadge(label: eyebrow, color: accentColor),
                      const Spacer(),
                      ?trailingBadge,
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displayMedium
                        ?.copyWith(fontSize: 23, height: 1.15),
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BunnyColors.textPrimary.withValues(alpha: 0.84),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (bottomChild != null) ...[
                    const SizedBox(height: 14),
                    bottomChild!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BunnyPillBadge extends StatelessWidget {
  const BunnyPillBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled ? color : color.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: filled ? Colors.black : color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: filled ? Colors.black : color,
            ),
          ),
        ],
      ),
    );
  }
}

class BunnySectionHeader extends StatelessWidget {
  const BunnySectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.accentColor,
  });

  final String title;
  final Widget? trailing;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (accentColor != null) ...[
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: BunnyColors.textSecondary,
              letterSpacing: 1.25,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class BunnyPrimaryButton extends StatelessWidget {
  const BunnyPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = BunnyColors.electricBlue,
    this.foregroundColor = Colors.white,
    this.icon,
    this.expanded = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color foregroundColor;
  final IconData? icon;
  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: BunnyColors.surfaceHighlight,
        disabledForegroundColor: BunnyColors.textMuted,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 20,
          vertical: compact ? 11 : 15,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: compact ? 13 : 14.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 17 : 19),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class BunnySecondaryButton extends StatelessWidget {
  const BunnySecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderColor = BunnyColors.border,
    this.foregroundColor = BunnyColors.textPrimary,
    this.icon,
    this.expanded = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color foregroundColor;
  final IconData? icon;
  final bool expanded;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        side: BorderSide(color: borderColor),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 18,
          vertical: compact ? 11 : 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: compact ? 12.5 : 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 17), const SizedBox(width: 8)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class BunnyStatTile extends StatelessWidget {
  const BunnyStatTile({
    super.key,
    required this.label,
    required this.value,
    this.accentColor = BunnyColors.electricBlue,
    this.subtitle,
  });

  final String label;
  final String value;
  final Color accentColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: BunnyColors.bgElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BunnyColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: BunnyColors.textMuted,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: BunnyColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
