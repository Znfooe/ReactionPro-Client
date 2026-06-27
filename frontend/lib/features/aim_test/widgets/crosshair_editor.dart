import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extension.dart';
import 'crosshair.dart';

class CrosshairEditor extends StatelessWidget {
  const CrosshairEditor({
    required this.style,
    required this.onChanged,
    required this.enabled,
    super.key,
  });

  final CrosshairStyle style;
  final ValueChanged<CrosshairStyle> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('准星样式', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x3),
        Container(
          height: AppSpacing.x10 * 3,
          decoration: BoxDecoration(
            color: extension.bgMuted,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: extension.borderMuted),
          ),
          child: Crosshair(style: style, dynamicSpreadPx: 10),
        ),
        const SizedBox(height: AppSpacing.x4),
        _EditorSlider(
          label: '长度',
          valueLabel: '${style.length.round()} px',
          value: style.length,
          min: 1,
          max: 50,
          divisions: 49,
          precision: 0,
          enabled: enabled,
          onChanged: (value) => onChanged(style.copyWith(length: value)),
        ),
        _EditorSlider(
          label: '宽度',
          valueLabel: '${style.thickness.round()} px',
          value: style.thickness,
          min: 1,
          max: 10,
          divisions: 9,
          precision: 0,
          enabled: enabled,
          onChanged: (value) => onChanged(style.copyWith(thickness: value)),
        ),
        _EditorSlider(
          label: '间隙',
          valueLabel: '${style.gap.round()} px',
          value: style.gap,
          min: 0,
          max: 30,
          divisions: 30,
          precision: 0,
          enabled: enabled,
          onChanged: (value) => onChanged(style.copyWith(gap: value)),
        ),
        _ColorSwatches(
          label: '颜色',
          selected: style.color,
          enabled: enabled,
          colors: const [
            AppColors.testCrosshairDefault,
            AppColors.blue300,
            AppColors.red500,
            AppColors.orange400,
            AppColors.testOnColor,
          ],
          onChanged: (color) => onChanged(style.copyWith(color: color)),
        ),
        _ToggleRow(
          label: '中心点',
          value: style.dot,
          enabled: enabled,
          onChanged: (value) => onChanged(style.copyWith(dot: value)),
        ),
        _EditorSlider(
          label: '中心点大小',
          valueLabel: '${style.dotSize.round()} px',
          value: style.dotSize,
          min: 1,
          max: 10,
          divisions: 9,
          precision: 0,
          enabled: enabled && style.dot,
          onChanged: (value) => onChanged(style.copyWith(dotSize: value)),
        ),
        _ToggleRow(
          label: '轮廓',
          value: style.outline,
          enabled: enabled,
          onChanged: (value) => onChanged(style.copyWith(outline: value)),
        ),
        _EditorSlider(
          label: '轮廓粗细',
          valueLabel: style.outlineThickness.toStringAsFixed(1),
          value: style.outlineThickness,
          min: 0,
          max: 3,
          divisions: 6,
          precision: 1,
          enabled: enabled && style.outline,
          onChanged: (value) =>
              onChanged(style.copyWith(outlineThickness: value)),
        ),
        _ColorSwatches(
          label: '轮廓颜色',
          selected: style.outlineColor,
          enabled: enabled && style.outline,
          colors: const [
            AppColors.gray950,
            AppColors.gray50,
            AppColors.blue900,
            AppColors.red900,
          ],
          onChanged: (color) => onChanged(style.copyWith(outlineColor: color)),
        ),
        _ToggleRow(
          label: 'T 形准星',
          value: style.tStyle,
          enabled: enabled,
          onChanged: (value) => onChanged(style.copyWith(tStyle: value)),
        ),
        _ToggleRow(
          label: '动态扩散',
          value: style.dynamicSpread,
          enabled: enabled,
          onChanged: (value) => onChanged(style.copyWith(dynamicSpread: value)),
        ),
      ],
    );
  }
}

