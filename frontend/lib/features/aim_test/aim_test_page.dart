import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
import '../reaction_test/core/timing_engine.dart';
import '../score/services/score_service.dart';
import '../score/widgets/score_submit_panel.dart';
import 'core/aim_geometry.dart';
import 'core/fullscreen_controller.dart';
import 'core/pointer_lock_controller.dart';
import 'core/aim_input_policy.dart';
import 'core/sensitivity.dart';
import 'core/target_manager.dart';
import 'render/scene_renderer.dart';
import 'widgets/crosshair.dart';
import 'widgets/crosshair_editor.dart';

class AimTestPage extends ConsumerStatefulWidget {
  const AimTestPage({super.key});

  @override
  ConsumerState<AimTestPage> createState() => _AimTestPageState();
}

class _AimTestPageState extends ConsumerState<AimTestPage>
    with SingleTickerProviderStateMixin {
  final _timer = const BrowserPerformanceTimer();
  final _pointerLock = PointerLockController();
  final _fullscreenController = FullscreenController();
  final _frameQuality = FrameQualityMonitor();
  late final AnimationController _frameTicker;
  AimTargetManager _manager = AimTargetManager(config: AimTestConfig.count());
  ViewAngles _camera = ViewAngles.zero;
  AimRendererMode _rendererMode = AimRendererMode.canvas;
  CrosshairStyle _crosshairStyle = const CrosshairStyle();
  double _crosshairSpreadPx = 0;
  Offset _touchAimOffset = Offset.zero;
  AimEvaluationMode _evaluationMode = AimEvaluationMode.count;
  AimTargetMode _targetMode = AimTargetMode.single;
  AimTargetBehavior _targetBehavior = AimTargetBehavior.static;
  AimMovementPattern _movementPattern = AimMovementPattern.bounce;
  AimTargetSizePreset _targetSize = AimTargetSizePreset.medium;
  double _targetRadiusPx = AimTestConfig.mediumRadiusPx;
  Color _targetColor = AppColors.testTargetColor;
  bool _targetOutline = true;
  Color _targetOutlineColor = Colors.white;
  Color? _sceneBackgroundColor;
  Color? _gridColor;
  double _gridOpacity = 0.22;
  double _gridStrokeWidth = 1;
  double _gridSpacingPx = AppSpacing.x8;
  int _gridLineCount = 8;
  double _sensitivity = 2;
  double _mYaw = 0.022;
  double _mPitch = 0.022;
  double _movementSpeedMetersPerSecond =
      AimTestConfig.mediumMovementSpeedMetersPerSecond;
  int _dpi = 800;
  int _targetCount = 10;
  int _durationSeconds = 20;
  int _activeTargetCount = 1;
  double _sceneNowMs = 0;
  bool _locked = false;
  bool _fullscreen = false;
  bool _fullscreenEnteredDuringSession = false;
  bool _pointerLockEnteredDuringSession = false;
  bool _immersive = false;
  bool _simplifiedInput = false;
  AimShotResult? _lastShot;
  bool _submittingScore = false;
  SubmittedScore? _submittedScore;
  String? _submitError;
  final List<_AimHistoryEntry> _historyEntries = [];
  bool _resultDialogOpen = false;

  Cs2Sensitivity get _cs2Sensitivity {
    return Cs2Sensitivity.normalized(
      sensitivity: _sensitivity,
      mYaw: _mYaw,
      mPitch: _mPitch,
      dpi: _dpi,
    );
  }

  bool get _running => _manager.state.phase == AimSessionPhase.running;

  bool get _completed => _manager.state.phase == AimSessionPhase.completed;

  @override
  void initState() {
    super.initState();
    _frameTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_handleFrameTick);
    _fullscreenController.startListening(
      onChange: (fullscreen) {
        if (mounted) {
          if (fullscreen) {
            _fullscreenEnteredDuringSession = true;
          }
          if (!fullscreen &&
              _immersive &&
              _running &&
              _fullscreenEnteredDuringSession) {
            _resetSession();
            return;
          }
          setState(() {
            _fullscreen = fullscreen;
          });
          if (fullscreen && _immersive && !_simplifiedInput && !_locked) {
            _pointerLock.requestLock();
          }
        }
      },
    );
    _pointerLock.startListening(
      onMove: _handlePointerMove,
      onLockChanged: (locked) {
        if (mounted) {
          if (locked) {
            _pointerLockEnteredDuringSession = true;
          }
          if (!locked &&
              _immersive &&
              _running &&
              !_simplifiedInput &&
              _pointerLockEnteredDuringSession) {
            _resetSession();
            return;
          }
          setState(() {
            _locked = locked;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _frameTicker.dispose();
    _fullscreenController.dispose();
    _pointerLock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);
    final simplifiedInput = _isSimplifiedAimContext(context);
    final sceneBackgroundColor = _sceneBackgroundColor ?? extension.bgMuted;
    final sceneGridColor = _gridColor ?? extension.borderMuted;

    if (_immersive) {
      return Scaffold(
        body: _AimArena(
          manager: _manager,
          camera: _camera,
          nowMs: _sceneNowMs,
          running: _running,
          completed: _completed,
          lastShot: _lastShot,
          rendererMode: _rendererMode,
          crosshairStyle: _crosshairStyle,
          crosshairSpreadPx: _crosshairSpreadPx,
          touchAimOffset: _touchAimOffset,
          targetColor: _targetColor,
          targetOutlineColor: _targetOutlineColor,
          showTargetOutline: _targetOutline,
          sceneBackgroundColor: sceneBackgroundColor,
          gridColor: sceneGridColor,
          gridOpacity: _gridOpacity,
          gridStrokeWidth: _gridStrokeWidth,
          gridSpacingPx: _gridSpacingPx,
          gridLineCount: _gridLineCount,
          immersive: true,
          fullscreen: _fullscreen,
          pointerLocked: _locked,
          simplifiedInput: _simplifiedInput,
          onShot: _handleShot,
          onDragAim: _handleDragAim,
          onRequestPointerLock: _pointerLock.requestLock,
          onExit: _resetSession,
        ),
      );
    }

    return AppPageScaffold(
      activeRoute: AppRoutes.aimTest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('击杀时间测试', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.x4),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              StatusPill(
                label: _rendererMode == AimRendererMode.canvas
                    ? '2D 模式'
                    : '3D 模式',
                color: colors.primary,
              ),
              const StatusPill(label: '目标球', color: AppColors.testTargetColor),
              StatusPill(
                label: simplifiedInput ? '触控简化模式' : '桌面精确模式',
                color: simplifiedInput
                    ? extension.colorWarning
                    : extension.colorSuccess,
              ),
              StatusPill(
                label: _locked ? 'Pointer Lock 已锁定' : 'Pointer Lock 待锁定',
                color: _locked
                    ? extension.colorSuccess
                    : extension.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 960;
              final config = _AimConfigPanel(
                evaluationMode: _evaluationMode,
                targetMode: _targetMode,
                targetBehavior: _targetBehavior,
                movementPattern: _movementPattern,
                targetSize: _targetSize,
                targetRadiusPx: _targetRadiusPx,
                targetColor: _targetColor,
                targetOutline: _targetOutline,
                targetOutlineColor: _targetOutlineColor,
                sceneBackgroundColor: sceneBackgroundColor,
                gridColor: sceneGridColor,
                gridOpacity: _gridOpacity,
                gridStrokeWidth: _gridStrokeWidth,
                gridSpacingPx: _gridSpacingPx,
                gridLineCount: _gridLineCount,
                targetCount: _targetCount,
                durationSeconds: _durationSeconds,
                activeTargetCount: _activeTargetCount,
                sensitivity: _sensitivity,
                mYaw: _mYaw,
                mPitch: _mPitch,
                dpi: _dpi,
                movementSpeedMetersPerSecond: _movementSpeedMetersPerSecond,
                rendererMode: _rendererMode,
                crosshairStyle: _crosshairStyle,
                cmPer360: _cs2Sensitivity.cmPer360,
                config: _manager.config,
                running: _running,
                onEvaluationModeChanged: _setEvaluationMode,
                onTargetModeChanged: _setTargetMode,
                onTargetBehaviorChanged: _setTargetBehavior,
                onMovementPatternChanged: _setMovementPattern,
                onTargetSizeChanged: _setTargetSize,
                onTargetRadiusPxChanged: (value) {
                  _updateConfig(() {
                    _targetSize = AimTargetSizePreset.custom;
                    _targetRadiusPx = value;
                  });
                },
                onTargetColorChanged: (value) {
                  setState(() {
                    _targetColor = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onTargetOutlineChanged: (value) {
                  setState(() {
                    _targetOutline = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onTargetOutlineColorChanged: (value) {
                  setState(() {
                    _targetOutlineColor = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onSceneBackgroundColorChanged: (value) {
                  setState(() {
                    _sceneBackgroundColor = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onGridColorChanged: (value) {
                  setState(() {
                    _gridColor = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onGridOpacityChanged: (value) {
                  setState(() {
                    _gridOpacity = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onGridStrokeWidthChanged: (value) {
                  setState(() {
                    _gridStrokeWidth = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onGridSpacingPxChanged: (value) {
                  setState(() {
                    _gridSpacingPx = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onGridLineCountChanged: (value) {
                  setState(() {
                    _gridLineCount = value.round();
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onRendererModeChanged: (value) {
                  setState(() {
                    _rendererMode = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onCrosshairStyleChanged: (value) {
                  setState(() {
                    _crosshairStyle = value;
                  });
                },
                onTargetCountChanged: _setTargetCount,
                onDurationSecondsChanged: _setDurationSeconds,
                onActiveTargetCountChanged: _setActiveTargetCount,
                onSensitivityChanged: (value) {
                  setState(() {
                    _sensitivity = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onMYawChanged: (value) {
                  setState(() {
                    _mYaw = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onMPitchChanged: (value) {
                  setState(() {
                    _mPitch = value;
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onDpiChanged: (value) {
                  setState(() {
                    _dpi = value.round();
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onMovementSpeedChanged: (value) {
                  setState(() {
                    _movementSpeedMetersPerSecond = value;
                    _manager = _createManager();
                    _submittedScore = null;
                    _submitError = null;
                  });
                },
                onStart: () => _startSession(simplifiedInput: simplifiedInput),
                onReset: _resetSession,
              );
              final arena = _AimArena(
                manager: _manager,
                camera: _camera,
                nowMs: _sceneNowMs,
                running: _running,
                completed: _completed,
                lastShot: _lastShot,
                rendererMode: _rendererMode,
                crosshairStyle: _crosshairStyle,
                crosshairSpreadPx: _crosshairSpreadPx,
                touchAimOffset: _touchAimOffset,
                targetColor: _targetColor,
                targetOutlineColor: _targetOutlineColor,
                showTargetOutline: _targetOutline,
                sceneBackgroundColor: sceneBackgroundColor,
                gridColor: sceneGridColor,
                gridOpacity: _gridOpacity,
                gridStrokeWidth: _gridStrokeWidth,
                gridSpacingPx: _gridSpacingPx,
                gridLineCount: _gridLineCount,
                immersive: false,
                fullscreen: _fullscreen,
                pointerLocked: _locked,
                simplifiedInput: simplifiedInput,
                onShot: _handleShot,
                onDragAim: _handleDragAim,
                onRequestPointerLock: _pointerLock.requestLock,
                onExit: _resetSession,
              );

              if (wide) {
                final workbenchHeight =
                    (MediaQuery.sizeOf(context).height - AppSpacing.x10 * 3)
                        .clamp(640.0, 840.0);
                return SizedBox(
                  height: workbenchHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: AppSpacing.x10 * 9, child: config),
                      const SizedBox(width: AppSpacing.x6),
                      Expanded(child: SingleChildScrollView(child: arena)),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: AppSpacing.x10 * 18, child: config),
                  const SizedBox(height: AppSpacing.x8),
                  arena,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.x8),
          _AimHistoryPanel(
            entries: _historyEntries,
            onOpenDetails: _showAimResultDialog,
          ),
        ],
      ),
    );
  }

  void _setTargetCount(int value) {
    _updateConfig(() {
      _targetCount = value;
    });
  }

  void _setDurationSeconds(int value) {
    _updateConfig(() {
      _durationSeconds = value;
    });
  }

  void _setActiveTargetCount(int value) {
    _updateConfig(() {
      _activeTargetCount = value;
    });
  }

  void _setEvaluationMode(AimEvaluationMode value) {
    _updateConfig(() {
      _evaluationMode = value;
    });
  }

  void _setTargetMode(AimTargetMode value) {
    _updateConfig(() {
      _targetMode = value;
      if (value == AimTargetMode.single) {
        _activeTargetCount = 1;
      } else if (_activeTargetCount < 2) {
        _activeTargetCount = 2;
      }
    });
  }

  void _setTargetBehavior(AimTargetBehavior value) {
    _updateConfig(() {
      _targetBehavior = value;
    });
  }

  void _setMovementPattern(AimMovementPattern value) {
    _updateConfig(() {
      _movementPattern = value;
    });
  }

  void _setTargetSize(AimTargetSizePreset value) {
    _updateConfig(() {
      _targetSize = value;
      _targetRadiusPx = AimTestConfig.radiusPxForSize(
        value,
        customRadiusPx: _targetRadiusPx,
      );
    });
  }

  void _updateConfig(VoidCallback mutation) {
    if (_running) {
      return;
    }
    setState(() {
      mutation();
      _manager = _createManager();
      _lastShot = null;
      _submittedScore = null;
      _submitError = null;
      _camera = ViewAngles.zero;
    });
  }

  void _startSession({required bool simplifiedInput}) {
    final nowMs = _timer.now();
    final alreadyFullscreen = _fullscreenController.isFullscreen;
    final alreadyLocked = _pointerLock.isLocked;
    _frameQuality.reset(nowMs: nowMs);
    setState(() {
      _manager = _createManager()..start(nowMs: nowMs);
      _camera = ViewAngles.zero;
      _crosshairSpreadPx = 0;
      _touchAimOffset = Offset.zero;
      _lastShot = null;
      _submittedScore = null;
      _submitError = null;
      _sceneNowMs = nowMs;
      _immersive = true;
      _simplifiedInput = simplifiedInput;
      _fullscreen = alreadyFullscreen;
      _locked = alreadyLocked;
      _fullscreenEnteredDuringSession = alreadyFullscreen;
      _pointerLockEnteredDuringSession = alreadyLocked;
    });
    _frameTicker.repeat();
    _fullscreenController.requestFullscreen();
    if (!simplifiedInput && alreadyFullscreen && !alreadyLocked) {
      _pointerLock.requestLock();
    }
  }

  void _resetSession() {
    _frameTicker.stop();
    _pointerLock.exitLock();
    _fullscreenController.exitFullscreen();
    setState(() {
      _manager = _createManager();
      _camera = ViewAngles.zero;
      _crosshairSpreadPx = 0;
      _touchAimOffset = Offset.zero;
      _lastShot = null;
      _submittedScore = null;
      _submitError = null;
      _locked = false;
      _fullscreen = false;
      _fullscreenEnteredDuringSession = false;
      _pointerLockEnteredDuringSession = false;
      _immersive = false;
      _simplifiedInput = false;
    });
  }

  void _handlePointerMove(double movementX, double movementY) {
    if (!_running || !mounted) {
      return;
    }
    setState(() {
      _camera = _cs2Sensitivity.applyMouseDelta(
        _camera,
        movementX: movementX,
        movementY: movementY,
      );
      if (_crosshairStyle.dynamicSpread) {
        final movement = movementX.abs() + movementY.abs();
        _crosshairSpreadPx = (_crosshairSpreadPx + movement * 0.04).clamp(
          0,
          18,
        );
      }
    });
  }

  void _handleDragAim(Offset delta) {
    if (_simplifiedInput) {
      setState(() {
        _touchAimOffset += delta;
        if (_crosshairStyle.dynamicSpread) {
          final movement = delta.dx.abs() + delta.dy.abs();
          _crosshairSpreadPx = (_crosshairSpreadPx + movement * 0.08).clamp(
            0,
            18,
          );
        }
      });
      return;
    }
    _handlePointerMove(delta.dx, delta.dy);
  }

  void _handleShot(
    AimViewport viewport,
    InputEventTiming inputTiming,
    Offset? localPosition,
  ) {
    if (!_running) {
      return;
    }
    final usesLocalShotPosition = AimInputPolicy.usesLocalShotPosition(
      simplifiedInput: _simplifiedInput,
      pointerLocked: _locked,
    );
    final localAim = usesLocalShotPosition
        ? localPosition ??
              Offset(viewport.centerX, viewport.centerY) + _touchAimOffset
        : null;
    final shot = _manager.handleShot(
      nowMs: _timer.now(),
      camera: _camera,
      viewport: viewport,
      estimatedInputDelayMs: 8,
      inputTiming: inputTiming,
      frameQuality: _frameQuality.snapshot(),
      pointerLocked: !_simplifiedInput && _locked,
      aimX: localAim?.dx,
      aimY: localAim?.dy,
    );
    final completedEntry = _manager.state.phase == AimSessionPhase.completed
        ? _captureHistoryEntry()
        : null;
    if (completedEntry != null) {
      _pointerLock.exitLock();
      _fullscreenController.exitFullscreen();
      _frameTicker.stop();
    }
    setState(() {
      _lastShot = shot;
      if (_simplifiedInput && localPosition != null) {
        _touchAimOffset =
            localPosition - Offset(viewport.centerX, viewport.centerY);
      }
      if (completedEntry != null) {
        _storeHistoryEntry(completedEntry);
        _immersive = false;
        _fullscreen = false;
      }
    });
    if (completedEntry != null) {
      _showAimResultDialog(completedEntry, allowScoreSubmit: true);
    }
  }

  AimTargetManager _createManager() {
    final config = switch (_evaluationMode) {
      AimEvaluationMode.count => AimTestConfig.count(
        targetCount: _targetCount,
        targetMode: _targetMode,
        activeTargetCount: _activeTargetCount,
        targetBehavior: _targetBehavior,
        movementPattern: _movementPattern,
        movementSpeedMetersPerSecond: _movementSpeedMetersPerSecond,
        targetSize: _targetSize,
        customRadiusPx: _targetRadiusPx,
      ),
      AimEvaluationMode.timed => AimTestConfig.timed(
        durationSeconds: _durationSeconds,
        targetMode: _targetMode,
        activeTargetCount: _activeTargetCount,
        targetBehavior: _targetBehavior,
        movementPattern: _movementPattern,
        movementSpeedMetersPerSecond: _movementSpeedMetersPerSecond,
        targetSize: _targetSize,
        customRadiusPx: _targetRadiusPx,
      ),
    };
    return AimTargetManager(config: config);
  }

  void _handleFrameTick() {
    if (!_running || !mounted) {
      return;
    }
    final nowMs = _timer.now();
    _frameQuality.recordFrame(nowMs);
    _manager.markActiveTargetsPresented(nowMs);
    _manager.advance(nowMs: nowMs);
    final completedEntry = _manager.state.phase == AimSessionPhase.completed
        ? _captureHistoryEntry()
        : null;
    if (completedEntry != null) {
      _pointerLock.exitLock();
      _fullscreenController.exitFullscreen();
      _frameTicker.stop();
    }
    setState(() {
      if (_crosshairSpreadPx > 0) {
        _crosshairSpreadPx = (_crosshairSpreadPx * 0.82).clamp(0, 18);
        if (_crosshairSpreadPx < 0.2) {
          _crosshairSpreadPx = 0;
        }
      }
      _sceneNowMs = nowMs;
      if (completedEntry != null) {
        _storeHistoryEntry(completedEntry);
        _immersive = false;
        _fullscreen = false;
      }
    });
    if (completedEntry != null) {
      _showAimResultDialog(completedEntry, allowScoreSubmit: true);
    }
  }

  _AimHistoryEntry _captureHistoryEntry() {
    return _AimHistoryEntry(
      completedAt: DateTime.now(),
      summary: _manager.summary,
      rounds: List<AimRoundResult>.unmodifiable(_manager.state.results),
      config: _manager.config,
      rendererMode: _rendererMode,
      targetMode: _targetMode,
      targetBehavior: _targetBehavior,
      movementPattern: _movementPattern,
      targetSize: _targetSize,
      targetRadiusPx: _targetRadiusPx,
      sensitivity: _sensitivity,
      mYaw: _mYaw,
      mPitch: _mPitch,
      dpi: _dpi,
    );
  }

  void _storeHistoryEntry(_AimHistoryEntry entry) {
    _historyEntries.insert(0, entry);
    if (_historyEntries.length > 50) {
      _historyEntries.removeRange(50, _historyEntries.length);
    }
  }

  void _showAimResultDialog(
    _AimHistoryEntry entry, {
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
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final authState = ref.read(authProvider);
              return AlertDialog(
                title: const Text('测试结果'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.x10 * 14,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AimResultDetails(entry: entry),
                        if (allowScoreSubmit) ...[
                          const SizedBox(height: AppSpacing.x4),
                          ScoreSubmitPanel(
                            completed: true,
                            authenticated: authState.isAuthenticated,
                            submitting: _submittingScore,
                            submittedScore: _submittedScore,
                            errorMessage: _submitError,
                            onSubmit: () {
                              _submitAimScore().whenComplete(() {
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
      _resultDialogOpen = false;
    });
  }

  Future<void> _submitAimScore() async {
    final summary = _manager.summary;
    final averageKillTimeMs = summary.averageKillTimeMs;
    final extension = AppThemeExtension.of(context);
    final sceneBackgroundColor = _sceneBackgroundColor ?? extension.bgMuted;
    final sceneGridColor = _gridColor ?? extension.borderMuted;
    if (_submittingScore ||
        _manager.state.phase != AimSessionPhase.completed ||
        averageKillTimeMs == null) {
      return;
    }

    setState(() {
      _submittingScore = true;
      _submitError = null;
    });

    try {
      final submitted = await ref
          .read(scoreServiceProvider)
          .submitAimScore(
            aimMode: _targetMode.name,
            evalMode: _evaluationMode == AimEvaluationMode.count
                ? 'count'
                : 'time',
            targetBehavior: _targetBehavior.name,
            targetCount: _evaluationMode == AimEvaluationMode.count
                ? _manager.config.totalTargetCount
                : null,
            duration: _evaluationMode == AimEvaluationMode.timed
                ? _manager.config.durationSeconds
                : null,
            targetSize: _targetSize.name,
            targetSpeed: _targetSpeedKey(_movementSpeedMetersPerSecond),
            directionMode: _movementPattern.name,
            multiTargetCount: _targetMode == AimTargetMode.multi
                ? _activeTargetCount
                : null,
            avgKillTime: averageKillTimeMs,
            bestTime: summary.bestKillTimeMs,
            worstTime: summary.worstKillTimeMs,
            trimmedMean: summary.trimmedMeanMs,
            hitRate: summary.hitRate * 100,
            errorRate: summary.errorRate * 100,
            totalKills: summary.hits,
            totalShots: summary.totalShots,
            sensitivity: _sensitivity,
            mYaw: _mYaw,
            mPitch: _mPitch,
            dpi: _dpi,
            leaderboardEligible: summary.leaderboardEligible,
            qualityScore: summary.qualityScore,
            qualityFlags: summary.qualityFlags,
            precisionData: {
              'evaluationMode': _evaluationMode.name,
              'targetMode': _targetMode.name,
              'targetBehavior': _targetBehavior.name,
              'movementPattern': _movementPattern.name,
              'targetSize': _targetSize.name,
              'targetRadiusPx': _targetRadiusPx,
              'targetColor': _formatColor(_targetColor),
              'targetOutline': _targetOutline,
              'targetOutlineColor': _formatColor(_targetOutlineColor),
              'rendererMode': _rendererMode.name,
              'sceneBackgroundColor': _formatColor(sceneBackgroundColor),
              'gridColor': _formatColor(sceneGridColor),
              'gridOpacity': _gridOpacity,
              'gridStrokeWidth': _gridStrokeWidth,
              'gridSpacingPx': _gridSpacingPx,
              'gridLineCount': _gridLineCount,
              'activeTargetCount': _manager.config.activeTargetCount,
              'movementSpeedMetersPerSecond': _movementSpeedMetersPerSecond,
              'mYaw': _mYaw,
              'mPitch': _mPitch,
              'crosshair': {
                'length': _crosshairStyle.length,
                'thickness': _crosshairStyle.thickness,
                'gap': _crosshairStyle.gap,
                'dot': _crosshairStyle.dot,
                'dotSize': _crosshairStyle.dotSize,
                'outline': _crosshairStyle.outline,
                'outlineThickness': _crosshairStyle.outlineThickness,
                'tStyle': _crosshairStyle.tStyle,
                'dynamicSpread': _crosshairStyle.dynamicSpread,
              },
            },
            perRoundData: [
              for (final result in _manager.state.results)
                {
                  'targetId': result.targetId,
                  'rawKillTimeMs': result.rawKillTimeMs,
                  'calibratedKillTimeMs': result.calibratedKillTimeMs,
                  'estimatedRenderDelayMs': result.estimatedRenderDelayMs,
                  'estimatedInputDelayMs': result.estimatedInputDelayMs,
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

final class _AimHistoryEntry {
  const _AimHistoryEntry({
    required this.completedAt,
    required this.summary,
    required this.rounds,
    required this.config,
    required this.rendererMode,
    required this.targetMode,
    required this.targetBehavior,
    required this.movementPattern,
    required this.targetSize,
    required this.targetRadiusPx,
    required this.sensitivity,
    required this.mYaw,
    required this.mPitch,
    required this.dpi,
  });

  final DateTime completedAt;
  final AimSummary summary;
  final List<AimRoundResult> rounds;
  final AimTestConfig config;
  final AimRendererMode rendererMode;
  final AimTargetMode targetMode;
  final AimTargetBehavior targetBehavior;
  final AimMovementPattern movementPattern;
  final AimTargetSizePreset targetSize;
  final double targetRadiusPx;
  final double sensitivity;
  final double mYaw;
  final double mPitch;
  final int dpi;
}

class _AimConfigPanel extends StatelessWidget {
  const _AimConfigPanel({
    required this.evaluationMode,
    required this.targetMode,
    required this.targetBehavior,
    required this.movementPattern,
    required this.targetSize,
    required this.targetRadiusPx,
    required this.targetColor,
    required this.targetOutline,
    required this.targetOutlineColor,
    required this.sceneBackgroundColor,
    required this.gridColor,
    required this.gridOpacity,
    required this.gridStrokeWidth,
    required this.gridSpacingPx,
    required this.gridLineCount,
    required this.targetCount,
    required this.durationSeconds,
    required this.activeTargetCount,
    required this.sensitivity,
    required this.mYaw,
    required this.mPitch,
    required this.dpi,
    required this.movementSpeedMetersPerSecond,
    required this.rendererMode,
    required this.crosshairStyle,
    required this.cmPer360,
    required this.config,
    required this.running,
    required this.onEvaluationModeChanged,
    required this.onTargetModeChanged,
    required this.onTargetBehaviorChanged,
    required this.onMovementPatternChanged,
    required this.onTargetSizeChanged,
    required this.onTargetRadiusPxChanged,
    required this.onTargetColorChanged,
    required this.onTargetOutlineChanged,
    required this.onTargetOutlineColorChanged,
    required this.onSceneBackgroundColorChanged,
    required this.onGridColorChanged,
    required this.onGridOpacityChanged,
    required this.onGridStrokeWidthChanged,
    required this.onGridSpacingPxChanged,
    required this.onGridLineCountChanged,
    required this.onRendererModeChanged,
    required this.onCrosshairStyleChanged,
    required this.onTargetCountChanged,
    required this.onDurationSecondsChanged,
    required this.onActiveTargetCountChanged,
    required this.onSensitivityChanged,
    required this.onMYawChanged,
    required this.onMPitchChanged,
    required this.onDpiChanged,
    required this.onMovementSpeedChanged,
    required this.onStart,
    required this.onReset,
  });

  final AimEvaluationMode evaluationMode;
  final AimTargetMode targetMode;
  final AimTargetBehavior targetBehavior;
  final AimMovementPattern movementPattern;
  final AimTargetSizePreset targetSize;
  final double targetRadiusPx;
  final Color targetColor;
  final bool targetOutline;
  final Color targetOutlineColor;
  final Color sceneBackgroundColor;
  final Color gridColor;
  final double gridOpacity;
  final double gridStrokeWidth;
  final double gridSpacingPx;
  final int gridLineCount;
  final int targetCount;
  final int durationSeconds;
  final int activeTargetCount;
  final double sensitivity;
  final double mYaw;
  final double mPitch;
  final int dpi;
  final double movementSpeedMetersPerSecond;
  final AimRendererMode rendererMode;
  final CrosshairStyle crosshairStyle;
  final double cmPer360;
  final AimTestConfig config;
  final bool running;
  final ValueChanged<AimEvaluationMode> onEvaluationModeChanged;
  final ValueChanged<AimTargetMode> onTargetModeChanged;
  final ValueChanged<AimTargetBehavior> onTargetBehaviorChanged;
  final ValueChanged<AimMovementPattern> onMovementPatternChanged;
  final ValueChanged<AimTargetSizePreset> onTargetSizeChanged;
  final ValueChanged<double> onTargetRadiusPxChanged;
  final ValueChanged<Color> onTargetColorChanged;
  final ValueChanged<bool> onTargetOutlineChanged;
  final ValueChanged<Color> onTargetOutlineColorChanged;
  final ValueChanged<Color> onSceneBackgroundColorChanged;
  final ValueChanged<Color> onGridColorChanged;
  final ValueChanged<double> onGridOpacityChanged;
  final ValueChanged<double> onGridStrokeWidthChanged;
  final ValueChanged<double> onGridSpacingPxChanged;
  final ValueChanged<double> onGridLineCountChanged;
  final ValueChanged<AimRendererMode> onRendererModeChanged;
  final ValueChanged<CrosshairStyle> onCrosshairStyleChanged;
  final ValueChanged<int> onTargetCountChanged;
  final ValueChanged<int> onDurationSecondsChanged;
  final ValueChanged<int> onActiveTargetCountChanged;
  final ValueChanged<double> onSensitivityChanged;
  final ValueChanged<double> onMYawChanged;
  final ValueChanged<double> onMPitchChanged;
  final ValueChanged<double> onDpiChanged;
  final ValueChanged<double> onMovementSpeedChanged;
  final VoidCallback onStart;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: DefaultTabController(
        length: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x4,
                AppSpacing.x4,
                AppSpacing.x2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '设置中心',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Icon(
                    running ? Icons.lock_outline : Icons.tune_outlined,
                    color: AppThemeExtension.of(context).textTertiary,
                  ),
                ],
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.rule_outlined), text: '测试'),
                Tab(icon: Icon(Icons.adjust_outlined), text: '目标'),
                Tab(icon: Icon(Icons.gps_fixed_outlined), text: '准星'),
                Tab(icon: Icon(Icons.grid_4x4_outlined), text: '场景'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _ConfigTabView(children: _buildTestTab(context)),
                  _ConfigTabView(children: _buildTargetTab(context)),
                  _ConfigTabView(children: _buildCrosshairTab(context)),
                  _ConfigTabView(children: _buildSceneTab(context)),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: running ? null : onStart,
                      icon: const Icon(Icons.play_arrow_outlined),
                      label: const Text('开始'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  IconButton.outlined(
                    onPressed: onReset,
                    tooltip: '重置',
                    icon: const Icon(Icons.restart_alt_outlined),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTestTab(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return [
      _ConfigSection(
        title: '评估方式',
        children: [
          SegmentedButton<AimEvaluationMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: AimEvaluationMode.count, label: Text('数量')),
              ButtonSegment(value: AimEvaluationMode.timed, label: Text('时间')),
            ],
            selected: {evaluationMode},
            onSelectionChanged: running
                ? null
                : (selection) => onEvaluationModeChanged(selection.single),
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final value
                  in evaluationMode == AimEvaluationMode.count
                      ? const [5, 10, 15]
                      : const [10, 20, 30])
                ChoiceChip(
                  label: Text(
                    evaluationMode == AimEvaluationMode.count
                        ? '$value 个'
                        : '$value 秒',
                  ),
                  selected: evaluationMode == AimEvaluationMode.count
                      ? targetCount == value
                      : durationSeconds == value,
                  onSelected: running
                      ? null
                      : (_) {
                          if (evaluationMode == AimEvaluationMode.count) {
                            onTargetCountChanged(value);
                          } else {
                            onDurationSecondsChanged(value);
                          }
                        },
                ),
            ],
          ),
          _SliderRow(
            label: evaluationMode == AimEvaluationMode.count
                ? '自定义数量'
                : '自定义时长',
            valueLabel: evaluationMode == AimEvaluationMode.count
                ? '$targetCount'
                : '$durationSeconds 秒',
            value: evaluationMode == AimEvaluationMode.count
                ? targetCount.toDouble()
                : durationSeconds.toDouble(),
            min: 1,
            max: 120,
            divisions: 119,
            precision: 0,
            onChanged: running
                ? null
                : (value) {
                    if (evaluationMode == AimEvaluationMode.count) {
                      onTargetCountChanged(value.round());
                    } else {
                      onDurationSecondsChanged(value.round());
                    }
                  },
          ),
        ],
      ),
      _ConfigSection(
        title: '目标数量',
        children: [
          SegmentedButton<AimTargetMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: AimTargetMode.single, label: Text('单目标')),
              ButtonSegment(value: AimTargetMode.multi, label: Text('多目标')),
            ],
            selected: {targetMode},
            onSelectionChanged: running
                ? null
                : (selection) => onTargetModeChanged(selection.single),
          ),
          if (targetMode == AimTargetMode.multi) ...[
            const SizedBox(height: AppSpacing.x3),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                for (final count in const [2, 3, 5])
                  ChoiceChip(
                    label: Text('$count 个同时出现'),
                    selected: activeTargetCount == count,
                    onSelected: running
                        ? null
                        : (_) => onActiveTargetCountChanged(count),
                  ),
              ],
            ),
            _SliderRow(
              label: '自定义多目标数',
              valueLabel: '$activeTargetCount',
              value: activeTargetCount.toDouble(),
              min: 2,
              max: 120,
              divisions: 118,
              precision: 0,
              onChanged: running
                  ? null
                  : (value) => onActiveTargetCountChanged(value.round()),
            ),
          ],
        ],
      ),
      _ConfigSection(
        title: '渲染模式',
        children: [
          SegmentedButton<AimRendererMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: AimRendererMode.canvas,
                label: Text('2D'),
                icon: Icon(Icons.grid_view_outlined),
              ),
              ButtonSegment(
                value: AimRendererMode.flutterScene,
                label: Text('3D'),
                icon: Icon(Icons.view_in_ar_outlined),
              ),
            ],
            selected: {rendererMode},
            onSelectionChanged: running
                ? null
                : (selection) => onRendererModeChanged(selection.single),
          ),
          const SizedBox(height: AppSpacing.x3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: extension.accentMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x3),
              child: Text(
                rendererMode == AimRendererMode.canvas
                    ? '2D Canvas：兼容性更好，适合低性能设备。'
                    : '3D 场景：空间感更强，适合练习立体瞄准。',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildTargetTab(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return [
      _ConfigSection(
        title: '目标行为',
        children: [
          SegmentedButton<AimTargetBehavior>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: AimTargetBehavior.static, label: Text('静态')),
              ButtonSegment(value: AimTargetBehavior.moving, label: Text('移动')),
            ],
            selected: {targetBehavior},
            onSelectionChanged: running
                ? null
                : (selection) => onTargetBehaviorChanged(selection.single),
          ),
          if (targetBehavior == AimTargetBehavior.moving) ...[
            const SizedBox(height: AppSpacing.x3),
            SegmentedButton<AimMovementPattern>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: AimMovementPattern.bounce,
                  label: Text('反弹'),
                ),
                ButtonSegment(
                  value: AimMovementPattern.random,
                  label: Text('随机'),
                ),
              ],
              selected: {movementPattern},
              onSelectionChanged: running
                  ? null
                  : (selection) => onMovementPatternChanged(selection.single),
            ),
            const SizedBox(height: AppSpacing.x3),
            Wrap(
              spacing: AppSpacing.x2,
              runSpacing: AppSpacing.x2,
              children: [
                for (final speed in const [
                  AimTestConfig.slowMovementSpeedMetersPerSecond,
                  AimTestConfig.mediumMovementSpeedMetersPerSecond,
                  AimTestConfig.fastMovementSpeedMetersPerSecond,
                ])
                  ChoiceChip(
                    label: Text(_movementSpeedLabel(speed)),
                    selected:
                        (movementSpeedMetersPerSecond - speed).abs() < 0.01,
                    onSelected: running
                        ? null
                        : (_) => onMovementSpeedChanged(speed),
                  ),
              ],
            ),
            _SliderRow(
              label: '自定义速度',
              valueLabel:
                  '${movementSpeedMetersPerSecond.toStringAsFixed(1)} m/s',
              value: movementSpeedMetersPerSecond,
              min: 0.2,
              max: 5,
              divisions: 48,
              precision: 1,
              onChanged: running ? null : onMovementSpeedChanged,
            ),
          ],
        ],
      ),
      _ConfigSection(
        title: '目标尺寸',
        children: [
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final option in const [
                AimTargetSizePreset.small,
                AimTargetSizePreset.medium,
                AimTargetSizePreset.large,
              ])
                ChoiceChip(
                  label: Text(_targetSizeLabel(option)),
                  selected: targetSize == option,
                  onSelected: running
                      ? null
                      : (_) => onTargetSizeChanged(option),
                ),
            ],
          ),
          _SliderRow(
            label: '自定义目标半径',
            valueLabel: '${targetRadiusPx.round()} px',
            value: targetRadiusPx,
            min: 8,
            max: 80,
            divisions: 72,
            precision: 0,
            onChanged: running ? null : onTargetRadiusPxChanged,
          ),
        ],
      ),
      _ConfigSection(
        title: '目标外观',
        children: [
          _ColorPickerRow(
            label: '目标颜色',
            selected: targetColor,
            enabled: !running,
            colors: const [
              AppColors.testTargetColor,
              AppColors.blue500,
              AppColors.green500,
              AppColors.orange500,
              AppColors.gray50,
            ],
            onChanged: onTargetColorChanged,
          ),
          _SwitchRow(
            label: '目标轮廓',
            value: targetOutline,
            enabled: !running,
            onChanged: onTargetOutlineChanged,
          ),
          _ColorPickerRow(
            label: '目标轮廓颜色',
            selected: targetOutlineColor,
            enabled: !running && targetOutline,
            colors: const [
              Colors.white,
              Colors.black,
              AppColors.blue900,
              AppColors.red900,
              AppColors.gray500,
            ],
            onChanged: onTargetOutlineColorChanged,
          ),
          const SizedBox(height: AppSpacing.x3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: extension.accentMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x3),
              child: Text(
                '${_evaluationModeLabel(evaluationMode)} · '
                '${_targetModeLabel(targetMode)} ${config.activeTargetCount} · '
                '${_targetBehaviorLabel(targetBehavior)} · '
                '${_targetSizeLabel(targetSize)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildCrosshairTab(BuildContext context) {
    return [
      _ConfigSection(
        title: '准星编辑器',
        children: [
          CrosshairEditor(
            style: crosshairStyle,
            enabled: !running,
            onChanged: onCrosshairStyleChanged,
          ),
        ],
      ),
      _ConfigSection(
        title: 'CS2 灵敏度',
        children: [
          _SliderRow(
            label: '灵敏度',
            valueLabel: sensitivity.toStringAsFixed(2),
            value: sensitivity,
            min: Cs2Sensitivity.minSensitivity,
            max: Cs2Sensitivity.maxSensitivity,
            divisions: 9999,
            precision: 2,
            onChanged: running ? null : onSensitivityChanged,
          ),
          _SliderRow(
            label: 'm_yaw',
            valueLabel: mYaw.toStringAsFixed(3),
            value: mYaw,
            min: Cs2Sensitivity.minMouseCoefficient,
            max: Cs2Sensitivity.maxMouseCoefficient,
            divisions: 499,
            precision: 3,
            onChanged: running ? null : onMYawChanged,
          ),
          _SliderRow(
            label: 'm_pitch',
            valueLabel: mPitch.toStringAsFixed(3),
            value: mPitch,
            min: Cs2Sensitivity.minMouseCoefficient,
            max: Cs2Sensitivity.maxMouseCoefficient,
            divisions: 499,
            precision: 3,
            onChanged: running ? null : onMPitchChanged,
          ),
          _SliderRow(
            label: 'DPI',
            valueLabel: '$dpi',
            value: dpi.toDouble(),
            min: Cs2Sensitivity.minDpi.toDouble(),
            max: Cs2Sensitivity.maxDpi.toDouble(),
            divisions: 638,
            precision: 0,
            onChanged: running ? null : onDpiChanged,
          ),
          const SizedBox(height: AppSpacing.x3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppThemeExtension.of(context).accentMuted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x3),
              child: Text(
                'cm/360° ${cmPer360.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSceneTab(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return [
      _ConfigSection(
        title: '背景',
        children: [
          _ColorPickerRow(
            label: '背景颜色',
            selected: sceneBackgroundColor,
            enabled: !running,
            colors: [
              extension.bgMuted,
              Theme.of(context).colorScheme.surface,
              AppColors.testWaitBg,
              AppColors.gray950,
              AppColors.gray50,
            ],
            onChanged: onSceneBackgroundColorChanged,
          ),
        ],
      ),
      _ConfigSection(
        title: '网格',
        children: [
          _ColorPickerRow(
            label: '网格颜色',
            selected: gridColor,
            enabled: !running,
            colors: [
              extension.borderMuted,
              Theme.of(context).colorScheme.primary,
              AppColors.gray50,
              AppColors.blue300,
              AppColors.green400,
            ],
            onChanged: onGridColorChanged,
          ),
          _SliderRow(
            label: '网格透明度',
            valueLabel: gridOpacity.toStringAsFixed(2),
            value: gridOpacity,
            min: 0,
            max: 1,
            divisions: 100,
            precision: 2,
            onChanged: running ? null : onGridOpacityChanged,
          ),
          _SliderRow(
            label: '网格间距',
            valueLabel: '${gridSpacingPx.round()} px',
            value: gridSpacingPx,
            min: 8,
            max: 96,
            divisions: 88,
            precision: 0,
            onChanged: running ? null : onGridSpacingPxChanged,
          ),
          _SliderRow(
            label: '网格厚度',
            valueLabel: gridStrokeWidth.toStringAsFixed(1),
            value: gridStrokeWidth,
            min: 0.5,
            max: 4,
            divisions: 35,
            precision: 1,
            onChanged: running ? null : onGridStrokeWidthChanged,
          ),
          _SliderRow(
            label: '网格数量',
            valueLabel: '$gridLineCount',
            value: gridLineCount.toDouble(),
            min: 2,
            max: 32,
            divisions: 30,
            precision: 0,
            onChanged: running ? null : onGridLineCountChanged,
          ),
        ],
      ),
    ];
  }
}

class _ConfigTabView extends StatelessWidget {
  const _ConfigTabView({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x4),
      children: children,
    );
  }
}

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.x3),
          ...children,
        ],
      ),
    );
  }
}

String _evaluationModeLabel(AimEvaluationMode mode) {
  return switch (mode) {
    AimEvaluationMode.count => '数量评估',
    AimEvaluationMode.timed => '时间评估',
  };
}

bool _isSimplifiedAimContext(BuildContext _) {
  final platform = defaultTargetPlatform;
  return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
}

String _targetModeLabel(AimTargetMode mode) {
  return switch (mode) {
    AimTargetMode.single => '单目标',
    AimTargetMode.multi => '多目标',
  };
}

String _targetBehaviorLabel(AimTargetBehavior behavior) {
  return switch (behavior) {
    AimTargetBehavior.static => '静态',
    AimTargetBehavior.moving => '移动',
  };
}

String _movementPatternLabel(AimMovementPattern pattern) {
  return switch (pattern) {
    AimMovementPattern.bounce => '反弹',
    AimMovementPattern.random => '随机',
  };
}

String _rendererModeLabel(AimRendererMode mode) {
  return switch (mode) {
    AimRendererMode.canvas => '2D',
    AimRendererMode.flutterScene => '3D',
  };
}

String _targetSizeLabel(AimTargetSizePreset targetSize) {
  return switch (targetSize) {
    AimTargetSizePreset.small => '小',
    AimTargetSizePreset.medium => '中',
    AimTargetSizePreset.large => '大',
    AimTargetSizePreset.custom => '自定义',
  };
}

String _movementSpeedLabel(double speed) {
  return switch (_targetSpeedKey(speed)) {
    'slow' => '慢',
    'medium' => '中',
    'fast' => '快',
    _ => '自定义',
  };
}

String _targetSpeedKey(double speed) {
  if ((speed - AimTestConfig.slowMovementSpeedMetersPerSecond).abs() < 0.01) {
    return 'slow';
  }
  if ((speed - AimTestConfig.mediumMovementSpeedMetersPerSecond).abs() < 0.01) {
    return 'medium';
  }
  if ((speed - AimTestConfig.fastMovementSpeedMetersPerSecond).abs() < 0.01) {
    return 'fast';
  }
  return 'custom';
}

String _formatColor(Color color) {
  return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.precision = 0,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double>? onChanged;
  final int precision;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            _EditableValueLabel(
              label: label,
              valueLabel: valueLabel,
              value: value,
              min: min,
              max: max,
              precision: precision,
              onChanged: onChanged,
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _EditableValueLabel extends StatelessWidget {
  const _EditableValueLabel({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.precision,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int precision;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
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
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
      onChanged?.call(submitted);
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

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
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

class _ColorPickerRow extends StatelessWidget {
  const _ColorPickerRow({
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
                icon: const Icon(Icons.palette_outlined),
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
                _ColorSwatchButton(
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
                for (final color in _paletteColors(context, colors, selected))
                  _ColorSwatchButton(
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
              helperText: '例如 #00FF66 或 #FF00FF66',
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

List<Color> _paletteColors(
  BuildContext context,
  List<Color> preferred,
  Color selected,
) {
  final colors = <Color>[
    selected,
    ...preferred,
    Theme.of(context).colorScheme.primary,
    Theme.of(context).colorScheme.surface,
    AppThemeExtension.of(context).bgMuted,
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

class _ColorSwatchButton extends StatelessWidget {
  const _ColorSwatchButton({
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

class _AimArena extends StatelessWidget {
  const _AimArena({
    required this.manager,
    required this.camera,
    required this.nowMs,
    required this.running,
    required this.completed,
    required this.rendererMode,
    required this.crosshairStyle,
    required this.crosshairSpreadPx,
    required this.touchAimOffset,
    required this.targetColor,
    required this.targetOutlineColor,
    required this.showTargetOutline,
    required this.sceneBackgroundColor,
    required this.gridColor,
    required this.gridOpacity,
    required this.gridStrokeWidth,
    required this.gridSpacingPx,
    required this.gridLineCount,
    required this.immersive,
    required this.fullscreen,
    required this.pointerLocked,
    required this.simplifiedInput,
    required this.onShot,
    required this.onDragAim,
    required this.onRequestPointerLock,
    required this.onExit,
    this.lastShot,
  });

  final AimTargetManager manager;
  final ViewAngles camera;
  final double nowMs;
  final bool running;
  final bool completed;
  final AimRendererMode rendererMode;
  final CrosshairStyle crosshairStyle;
  final double crosshairSpreadPx;
  final Offset touchAimOffset;
  final Color targetColor;
  final Color targetOutlineColor;
  final bool showTargetOutline;
  final Color sceneBackgroundColor;
  final Color gridColor;
  final double gridOpacity;
  final double gridStrokeWidth;
  final double gridSpacingPx;
  final int gridLineCount;
  final bool immersive;
  final bool fullscreen;
  final bool pointerLocked;
  final bool simplifiedInput;
  final AimShotResult? lastShot;
  final void Function(
    AimViewport viewport,
    InputEventTiming inputTiming,
    Offset? localPosition,
  )
  onShot;
  final ValueChanged<Offset> onDragAim;
  final VoidCallback onRequestPointerLock;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final scene = LayoutBuilder(
      builder: (context, constraints) {
        final viewport = AimViewport(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
        );
        final usesMovableCrosshair = AimInputPolicy.usesMovableCrosshair(
          simplifiedInput: simplifiedInput,
          running: running,
          pointerLocked: pointerLocked,
        );
        final sceneContent = MouseRegion(
          cursor: running ? SystemMouseCursors.none : SystemMouseCursors.click,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AimSceneRenderer(
                manager: manager,
                camera: camera,
                nowMs: nowMs,
                backgroundColor: sceneBackgroundColor,
                gridColor: gridColor,
                gridOpacity: gridOpacity,
                gridStrokeWidth: gridStrokeWidth,
                gridSpacingPx: gridSpacingPx,
                gridLineCount: gridLineCount,
                targetColor: targetColor,
                targetOutlineColor: targetOutlineColor,
                showTargetOutline: showTargetOutline,
                mode: rendererMode,
              ),
              Crosshair(
                style: crosshairStyle,
                dynamicSpreadPx: crosshairSpreadPx,
                centerOffset: usesMovableCrosshair
                    ? touchAimOffset
                    : Offset.zero,
              ),
              _ArenaHud(
                config: manager.config,
                hits: manager.state.hits,
                misses: manager.state.misses,
                lastShot: lastShot,
                fullscreen: fullscreen,
                simplifiedInput: simplifiedInput,
              ),
              if (!running && !completed)
                _StartOverlay(simplifiedInput: simplifiedInput),
            ],
          ),
        );

        if (simplifiedInput) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) => onDragAim(details.delta),
            onTapUp: (details) {
              final handledAtMs = const BrowserPerformanceTimer().now();
              onShot(
                viewport,
                InputEventTiming(
                  eventTimestampMs: handledAtMs,
                  handledAtMs: handledAtMs,
                ),
                details.localPosition,
              );
            },
            child: sceneContent,
          );
        }

        return Listener(
          onPointerDown: (event) {
            if (running && !pointerLocked) {
              onRequestPointerLock();
            }
            final handledAtMs = const BrowserPerformanceTimer().now();
            onShot(
              viewport,
              InputEventTiming(
                eventTimestampMs: event.timeStamp.inMicroseconds / 1000,
                handledAtMs: handledAtMs,
              ),
              pointerLocked ? null : event.localPosition,
            );
          },
          child: sceneContent,
        );
      },
    );

    if (immersive) {
      return Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape) {
            onExit();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            scene,
            Positioned(
              right: AppSpacing.x4,
              top: AppSpacing.x4,
              child: IconButton.filledTonal(
                onPressed: onExit,
                tooltip: '退出',
                icon: const Icon(Icons.close_fullscreen_outlined),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: scene,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        _RoundTrend(results: manager.state.results),
      ],
    );
  }
}

class _ArenaHud extends StatelessWidget {
  const _ArenaHud({
    required this.config,
    required this.hits,
    required this.misses,
    required this.fullscreen,
    required this.simplifiedInput,
    this.lastShot,
  });

  final AimTestConfig config;
  final int hits;
  final int misses;
  final bool fullscreen;
  final bool simplifiedInput;
  final AimShotResult? lastShot;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.x4,
      top: AppSpacing.x4,
      right: AppSpacing.x4,
      child: Wrap(
        spacing: AppSpacing.x2,
        runSpacing: AppSpacing.x2,
        children: [
          _HudPill(
            label: config.evaluationMode == AimEvaluationMode.count
                ? '目标'
                : '击杀',
            value: config.evaluationMode == AimEvaluationMode.count
                ? '$hits / ${config.totalTargetCount}'
                : '$hits',
          ),
          if (config.evaluationMode == AimEvaluationMode.timed)
            _HudPill(label: '时长', value: '${config.durationSeconds}s'),
          _HudPill(label: '空枪', value: '$misses'),
          _HudPill(label: '输入', value: simplifiedInput ? '触控' : '鼠标'),
          _HudPill(label: '全屏', value: fullscreen ? '已开启' : '应用内'),
          if (lastShot != null)
            _HudPill(
              label: lastShot!.hit ? '击杀时间' : '射击',
              value: lastShot!.hit
                  ? '${lastShot!.calibratedKillTimeMs} ms'
                  : '空枪',
            ),
        ],
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.44),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x2,
        ),
        child: Text(
          '$label $value',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.testOnColor),
        ),
      ),
    );
  }
}

class _StartOverlay extends StatelessWidget {
  const _StartOverlay({required this.simplifiedInput});

  final bool simplifiedInput;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.28)),
      child: Center(
        child: Text(
          simplifiedInput ? '点击开始后进入触控测试' : '点击开始后进入全屏测试',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.testOnColor),
        ),
      ),
    );
  }
}

class _AimHistoryPanel extends StatelessWidget {
  const _AimHistoryPanel({required this.entries, required this.onOpenDetails});

  final List<_AimHistoryEntry> entries;
  final ValueChanged<_AimHistoryEntry> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '历史数据',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  '${entries.length} 次',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: extension.textSecondary,
                  ),
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
                    '完成一次击杀时间测试后，这里会显示完整测试数据。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: extension.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _AimHistoryTile(
                      index: i,
                      entry: entries[i],
                      onOpenDetails: onOpenDetails,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AimHistoryTile extends StatelessWidget {
  const _AimHistoryTile({
    required this.index,
    required this.entry,
    required this.onOpenDetails,
  });

  final int index;
  final _AimHistoryEntry entry;
  final ValueChanged<_AimHistoryEntry> onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final summary = entry.summary;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.x4),
      leading: CircleAvatar(child: Text('${index + 1}')),
      title: Text(
        '${_formatHistoryTime(entry.completedAt)} · ${_formatMs(summary.averageKillTimeMs)}',
      ),
      subtitle: Text(
        '命中 ${summary.hits} · 空枪 ${summary.misses} · 准确率 ${_formatPercent(summary.shotAccuracy)} · 质量分 ${summary.qualityScore}',
      ),
      children: [
        _AimResultDetails(entry: entry),
        const SizedBox(height: AppSpacing.x3),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () => onOpenDetails(entry),
            icon: const Icon(Icons.open_in_full_outlined),
            label: const Text('弹窗查看'),
          ),
        ),
      ],
    );
  }
}

class _AimResultDetails extends StatelessWidget {
  const _AimResultDetails({required this.entry});

  final _AimHistoryEntry entry;

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
              label: '平均击杀时间',
              value: _formatMs(summary.averageKillTimeMs),
            ),
            _SummaryMetric(
              label: '最优成绩',
              value: _formatMs(summary.bestKillTimeMs),
            ),
            _SummaryMetric(
              label: '最差成绩',
              value: _formatMs(summary.worstKillTimeMs),
            ),
            _SummaryMetric(
              label: '目标命中率',
              value: _formatPercent(summary.hitRate),
            ),
            _SummaryMetric(
              label: '射击准确率',
              value: _formatPercent(summary.shotAccuracy),
            ),
            _SummaryMetric(
              label: '空枪率',
              value: _formatPercent(summary.errorRate),
            ),
            _SummaryMetric(label: '空枪', value: '${summary.misses}'),
            if (summary.evaluationMode == AimEvaluationMode.count)
              _SummaryMetric(
                label: '完成回合',
                value: '${summary.hits} / ${summary.totalTargetCount}',
              ),
            if (summary.evaluationMode == AimEvaluationMode.timed) ...[
              _SummaryMetric(
                label: 'KPS',
                value: (summary.killsPerSecond ?? 0).toStringAsFixed(2),
              ),
              _SummaryMetric(
                label: 'KPM',
                value: (summary.killsPerMinute ?? 0).toStringAsFixed(1),
              ),
            ],
            _SummaryMetric(
              label: '入榜资格',
              value: summary.leaderboardEligible ? '可入榜' : '仅练习',
            ),
            _SummaryMetric(label: '质量分', value: '${summary.qualityScore}'),
          ],
        ),
        if (summary.qualityFlags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x4),
          _ResultSection(
            title: '质量标记',
            child: Text(
              summary.qualityFlags.join(', '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.x4),
        _ResultSection(
          title: '测试配置',
          child: Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              _DataChip(
                label: '评估模式',
                value: _evaluationModeLabel(summary.evaluationMode),
              ),
              _DataChip(
                label: '渲染模式',
                value: _rendererModeLabel(entry.rendererMode),
              ),
              _DataChip(
                label: '目标模式',
                value: _targetModeLabel(entry.targetMode),
              ),
              _DataChip(
                label: '目标行为',
                value: _targetBehaviorLabel(entry.targetBehavior),
              ),
              _DataChip(
                label: '移动轨迹',
                value: entry.targetBehavior == AimTargetBehavior.moving
                    ? _movementPatternLabel(entry.movementPattern)
                    : '无',
              ),
              _DataChip(
                label: '目标大小',
                value:
                    '${_targetSizeLabel(entry.targetSize)} / ${entry.targetRadiusPx.round()} px',
              ),
              _DataChip(
                label: '目标数量',
                value: summary.evaluationMode == AimEvaluationMode.count
                    ? '${summary.totalTargetCount}'
                    : '${summary.durationSeconds} 秒',
              ),
              _DataChip(
                label: '同屏目标',
                value: '${entry.config.activeTargetCount}',
              ),
              _DataChip(
                label: '目标速度',
                value:
                    '${_movementSpeedLabel(entry.config.movementSpeedMetersPerSecond)} / ${entry.config.movementSpeedMetersPerSecond.toStringAsFixed(1)} m/s',
              ),
              _DataChip(
                label: '灵敏度',
                value: entry.sensitivity.toStringAsFixed(2),
              ),
              _DataChip(label: 'm_yaw', value: entry.mYaw.toStringAsFixed(3)),
              _DataChip(
                label: 'm_pitch',
                value: entry.mPitch.toStringAsFixed(3),
              ),
              _DataChip(label: 'DPI', value: '${entry.dpi}'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        _ResultSection(
          title: '逐回合数据',
          child: _RoundDataTable(rounds: entry.rounds),
        ),
      ],
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

class _RoundDataTable extends StatelessWidget {
  const _RoundDataTable({required this.rounds});

  final List<AimRoundResult> rounds;

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return Text('没有命中回合数据。', style: Theme.of(context).textTheme.bodyMedium);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: AppSpacing.x5,
        columns: const [
          DataColumn(label: Text('回合')),
          DataColumn(label: Text('目标')),
          DataColumn(label: Text('原始')),
          DataColumn(label: Text('校准')),
          DataColumn(label: Text('渲染延迟')),
          DataColumn(label: Text('输入延迟')),
          DataColumn(label: Text('资格')),
          DataColumn(label: Text('质量分')),
          DataColumn(label: Text('标记')),
        ],
        rows: [
          for (var i = 0; i < rounds.length; i++)
            DataRow(
              cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(rounds[i].targetId)),
                DataCell(Text(_formatMs(rounds[i].rawKillTimeMs))),
                DataCell(Text(_formatMs(rounds[i].calibratedKillTimeMs))),
                DataCell(Text(_formatMs(rounds[i].estimatedRenderDelayMs))),
                DataCell(Text(_formatMs(rounds[i].estimatedInputDelayMs))),
                DataCell(Text(rounds[i].leaderboardEligible ? '可入榜' : '练习')),
                DataCell(Text('${rounds[i].qualityScore}')),
                DataCell(Text(rounds[i].qualityFlags.join(', '))),
              ],
            ),
        ],
      ),
    );
  }
}

String _formatMs(int? value) => value == null ? '-- ms' : '$value ms';

String _formatPercent(double value) => '${(value * 100).round()}%';

String _formatHistoryTime(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.month)}-${twoDigits(value.day)} '
      '${twoDigits(value.hour)}:${twoDigits(value.minute)}:${twoDigits(value.second)}';
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.x10 * 4,
      child: Column(
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
    );
  }
}

class _RoundTrend extends StatelessWidget {
  const _RoundTrend({required this.results});

  final List<AimRoundResult> results;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    return SizedBox(
      height: AppSpacing.x10 * 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: extension.borderMuted),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x3),
          child: CustomPaint(
            painter: _RoundTrendPainter(
              results: results,
              lineColor: Theme.of(context).colorScheme.primary,
              gridColor: extension.borderMuted,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

final class _RoundTrendPainter extends CustomPainter {
  const _RoundTrendPainter({
    required this.results,
    required this.lineColor,
    required this.gridColor,
  });

  final List<AimRoundResult> results;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.56)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (results.isEmpty) {
      return;
    }

    final values = results
        .map((result) => result.calibratedKillTimeMs)
        .toList();
    final minValue = values.reduce((a, b) => a < b ? a : b).toDouble();
    final maxValue = values.reduce((a, b) => a > b ? a : b).toDouble();
    final range = (maxValue - minValue).clamp(1, double.infinity);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1 ? 0.0 : size.width * i / (values.length - 1);
      final normalized = (values[i] - minValue) / range;
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RoundTrendPainter oldDelegate) {
    return oldDelegate.results != results ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
