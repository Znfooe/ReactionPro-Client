import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../../score/services/score_service.dart';

class ScoreDetailDialog extends StatelessWidget {
  const ScoreDetailDialog({required this.detail, super.key});

  final Future<ScoreDetail> detail;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AlertDialog(
      title: const Text('测试完整数据'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppSpacing.x10 * 22,
          maxHeight: size.height * 0.72,
        ),
        child: FutureBuilder<ScoreDetail>(
          future: detail,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: AppSpacing.x16,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || snapshot.data == null) {
              return const _DetailMessage(
                icon: Icons.error_outline,
                text: '数据加载失败，请关闭后重试。',
              );
            }
            return SingleChildScrollView(
              child: _ScoreDetailContent(detail: snapshot.data!),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

class _ScoreDetailContent extends StatelessWidget {
  const _ScoreDetailContent({required this.detail});

  static const _nestedKeys = {'precisionData', 'perRoundData'};

  final ScoreDetail detail;

  @override
  Widget build(BuildContext context) {
    final data = detail.data;
    final primaryEntries = data.entries
        .where(
          (entry) => !_nestedKeys.contains(entry.key) && entry.value != null,
        )
        .toList(growable: false);
    final precisionData = data['precisionData'];
    final perRoundData = data['perRoundData'];

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailSection(
            title: '成绩与测试配置',
            child: _DetailGrid(entries: primaryEntries),
          ),
          if (precisionData is Map<String, Object?>) ...[
            const SizedBox(height: AppSpacing.x4),
            _DetailSection(
              title: '精度数据',
              child: _DetailGrid(entries: precisionData.entries.toList()),
            ),
          ],
          if (perRoundData is List<Object?> && perRoundData.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x4),
            _DetailSection(
              title: '逐回合数据',
              child: Column(
                children: [
                  for (var index = 0; index < perRoundData.length; index++) ...[
                    if (perRoundData[index]
                        case final Map<String, Object?> round)
                      _RoundDetail(index: index, data: round),
                    if (index != perRoundData.length - 1)
                      const SizedBox(height: AppSpacing.x3),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: extension.borderMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.x3),
            child,
          ],
        ),
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.entries});

  final List<MapEntry<String, Object?>> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.x3,
      runSpacing: AppSpacing.x3,
      children: [
        for (final entry in entries)
          SizedBox(
            width: AppSpacing.x10 * 7,
            child: _DetailValue(name: entry.key, value: entry.value),
          ),
      ],
    );
  }
}

class _RoundDetail extends StatelessWidget {
  const _RoundDetail({required this.index, required this.data});

  final int index;
  final Map<String, Object?> data;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: extension.bgMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '回合 ${index + 1}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.x2),
            _DetailGrid(entries: data.entries.toList()),
          ],
        ),
      ),
    );
  }
}

class _DetailValue extends StatelessWidget {
  const _DetailValue({required this.name, required this.value});

  final String name;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _labelFor(name),
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: extension.textSecondary),
        ),
        const SizedBox(height: AppSpacing.x1),
        Text(
          _formatValue(name, value),
          style: AppTypography.mono(
            fontSize: AppTypography.textSm,
            lineHeight: AppTypography.lineSm,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: AppSpacing.x2),
          Text(text),
        ],
      ),
    );
  }
}

const _labels = <String, String>{
  'id': '成绩 ID',
  'testType': '测试类型',
  'category': '排行榜分类',
  'roundCount': '回合数',
  'rawTime': '原始反应时间',
  'calibratedTime': '校准反应时间',
  'estimatedRenderDelay': '估计渲染延迟',
  'estimatedInputDelay': '估计输入延迟',
  'aimMode': '击杀模式',
  'evalMode': '评估模式',
  'targetBehavior': '目标行为',
  'targetCount': '目标数',
  'duration': '持续时间',
  'targetSize': '目标尺寸',
  'targetSpeed': '目标速度',
  'directionMode': '方向模式',
  'multiTargetCount': '同时目标数',
  'sensitivity': '灵敏度',
  'mYaw': 'm_yaw',
  'mPitch': 'm_pitch',
  'dpi': 'DPI',
  'avgKillTime': '平均击杀时间',
  'bestTime': '最佳成绩',
  'worstTime': '最差成绩',
  'trimmedMean': '去极值平均',
  'hitRate': '命中率',
  'errorRate': '空枪率',
  'totalKills': '击杀数',
  'totalShots': '射击数',
  'isValid': '成绩有效',
  'leaderboardEligible': '已发布排行榜',
  'leaderboardQualified': '通过质量门禁',
  'leaderboardAnonymous': '匿名展示',
  'qualityScore': '质量分',
  'qualityFlags': '质量标记',
  'createdAt': '测试时间',
  'droppedFrameRate': '掉帧率',
  'droppedFrameCount': '掉帧数',
  'frameSampleCount': '帧样本数',
};

String _labelFor(String name) => _labels[name] ?? name;

String _formatValue(String name, Object? value) {
  if (value == null) {
    return '--';
  }
  if (value is bool) {
    return value ? '是' : '否';
  }
  if (value is List<Object?>) {
    return value.isEmpty ? '无' : value.join(', ');
  }
  if (name == 'testType') {
    return value == 'reaction' ? '反应力测试' : '击杀时间测试';
  }
  if (name == 'createdAt' && value is String) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date != null) {
      String twoDigits(int number) => number.toString().padLeft(2, '0');
      return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)} '
          '${twoDigits(date.hour)}:${twoDigits(date.minute)}:${twoDigits(date.second)}';
    }
  }
  if (name.toLowerCase().contains('rate') && value is num) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
  if ((name.toLowerCase().contains('time') ||
          name.toLowerCase().contains('delay') ||
          name.toLowerCase().contains('mean')) &&
      value is num) {
    return '$value ms';
  }
  return value.toString();
}
