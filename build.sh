#!/bin/bash
# MusicFlow 构建脚本
# 使用方式: ./build.sh [web|macos|ios|android|windows|all]

set -e

echo "🎵 MusicFlow Build Script"
echo "========================="

case "${1:-web}" in
  web)
    echo "📦 Building for Web..."
    flutter build web --release
    echo "✅ Web build complete: build/web/"
    ;;
  macos)
    echo "📦 Building for macOS..."
    echo "⚠️  需要安装 Xcode（完整版，非 Command Line Tools）"
    flutter build macos --release
    echo "✅ macOS build complete: build/macos/Build/Products/Release/"
    ;;
  ios)
    echo "📦 Building for iOS..."
    echo "⚠️  需要安装 Xcode + CocoaPods"
    flutter build ios --release
    echo "✅ iOS build complete"
    ;;
  android)
    echo "📦 Building for Android..."
    echo "⚠️  需要安装 Android SDK"
    flutter build apk --release
    echo "✅ Android build complete: build/app/outputs/flutter-apk/"
    ;;
  windows)
    echo "📦 Building for Windows..."
    echo "⚠️  需要安装 Visual Studio Build Tools"
    flutter build windows --release
    echo "✅ Windows build complete: build/windows/runner/Release/"
    ;;
  all)
    echo "📦 Building all platforms... (跳过需要特殊工具链的平台)"
    flutter build web --release && echo "✅ Web OK"
    echo "ℹ️  要构建 macOS/Windows/iOS/Android，请使用:"
    echo "   ./build.sh macos    # 需要 Xcode"
    echo "   ./build.sh android  # 需要 Android SDK"
    echo "   ./build.sh ios      # 需要 Xcode"
    echo "   ./build.sh windows  # 需要 Visual Studio"
    ;;
  serve)
    echo "🌐 启动本地预览服务器..."
    echo "   打开 http://localhost:8080"
    cd build/web && python3 -m http.server 8080 || python -m http.server 8080
    ;;
  *)
    echo "用法: ./build.sh [web|macos|ios|android|windows|all|serve]"
    echo "  默认: web"
    ;;
esac
