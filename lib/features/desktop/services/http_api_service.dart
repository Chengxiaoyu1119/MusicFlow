import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../../../audio/audio_handler.dart';
import '../../../data/models/music.dart';

/// Local HTTP API service for remote playback control.
///
/// Starts a lightweight HTTP server that allows third-party apps
/// (or browser extensions) to control playback via REST endpoints.
///
/// Endpoints:
/// - GET  /api/status     — Current playback state + queue info
/// - POST /api/play       — Resume playback
/// - POST /api/pause      — Pause playback
/// - POST /api/toggle     — Toggle play/pause
/// - POST /api/next       — Skip to next track
/// - POST /api/previous   — Skip to previous track
/// - POST /api/seek       — Seek to position (body: {"position": 123.4} seconds)
/// - GET  /api/queue      — Get current queue
/// - POST /api/volume     — Set volume (body: {"volume": 0.8})
///
/// Default port: 16060
class HttpApiService {
  final MusicAudioHandler _handler;
  HttpServer? _server;
  int _port;
  bool _running = false;

  HttpApiService(this._handler, {int port = 16060}) : _port = port;

  int get port => _port;
  bool get isRunning => _running;

  Future<void> start({int? port}) async {
    if (_running) return;

    if (port != null) _port = port;

    final router = Router();

    // Status
    router.get('/api/status', (Request request) {
      final current = _handler.currentMusic;
      return _json({
        'playing': _handler.isPlaying,
        'volume': _handler.volume,
        'speed': _handler.speed,
        'position': _handler.positionStream.last.toString(),
        'duration': _handler.durationStream.last.toString(),
        'track': current != null ? _musicToJson(current) : null,
        'queueLength': _handler.queueLength,
      });
    });

    // Playback control
    router.post('/api/play', (_) => _exec(() => _handler.play()));
    router.post('/api/pause', (_) => _exec(() => _handler.pause()));
    router.post('/api/toggle', (_) => _exec(() => _handler.togglePlayPause()));
    router.post('/api/next', (_) => _exec(() => _handler.skipToNext()));
    router.post('/api/previous', (_) => _exec(() => _handler.skipToPrevious()));

    // Seek
    router.post('/api/seek', (Request request) async {
      final body = await _parseBody(request);
      final seconds = body['position'] as num? ?? 0;
      await _handler.seek(Duration(milliseconds: (seconds * 1000).round()));
      return _ok();
    });

    // Queue
    router.get('/api/queue', (_) {
      // For now return empty queue since we don't expose the full list
      return _json({'queue': [], 'count': _handler.queueLength});
    });

    // Volume
    router.post('/api/volume', (Request request) async {
      final body = await _parseBody(request);
      final volume = (body['volume'] as num?)?.toDouble() ?? 0.8;
      await _handler.setVolume(volume.clamp(0.0, 1.0));
      return _ok();
    });

    // OPTIONS handler for CORS preflight
    router.add('OPTIONS', '/api/<path>', (_) => Response.ok(''));

    final handler = router;

    try {
      _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, _port);
      _running = true;
      debugPrint('HTTP API server running on http://127.0.0.1:$_port');
    } catch (e) {
      // Port in use — try next port
      for (int i = 1; i < 10; i++) {
        try {
          _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, _port + i);
          _port = _port + i;
          _running = true;
          debugPrint('HTTP API server running on http://127.0.0.1:$_port');
          return;
        } catch (_) {}
      }
      debugPrint('Failed to start HTTP API server: $e');
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _running = false;
  }

  Response _json(Map<String, dynamic> data) => Response.ok(
    jsonEncode(data),
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  );

  Response _ok() => Response.ok(
    '{"ok":true}',
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  );

  Future<void> _exec(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _parseBody(Request request) async {
    final body = await request.readAsString();
    if (body.isEmpty) return {};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Map<String, dynamic> _musicToJson(Music music) => {
    'id': music.id,
    'title': music.title,
    'artist': music.artist,
    'album': music.album,
    'artworkUrl': music.artworkUrl,
  };
}
