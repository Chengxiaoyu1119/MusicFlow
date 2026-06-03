import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/auth_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiUrlController = TextEditingController(text: 'http://localhost:3000');
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    ref.read(authProvider.notifier).init();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    if (auth.isLoggedIn) {
      return _LoggedInView(nickname: auth.nickname ?? '用户', avatarUrl: auth.avatarUrl);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 24),
          // Logo
          Icon(Icons.music_note_rounded, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('MusicFlow', textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text('登录网易云音乐获取你的歌单',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),

          // API 地址
          TextField(
            controller: _apiUrlController,
            decoration: InputDecoration(
              labelText: 'API 地址',
              hintText: 'http://localhost:3000',
              prefixIcon: const Icon(Icons.link_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          Text('需要先启动 Binaryify/NeteaseCloudMusicApi',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant)),

          const SizedBox(height: 24),

          // 手机号登录
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: '手机号',
              prefixIcon: const Icon(Icons.phone_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: auth.status == AuthStatus.loggingIn ? null : () => _login(),
            child: auth.status == AuthStatus.loggingIn
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('登录'),
          ),

          if (auth.error != null) ...[
            const SizedBox(height: 12),
            Text(auth.error!, style: TextStyle(color: theme.colorScheme.error)),
          ],

          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _startQrLogin(),
            child: const Text('扫码登录'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final authN = ref.read(authProvider.notifier);
    authN.init(apiBaseUrl: _apiUrlController.text);
    final error = await authN.loginByPhone(
      _phoneController.text,
      _passwordController.text,
    );
    if (error == null && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _startQrLogin() async {
    final authN = ref.read(authProvider.notifier);
    authN.init(apiBaseUrl: _apiUrlController.text);
    final api = authN.api;

    final key = await api.getQrKey();
    if (key == null) return;

    // 轮询扫码状态
    if (!mounted) return;
    for (int i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final status = await api.checkQrStatus(key);
      if (status == 803) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
    }
  }
}

class _LoggedInView extends ConsumerWidget {
  final String nickname;
  final String? avatarUrl;

  const _LoggedInView({required this.nickname, this.avatarUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(nickname.isNotEmpty ? nickname[0] : '?',
              style: TextStyle(fontSize: 32, color: theme.colorScheme.onPrimaryContainer)),
          ),
          const SizedBox(height: 16),
          Text('已登录', style: theme.textTheme.titleLarge),
          Text(nickname, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }
}
