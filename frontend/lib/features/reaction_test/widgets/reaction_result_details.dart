import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/theme/app_typography.dart';
import '../logic/reaction_session_record.dart';
import '../logic/reaction_test_controller.dart';

class ReactionHistoryPanel extends StatelessWidget {
  const ReactionHistoryPanel({
    required this.entries,
    required this.onOpenDetails,
    super.key,
  });

  final List<ReactionSessionRecord> entries;
  final ValueChanged<ReactionSessionRecord> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '反应力历史数据',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '${entries.length} 次',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: extension.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        if (entries.isEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: extension.accentMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: extension.borderMuted),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Text(
                '完成一个回合组后，这里会保留总结、延迟分解和全部逐回合数据。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: extension.textSecondary,
                ),
              ),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: extension.borderMuted),
              ),
            ),
            child: Column(
              children: [
                for (var index = 0; index < entries.length; index++)
                  _ReactionHistoryTile(
                    index: index,
                    entry: entries[index],
                    onOpenDetails: onOpenDetails,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class ReactionResultDetails extends StatelessWidget {
  const ReactionResultDetails({required this.entry, super.key});

  final ReactionSessionRecord entry;

  @override
  Widget build(BuildContext context) {
    final summary = entry.summary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: AppSpacing.x3,
          runSpacing: AppSpacing.x3,
          children: [
            _SummaryMetric(
              label: '平均校准反应时间',
              value: _formatDecimalMs(summary.averageReactionTimeMs),
              emphasized: true,
            ),
            _SummaryMetric(
              label: '最优成绩',
              value: _formatMs(summary.bestReactionTimeMs),
            ),
            _SummaryMetric(
              label: '最差成绩',
              value: _formatMs(summary.worstReactionTimeMs),
            ),
            _SummaryMetric(
              label: '标准差',
              value: _formatDecimalMs(summary.standardDeviationMs),
            ),
            if (summary.trimmedMeanMs != null)
              _SummaryMetric(
                label: '去极值平均',
                value: _formatDecimalMs(summary.trimmedMeanMs!),
              ),
            _SummaryMetric(
              label: '入榜资格',
              value: entry.leaderboardEligible ? '可入榜' : '仅练习',
            ),
            _SummaryMetric(label: '质量分', value: '${entry.qualityScore}'),
            _SummaryMetric(
              label: '掉帧率',
              value: _formatPercent(entry.droppedFrameRate),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        _ResultSection(
          title: '延迟分解汇总',
          child: Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              _DataChip(
                label: '平均原始反应时间',
                value: _formatDecimalMs(entry.averageRawReactionTimeMs),
              ),
              _DataChip(
                label: '平均渲染延迟',
                value: _formatDecimalMs(entry.averageEstimatedRenderDelayMs),
              ),
              _DataChip(
                label: '平均输入延迟',
                value: _formatDecimalMs(entry.averageEstimatedInputDelayMs),
              ),
              _DataChip(
                label: '平均硬件延迟估算',
                value: _formatDecimalMs(entry.averageHardwareLatencyEstimateMs),
              ),
              _DataChip(
                label: '平均校准反应时间',
                value: _formatDecimalMs(entry.averageCalibratedReactionTimeMs),
              ),
              _DataChip(
                label: '延迟补偿值',
                value: _formatDecimalMs(entry.calibrationOffsetMs),
              ),
              _DataChip(
                label: '掉帧',
                value:
                    '${entry.totalDroppedFrameCount} / ${entry.totalFrameSampleCount}',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        _ResultSection(
          title: '测试配置',
          child: Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              _DataChip(label: '回合组', value: '${entry.selectedRoundCount} 回合'),
              _DataChip(
                label: '信号出现范围',
                value:
                    '${entry.signalMinDelaySeconds}-${entry.signalMaxDelaySeconds} 秒',
              ),
              _DataChip(
                label: '随机跨度',
                value:
                    '${entry.signalMaxDelaySeconds - entry.signalMinDelaySeconds} 秒',
              ),
              _DataChip(
                label: '完成时间',
                value: _formatHistoryTime(entry.completedAt),
              ),
            ],
          ),
        ),
        if (entry.qualityFlags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x4),
          _ResultSection(
            title: '质量标记',
            child: Text(
              entry.qualityFlags.join(', '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x4),
        _ResultSection(
          title: '回合趋势',
          child: ReactionTrendChart(results: entry.rounds),
        ),
        const SizedBox(height: AppSpacing.x4),
        _ResultSection(
          title: '逐回合完整数据',
          child: _ReactionRoundDataTable(rounds: entry.rounds),
        ),
      ],
    );
  }
}

class ReactionTrendChart extends StatelessWidget {
  const ReactionTrendChart({required this.results, super.key});

  final List<ReactionRoundResult> results;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);
    final spots = <FlSpot>[
      for (final result in results)
        FlSpot(
          result.roundNumber.toDouble(),
          result.calibratedReactionTimeMs.toDouble(),
        ),
    ];

    return SizedBox(
      height: AppSpacing.x10 * 4,
      child: LineChart(
        LineChartData(
          minX: 1,
          maxX: results.length.toDouble(),
          minY: 0,
          gridData: FlGridData(
            getDrawingHorizontalLine: (value) {
              return FlLine(color: extension.borderMuted, strokeWidth: 1);
            },
            getDrawingVerticalLine: (value) {
              return FlLine(color: extension.borderMuted, strokeWidth: 1);
            },
          ),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            border: Border.all(color: extension.borderMuted),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: colors.primary,
              barWidth: 2,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactionHistoryTile extends StatelessWidget {
  const _ReactionHistoryTile({
    required this.index,
    required this.entry,
    required this.onOpenDetails,
  });

  final int index;
  final ReactionSessionRecord entry;
  final ValueChanged<ReactionSessionRecord> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.x4),
      leading: CircleAvatar(child: Text('${index + 1}')),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${_formatHistoryTime(entry.completedAt)} · '
              '${_formatDecimalMs(entry.averageCalibratedReactionTimeMs)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.x3),
          OutlinedButton.icon(
            onPressed: () => onOpenDetails(entry),
            icon: const Icon(Icons.open_in_full_outlined),
            label: const Text('弹窗查看'),
          ),
        ],
      ),
      subtitle: Text(
        '${entry.selectedRoundCount} 回合 · '
        '硬件延迟 ${_formatDecimalMs(entry.averageHardwareLatencyEstimateMs)} · '
        '${entry.leaderboardEligible ? '可入榜' : '仅练习'}',
      ),
      children: [ReactionResultDetails(entry: entry)],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return SizedBox(
      width: AppSpacing.x10 * 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: emphasized
              ? extension.accentMuted
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: extension.borderMuted),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.mono(
                  fontSize: AppTypography.text2xl,
                  lineHeight: AppTypography.line2xl,
                  fontWeight: AppTypography.fontWeightBold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.child});

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

class _DataChip extends StatelessWidget {
  const _DataChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: extension.accentMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x2,
        ),
        child: Text(
          '$label $value',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _ReactionRoundDataTable extends StatelessWidget {
  const _ReactionRoundDataTable({required this.rounds});

  final List<ReactionRoundResult> rounds;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: AppSpacing.x5,
        columns: const [
          DataColumn(label: Text('回合')),
          DataColumn(label: Text('原始反应')),
          DataColumn(label: Text('渲染延迟')),
          DataColumn(label: Text('输入延迟')),
          DataColumn(label: Text('硬件延迟估算')),
          DataColumn(label: Text('校准反应')),
          DataColumn(label: Text('资格')),
          DataColumn(label: Text('质量分')),
          DataColumn(label: Text('掉帧率')),
          DataColumn(label: Text('质量标记')),
        ],
        rows: [
          for (final round in rounds)
            DataRow(
              cells: [
                DataCell(Text('${round.roundNumber}')),
                DataCell(Text(_formatMs(round.rawReactionTimeMs))),
                DataCell(Text(_formatMs(round.estimatedRenderDelayMs))),
                DataCell(Text(_formatMs(round.estimatedInputDelayMs))),
                DataCell(Text(_formatMs(round.hardwareLatencyEstimateMs))),
                DataCell(Text(_formatMs(round.calibratedReactionTimeMs))),
                DataCell(Text(round.leaderboardEligible ? '可入榜' : '练习')),
                DataCell(Text('${round.qualityScore}')),
                DataCell(Text(_formatPercent(round.droppedFrameRate))),
                DataCell(
                  Text(
                    round.qualityFlags.isEmpty
                        ? '无'
                        : round.qualityFlags.join(', '),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

String _formatMs(int value) => '$value ms';

String _formatDecimalMs(double value) => '${value.toStringAsFixed(1)} ms';

String _formatPercent(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _formatHistoryTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}:${twoDigits(value.second)}';
}
