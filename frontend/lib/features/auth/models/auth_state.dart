import 'user_model.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

final class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.loading() : this(status: AuthStatus.loading);

  const AuthState.unauthenticated({String? errorMessage})
      : this(
          status: AuthStatus.unauthenticated,
          errorMessage: errorMessage,
        );

  const AuthState.authenticated(SiteUser user)
      : this(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final SiteUser? user;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}
