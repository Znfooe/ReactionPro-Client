import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/splash_appearance.dart';
import '../../core/theme/splash_appearance_provider.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/reactionpro_pattern.dart';
import '../../shared/widgets/status_pill.dart';
import 'client_update/client_update_settings_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(splashAppearanceProvider);
    final controller = ref.read(splashAppearanceProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);

    return AppPageScaffold(
      activeRoute: AppRoutes.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('设置', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.x4),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              StatusPill(label: '开屏动画', color: colors.primary),
              StatusPill(label: '本机保存', color: extension.colorSuccess),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          const ClientUpdateSettingsCard(),
          const SizedBox(height: AppSpacing.x12),
          Text('外观与开屏', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.x6),
          LayoutBuilder(
            builder: (context, constraints) {
              final editor = _AppearanceEditor(
                appearance: appearance,
                onPresetSelected: controller.selectPreset,
                onColorChanged: controller.updateColor,
                onReset: controller.reset,
              );
              final preview = _SplashPreview(appearance: appearance);

              if (constraints.maxWidth >= AppSpacing.x10 * 22) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: editor),
                    const SizedBox(width: AppSpacing.x8),
                    Expanded(flex: 9, child: preview),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  preview,
                  const SizedBox(height: AppSpacing.x8),
                  editor,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AppearanceEditor extends StatelessWidget {
  const _AppearanceEditor({
    required this.appearance,
    required this.onPresetSelected,
    required this.onColorChanged,
    required this.onReset,
  });

  final SplashAppearance appearance;
  final ValueChanged<SplashAppearancePreset> onPresetSelected;
  final void Function(SplashColorRole role, Color color) onColorChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('配色模板', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.x2),
        Text('选择模板后仍可继续调整任意颜色。', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.x4),
        Wrap(
          spacing: AppSpacing.x3,
          runSpacing: AppSpacing.x3,
          children: [
            for (final preset in splashAppearancePresets)
              _PresetTile(
                preset: preset,
                selected: appearance.presetId == preset.id,
                onTap: () => onPresetSelected(preset),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        Row(
          children: [
            Expanded(
              child: Text(
                '自定义颜色',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: onReset,
              tooltip: '恢复默认配色',
              icon: const Icon(Icons.restart_alt_outlined),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        _ColorControl(
          label: '幕布背景',
          description: '开屏与收屏时的底色',
          color: appearance.background,
          onTap: () => _pickColor(
            context,
            role: SplashColorRole.background,
            initialColor: appearance.background,
          ),
        ),
        _ColorControl(
          label: '分屏线与纹样',
          description: '中线、主要花纹和动态边界',
          color: appearance.line,
          onTap: () => _pickColor(
            context,
            role: SplashColorRole.line,
            initialColor: appearance.line,
          ),
        ),
        _ColorControl(
          label: '文字轮廓',
          description: 'ZNFOOE 2026 的描边颜色',
          color: appearance.outline,
          onTap: () => _pickColor(
            context,
            role: SplashColorRole.outline,
            initialColor: appearance.outline,
          ),
        ),
        _ColorControl(
          label: '文字渐变起点',
          description: '文字左侧颜色',
          color: appearance.textStart,
          onTap: () => _pickColor(
            context,
            role: SplashColorRole.textStart,
            initialColor: appearance.textStart,
          ),
        ),
        _ColorControl(
          label: '文字渐变终点',
          description: '文字右侧颜色',
          color: appearance.textEnd,
          onTap: () => _pickColor(
            context,
            role: SplashColorRole.textEnd,
            initialColor: appearance.textEnd,
          ),
        ),
      ],
    );
  }

  Future<void> _pickColor(
    BuildContext context, {
    required SplashColorRole role,
    required Color initialColor,
  }) async {
    final selected = await showSplashColorPicker(
      context,
      initialColor: initialColor,
    );
    if (selected != null) {
      onColorChanged(role, selected);
    }
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final SplashAppearancePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    final colors = Theme.of(context).colorScheme;
    final appearance = preset.appearance;

    return SizedBox(
      width: AppSpacing.x10 * 6,
      child: Material(
        color: selected ? extension.accentMuted : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: selected ? colors.primary : extension.borderMuted,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ColorStrip(
                        colors: [
                          appearance.background,
                          appearance.line,
                          appearance.outline,
                          appearance.textStart,
                          appearance.textEnd,
                        ],
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: AppSpacing.x2),
                      Icon(Icons.check_circle, color: colors.primary),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  preset.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  preset.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorStrip extends StatelessWidget {
  const _ColorStrip({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        height: AppSpacing.x4,
        child: Row(
          children: [
            for (final color in colors)
              Expanded(child: ColoredBox(color: color)),
          ],
        ),
      ),
    );
  }
}

class _ColorControl extends StatelessWidget {
  const _ColorControl({
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(description),
      trailing: IconButton(
        onPressed: onTap,
        tooltip: '选择$label',
        icon: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppThemeExtension.of(context).borderDefault,
            ),
          ),
          child: const SizedBox.square(dimension: AppSpacing.x8),
        ),
      ),
    );
  }
}

class _SplashPreview extends StatelessWidget {
  const _SplashPreview({required this.appearance});

  final SplashAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('实时预览', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.x4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ReactionProPatternSurface(appearance: appearance),
                Center(child: _PreviewBrandMark(appearance: appearance)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x3),
        Text(
          appearance.presetId == 'custom' ? '当前为自定义配色' : '模板会同步用于首次开屏与页面切换幕布',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: extension.textSecondary),
        ),
      ],
    );
  }
}

class _PreviewBrandMark extends StatelessWidget {
  const _PreviewBrandMark({required this.appearance});

  final SplashAppearance appearance;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: Colors.white,
      fontFamily: 'CangErYuMoW03',
      fontFamilyFallback: AppTypography.fontFallback,
      fontSize: AppTypography.text4xl,
      fontWeight: AppTypography.fontWeightBold,
      letterSpacing: AppTypography.splashLetterSpacing,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'ZNFOOE 2026',
          style: style.copyWith(
            foreground: ui.Paint()
              ..style = ui.PaintingStyle.stroke
              ..strokeWidth = AppTypography.splashOutlineWidth
              ..color = appearance.outline,
          ),
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => LinearGradient(
            colors: [appearance.textStart, appearance.textEnd],
          ).createShader(bounds),
          child: Text('ZNFOOE 2026', style: style),
        ),
      ],
    );
  }
}

