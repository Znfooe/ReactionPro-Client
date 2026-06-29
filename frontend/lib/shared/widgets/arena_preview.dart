import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class ArenaPreview extends StatelessWidget {
  const ArenaPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: SizedBox(
          height: AppSpacing.x10 * 8,
          width: double.infinity,
          child: Image.asset(
            'assets/images/home/anime-girl.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.high,
            semanticLabel: '蓝天下挥手的水彩二次元女孩',
          ),
        ),
      ),
    );
  }
}
