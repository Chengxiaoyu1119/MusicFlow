# MusicFlow 🎵

> A beautiful, cross-platform music player with plugin ecosystem.
> Built with Flutter — one codebase for macOS, Windows, Linux, iOS, Android & Web.

[![Flutter](https://img.shields.io/badge/Flutter-3.44+-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows%20%7C%20Linux%20%7C%20iOS%20%7C%20Android%20%7C%20Web-blue)]()

---

## ✨ Features

### 🎧 Player
- **High-quality audio** engine based on `just_audio` + `audio_service`
- **Background playback** with notification controls (lock screen, headset buttons)
- **Equalizer** — 10-band graphic EQ with 8 presets
- **Playback speed** control (0.5x – 2.0x)
- **Sleep timer** with presets

### 🎨 UI
- **Material 3 Design** with dynamic color theming (18 accent colors)
- **Light / Dark / System** theme modes
- **Glassmorphism** — frosted glass album art background
- **Synced lyrics** — LRC parser with auto-scroll, tap-to-seek
- **Spectrum visualization** — animated frequency bars
- **Gesture controls** — swipe to change track, double-tap to seek

### 🔌 Plugin System
- **Extensible** — plugins provide search, playback & lyrics from different sources
- **Built-in** Netease Cloud Music & QQ Music plugins
- **External JS plugins** loaded at runtime with sandboxed execution
- **AES-256-GCM encrypted** plugin storage
- **Plugin manager** with enable/disable toggle

### 📥 Download & Library
- **Local music scanning** — auto-detect audio files in system directories
- **Song downloading** with progress tracking
- **Playlist management** with create/edit/delete
- **Playlist import** (M3U, PLS formats)
- **Play statistics** — top tracks, total listening time

### 🖥 Desktop Features
- **Global media keys** (Play/Pause, Next, Previous)
- **System tray** with context menu
- **Window state** persistence (size & position)
- **Local HTTP API** for remote playback control
- **Desktop lyrics** — full-screen lyrics overlay

---

## 🚀 Quick Start

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.44+
- Platform-specific toolchains (Xcode for macOS/iOS, VS Build Tools for Windows)

### Run

```bash
# Clone & enter
git clone https://github.com/yourusername/musicflow.git
cd musicflow

# Get dependencies
flutter pub get

# Run on your platform
flutter run -d macos      # macOS
flutter run -d windows    # Windows
flutter run -d linux      # Linux
flutter run -d chrome     # Web
flutter run -d android    # Android
```

### Build

```bash
flutter build web         # Web
flutter build macos       # macOS .app
flutter build apk         # Android .apk
```

---

## 🏗 Architecture

```
lib/
├── main.dart                  # Entry point
├── app.dart                   # Router + theme + app shell
├── audio/                     # Audio engine (just_audio + audio_service)
├── core/                      # Theme, constants, platform helper
├── data/                      # Models, database, repositories
├── features/                  # Feature modules
│   ├── player/                # Full player, lyrics, spectrum, gestures
│   ├── library/               # Local music library
│   ├── search/                # Search (local + online plugins)
│   ├── playlist/              # Playlist management + import/export
│   ├── plugins/               # Plugin manager UI
│   ├── settings/              # Settings page
│   ├── downloads/             # Download management
│   ├── equalizer/             # Equalizer UI
│   ├── stats/                 # Play statistics
│   └── desktop/               # Shortcuts, tray, window, HTTP API
├── plugin/                    # Plugin system (engine, sandbox, built-in)
└── shared/widgets/            # Reusable widgets (mini player, music tile)
```

---

## 🔌 Plugin Development

Plugins are JavaScript modules that implement a standard interface:

```javascript
module.exports = {
  platform: "My Source",
  version: "1.0.0",

  async search(query, page, type) {
    // Return { isEnd, data: [ { id, title, artist, album, artwork, duration } ] }
  },

  async getMediaSource(id, quality) {
    // Return audio URL string
  },

  async getLyric(id) {
    // Return LRC text
  }
};
```

Install from URL: **Settings → Plugins → + → Paste URL**

---

## 📦 Dependencies

| Category | Packages |
|----------|---------|
| Audio | `just_audio`, `audio_service`, `audio_session` |
| State | `flutter_riverpod` |
| Routing | `go_router` |
| Storage | `hive`, `shared_preferences` |
| Networking | `dio`, `http`, `shelf` |
| UI | `cached_network_image`, `shimmer`, `lottie`, `palette_generator` |
| Desktop | `hotkey_manager`, `tray_manager`, `window_manager` |
| Security | `encrypt`, `crypto` |

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [lx-music](https://github.com/lyswhut/lx-music-desktop) — Architecture inspiration
- [MusicFree](https://github.com/maotoumao/MusicFree) — Plugin system design
- [YesPlayMusic](https://github.com/qier222/YesPlayMusic) — UI inspiration
- [Binaryify/NeteaseCloudMusicApi](https://github.com/Binaryify/NeteaseCloudMusicApi)
