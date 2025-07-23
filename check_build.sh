#!/bin/bash

# Build Status Check for Elasticsearch Query Helper

echo "🔍 Elasticsearch Query Helper - Build Status Check"
echo "=================================================="
echo

# Check Flutter
echo "📱 Flutter Status:"
if command -v flutter &> /dev/null; then
    echo "  ✅ Flutter installed: $(flutter --version | head -n1)"
    echo "  📋 Supported devices:"
    flutter devices --machine 2>/dev/null | grep -q "linux" && echo "  ✅ Linux desktop support available" || echo "  ❌ Linux desktop support not available"
else
    echo "  ❌ Flutter not installed"
fi
echo

# Check system dependencies
echo "🔧 System Dependencies:"
deps=("clang" "cmake" "ninja" "pkg-config")
for dep in "${deps[@]}"; do
    if command -v "$dep" &> /dev/null; then
        echo "  ✅ $dep installed"
    else
        echo "  ❌ $dep missing"
    fi
done

# Check GTK
echo
echo "🖼️  GTK Status:"
if pkg-config --exists gtk+-3.0; then
    echo "  ✅ GTK+3 available: $(pkg-config --modversion gtk+-3.0)"
else
    echo "  ❌ GTK+3 not found"
fi
echo

# Check project files
echo "📁 Project Status:"
files=("pubspec.yaml" "lib/main.dart" "linux/CMakeLists.txt" "linux/main.cc")
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file exists"
    else
        echo "  ❌ $file missing"
    fi
done
echo

# Check builds
echo "🏗️  Build Status:"
if [ -f "build/linux/x64/release/bundle/elasticsearch_query_helper" ]; then
    echo "  ✅ Flutter release bundle built and ready"
    echo "  🎯 Run with: cd build/linux/x64/release/bundle && ./elasticsearch_query_helper"
    echo "  📝 Or use: ./run_linux.sh"
elif [ -f "linux/build/elasticsearch_query_helper" ]; then
    echo "  ✅ GTK demo built and ready"
    echo "  🎯 Run with: cd linux/build && ./elasticsearch_query_helper"
else
    echo "  ❌ No builds found"
    echo "  🔨 Build with: flutter build linux"
fi
echo

# Recommendations
echo "💡 Recommendations:"
if ! command -v flutter &> /dev/null; then
    echo "  📥 Install Flutter SDK for full functionality"
fi

missing_deps=()
for dep in "${deps[@]}"; do
    if ! command -v "$dep" &> /dev/null; then
        missing_deps+=("$dep")
    fi
done

if [ ${#missing_deps[@]} -gt 0 ]; then
    echo "  📦 Install missing dependencies:"
    echo "     Arch/Manjaro: sudo pacman -S ${missing_deps[*]}"
    echo "     Ubuntu/Debian: sudo apt-get install ${missing_deps[*]}"
fi

if ! pkg-config --exists gtk+-3.0; then
    echo "  🖼️  Install GTK+3:"
    echo "     Arch/Manjaro: sudo pacman -S gtk3"
    echo "     Ubuntu/Debian: sudo apt-get install libgtk-3-dev"
fi

echo "✨ Run ./run_linux.sh for an interactive setup!"