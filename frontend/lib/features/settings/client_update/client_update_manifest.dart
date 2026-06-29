final class ClientUpdateManifest {
  const ClientUpdateManifest({
    required this.enabled,
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.sha256,
    required this.releaseNotes,
    required this.publishedAt,
  });

  final bool enabled;
  final String? version;
  final int? buildNumber;
  final Uri? downloadUrl;
  final String? sha256;
  final String releaseNotes;
  final DateTime? publishedAt;

  factory ClientUpdateManifest.fromJson(Map<String, Object?> json) {
    final downloadUrl = json['downloadUrl'] as String?;
    final publishedAt = json['publishedAt'] as String?;
    final enabled = json['enabled'] as bool? ?? false;
    final uri = downloadUrl == null ? null : Uri.tryParse(downloadUrl);
    if (enabled &&
        (json['version'] is! String ||
            json['buildNumber'] is! int ||
            uri?.scheme != 'https' ||
            json['sha256'] is! String)) {
      throw const FormatException('Incomplete Windows update manifest.');
    }
    return ClientUpdateManifest(
      enabled: enabled,
      version: json['version'] as String?,
      buildNumber: json['buildNumber'] as int?,
      downloadUrl: uri,
      sha256: json['sha256'] as String?,
      releaseNotes: json['releaseNotes'] as String? ?? '',
      publishedAt: publishedAt == null ? null : DateTime.tryParse(publishedAt),
    );
  }

  bool isNewerThan({required String version, required int buildNumber}) {
    if (!enabled || this.version == null || this.buildNumber == null) {
      return false;
    }
    return compareClientVersions(
          candidateVersion: this.version!,
          candidateBuildNumber: this.buildNumber!,
          currentVersion: version,
          currentBuildNumber: buildNumber,
        ) >
        0;
  }
}

int compareClientVersions({
  required String candidateVersion,
  required int candidateBuildNumber,
  required String currentVersion,
  required int currentBuildNumber,
}) {
  final candidate = _ParsedVersion.parse(candidateVersion);
  final current = _ParsedVersion.parse(currentVersion);
  final versionComparison = candidate.compareTo(current);
  if (versionComparison != 0) {
    return versionComparison;
  }
  return candidateBuildNumber.compareTo(currentBuildNumber);
}

final class _ParsedVersion implements Comparable<_ParsedVersion> {
  const _ParsedVersion(this.core, this.preRelease);

  final List<int> core;
  final List<String> preRelease;

  factory _ParsedVersion.parse(String value) {
    final separator = value.indexOf('-');
    final coreValue = separator == -1 ? value : value.substring(0, separator);
    final preReleaseValue = separator == -1
        ? null
        : value.substring(separator + 1);
    final core = coreValue
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    while (core.length < 3) {
      core.add(0);
    }
    return _ParsedVersion(core, preReleaseValue?.split('.') ?? const []);
  }

  @override
  int compareTo(_ParsedVersion other) {
    for (var index = 0; index < 3; index++) {
      final comparison = core[index].compareTo(other.core[index]);
      if (comparison != 0) {
        return comparison;
      }
    }
    if (preRelease.isEmpty && other.preRelease.isNotEmpty) {
      return 1;
    }
    if (preRelease.isNotEmpty && other.preRelease.isEmpty) {
      return -1;
    }
    for (
      var index = 0;
      index < preRelease.length || index < other.preRelease.length;
      index++
    ) {
      if (index >= preRelease.length) {
        return -1;
      }
      if (index >= other.preRelease.length) {
        return 1;
      }
      final candidateNumber = int.tryParse(preRelease[index]);
      final currentNumber = int.tryParse(other.preRelease[index]);
      final comparison = candidateNumber != null && currentNumber != null
          ? candidateNumber.compareTo(currentNumber)
          : preRelease[index].compareTo(other.preRelease[index]);
      if (comparison != 0) {
        return comparison;
      }
    }
    return 0;
  }
}
