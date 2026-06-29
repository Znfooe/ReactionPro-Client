import 'package:flutter_test/flutter_test.dart';
import 'package:reaction_time_test/features/settings/client_update/client_update_manifest.dart';

void main() {
  group('compareClientVersions', () {
    test('compares semantic version components numerically', () {
      expect(
        compareClientVersions(
          candidateVersion: '1.10.0',
          candidateBuildNumber: 1,
          currentVersion: '1.2.0',
          currentBuildNumber: 99,
        ),
        greaterThan(0),
      );
    });

    test('uses build number when semantic versions are equal', () {
      expect(
        compareClientVersions(
          candidateVersion: '1.0.0',
          candidateBuildNumber: 2,
          currentVersion: '1.0.0',
          currentBuildNumber: 1,
        ),
        greaterThan(0),
      );
    });

    test('treats a prerelease as older than the stable release', () {
      expect(
        compareClientVersions(
          candidateVersion: '2.0.0-beta.1',
          candidateBuildNumber: 9,
          currentVersion: '2.0.0',
          currentBuildNumber: 1,
        ),
        lessThan(0),
      );
    });
  });
}
