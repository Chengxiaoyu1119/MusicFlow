import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings for the desktop lyrics overlay appearance.
class LyricsAppearance {
  final double fontSize;
  final Color textColor;
  final Color activeColor;
  final double backgroundOpacity;
  final bool pauseTransparent;

  const LyricsAppearance({
    this.fontSize = 28,
    this.textColor = Colors.white,
    this.activeColor = Colors.cyan,
    this.backgroundOpacity = 0.85,
    this.pauseTransparent = true,
  });

  LyricsAppearance copyWith({
    double? fontSize,
    Color? textColor,
    Color? activeColor,
    double? backgroundOpacity,
    bool? pauseTransparent,
  }) {
    return LyricsAppearance(
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      activeColor: activeColor ?? this.activeColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      pauseTransparent: pauseTransparent ?? this.pauseTransparent,
    );
  }
}

/// Manages lyrics appearance settings with persistence.
class LyricsSettingsNotifier extends StateNotifier<LyricsAppearance> {
  LyricsSettingsNotifier() : super(const LyricsAppearance()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = LyricsAppearance(
      fontSize: prefs.getDouble('lyrics_font_size') ?? 28,
      textColor: Color(prefs.getInt('lyrics_text_color') ?? Colors.white.value),
      activeColor: Color(prefs.getInt('lyrics_active_color') ?? Colors.cyan.value),
      backgroundOpacity: prefs.getDouble('lyrics_bg_opacity') ?? 0.85,
      pauseTransparent: prefs.getBool('lyrics_pause_transparent') ?? true,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lyrics_font_size', state.fontSize);
    await prefs.setInt('lyrics_text_color', state.textColor.value);
    await prefs.setInt('lyrics_active_color', state.activeColor.value);
    await prefs.setDouble('lyrics_bg_opacity', state.backgroundOpacity);
    await prefs.setBool('lyrics_pause_transparent', state.pauseTransparent);
  }

  void setFontSize(double size) {
    state = state.copyWith(fontSize: size.clamp(14, 72));
    _save();
  }

  void setTextColor(Color color) {
    state = state.copyWith(textColor: color);
    _save();
  }

  void setActiveColor(Color color) {
    state = state.copyWith(activeColor: color);
    _save();
  }

  void setBackgroundOpacity(double opacity) {
    state = state.copyWith(backgroundOpacity: opacity.clamp(0.0, 1.0));
    _save();
  }

  void setPauseTransparent(bool value) {
    state = state.copyWith(pauseTransparent: value);
    _save();
  }
}

final lyricsSettingsProvider = StateNotifierProvider<LyricsSettingsNotifier, LyricsAppearance>((ref) {
  return LyricsSettingsNotifier();
});
