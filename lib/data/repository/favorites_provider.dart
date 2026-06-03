import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

/// Manages favorited/liked track IDs with persistence.
class FavoritesNotifier extends StateNotifier<Set<String>> {
  Box<String>? _box;

  FavoritesNotifier() : super({}) {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<String>('favorites');
    _load();
  }

  void _load() {
    final raw = _box?.get('favorite_ids') ?? '[]';
    try {
      final ids = jsonDecode(raw) as List<dynamic>;
      state = ids.map((e) => e.toString()).toSet();
    } catch (_) {
      state = {};
    }
  }

  Future<void> _save() async {
    await _box?.put('favorite_ids', jsonEncode(state.toList()));
  }

  bool isFavorite(String musicId) => state.contains(musicId);

  Future<void> toggle(String musicId) async {
    if (state.contains(musicId)) {
      state = {...state}..remove(musicId);
    } else {
      state = {...state, musicId};
    }
    await _save();
  }

  int get count => state.length;
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});
