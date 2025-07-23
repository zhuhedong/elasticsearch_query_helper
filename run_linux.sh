#!/bin/bash

# Elasticsearch Query Helper - Linux Run Script

echo "🔍 Elasticsearch Query Helper - Linux Platform"
echo "=============================================="
echo

# Add Flutter to PATH if it exists
export PATH="/opt/flutter/bin:$PATH"

# Check if Flutter is installed
if command -v flutter &> /dev/null; then
    echo "✅ Flutter found: $(flutter --version | head -n1)"
    echo
    
    # Check if we have a built bundle
    if [ -f "build/linux/x64/release/bundle/elasticsearch_query_helper" ]; then
        echo "🎯 Found pre-built release bundle!"
        read -p "🚀 Would you like to run the release version? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🎮 Starting Elasticsearch Query Helper (Release)..."
            cd build/linux/x64/release/bundle && ./elasticsearch_query_helper
            exit 0
        fi
    fi
    
    echo "🚀 Building and running Flutter app for Linux..."
    flutter build linux && {
        echo "✅ Build successful!"
        echo "🎮 Starting Elasticsearch Query Helper..."
        cd build/linux/x64/release/bundle && ./elasticsearch_query_helper
    }
else
    echo "❌ Flutter not found in PATH"
    echo
    echo "📋 To run the full Flutter application:"
    echo "   1. Install Flutter SDK:"
    echo "      https://docs.flutter.dev/get-started/install/linux"
    echo
    echo "   2. Add Flutter to your PATH:"
    echo "      export PATH=\"/opt/flutter/bin:\$PATH\""
    echo
    echo "   3. Run this script again"
    echo
    
    # Check if we have a pre-built bundle
    if [ -f "build/linux/x64/release/bundle/elasticsearch_query_helper" ]; then
        echo "✅ Pre-built release bundle is available!"
        read -p "🎯 Would you like to run it now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🎮 Starting Elasticsearch Query Helper (Pre-built)..."
            cd build/linux/x64/release/bundle && ./elasticsearch_query_helper
        fi
    else
        echo "⚠️  No pre-built bundle found."
        echo "   Install Flutter and run this script to build and run the app."
    fi
fi