import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_links.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../core/theme/app_typography.dart';

class AuthorShowcaseSection extends StatelessWidget {
  const AuthorShowcaseSection({super.key});

  static const _projects = <_AuthorProject>[
    _AuthorProject(
      index: '01',
      title: 'FabricYun',
      role: '独立全栈开发 · B2B SaaS',
      summary: '面向纺织行业的全链路管理系统，覆盖客户、产品、订单、财务对账与数据分析，并落地 AI 助手辅助业务查询。',
      stack:
          'React 18 / TypeScript / Vite / Spring Boot 3 / PostgreSQL / Redis',
      highlights: ['订单向导流程', 'Flyway 版本迁移', 'Docker Compose 部署'],
      url: 'https://fabricyun.top',
      ctaLabel: '打开项目站点',
    ),
    _AuthorProject(
      index: '02',
      title: '封面 AI',
      role: '桌面端 AI 生产工具',
      summary: '围绕 AI 对话、图片生成与批量封面制作构建的一体化桌面应用，重点解决多模型接入、流式响应与批量任务调度。',
      stack: 'Vue 3 / TypeScript / Electron / Pinia / IndexedDB / Playwright',
      highlights: ['SSE 流式对话', '并发批量生成', 'Web Worker 解码优化'],
    ),
    _AuthorProject(
      index: '03',
      title: 'PetCollar',
      role: 'IoT 宠物健康平台',
      summary:
          '从 ESP32 设备数据采集到 Web/Android 可视化的完整闭环，聚焦实时监测、电子围栏、健康评分与 AI 健康分析。',
      stack: 'Next.js 14 / Express / MQTT / Prisma / Capacitor / Docker',
      highlights: ['SSE + MQTT 实时链路', '多维健康评分', '跨端能力封装'],
    ),
  ];

  static const _blessings = <String>[
    '愿你今天的每一次点击，都更接近热爱。',
    '祝你稳定发挥，也别忘了好好休息。',
    '愿你写下的每一行代码，都长成想要的未来。',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionHeader(
          eyebrow: '关于作者',
          title: '把热爱做成作品，把作品做成长期主义。',
          description: '这里放的是作者信息、项目经历、联系入口和一点温柔的小心意。',
        ),
        SizedBox(height: AppSpacing.x8),
        _AboutAuthorHero(),
        SizedBox(height: AppSpacing.x10),
        _ProjectStorySection(projects: _projects),
        SizedBox(height: AppSpacing.x10),
        _ContactSection(),
        SizedBox(height: AppSpacing.x10),
        _SupportSection(blessings: _blessings),
      ],
    );
  }
}

class _AboutAuthorHero extends StatelessWidget {
  const _AboutAuthorHero();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Znfooe',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontFamily: 'CangErYuMoW01',
            fontFamilyFallback: AppTypography.fontFallback,
            fontSize: AppTypography.text5xl,
            height: AppTypography.line5xl / AppTypography.text5xl,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          'Maybe not today, maybe not tomorrow, maybe not next month, but one day',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'CangErYuMoW01',
            fontFamilyFallback: AppTypography.fontFallback,
            color: extension.textSecondary,
          ),
        ),
      ],
    );

    final face = const _AuthorMotionPanel();

    return _SectionCard(
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 3, child: copy),
                const SizedBox(width: AppSpacing.x8),
                Expanded(flex: 2, child: face),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.x8),
                face,
              ],
            ),
    );
  }
}

class _ProjectStorySection extends StatelessWidget {
  const _ProjectStorySection({required this.projects});

  final List<_AuthorProject> projects;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('项目经历', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.x2),
        Text(
          '按实战感和体系感排序，先看 FabricYun，再看桌面 AI 工具，最后是 IoT 宠物健康平台。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.x6),
        for (final project in projects) ...[
          _ProjectStoryCard(project: project),
          if (project != projects.last) const SizedBox(height: AppSpacing.x4),
        ],
      ],
    );
  }
}

class _ProjectStoryCard extends StatelessWidget {
  const _ProjectStoryCard({required this.project});

  final _AuthorProject project;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 760;

