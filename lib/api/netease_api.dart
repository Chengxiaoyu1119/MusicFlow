/// 网易云音乐 API 客户端
///
/// 通过 Binaryify/NeteaseCloudMusicApi 的 HTTP API 实现。
/// 用户需要在本机或服务器上运行该 API 服务：
/// ```bash
//  git clone https://github.com/Binaryify/NeteaseCloudMusicApi.git
//  cd NeteaseCloudMusicApi && npm install && node app.js
/// # 默认监听 localhost:3000
/// ```
library;

import 'package:dio/dio.dart';

class NeteaseApiClient {
  final Dio _dio;
  final String baseUrl;

  /// Cookie 用于保持登录状态
  String? _cookie;
  bool get isLoggedIn => _cookie != null;

  /// 当前登录用户信息
  Map<String, dynamic>? _account;
  Map<String, dynamic>? get account => _account;
  int? get userId => _account?['id'] as int?;
  String? get nickname => _account?['nickname'] as String?;
  String? get avatarUrl => _account?['avatarUrl'] as String?;

  NeteaseApiClient({
    this.baseUrl = 'http://localhost:3000',
    Dio? dio,
  }) : _dio = dio ?? Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'User-Agent': 'MusicFlow/1.0'},
  ));

  // ==================== 登录 ====================

  /// 手机号登录
  Future<ApiResponse> loginByPhone(String phone, String password) async {
    final r = await _dio.post('$baseUrl/login/cellphone', data: {
      'phone': phone,
      'password': password,
    });
    _handleCookie(r);
    if (r.data['code'] == 200) {
      _account = r.data['profile'] as Map<String, dynamic>?;
    }
    return ApiResponse.fromJson(r.data);
  }

  /// 邮箱登录
  Future<ApiResponse> loginByEmail(String email, String password) async {
    final r = await _dio.post('$baseUrl/login', data: {
      'email': email,
      'password': password,
    });
    _handleCookie(r);
    if (r.data['code'] == 200) {
      _account = r.data['profile'] as Map<String, dynamic>?;
    }
    return ApiResponse.fromJson(r.data);
  }

  /// 扫码登录第一步：获取 key
  Future<String?> getQrKey() async {
    final r = await _dio.get('$baseUrl/login/qr/key');
    if (r.data['code'] == 200) {
      return r.data['data']['unikey'] as String?;
    }
    return null;
  }

  /// 扫码登录第二步：生成二维码 base64
  Future<String?> getQrCode(String key) async {
    final r = await _dio.get('$baseUrl/login/qr/create', queryParameters: {
      'key': key,
      'qrimg': true,
    });
    if (r.data['code'] == 200) return r.data['data']['qrimg'] as String?;
    return null;
  }

  /// 扫码登录第三步：轮询检查扫码状态
  Future<int> checkQrStatus(String key) async {
    try {
      final r = await _dio.get('$baseUrl/login/qr/check', queryParameters: {
        'key': key,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      final code = r.data['code'] as int? ?? -1;
      if (code == 803) {
        _handleCookie(r);
        final profile = r.data['profile'] as Map<String, dynamic>?;
        if (profile != null) _account = profile;
      }
      return code;
    } catch (_) {
      return -1;
    }
  }

  /// 获取登录状态
  Future<bool> checkLoginStatus() async {
    try {
      final r = await _dio.get('$baseUrl/login/status');
      return r.data['code'] == 200;
    } catch (_) {
      return false;
    }
  }

  // ==================== 歌单 ====================

  /// 获取用户歌单
  Future<List<Map<String, dynamic>>> getUserPlaylists({int? uid, int limit = 50, int offset = 0}) async {
    final r = await _dio.get('$baseUrl/user/playlist', queryParameters: {
      'uid': uid ?? userId,
      'limit': limit,
      'offset': offset,
    }, options: _authOptions);
    if (r.data['code'] != 200) return [];
    return (r.data['playlist'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// 获取歌单详情（含曲目）
  Future<List<Map<String, dynamic>>> getPlaylistTracks(String playlistId, {int limit = 1000}) async {
    final r = await _dio.get('$baseUrl/playlist/track/all', queryParameters: {
      'id': playlistId,
      'limit': limit,
    }, options: _authOptions);
    if (r.data['code'] != 200) return [];
    return (r.data['songs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // ==================== 搜索 ====================

  /// 搜索歌曲
  Future<List<Map<String, dynamic>>> search(String query, {int page = 1, int type = 1}) async {
    final r = await _dio.get('$baseUrl/cloudsearch', queryParameters: {
      'keywords': query,
      'type': type,
      'offset': (page - 1) * 30,
      'limit': 30,
    });
    if (r.data['code'] != 200) return [];
    final result = r.data['result'] as Map<String, dynamic>?;
    if (result == null) return [];
    return (result['songs'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // ==================== 播放 ====================

  /// 获取歌曲播放 URL
  Future<String?> getSongUrl(String songId, {String level = 'standard'}) async {
    final r = await _dio.get('$baseUrl/song/url/v1', queryParameters: {
      'id': songId,
      'level': level,
    }, options: _authOptions);
    if (r.data['code'] != 200) return null;
    final data = r.data['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) return null;
    return data[0]['url'] as String?;
  }

  /// 获取歌词
  Future<String?> getLyric(String songId) async {
    final r = await _dio.get('$baseUrl/lyric', queryParameters: {'id': songId});
    if (r.data['code'] != 200) return null;
    final lrc = r.data['lrc'] as Map<String, dynamic>?;
    return lrc?['lyric'] as String?;
  }

  /// 获取歌曲详情
  Future<Map<String, dynamic>?> getSongDetail(String songId) async {
    final r = await _dio.get('$baseUrl/song/detail', queryParameters: {'ids': songId});
    if (r.data['code'] != 200) return null;
    final songs = r.data['songs'] as List<dynamic>?;
    return songs?.firstOrNull as Map<String, dynamic>?;
  }

  // ==================== 推荐 ====================

  /// 每日推荐歌单
  Future<List<Map<String, dynamic>>> getDailyPlaylists() async {
    final r = await _dio.get('$baseUrl/recommend/resource', options: _authOptions);
    if (r.data['code'] != 200) return [];
    return (r.data['recommend'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// 推荐歌单
  Future<List<Map<String, dynamic>>> getRecommendPlaylists({int limit = 30}) async {
    final r = await _dio.get('$baseUrl/personalized', queryParameters: {'limit': limit});
    if (r.data['code'] != 200) return [];
    return (r.data['result'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// 排行榜
  Future<List<Map<String, dynamic>>> getToplists() async {
    final r = await _dio.get('$baseUrl/toplist');
    if (r.data['code'] != 200) return [];
    return (r.data['list'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  }

  // ==================== 工具 ====================

  Options get _authOptions => Options(headers: {
    if (_cookie != null) 'Cookie': _cookie,
  });

  void _handleCookie(Response r) {
    final setCookie = r.headers['set-cookie'];
    if (setCookie != null) {
      _cookie = setCookie.join('; ');
    }
  }

  /// 清除登录状态
  void logout() {
    _cookie = null;
    _account = null;
  }
}

/// 统一 API 响应
class ApiResponse {
  final int code;
  final String? message;
  final Map<String, dynamic>? data;

  const ApiResponse({required this.code, this.message, this.data});

  bool get success => code == 200;

  factory ApiResponse.fromJson(Map<String, dynamic> json) => ApiResponse(
    code: json['code'] as int? ?? -1,
    message: json['message'] as String?,
    data: json['data'] as Map<String, dynamic>?,
  );
}
