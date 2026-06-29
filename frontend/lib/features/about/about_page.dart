import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import '../home/widgets/author_showcase_section.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPageScaffold(
      activeRoute: AppRoutes.about,
      child: AuthorShowcaseSection(),
    );
  }
}
