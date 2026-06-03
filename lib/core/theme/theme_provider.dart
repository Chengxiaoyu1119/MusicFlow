import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the accent color seed.
final accentColorProvider = StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  return AccentColorNotifier();
});

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier() : super(const Color(0xFF6366F1)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt('accent_color');
    if (value != null) {
      state = Color(value);
    }
  }

  Future<void> setColor(Color color) async {
    state = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color', color.value);
  }
}

/// Predefined accent colors for the theme picker.
const List<Color> accentColors = [
  Color(0xFF6366F1), // Indigo
  Color(0xFFE53935), // Red
  Color(0xFFEC407A), // Pink
  Color(0xFFAB47BC), // Purple
  Color(0xFF7E57C2), // Deep Purple
  Color(0xFF5C6BC0), // Blue
  Color(0xFF42A5F5), // Light Blue
  Color(0xFF26C6DA), // Cyan
  Color(0xFF26A69A), // Teal
  Color(0xFF66BB6A), // Green
  Color(0xFF9CCC65), // Light Green
  Color(0xFFD4E157), // Lime
  Color(0xFFFFEE58), // Yellow
  Color(0xFFFFCA28), // Amber
  Color(0xFFFFA726), // Orange
  Color(0xFF8D6E63), // Brown
  Color(0xFF78909C), // Blue Grey
  Color(0xFF000000), // Black
];
