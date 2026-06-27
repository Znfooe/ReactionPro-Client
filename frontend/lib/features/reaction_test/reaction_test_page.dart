import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/precision/precision_timing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../../shared/widgets/status_pill.dart';
import '../auth/providers/auth_provider.dart';
import '../aim_test/core/fullscreen_controller.dart';
import '../score/services/score_service.dart';
import '../score/widgets/score_submit_panel.dart';
import 'core/timing_engine.dart';
import 'logic/reaction_session_record.dart';
import 'logic/reaction_test_controller.dart';
import 'widgets/reaction_result_details.dart';

class ReactionTestPage extends ConsumerStatefulWidget {
  const ReactionTestPage({super.key});

  @override
  ConsumerState<ReactionTestPage> createState() => _ReactionTestPageState();
}

class _ReactionTestPageState extends ConsumerState<ReactionTestPage>
    with SingleTickerProviderStateMixin {
  final _timer = const BrowserPerformanceTimer();
  final _frameQuality = FrameQualityMonitor();
  final _fullscreenController = FullscreenController();
  late final AnimationController _frameTicker;
  bool _submittingScore = false;
  bool _immersive = false;
  SubmittedScore? _submittedScore;
  String? _submitError;
  final List<ReactionSessionRecord> _historyEntries = [];
  bool _resultDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _frameQuality.reset(nowMs: _timer.now());
    _frameTicker =
        AnimationController(vsync: this, duration: const Duration(seconds: 1))
          ..addListener(() {
            _frameQuality.recordFrame(_timer.now());
          })
          ..repeat();
    _fullscreenController.startListening(
      onChange: (fullscreen) {
        if (!mounted) {
          return;
        }
        if (!fullscreen && _immersive) {
          ref.read(reactionTestControllerProvider.notifier).resetSession();
          setState(() {
            _immersive = false;
          });
          return;
        }
      },
    );
    Future<void>.microtask(() async {
      if (!mounted) {
        return;
      }

      await ref
          .read(reactionTestControllerProvider.notifier)
          .loadCalibrationOffset(
            service: ref.read(calibrationServiceProvider),
            store: ref.read(calibrationOffsetStoreProvider),
          );
    });
  }

  @override
  void dispose() {
    _fullscreenController.dispose();
    _frameTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reactionTestControllerProvider);
    final controller = ref.read(reactionTestControllerProvider.notifier);
    final authState = ref.watch(authProvider);

    if (_immersive) {
      return Scaffold(
        body: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.escape) {
              _exitReactionSession();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: _ReactionArenaShell(
                  state: state,
                  immersive: true,
                  onPointerDown: (inputTiming) {
                    _handleReactionTap(
                      state,
                      controller,
                      inputTiming: inputTiming,
                    );
                  },
                ),
              ),
              Positioned(
                right: AppSpacing.x4,
                top: AppSpacing.x4,
                child: IconButton.filledTonal(
                  onPressed: _exitReactionSession,
                  tooltip: '退出',
                  icon: const Icon(Icons.close_fullscreen_outlined),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AppPageScaffold(
      activeRoute: AppRoutes.reactionTest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('反应力测试', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.x4),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: const [
              StatusPill(label: '等待期', color: AppColors.testWaitBg),
              StatusPill(label: '信号期', color: AppColors.testSignalBg),
              StatusPill(label: '抢跑', color: AppColors.testFalseStartBg),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 880;

              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _ReactionArenaShell(
                        state: state,
                        onPointerDown: (inputTiming) {
                          _handleReactionTap(
                            state,
                            controller,
                            inputTiming: inputTiming,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x8),
                    Expanded(
                      flex: 2,
                      child: _RoundPanel(
                        state: state,
                        onSelectRoundCount: controller.selectRoundCount,
                        authenticated: authState.isAuthenticated,
                        submittingScore: _submittingScore,
                        submittedScore: _submittedScore,
                        submitError: _submitError,
                        onPrimaryAction: () =>
                            _handleReactionTap(state, controller),
                        onSignalDelayRangeChanged: (minSeconds, maxSeconds) =>
                            controller.setSignalDelayRange(
                              minSeconds: minSeconds,
                              maxSeconds: maxSeconds,
                            ),
                        onSubmitScore: () => _submitCurrentReactionScore(state),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReactionArenaShell(
                    state: state,
                    onPointerDown: (inputTiming) {
                      _handleReactionTap(
                        state,
                        controller,
                        inputTiming: inputTiming,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  _RoundPanel(
                    state: state,
                    onSelectRoundCount: controller.selectRoundCount,
                    authenticated: authState.isAuthenticated,
                    submittingScore: _submittingScore,
                    submittedScore: _submittedScore,
                    submitError: _submitError,
                    onPrimaryAction: () =>
                        _handleReactionTap(state, controller),
                    onSignalDelayRangeChanged: (minSeconds, maxSeconds) =>
                        controller.setSignalDelayRange(
                          minSeconds: minSeconds,
                          maxSeconds: maxSeconds,
                        ),
                    onSubmitScore: () => _submitCurrentReactionScore(state),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.x8),
          ReactionHistoryPanel(
            entries: _historyEntries,
            onOpenDetails: _showReactionResultDialog,
          ),
        ],
      ),
    );
  }

  void _handleReactionTap(
    ReactionTestState state,
    ReactionTestController controller, {
    InputEventTiming? inputTiming,
  }) {
    final starting =
        state.phase == ReactionTestPhase.idle ||
        state.phase == ReactionTestPhase.completed;
    if (starting) {
      _clearSubmittedScoreIfStarting(state);
      setState(() {
        _immersive = true;
      });
      _fullscreenController.requestFullscreen();
    }

    controller.tapArena(
      inputTiming: inputTiming,
      frameQuality: _frameQuality.snapshot(),
    );

    final updatedState = ref.read(reactionTestControllerProvider);
    if (updatedState.phase == ReactionTestPhase.completed) {
      final entry = ReactionSessionRecord.fromCompletedState(
        updatedState,
        completedAt: DateTime.now(),
      );
      if (mounted) {
        setState(() {
          _immersive = false;
          _storeHistoryEntry(entry);
        });
      }
      _fullscreenController.exitFullscreen();
      _showReactionResultDialog(entry, allowScoreSubmit: true);
    }
  }

  void _exitReactionSession() {
    ref.read(reactionTestControllerProvider.notifier).resetSession();
    if (mounted) {
      setState(() {
        _immersive = false;
      });
    }
    _fullscreenController.exitFullscreen();
  }

  void _clearSubmittedScoreIfStarting(ReactionTestState state) {
    if (state.phase != ReactionTestPhase.completed &&
        state.phase != ReactionTestPhase.idle) {
      return;
    }
    if (_submittedScore == null && _submitError == null) {
      return;
    }
    setState(() {
      _submittedScore = null;
      _submitError = null;
    });
  }

  void _storeHistoryEntry(ReactionSessionRecord entry) {
    _historyEntries.insert(0, entry);
    if (_historyEntries.length > 50) {
      _historyEntries.removeRange(50, _historyEntries.length);
    }
  }

  void _showReactionResultDialog(
    ReactionSessionRecord entry, {
    bool allowScoreSubmit = false,
  }) {
    if (_resultDialogOpen || !mounted) {
      return;
    }
    _resultDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _resultDialogOpen = false;
        return;
      }
      try {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                final authState = ref.read(authProvider);
                final availableHeight = MediaQuery.sizeOf(context).height;
                return AlertDialog(
                  title: const Text('反应力测试结果'),
                  content: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppSpacing.x10 * 24,
                      maxHeight: availableHeight * 0.76,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ReactionResultDetails(entry: entry),
                          if (allowScoreSubmit) ...[
                            const SizedBox(height: AppSpacing.x4),
                            ScoreSubmitPanel(
                              completed: true,
                              authenticated: authState.isAuthenticated,
                              submitting: _submittingScore,
                              submittedScore: _submittedScore,
                              errorMessage: _submitError,
                              onSubmit: () {
                                _submitReactionScore(entry).whenComplete(() {
                                  if (dialogContext.mounted) {
                                    setDialogState(() {});
                                  }
                                });
                              },
                              onLogin: () {
                                Navigator.of(dialogContext).pop();
                                context.go(AppRoutes.login);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('关闭'),
                    ),
                  ],
                );
              },
            );
          },
        );
      } finally {
        _resultDialogOpen = false;
      }
    });
  }

  void _submitCurrentReactionScore(ReactionTestState state) {
    if (state.phase != ReactionTestPhase.completed || state.results.isEmpty) {
      return;
    }
    final entry = _historyEntries.isNotEmpty
        ? _historyEntries.first
        : ReactionSessionRecord.fromCompletedState(
            state,
            completedAt: DateTime.now(),
          );
    _submitReactionScore(entry);
  }

  Future<void> _submitReactionScore(ReactionSessionRecord entry) async {
    if (_submittingScore || entry.rounds.isEmpty) {
      return;
    }

    setState(() {
      _submittingScore = true;
      _submitError = null;
    });

    try {
      final results = entry.rounds;
      final rawTime = _averageInt(
        results.map((result) => result.rawReactionTimeMs),
      );
      final calibratedTime = _averageInt(
        results.map((result) => result.calibratedReactionTimeMs),
      );
      final renderDelay = _averageInt(
        results.map((result) => result.estimatedRenderDelayMs),
      );
      final inputDelay = _averageInt(
        results.map((result) => result.estimatedInputDelayMs),
      );
      final qualityScore = results
          .map((result) => result.qualityScore)
          .reduce((left, right) => left < right ? left : right);
      final qualityFlags = <String>{
        for (final result in results) ...result.qualityFlags,
      }.toList();
      final submitted = await ref
          .read(scoreServiceProvider)
          .submitReactionScore(
            roundCount: entry.selectedRoundCount,
            rawTime: rawTime,
            calibratedTime: calibratedTime,
            estimatedRenderDelay: renderDelay,
            estimatedInputDelay: inputDelay,
            leaderboardEligible: entry.leaderboardEligible,
            qualityScore: qualityScore,
            qualityFlags: qualityFlags,
            precisionData: {
              'rounds': results.length,
              'signalMinDelaySeconds': entry.signalMinDelaySeconds,
              'signalMaxDelaySeconds': entry.signalMaxDelaySeconds,
              'calibrationOffsetMs': entry.calibrationOffsetMs,
              'averageHardwareLatencyEstimateMs':
                  entry.averageHardwareLatencyEstimateMs,
              'qualityFlags': qualityFlags,
            },
            perRoundData: [
              for (final result in results)
                {
                  'roundNumber': result.roundNumber,
                  'rawReactionTimeMs': result.rawReactionTimeMs,
                  'calibratedReactionTimeMs': result.calibratedReactionTimeMs,
                  'estimatedRenderDelayMs': result.estimatedRenderDelayMs,
                  'estimatedInputDelayMs': result.estimatedInputDelayMs,
                  'hardwareLatencyEstimateMs': result.hardwareLatencyEstimateMs,
                  'leaderboardEligible': result.leaderboardEligible,
                  'qualityScore': result.qualityScore,
                  'qualityFlags': result.qualityFlags,
                },
            ],
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _submittedScore = submitted;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitError = '提交失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submittingScore = false;
        });
      }
    }
  }
}