    final leading = Container(
      width: AppSpacing.x12 + AppSpacing.x4,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        color: extension.bgMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        project.index,
        style: AppTypography.mono(
          fontSize: AppTypography.text2xl,
          lineHeight: AppTypography.line2xl,
          fontWeight: AppTypography.fontWeightBold,
          color: colors.primary,
        ),
      ),
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(project.title, style: Theme.of(context).textTheme.titleLarge),
            _TinyPill(label: project.role),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        Text(
          project.summary,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          project.stack,
          style: AppTypography.mono(
            fontSize: AppTypography.textSm,
            lineHeight: AppTypography.lineSm,
            color: extension.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Wrap(
          spacing: AppSpacing.x2,
          runSpacing: AppSpacing.x2,
          children: [
            for (final highlight in project.highlights)
              _TinyPill(label: highlight, emphasized: true),
          ],
        ),
        if (project.url case final url?) ...[
          const SizedBox(height: AppSpacing.x4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _openUrl(context, url),
              icon: const Icon(Icons.open_in_new_outlined),
              label: Text(project.ctaLabel ?? '打开链接'),
            ),
          ),
        ],
      ],
    );

    return _SectionCard(
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(width: AppSpacing.x4),
                Expanded(child: details),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading,
                const SizedBox(height: AppSpacing.x4),
                details,
              ],
            ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    final contacts = <_AuthorContact>[
      _AuthorContact(
        label: '微信',
        value: 'acb3238',
        caption: '适合聊合作、想法和日常。',
        icon: SimpleIcons.wechat,
        brandColor: SimpleIconColors.wechat,
        actionLabel: '复制微信号',
        onTap: () => _copyValue(context, '微信号', 'acb3238'),
      ),
      _AuthorContact(
        label: 'QQ',
        value: '3274098996',
        caption: '有事也可以直接加 QQ。',
        icon: SimpleIcons.qq,
        brandColor: SimpleIconColors.qq,
        actionLabel: '复制 QQ 号',
        onTap: () => _copyValue(context, 'QQ 号', '3274098996'),
      ),
      _AuthorContact(
        label: 'GitHub',
        value: 'github.com/Znfooe',
        caption: '代码、实验和一些长期项目。',
        icon: SimpleIcons.github,
        brandColor: SimpleIconColors.github,
        actionLabel: '打开 GitHub',
        onTap: () => _openUrl(context, 'https://github.com/Znfooe'),
      ),
      _AuthorContact(
        label: '哔哩哔哩',
        value: 'UID 1385099245',
        caption: '记录一些作品、想法和过程。',
        icon: SimpleIcons.bilibili,
        brandColor: SimpleIconColors.bilibili,
        actionLabel: '打开主页',
        onTap: () => _openUrl(context, 'https://space.bilibili.com/1385099245'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('关注与联系', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'ReactionPro 前端代码已公开，微信和 QQ 支持一键复制，其他平台可以直接打开。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.x6),
        const _OpenSourceCard(),
        const SizedBox(height: AppSpacing.x4),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= AppSpacing.x10 * 18;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contacts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: twoColumns ? 2 : 1,
                crossAxisSpacing: AppSpacing.x4,
                mainAxisSpacing: AppSpacing.x4,
                childAspectRatio: twoColumns ? 2.2 : 1.65,
              ),
              itemBuilder: (context, index) =>
                  _ContactCard(contact: contacts[index]),
            );
          },
        ),
      ],
    );
  }
}

