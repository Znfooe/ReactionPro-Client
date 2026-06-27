abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  static const oauthGithubClientId = String.fromEnvironment(
    'OAUTH_GITHUB_CLIENT_ID',
  );
  static const oauthGoogleClientId = String.fromEnvironment(
    'OAUTH_GOOGLE_CLIENT_ID',
  );
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
}