int _averageInt(Iterable<int> values) {
  final list = values.toList();
  return (list.reduce((left, right) => left + right) / list.length).round();
}

class _ReactionArenaShell extends StatelessWidget {
  const _ReactionArenaShell({
    required this.state,
    required this.onPointerDown,
    this.immersive = false,
  });

  final ReactionTestState state;
  final ValueChanged<InputEventTiming> onPointerDown;
  final bool immersive;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _arenaColor(context, state.phase);

    final arena = Listener(
      key: const Key('reaction-arena'),
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        final handledAtMs = const BrowserPerformanceTimer().now();
        onPointerDown(
          InputEventTiming(
            eventTimestampMs: event.timeStamp.inMicroseconds / 1000,
            handledAtMs: handledAtMs,
          ),
        );
      },
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ReactionArenaPainter(color: backgroundColor),
          child: SizedBox(
            height: immersive ? null : AppSpacing.x10 * 10,
            width: double.infinity,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x6),
                child: _ArenaContent(state: state),
              ),
            ),
          ),
        ),
      ),
    );

    if (immersive) {
      return arena;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: arena,
    );
  }

  Color _arenaColor(BuildContext context, ReactionTestPhase phase) {
    final colors = Theme.of(context).colorScheme;
    return switch (phase) {
      ReactionTestPhase.signal => AppColors.testSignalBg,
      ReactionTestPhase.falseStart => AppColors.testFalseStartBg,
      ReactionTestPhase.timeout => AppColors.testFalseStartBg,
      ReactionTestPhase.result => colors.surfaceContainerHighest,
      ReactionTestPhase.completed => colors.surfaceContainerHighest,
      ReactionTestPhase.idle ||
      ReactionTestPhase.waiting ||
      ReactionTestPhase.clicked => AppColors.testWaitBg,
    };
  }
}