class _EditorSlider extends StatelessWidget {
  const _EditorSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.enabled,
    required this.onChanged,
    this.precision = 0,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final int precision;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            _EditableEditorValue(
              label: label,
              valueLabel: valueLabel,
              value: value,
              min: min,
              max: max,
              precision: precision,
              enabled: enabled,
              onChanged: onChanged,
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class _EditableEditorValue extends StatelessWidget {
  const _EditableEditorValue({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.precision,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int precision;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => _showPreciseInput(context) : null,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2,
          vertical: AppSpacing.x1,
        ),
        child: Text(
          valueLabel,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            decoration: enabled ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }

  Future<void> _showPreciseInput(BuildContext context) async {
    final controller = TextEditingController(
      text: value.toStringAsFixed(precision),
    );
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    final submitted = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(label),
          content: TextField(
            controller: controller,
            autofocus: true,
            selectAllOnFocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '输入数值',
              helperText:
                  '${min.toStringAsFixed(precision)} - ${max.toStringAsFixed(precision)}',
            ),
            onSubmitted: (text) {
              Navigator.of(context).pop(_parseValue(text));
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(_parseValue(controller.text));
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    if (submitted != null) {
      onChanged(submitted);
    }
  }

  double? _parseValue(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null) {
      return null;
    }
    return parsed.clamp(min, max).toDouble();
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.labelLarge),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches({
    required this.label,
    required this.selected,
    required this.colors,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final Color selected;
  final List<Color> colors;
  final bool enabled;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              TextButton.icon(
                onPressed: enabled ? () => _showColorPalette(context) : null,
                icon: const Icon(Icons.palette_outlined, size: 16),
                label: const Text('颜色板'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x2),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final color in colors)
                _SwatchButton(
                  color: color,
                  selected: selected == color,
                  enabled: enabled,
                  onTap: () => onChanged(color),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showColorPalette(BuildContext context) async {
    final submitted = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(label),
          content: SizedBox(
            width: AppSpacing.x10 * 8,
            child: Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                for (final color in _paletteColors(colors, selected))
                  _SwatchButton(
                    color: color,
                    selected: selected == color,
                    enabled: true,
                    onTap: () => Navigator.of(context).pop(color),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _showColorInput(context);
              },
              icon: const Icon(Icons.tag_outlined),
              label: const Text('高级 HEX'),
            ),
          ],
        );
      },
    );
    if (submitted != null) {
      onChanged(submitted);
    }
  }

  Future<void> _showColorInput(BuildContext context) async {
    final controller = TextEditingController(text: _formatColor(selected));
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    final submitted = await showDialog<Color>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(label),
          content: TextField(
            controller: controller,
            autofocus: true,
            selectAllOnFocus: true,
            decoration: const InputDecoration(
              labelText: 'HEX 颜色',
              helperText: '#RRGGBB 或 #AARRGGBB',
            ),
            onSubmitted: (text) {
              Navigator.of(context).pop(_parseHexColor(text));
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(_parseHexColor(controller.text));
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
    if (submitted != null) {
      onChanged(submitted);
    }
  }
}

String _formatColor(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

Color? _parseHexColor(String text) {
  final normalized = text.trim().replaceFirst('#', '');
  if (normalized.length != 6 && normalized.length != 8) {
    return null;
  }
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) {
    return null;
  }
  if (normalized.length == 6) {
    return Color(0xFF000000 | parsed);
  }
  return Color(parsed);
}

List<Color> _paletteColors(List<Color> preferred, Color selected) {
  final colors = <Color>[
    selected,
    ...preferred,
    AppColors.testCrosshairDefault,
    AppColors.testTargetColor,
    AppColors.testWaitBg,
    AppColors.testSignalBg,
    AppColors.gray50,
    AppColors.gray200,
    AppColors.gray500,
    AppColors.gray950,
    AppColors.blue300,
    AppColors.blue500,
    AppColors.blue700,
    AppColors.green400,
    AppColors.green500,
    AppColors.orange400,
    AppColors.orange500,
    AppColors.red400,
    AppColors.red500,
    AppColors.red700,
    Colors.white,
    Colors.black,
  ];
  final seen = <int>{};
  return [
    for (final color in colors)
      if (seen.add(color.toARGB32())) color,
  ];
}

class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.color,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        width: AppSpacing.x8,
        height: AppSpacing.x8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : AppThemeExtension.of(context).borderMuted,
            width: selected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
