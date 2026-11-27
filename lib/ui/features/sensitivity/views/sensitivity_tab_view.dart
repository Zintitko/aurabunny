import 'package:flutter/material.dart';

import '../../../../data/repositories/bunny_repository.dart';
import '../../../core/l10n/bunny_strings.dart';
import '../../../core/theme/bunny_theme.dart';
import '../../../core/widgets/bunny_components.dart';

class SensitivityTabView extends StatefulWidget {
  const SensitivityTabView({super.key, required this.state});

  final BunnyAppState state;

  @override
  State<SensitivityTabView> createState() => _SensitivityTabViewState();
}

class _SensitivityTabViewState extends State<SensitivityTabView> {
  Offset _cursorNormalized = const Offset(0.5, 0.5);
  bool _isDragging = false;

  Future<void> _showSavePresetDialog() async {
    final controller = TextEditingController(
      text: widget.state.activeSensitivity.name,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(BunnyStrings.t('Sensitivity presets')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Tournament Drag',
            filled: true,
            fillColor: BunnyColors.bgElevated,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(BunnyStrings.t('Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: BunnyColors.violet,
              foregroundColor: Colors.white,
            ),
            child: Text(BunnyStrings.t('Done')),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      await widget.state.saveSensitivityPreset(name.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(BunnyStrings.t('Saved locally.'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sens = widget.state.activeSensitivity;
    final multiplier = 0.45 + (sens.general / 200.0) * 1.65;

    return Scaffold(
      backgroundColor: BunnyColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            BunnyHeroBanner(
              imageAsset: 'assets/images/SensitivityBanner.png',
              eyebrow: BunnyStrings.t('SENSITIVITY LAB'),
              title: BunnyStrings.t(
                'Save your values.\nTest what feels right.',
              ),
              subtitle: BunnyStrings.t(
                'Pick a starting point, then adjust your six reference values to suit your practice.',
              ),
              accentColor: BunnyColors.violet,
              height: 185,
            ),
            const SizedBox(height: 18),

            // Quick Starting Point Rollers
            BunnySectionHeader(
              title: BunnyStrings.t('GENERIC MANUAL REFERENCES'),
              accentColor: BunnyColors.violet,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _presetButton(
                    title: BunnyStrings.t('Balanced'),
                    subtitle: '80–125',
                    color: BunnyColors.electricBlue,
                    onTap: () {
                      widget.state.triggerSelectionHaptic();
                      widget.state.applyBalancedSensitivity();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _presetButton(
                    title: BunnyStrings.t('Fast Drag'),
                    subtitle: BunnyStrings.t('FAST 150–200'),
                    color: BunnyColors.crimson,
                    onTap: () {
                      widget.state.triggerImpactHaptic();
                      widget.state.rollSensitivityPreset(fastDrag: true);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _presetButton(
                    title: BunnyStrings.t('Precision'),
                    subtitle: BunnyStrings.t('PRECISION 30–80'),
                    color: BunnyColors.violet,
                    onTap: () {
                      widget.state.triggerImpactHaptic();
                      widget.state.rollSensitivityPreset(fastDrag: false);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Live Practice Cursor & Drag-Fire Preview
            BunnySectionHeader(
              title: BunnyStrings.t('Practice control preview'),
              accentColor: BunnyColors.violetBright,
              trailing: BunnyPillBadge(
                label: '${BunnyStrings.t('GENERAL')} ${sens.general}',
                color: BunnyColors.violet,
              ),
            ),
            const SizedBox(height: 10),
            BunnyCard(
              accentColor: BunnyColors.violet,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 170,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final h = constraints.maxHeight;
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (_) {
                              widget.state.triggerSelectionHaptic();
                              setState(() => _isDragging = true);
                            },
                            onPanUpdate: (d) {
                              setState(() {
                                _cursorNormalized = Offset(
                                  (_cursorNormalized.dx +
                                          (d.delta.dx / w) * multiplier)
                                      .clamp(0.06, 0.94),
                                  (_cursorNormalized.dy +
                                          (d.delta.dy / h) * multiplier)
                                      .clamp(0.10, 0.90),
                                );
                              });
                            },
                            onPanEnd: (_) => setState(() {
                              _isDragging = false;
                              _cursorNormalized = const Offset(0.5, 0.5);
                            }),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF05070E),
                                border: Border.all(
                                  color: _isDragging
                                      ? BunnyColors.violet
                                      : BunnyColors.border,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _SensPreviewPainter(
                                        cursor: Offset(
                                          _cursorNormalized.dx * w,
                                          _cursorNormalized.dy * h,
                                        ),
                                        active: _isDragging,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    left: 10,
                                    right: 10,
                                    child: Text(
                                      BunnyStrings.t(
                                        'Hold and drag to test the fire control',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: BunnyColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Six Reference Sliders
            BunnyCard(
              child: Column(
                children: [
                  _sensSlider(
                    label: BunnyStrings.t('General'),
                    value: sens.general,
                    highlight: true,
                    onChanged: (v) => widget.state.updateActiveSensitivity(
                      sens.copyWith(general: v),
                    ),
                  ),
                  _sensSlider(
                    label: BunnyStrings.t('Red Dot'),
                    value: sens.redDot,
                    onChanged: (v) => widget.state.updateActiveSensitivity(
                      sens.copyWith(redDot: v),
                    ),
                  ),
                  _sensSlider(
                    label: BunnyStrings.t('2× Scope'),
                    value: sens.scope2x,
                    onChanged: (v) => widget.state.updateActiveSensitivity(
                      sens.copyWith(scope2x: v),
                    ),
                  ),
                  _sensSlider(
                    label: BunnyStrings.t('4× Scope'),
                    value: sens.scope4x,
                    onChanged: (v) => widget.state.updateActiveSensitivity(
                      sens.copyWith(scope4x: v),
                    ),
                  ),
                  _sensSlider(
                    label: BunnyStrings.t('Sniper Scope'),
                    value: sens.sniperScope,
                    onChanged: (v) => widget.state.updateActiveSensitivity(
                      sens.copyWith(sniperScope: v),
                    ),
                  ),
                  _sensSlider(
                    label: BunnyStrings.t('Free Look'),
                    value: sens.freeLook,
                    onChanged: (v) => widget.state.updateActiveSensitivity(
                      sens.copyWith(freeLook: v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  BunnyPrimaryButton(
                    label: BunnyStrings.t('Sensitivity presets'),
                    color: BunnyColors.violet,
                    icon: Icons.bookmark_add_rounded,
                    compact: true,
                    onPressed: _showSavePresetDialog,
                  ),
                ],
              ),
            ),

            if (widget.state.savedSensitivities.isNotEmpty) ...[
              const SizedBox(height: 18),
              BunnySectionHeader(
                title: BunnyStrings.t('STORED ON DEVICE'),
                accentColor: BunnyColors.violet,
              ),
              const SizedBox(height: 10),
              ...widget.state.savedSensitivities.map((preset) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BunnyCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    onTap: () {
                      widget.state.triggerSelectionHaptic();
                      widget.state.updateActiveSensitivity(preset);
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'GEN ${preset.general} · RD ${preset.redDot} · 2× ${preset.scope2x} · 4× ${preset.scope4x} · SN ${preset.sniperScope}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: BunnyColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: BunnyColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () =>
                              widget.state.deleteSensitivityPreset(preset.id),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 14),
            Text(
              BunnyStrings.t(
                'These six values are saved only inside Bunny. Only General affects Bunny’s practice cursor; Bunny does not change another app.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: BunnyColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetButton({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BunnyCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      onTap: onTap,
      child: Column(
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: BunnyColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _sensSlider({
    required String label,
    required int value,
    bool highlight = false,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight
                    ? BunnyColors.violetBright
                    : BunnyColors.textPrimary,
              ),
            ),
            if (highlight) ...[
              const SizedBox(width: 6),
              BunnyPillBadge(
                label: BunnyStrings.t('Bunny cursor + reference'),
                color: BunnyColors.violet,
              ),
            ],
            const Spacer(),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: highlight
                    ? BunnyColors.violetBright
                    : BunnyColors.textPrimary,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 200,
          activeColor: highlight
              ? BunnyColors.violetBright
              : BunnyColors.violet,
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}

class _SensPreviewPainter extends CustomPainter {
  _SensPreviewPainter({required this.cursor, required this.active});

  final Offset cursor;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(
      center,
      cursor,
      Paint()
        ..color = BunnyColors.violet.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );

    // Center reference ring
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = BunnyColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Live cursor reticle
    canvas.drawCircle(
      cursor,
      active ? 22 : 16,
      Paint()
        ..color = BunnyColors.violet.withValues(alpha: active ? 0.35 : 0.18),
    );
    canvas.drawCircle(
      cursor,
      active ? 22 : 16,
      Paint()
        ..color = BunnyColors.violetBright
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(cursor, 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SensPreviewPainter oldDelegate) => true;
}