class _ReactionArenaPainter extends CustomPainter {
  const _ReactionArenaPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _ReactionArenaPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ArenaContent extends StatelessWidget {
  const _ArenaContent({required this.state});

  final ReactionTestState state;

  @override
  Widget build(BuildContext context) {
    final onTestColor = _usesTestBackground(state.phase)
        ? AppColors.testOnColor
        : Theme.of(context).colorScheme.onSurface;
    final currentResult = state.currentResult;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _titleForPhase(state.phase),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: onTestColor,
            fontWeight: AppTypography.fontWeightBold,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        if (currentResult == null)
          Text(
            _subtitleForPhase(state),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: onTestColor),
          )
        else
          Text(
            '${currentResult.calibratedReactionTimeMs} ms',
            style: AppTypography.mono(
              fontSize: AppTypography.text5xl,
              lineHeight: AppTypography.line5xl,
              fontWeight: AppTypography.fontWeightBold,
              color: onTestColor,
            ),
          ),
      ],
    );
  }

  bool _usesTestBackground(ReactionTestPhase phase) {
    return phase == ReactionTestPhase.idle ||
        phase == ReactionTestPhase.waiting ||
        phase == ReactionTestPhase.signal ||
        phase == ReactionTestPhase.falseStart ||
        phase == ReactionTestPhase.timeout ||
        phase == ReactionTestPhase.clicked;
  }

  String _titleForPhase(ReactionTestPhase phase) {
    return switch (phase) {
      ReactionTestPhase.idle => '点击任意区域开始',
      ReactionTestPhase.waiting => '等待信号...',
      ReactionTestPhase.signal => '点击！',
      ReactionTestPhase.clicked => '记录中',
      ReactionTestPhase.falseStart => '抢跑！',
      ReactionTestPhase.timeout => '超时！',
      ReactionTestPhase.result => '本回合结果',
      ReactionTestPhase.completed => '总结报告',
    };
  }

  String _subtitleForPhase(ReactionTestState state) {
    return switch (state.phase) {
      ReactionTestPhase.idle => '${state.selectedRoundCount} 回合组',
      ReactionTestPhase.waiting => '第 ${state.currentRoundNumber} 回合',
      ReactionTestPhase.signal => '第 ${state.currentRoundNumber} 回合',
      ReactionTestPhase.clicked => '正在计算校准反应时间',
      ReactionTestPhase.falseStart => '请等待绿色信号后再点击',
      ReactionTestPhase.timeout => '信号已出现 2 秒',
      ReactionTestPhase.result => '点击任意区域继续',
      ReactionTestPhase.completed => '${state.completedRoundCount} 回合已完成',
    };
  }
}

