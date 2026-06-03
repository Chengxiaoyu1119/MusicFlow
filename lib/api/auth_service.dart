import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'netease_api.dart';

/// 登录状态
enum AuthStatus { loggedOut, loggingIn, loggedIn, error }

/// 认证状态管理
class AuthNotifier extends StateNotifier<AuthState> {
  late final NeteaseApiClient _api;

  AuthNotifier() : super(AuthState());

  NeteaseApiClient get api => _api;

  void init({String apiBaseUrl = 'http://localhost:3000'}) {
    _api = NeteaseApiClient(baseUrl: apiBaseUrl);
    _restoreSession();
  }

  /// 手机号登录
  Future<String?> loginByPhone(String phone, String password) async {
    state = state.copyWith(status: AuthStatus.loggingIn, error: null);
    final r = await _api.loginByPhone(phone, password);
    if (r.success && _api.isLoggedIn) {
      await _saveSession();
      state = state.copyWith(
        status: AuthStatus.loggedIn,
        nickname: _api.nickname,
        avatarUrl: _api.avatarUrl,
        userId: _api.userId,
      );
      return null;
    }
    state = state.copyWith(status: AuthStatus.error, error: r.message ?? '登录失败');
    return r.message ?? '登录失败';
  }

  /// 退出登录
  Future<void> logout() async {
    _api.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('netease_cookie');
    state = AuthState();
  }

  /// 保存 session
  Future<void> _saveSession() async {
    // Cookie 已存储在 _api 中，下次启动时通过恢复机制重登录
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('netease_logged_in', true);
  }

  /// 恢复登录
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final wasLoggedIn = prefs.getBool('netease_logged_in') ?? false;
    if (wasLoggedIn) {
      // 尝试恢复，这里简化处理，实际需要重登录或 cookie 持久化
      state = state.copyWith(status: AuthStatus.loggedOut);
    }
  }
}

/// 认证状态
class AuthState {
  final AuthStatus status;
  final String? nickname;
  final String? avatarUrl;
  final int? userId;
  final String? error;

  const AuthState({
    this.status = AuthStatus.loggedOut,
    this.nickname,
    this.avatarUrl,
    this.userId,
    this.error,
  });

  bool get isLoggedIn => status == AuthStatus.loggedIn;

  AuthState copyWith({
    AuthStatus? status,
    String? nickname,
    String? avatarUrl,
    int? userId,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      userId: userId ?? this.userId,
      error: error ?? this.error,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
