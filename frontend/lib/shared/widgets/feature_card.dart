import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_extension.dart';

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.route,
    required this.icon,
    required this.title,
    required this.primaryMetric,
    required this.secondaryMetric,
  });

  final String route;
  final IconData icon;
  final String title;
  final String primaryMetric;
  final String secondaryMetric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final extension = AppThemeExtension.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSpacing.x10,
                    height: AppSpacing.x10,
                    decoration: BoxDecoration(
                      color: extension.accentMuted,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(icon, color: colors.primary),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_outlined,
                    color: extension.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x6),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.x2),
              Text(
                primaryMetric,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x4),
              Text(
                secondaryMetric,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: colors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