class _RoundPanel extends StatelessWidget {
  const _RoundPanel({
    required this.state,
    required this.onSelectRoundCount,
    required this.authenticated,
    required this.submittingScore,
    required this.onPrimaryAction,
    required this.onSignalDelayRangeChanged,
    required this.onSubmitScore,
    this.submittedScore,
    this.submitError,
  });

  final ReactionTestState state;
  final ValueChanged<int> onSelectRoundCount;
  final bool authenticated;
  final bool submittingScore;
  final VoidCallback onPrimaryAction;
  final void Function(int minSeconds, int maxSeconds) onSignalDelayRangeChanged;
  final VoidCallback onSubmitScore;
  final SubmittedScore? submittedScore;
  final String? submitError;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('回合组', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.x4),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 5, label: Text('5')),
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 15, label: Text('15')),
              ],
              selected: {state.selectedRoundCount},
              onSelectionChanged: state.canConfigure
                  ? (values) => onSelectRoundCount(values.single)
                  : null,
            ),
            const SizedBox(height: AppSpacing.x4),
            _DelaySliderRow(
              label: '最短出现时间',
              value: state.signalMinDelaySeconds,
              min: ReactionTestController.minSignalDelaySeconds,
              max:
                  state.signalMaxDelaySeconds -
                  ReactionTestController.minSignalDelaySpanSeconds,
              enabled: state.canConfigure,
              onChanged: (value) =>
                  onSignalDelayRangeChanged(value, state.signalMaxDelaySeconds),
            ),
            _DelaySliderRow(
              label: '最长出现时间',
              value: state.signalMaxDelaySeconds,
              min:
                  state.signalMinDelaySeconds +
                  ReactionTestController.minSignalDelaySpanSeconds,
              max: ReactionTestController.maxSignalDelaySeconds,
              enabled: state.canConfigure,
              onChanged: (value) =>
                  onSignalDelayRangeChanged(state.signalMinDelaySeconds, value),
            ),
            const SizedBox(height: AppSpacing.x6),
            FilledButton.icon(
              onPressed: onPrimaryAction,
              icon: Icon(_primaryActionIcon(state.phase)),
              label: Text(_primaryActionLabel(state.phase)),
            ),
            const SizedBox(height: AppSpacing.x6),
            const Divider(),
            _MetricRow(
              label: '原始反应时间',
              value: _formatMs(state.currentResult?.rawReactionTimeMs),
            ),
            _MetricRow(
              label: '估计渲染延迟',
              value: _formatMs(state.currentResult?.estimatedRenderDelayMs),
            ),
            _MetricRow(
              label: '估计输入延迟',
              value: _formatMs(state.currentResult?.estimatedInputDelayMs),
            ),
            _MetricRow(
              label: '校准反应时间',
              value: _formatMs(state.currentResult?.calibratedReactionTimeMs),
              emphasized: true,
            ),
            _MetricRow(
              label: '入榜资格',
              value: _formatEligibility(state.currentResult),
            ),
            _MetricRow(
              label: '质量分',
              value: state.currentResult == null
                  ? '--'
                  : '${state.currentResult!.qualityScore}',
            ),
            _MetricRow(
              label: '质量标记',
              value: _formatQualityFlags(state.currentResult),
            ),
            _MetricRow(
              label: '延迟补偿值',
              value: '${state.calibrationOffsetMs.toStringAsFixed(1)} ms',
            ),
            if (state.summary != null) ...[
              const SizedBox(height: AppSpacing.x6),
              _SummaryBlock(state: state),
            ],
            ScoreSubmitPanel(
              completed: state.phase == ReactionTestPhase.completed,
              authenticated: authenticated,
              submitting: submittingScore,
              submittedScore: submittedScore,
              errorMessage: submitError,
              onSubmit: onSubmitScore,
              onLogin: () => context.go(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }

  IconData _primaryActionIcon(ReactionTestPhase phase) {
    return switch (phase) {
      ReactionTestPhase.falseStart ||
      ReactionTestPhase.timeout => Icons.refresh_outlined,
      ReactionTestPhase.result => Icons.arrow_forward_outlined,
      ReactionTestPhase.completed => Icons.replay_outlined,
      _ => Icons.play_arrow_outlined,
    };
  }

  String _primaryActionLabel(ReactionTestPhase phase) {
    return switch (phase) {
      ReactionTestPhase.idle => '开始',
      ReactionTestPhase.waiting => '等待中',
      ReactionTestPhase.signal => '点击测试区域',
      ReactionTestPhase.falseStart => '重试本回合',
      ReactionTestPhase.timeout => '重试本回合',
      ReactionTestPhase.result => '继续',
      ReactionTestPhase.completed => '重新开始',
      ReactionTestPhase.clicked => '记录中',
    };
  }

  String _formatMs(int? value) {
    if (value == null) {
      return '-- ms';
    }
    return '$value ms';
  }

  String _formatEligibility(ReactionRoundResult? result) {
    if (result == null) {
      return '--';
    }
    return result.leaderboardEligible ? '可入榜' : '仅练习';
  }

  String _formatQualityFlags(ReactionRoundResult? result) {
    if (result == null) {
      return '--';
    }
    if (result.qualityFlags.isEmpty) {
      return '无';
    }
    return result.qualityFlags.join(', ');
  }
}

