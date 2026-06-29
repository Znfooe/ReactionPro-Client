import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../services/score_service.dart';

class ScoreSubmitPanel extends StatelessWidget {
  const ScoreSubmitPanel({
    required this.completed,
    required this.authenticated,
    required this.submitting,
    required this.onSubmit,
    required this.onLogin,
    this.submittedScore,
    this.errorMessage,
    super.key,
  });

  final bool completed;
  final bool authenticated;
  final bool submitting;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;
  final SubmittedScore? submittedScore;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (!completed) {
      return const SizedBox.shrink();
    }

    final extension = AppThemeExtension.of(context);
    final submittedScore = this.submittedScore;
    final statusColor = submittedScore == null
        ? extension.textSecondary
        : extension.colorSuccessText;
    final statusText = submittedScore == null
        ? authenticated
              ? '成绩尚未提交'
              : '登录后提交成绩'
        : submittedScore.leaderboardEligible
        ? '提交完成 · 已入榜'
        : '提交完成';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: extension.accentMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: extension.borderMuted),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    statusText,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: statusColor),
                  ),
                ),
                FilledButton.icon(
                  onPressed: submittedScore != null || submitting
                      ? null
                      : authenticated
                      ? onSubmit
                      : onLogin,
                  icon: submitting
                      ? const SizedBox.square(
                          dimension: AppSpacing.x4,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          authenticated
                              ? Icons.cloud_upload_outlined
                              : Icons.login_outlined,
                        ),
                  label: Text(
                    submitting
                        ? '提交中'
                        : submittedScore != null
                        ? '已提交'
                        : authenticated
                        ? '提交成绩'
                        : '去登录',
                  ),
                ),
              ],
            ),
            if (submittedScore != null) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(
                '${submittedScore.category} · 质量分 ${submittedScore.qualityScore}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: AppSpacing.x2),
              Text(
                errorMessage!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: extension.colorErrorText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
