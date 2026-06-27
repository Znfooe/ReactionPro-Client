import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';
import '../../features/auth/providers/auth_provider.dart';

class TutorialLauncher extends StatelessWidget {
  const TutorialLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: () => showOnboardingTutorial(context),
      tooltip: '新手使用教程',
      child: const Icon(Icons.school_outlined),
    );
  }
}

Future<void> showOnboardingTutorial(
  BuildContext context, {
  int initialStep = 0,
}) {
  final router = GoRouter.of(context);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: AppSpacing.x10 * 18),
    builder: (context) {
      return _OnboardingTutorialSheet(
        initialStep: initialStep,
        onNavigate: (route) {
          Navigator.of(context).pop();
          router.go(route);
        },
      );
    },
  );
}

class _OnboardingTutorialSheet extends ConsumerStatefulWidget {
  const _OnboardingTutorialSheet({
    required this.initialStep,
    required this.onNavigate,
  });

  final int initialStep;
  final ValueChanged<String> onNavigate;

  @override
  ConsumerState<_OnboardingTutorialSheet> createState() =>
      _OnboardingTutorialSheetState();
}

class _OnboardingTutorialSheetState
    extends ConsumerState<_OnboardingTutorialSheet> {
  late final PageController _pageController;
  late int _step;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(0, _steps.length - 1);
    _pageController = PageController(initialPage: _step);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authenticated = ref.watch(authProvider).isAuthenticated;
    final extension = AppThemeExtension.of(context);

    return SizedBox(
      height: MediaQuery.sizeOf(
        context,
      ).height.clamp(AppSpacing.x10 * 12, AppSpacing.x10 * 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x6,
          AppSpacing.x5,
          AppSpacing.x6,
          AppSpacing.x6,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ReactionPro 新手教程',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '关闭',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            Row(
              children: [
                for (var index = 0; index < _steps.length; index++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: AppSpacing.x1,
                      color: index <= _step
                          ? Theme.of(context).colorScheme.primary
                          : extension.borderMuted,
                    ),
                  ),
                  if (index != _steps.length - 1)
                    const SizedBox(width: AppSpacing.x1),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.x6),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (value) => setState(() => _step = value),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return SingleChildScrollView(
                    child: _TutorialStepView(
                      step: step,
                      authenticated: authenticated,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.x4),
            Row(
              children: [
                if (_step > 0)
                  IconButton.outlined(
                    onPressed: _previous,
                    tooltip: '上一步',
                    icon: const Icon(Icons.arrow_back),
                  )
                else
                  const SizedBox.square(dimension: AppSpacing.x10),
                const Spacer(),
                Text(
                  '${_step + 1} / ${_steps.length}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const Spacer(),
                if (_step < _steps.length - 1)
                  IconButton.filled(
                    onPressed: _next,
                    tooltip: '下一步',
                    icon: const Icon(Icons.arrow_forward),
                  )
                else if (authenticated)
                  FilledButton.icon(
                    onPressed: () => widget.onNavigate(AppRoutes.reactionTest),
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: const Text('开始测试'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => widget.onNavigate(AppRoutes.login),
                    icon: const Icon(Icons.login_outlined),
                    label: const Text('去登录'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _previous() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}

class _TutorialStepView extends StatelessWidget {
  const _TutorialStepView({required this.step, required this.authenticated});

  final _TutorialStep step;
  final bool authenticated;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);
    final isLoginStep = step.kind == _TutorialStepKind.login;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: extension.accentMuted,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Icon(
              isLoginStep && authenticated
                  ? Icons.verified_user_outlined
                  : step.icon,
              size: AppSpacing.x8,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x5),
        Text(
          isLoginStep
              ? authenticated
                    ? '你已经登录'
                    : '要登录后再提交吗？'
              : step.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.x3),
        Text(
          isLoginStep
              ? authenticated
                    ? '当前成绩可以提交到账号，并参与符合条件的排行榜。'
                    : '不登录也能完成测试并查看本次数据；登录后才能提交成绩、参与排行榜，并把记录保存在账号下。'
              : step.description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.x6),
        for (final item in step.items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: AppSpacing.x5,
                  color: extension.colorSuccessText,
                ),
                const SizedBox(width: AppSpacing.x3),
                Expanded(
                  child: Text(
                    item,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

enum _TutorialStepKind { standard, login }

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.items,
    this.kind = _TutorialStepKind.standard,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> items;
  final _TutorialStepKind kind;
}

const _steps = [
  _TutorialStep(
    icon: Icons.route_outlined,
    title: '先选择测试方式',
    description: '反应力测试衡量看到信号后的点击速度；击杀时间测试衡量瞄准、命中与空枪表现。',
    items: ['反应力测试支持 5、10、15 回合组。', '击杀时间测试支持 2D/3D、单目标/多目标与静态/移动目标。'],
  ),
  _TutorialStep(
    icon: Icons.tune_outlined,
    title: '设置参数并观察预览',
    description: '测试页的设置中心会实时同步到右侧预览；右上角齿轮可以调整开屏动画配色。',
    items: ['先设置回合数、出现时间、目标大小和目标行为。', '再调整准星、背景、网格和输入灵敏度。', '确认预览符合预期后点击“开始”。'],
  ),
  _TutorialStep(
    icon: Icons.analytics_outlined,
    title: '完成后查看完整数据',
    description: '测试结束后，数据会显示在测试区域之外，并保留逐回合明细。',
    items: [
      '反应力数据包含原始时间、校准反应时间、延迟估计和质量标记。',
      '击杀数据包含平均/最佳/最差击杀时间、命中率、空枪率和逐回合记录。',
      '质量分与质量标记决定成绩能否进入严肃排行榜。',
    ],
  ),
  _TutorialStep(
    icon: Icons.cloud_upload_outlined,
    title: '把成绩提交到排行榜',
    description: '完成整组测试后，在结果面板底部找到“提交成绩”。',
    items: [
      '先登录账号，再完成一整组测试。',
      '点击“提交成绩”，服务端会保存本次配置、汇总和逐回合数据。',
      '通过质量门禁的成绩显示“已入榜”；未通过的会保存为练习成绩。',
      '前往排行榜并选择相同分类，即可查看对应排名。',
    ],
  ),
  _TutorialStep(
    icon: Icons.login_outlined,
    title: '登录与账号收益',
    description: '',
    kind: _TutorialStepKind.login,
    items: ['提交成绩并参加分项排行榜。', '将测试记录关联到个人账号。', '维护显示名与头像，形成稳定的排行榜身份。'],
  ),
];