class _DelaySliderRow extends StatelessWidget {
  const _DelaySliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final effectiveMin = min
        .clamp(
          ReactionTestController.minSignalDelaySeconds,
          ReactionTestController.maxSignalDelaySeconds,
        )
        .toInt();
    final effectiveMax = max
        .clamp(effectiveMin, ReactionTestController.maxSignalDelaySeconds)
        .toInt();
    final effectiveValue = value.clamp(effectiveMin, effectiveMax).toInt();
    final divisions = effectiveMax - effectiveMin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            _EditableDelayValue(
              label: label,
              value: effectiveValue,
              min: effectiveMin,
              max: effectiveMax,
              enabled: enabled,
              onChanged: onChanged,
            ),
          ],
        ),
        Slider(
          value: effectiveValue.toDouble(),
          min: effectiveMin.toDouble(),
          max: effectiveMax.toDouble(),
          divisions: divisions > 0 ? divisions : null,
          label: '$effectiveValue 秒',
          onChanged: enabled ? (value) => onChanged(value.round()) : null,
        ),
      ],
    );
  }
}

class _EditableDelayValue extends StatelessWidget {
  const _EditableDelayValue({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final bool enabled;
  final ValueChanged<int> onChanged;

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
          '$value 秒',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            decoration: enabled ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }

  Future<void> _showPreciseInput(BuildContext context) async {
    final controller = TextEditingController(text: '$value');
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
    final submitted = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(label),
          content: TextField(
            controller: controller,
            autofocus: true,
            selectAllOnFocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '秒',
              helperText: '$min - $max',
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

  int? _parseValue(String text) {
    final parsed = int.tryParse(text.trim());
    if (parsed == null) {
      return null;
    }
    return parsed.clamp(min, max).toInt();
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
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
    final color = emphasized
        ? Theme.of(context).colorScheme.primary
        : extension.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: AppTypography.mono(
              fontSize: emphasized
                  ? AppTypography.textBase
                  : AppTypography.textSm,
              lineHeight: emphasized
                  ? AppTypography.lineBase
                  : AppTypography.lineSm,
              fontWeight: emphasized
                  ? AppTypography.fontWeightBold
                  : AppTypography.fontWeightMedium,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.state});

  final ReactionTestState state;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    if (summary == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('总结报告', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x3),
        _MetricRow(
          label: '平均反应时间',
          value: '${summary.averageReactionTimeMs.toStringAsFixed(1)} ms',
        ),
        _MetricRow(label: '最优成绩', value: '${summary.bestReactionTimeMs} ms'),
        _MetricRow(label: '最差成绩', value: '${summary.worstReactionTimeMs} ms'),
        _MetricRow(
          label: '标准差',
          value: '${summary.standardDeviationMs.toStringAsFixed(1)} ms',
        ),
        if (summary.trimmedMeanMs != null)
          _MetricRow(
            label: '去极值平均',
            value: '${summary.trimmedMeanMs!.toStringAsFixed(1)} ms',
          ),
        const SizedBox(height: AppSpacing.x4),
        ReactionTrendChart(results: state.results),
      ],
    );
  }
}