class _OpenSourceCard extends StatelessWidget {
  const _OpenSourceCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);
    final compact = MediaQuery.sizeOf(context).width < AppSpacing.x10 * 9;

    final identity = Row(
      children: [
        Container(
          width: AppSpacing.x12,
          height: AppSpacing.x12,
          decoration: BoxDecoration(
            color: extension.bgMuted,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(SimpleIcons.github, size: AppSpacing.x6),
        ),
        const SizedBox(width: AppSpacing.x4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ReactionPro 开源前端',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                'Znfooe/ReactionPro-Client · Flutter',
                style: AppTypography.mono(
                  fontSize: AppTypography.textSm,
                  lineHeight: AppTypography.lineSm,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                '公开客户端源码、构建说明和版本安装包，欢迎查看、交流与贡献。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: extension.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: AppSpacing.x2,
      runSpacing: AppSpacing.x2,
      children: [
        FilledButton.icon(
          onPressed: () => _openUrl(context, AppLinks.publicClientRepository),
          icon: const Icon(Icons.code_outlined),
          label: const Text('查看源码'),
        ),
        OutlinedButton.icon(
          onPressed: () => _openUrl(context, AppLinks.publicClientReleases),
          icon: const Icon(Icons.download_outlined),
          label: const Text('版本下载'),
        ),
      ],
    );

    return _SectionCard(
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppSpacing.x4),
                actions,
              ],
            )
          : Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: AppSpacing.x6),
                actions,
              ],
            ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection({required this.blessings});

  final List<String> blessings;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('请杯咖啡', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.x2),
        Text(
          '扫一扫即可联系或请杯咖啡。二维码保持紧凑，不抢走页面的呼吸感。',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.x6),
        wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Expanded(
                    child: _QrShowcaseCard(
                      title: '微信收款码',
                      subtitle: '扫一扫就能请我喝杯咖啡，感谢你愿意支持这个小站继续生长。',
                      accentColor: SimpleIconColors.wechat,
                      icon: SimpleIcons.wechat,
                      imagePath: 'assets/images/author/payment-code.jpg',
                      footer: '你的一点支持，会被认真收下。',
                    ),
                  ),
                  SizedBox(width: AppSpacing.x4),
                  Expanded(
                    child: _QrShowcaseCard(
                      title: 'QQ 加好友码',
                      subtitle: '如果更习惯扫码加好友，这里可以直接扫 QQ 联系我。',
                      accentColor: SimpleIconColors.qq,
                      icon: SimpleIcons.qq,
                      imagePath: 'assets/images/author/qq-friend-code-v2.jpg',
                      footer: '当前仍可直接复制 QQ 号：3274098996',
                    ),
                  ),
                ],
              )
            : const Column(
                children: [
                  _QrShowcaseCard(
                    title: '微信收款码',
                    subtitle: '扫一扫就能请我喝杯咖啡，感谢你愿意支持这个小站继续生长。',
                    accentColor: SimpleIconColors.wechat,
                    icon: SimpleIcons.wechat,
                    imagePath: 'assets/images/author/payment-code.jpg',
                    footer: '你的一点支持，会被认真收下。',
                  ),
                  SizedBox(height: AppSpacing.x4),
                  _QrShowcaseCard(
                    title: 'QQ 加好友码',
                    subtitle: '如果更习惯扫码加好友，这里可以直接扫 QQ 联系我。',
                    accentColor: SimpleIconColors.qq,
                    icon: SimpleIcons.qq,
                    imagePath: 'assets/images/author/qq-friend-code-v2.jpg',
                    footer: '当前仍可直接复制 QQ 号：3274098996',
                  ),
                ],
              ),
        const SizedBox(height: AppSpacing.x6),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.x6),
        _BlessingTicker(phrases: blessings),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final _AuthorContact contact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.x10,
                height: AppSpacing.x10,
                decoration: BoxDecoration(
                  color: extension.bgMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(contact.icon, color: contact.brandColor),
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      contact.value,
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: colors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(contact.caption, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: contact.onTap,
            icon: const Icon(Icons.arrow_outward_outlined),
            label: Text(contact.actionLabel),
          ),
        ],
      ),
    );
  }
}