Future<Color?> showSplashColorPicker(
  BuildContext context, {
  required Color initialColor,
}) {
  var selected = HSVColor.fromColor(initialColor);

  return showDialog<Color>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('选择颜色'),
            content: SizedBox(
              width: AppSpacing.x10 * 9,
              child: _HsvColorPicker(
                color: selected,
                onChanged: (value) => setDialogState(() => selected = value),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(selected.toColor()),
                child: const Text('应用'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _HsvColorPicker extends StatelessWidget {
  const _HsvColorPicker({required this.color, required this.onChanged});

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSpacing.x10 * 5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              void update(Offset position) {
                final saturation = (position.dx / constraints.maxWidth).clamp(
                  0.0,
                  1.0,
                );
                final value =
                    1 - (position.dy / constraints.maxHeight).clamp(0.0, 1.0);
                onChanged(color.withSaturation(saturation).withValue(value));
              }

              return GestureDetector(
                onTapDown: (details) => update(details.localPosition),
                onPanUpdate: (details) => update(details.localPosition),
                child: CustomPaint(
                  painter: _SaturationValuePainter(color: color),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        SizedBox(
          height: AppSpacing.x6,
          child: LayoutBuilder(
            builder: (context, constraints) {
              void update(Offset position) {
                final hue =
                    (position.dx / constraints.maxWidth).clamp(0.0, 1.0) * 360;
                onChanged(color.withHue(hue));
              }

              return GestureDetector(
                onTapDown: (details) => update(details.localPosition),
                onPanUpdate: (details) => update(details.localPosition),
                child: CustomPaint(painter: _HuePainter(hue: color.hue)),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.toColor(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppThemeExtension.of(context).borderDefault,
                ),
              ),
              child: const SizedBox.square(dimension: AppSpacing.x10),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Text(
                '拖动色板确定明暗与饱和度，拖动色相条选择色系。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({required this.color});

  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, color.hue, 1, 1).toColor();
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );

    final point = Offset(
      size.width * color.saturation,
      size.height * (1 - color.value),
    );
    canvas.drawCircle(
      point,
      AppSpacing.x2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      point,
      AppSpacing.x2 + 1,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _SaturationValuePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

final class _HuePainter extends CustomPainter {
  const _HuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColors = [
      for (var index = 0; index <= 6; index++)
        HSVColor.fromAHSV(1, index * 60, 1, 1).toColor(),
    ];
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(AppRadius.sm)),
      Paint()..shader = LinearGradient(colors: hueColors).createShader(rect),
    );
    final x = size.width * hue / 360;
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _HuePainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}