class _QrShowcaseCard extends StatelessWidget {
  const _QrShowcaseCard({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.imagePath,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final String imagePath;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor),
              const SizedBox(width: AppSpacing.x2),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.x4),
          Align(
            alignment: Alignment.center,
            child: SizedBox.square(
              dimension: AppSpacing.x10 * 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: extension.bgMuted,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(footer, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _BlessingTicker extends StatefulWidget {
  const _BlessingTicker({required this.phrases});

  final List<String> phrases;

  @override
  State<_BlessingTicker> createState() => _BlessingTickerState();
}

class _BlessingTickerState extends State<_BlessingTicker> {
  static const _step = Duration(milliseconds: 90);
  static const _hold = Duration(milliseconds: 900);

  Timer? _timer;
  int _phraseIndex = 0;
  int _visibleCount = 0;
  bool _erasing = false;

  @override
  void initState() {
    super.initState();
    _scheduleTick(_step);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(
        widget.phrases.first,
        style: Theme.of(context).textTheme.titleMedium,
      );
    }

    final extension = AppThemeExtension.of(context);
    final current = widget.phrases[_phraseIndex];
    final visible = current.characters.take(_visibleCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('送你一句话', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.x3),
        Wrap(
          spacing: 0,
          runSpacing: 0,
          children: [
            for (var i = 0; i < visible.length; i++)
              AnimatedContainer(
                duration: AppDurations.fast,
                curve: AppCurves.easeOut,
                transform: Matrix4.translationValues(0, 0, 0),
                margin: EdgeInsets.only(
                  right: visible[i] == ' ' ? AppSpacing.x1 : 0,
                ),
                child: Text(
                  visible[i],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: i.isEven ? extension.accentText : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _scheduleTick(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _handleTick);
  }

  void _handleTick() {
    if (!mounted) {
      return;
    }

    final currentLength = widget.phrases[_phraseIndex].characters.length;
    setState(() {
      if (!_erasing && _visibleCount < currentLength) {
        _visibleCount += 1;
      } else if (!_erasing) {
        _erasing = true;
      } else if (_visibleCount > 0) {
        _visibleCount -= 1;
      } else {
        _erasing = false;
        _phraseIndex = (_phraseIndex + 1) % widget.phrases.length;
      }
    });

    if (!_erasing && _visibleCount == currentLength) {
      _scheduleTick(_hold);
      return;
    }
    if (_erasing && _visibleCount == 0) {
      _scheduleTick(const Duration(milliseconds: 260));
      return;
    }
    _scheduleTick(_step);
  }
}

class _AuthorMotionPanel extends StatefulWidget {
  const _AuthorMotionPanel();

  @override
  State<_AuthorMotionPanel> createState() => _AuthorMotionPanelState();
}

class _AuthorMotionPanelState extends State<_AuthorMotionPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool? _animationsDisabled;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.authorSignal,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animationsDisabled =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_animationsDisabled == animationsDisabled) {
      return;
    }
    _animationsDisabled = animationsDisabled;
    if (animationsDisabled) {
      _controller
        ..stop()
        ..value = 0.36;
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AspectRatio(
        aspectRatio: 1,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _AuthorMotionPainter(
              animation: _controller,
              backgroundColor: extension.accentMuted,
              primaryColor: colors.primary,
              secondaryColor: colors.tertiary,
              lineColor: extension.borderAccent,
              nodeColor: colors.surface,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final extension = AppThemeExtension.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: extension.accentText),
        ),
        const SizedBox(height: AppSpacing.x2),
        Text(title, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: AppSpacing.x3),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: extension.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x6),
        child: child,
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x3,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: emphasized ? extension.accentMuted : extension.bgMuted,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: emphasized ? extension.borderAccent : extension.borderMuted,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: emphasized ? colors.primary : extension.textSecondary,
        ),
      ),
    );
  }
}

class _AuthorProject {
  const _AuthorProject({
    required this.index,
    required this.title,
    required this.role,
    required this.summary,
    required this.stack,
    required this.highlights,
    this.url,
    this.ctaLabel,
  });

  final String index;
  final String title;
  final String role;
  final String summary;
  final String stack;
  final List<String> highlights;
  final String? url;
  final String? ctaLabel;
}

class _AuthorContact {
  const _AuthorContact({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.brandColor,
    required this.actionLabel,
    required this.onTap,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color brandColor;
  final String actionLabel;
  final VoidCallback onTap;
}

class _AuthorMotionPainter extends CustomPainter {
  _AuthorMotionPainter({
    required Animation<double> animation,
    required this.backgroundColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.lineColor,
    required this.nodeColor,
  }) : _animation = animation,
       super(repaint: animation);

  final Animation<double> _animation;
  final Color backgroundColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color lineColor;
  final Color nodeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);
    final progress = _animation.value;
    final pulse = (math.sin(progress * math.pi * 2) + 1) / 2;
    final bounds = Offset.zero & size;

    canvas.drawRect(bounds, Paint()..color = backgroundColor);
    _paintGrid(canvas, size, shortestSide);
    final paths = _createSignalPaths(size);
    _paintPaths(canvas, paths, shortestSide);
    _paintFlowingSignals(canvas, paths, shortestSide, progress);
    _paintCore(canvas, size, shortestSide, progress, pulse);
  }

  void _paintGrid(Canvas canvas, Size size, double shortestSide) {
    final gridPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.18)
      ..strokeWidth = shortestSide * 0.002;

    for (var index = 1; index < 6; index += 1) {
      final fraction = index / 6;
      canvas.drawLine(
        Offset(size.width * fraction, 0),
        Offset(size.width * fraction, size.height),
        gridPaint,
      );
      canvas.drawLine(
        Offset(0, size.height * fraction),
        Offset(size.width, size.height * fraction),
        gridPaint,
      );
    }
  }

  List<Path> _createSignalPaths(Size size) {
    final width = size.width;
    final height = size.height;

    return [
      Path()
        ..moveTo(-width * 0.08, height * 0.26)
        ..cubicTo(
          width * 0.18,
          height * 0.08,
          width * 0.34,
          height * 0.48,
          width * 0.58,
          height * 0.32,
        )
        ..cubicTo(
          width * 0.76,
          height * 0.20,
          width * 0.86,
          height * 0.38,
          width * 1.08,
          height * 0.22,
        ),
      Path()
        ..moveTo(-width * 0.08, height * 0.68)
        ..cubicTo(
          width * 0.16,
          height * 0.84,
          width * 0.36,
          height * 0.46,
          width * 0.56,
          height * 0.62,
        )
        ..cubicTo(
          width * 0.76,
          height * 0.78,
          width * 0.88,
          height * 0.54,
          width * 1.08,
          height * 0.72,
        ),
      Path()
        ..moveTo(width * 0.08, height * 1.08)
        ..cubicTo(
          width * 0.24,
          height * 0.76,
          width * 0.38,
          height * 0.72,
          width * 0.52,
          height * 0.50,
        )
        ..cubicTo(
          width * 0.68,
          height * 0.24,
          width * 0.76,
          height * 0.18,
          width * 0.92,
          -height * 0.08,
        ),
    ];
  }

  void _paintPaths(Canvas canvas, List<Path> paths, double shortestSide) {
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = shortestSide * 0.008;

    for (var index = 0; index < paths.length; index += 1) {
      basePaint.color = (index == 1 ? secondaryColor : primaryColor).withValues(
        alpha: index == 2 ? 0.28 : 0.44,
      );
      canvas.drawPath(paths[index], basePaint);
    }
  }

  void _paintFlowingSignals(
    Canvas canvas,
    List<Path> paths,
    double shortestSide,
    double progress,
  ) {
    for (var pathIndex = 0; pathIndex < paths.length; pathIndex += 1) {
      final metric = paths[pathIndex].computeMetrics().first;
      for (var signalIndex = 0; signalIndex < 3; signalIndex += 1) {
        final phase =
            (progress +
                pathIndex * 0.18 +
                signalIndex / 3 +
                math.sin(progress * math.pi * 2) * 0.015) %
            1;
        final tangent = metric.getTangentForOffset(metric.length * phase);
        if (tangent == null) {
          continue;
        }

        final color = pathIndex == 1 ? secondaryColor : primaryColor;
        final radius = shortestSide * (signalIndex == 0 ? 0.020 : 0.012);
        final vectorLength = tangent.vector.distance;
        final direction = vectorLength == 0
            ? Offset.zero
            : tangent.vector / vectorLength;

        canvas.drawLine(
          tangent.position - direction * radius * 4,
          tangent.position,
          Paint()
            ..color = color.withValues(alpha: 0.28)
            ..strokeWidth = radius
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          tangent.position,
          radius * 2.4,
          Paint()..color = color.withValues(alpha: 0.10),
        );
        canvas.drawCircle(tangent.position, radius, Paint()..color = color);
      }
    }
  }

  void _paintCore(
    Canvas canvas,
    Size size,
    double shortestSide,
    double progress,
    double pulse,
  ) {
    final center = Offset(size.width * 0.54, size.height * 0.50);
    final coreRadius = shortestSide * 0.055;
    final orbitRadius = shortestSide * 0.19;

    for (var ring = 3; ring >= 1; ring -= 1) {
      final radius =
          coreRadius * (1.8 + ring * 0.9) + pulse * shortestSide * 0.012;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = shortestSide * 0.004
          ..color = primaryColor.withValues(alpha: 0.08 * ring),
      );
    }

    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = shortestSide * 0.005
      ..color = lineColor.withValues(alpha: 0.70);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: orbitRadius * 2.2,
        height: orbitRadius,
      ),
      orbitPaint,
    );

    for (var index = 0; index < 3; index += 1) {
      final angle = index * math.pi * 2 / 3;
      final position = Offset(
        math.cos(angle) * orbitRadius * 1.1,
        math.sin(angle) * orbitRadius * 0.5,
      );
      final color = index == 1 ? secondaryColor : primaryColor;
      canvas.drawCircle(position, shortestSide * 0.017, Paint()..color = color);
    }
    canvas.restore();

    canvas.drawCircle(
      center,
      coreRadius * (1.7 + pulse * 0.3),
      Paint()..color = primaryColor.withValues(alpha: 0.12),
    );
    canvas.drawCircle(center, coreRadius, Paint()..color = nodeColor);
    canvas.drawCircle(center, coreRadius * 0.42, Paint()..color = primaryColor);
  }

  @override
  bool shouldRepaint(covariant _AuthorMotionPainter oldDelegate) {
    return oldDelegate._animation != _animation ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.nodeColor != nodeColor;
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
  if (!context.mounted || launched) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('暂时无法打开链接：$url')));
}

Future<void> _copyValue(
  BuildContext context,
  String label,
  String value,
) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('$label已复制：$value')));
}
