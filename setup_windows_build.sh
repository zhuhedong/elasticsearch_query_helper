#!/bin/bash

echo "🏗️ Flutter Windows 支持配置和打包脚本"
echo "======================================="

# 检查当前目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 错误: 请在Flutter项目根目录运行此脚本"
    exit 1
fi

echo "📋 项目信息:"
echo "  项目名称: $(grep '^name:' pubspec.yaml | cut -d' ' -f2)"
echo "  当前目录: $(pwd)"

echo ""
echo "🔧 Windows 支持配置步骤:"

# 步骤1: 检查Flutter环境
echo "1. 检查Flutter环境..."
if command -v flutter &> /dev/null; then
    echo "  ✅ Flutter已安装"
    flutter --version | head -1
else
    echo "  ❌ Flutter未安装或未在PATH中"
    echo "     请先安装Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# 步骤2: 启用Windows支持
echo ""
echo "2. 启用Windows桌面支持..."
flutter config --enable-windows-desktop
if [ $? -eq 0 ]; then
    echo "  ✅ Windows桌面支持已启用"
else
    echo "  ❌ 启用Windows支持失败"
fi

# 步骤3: 创建Windows平台文件
echo ""
echo "3. 创建Windows平台文件..."
flutter create --platforms=windows .
if [ $? -eq 0 ]; then
    echo "  ✅ Windows平台文件已创建"
else
    echo "  ❌ 创建Windows平台文件失败"
fi

# 步骤4: 检查Windows目录
echo ""
echo "4. 验证Windows配置..."
if [ -d "windows" ] && [ -f "windows/CMakeLists.txt" ]; then
    echo "  ✅ Windows目录和配置文件已创建"
    echo "  📁 Windows文件结构:"
    ls -la windows/ | sed 's/^/    /'
else
    echo "  ❌ Windows配置不完整"
fi

# 步骤5: 获取依赖
echo ""
echo "5. 获取项目依赖..."
flutter pub get
if [ $? -eq 0 ]; then
    echo "  ✅ 依赖获取成功"
else
    echo "  ❌ 依赖获取失败"
fi

echo ""
echo "🎯 Windows 构建命令:"
echo "  调试版本: flutter build windows --debug"
echo "  发布版本: flutter build windows --release"

echo ""
echo "📦 构建输出位置:"
echo "  调试版本: build/windows/runner/Debug/"
echo "  发布版本: build/windows/runner/Release/"

echo ""
echo "🚀 完整打包流程:"
cat << 'EOF'

# 1. 清理并构建
flutter clean
flutter pub get
flutter build windows --release

# 2. 创建分发目录
mkdir -p dist/elasticsearch_query_helper_windows
cp -r build/windows/runner/Release/* dist/elasticsearch_query_helper_windows/

# 3. 创建启动脚本 (可选)
cat > dist/elasticsearch_query_helper_windows/start.bat << 'BATCH'
@echo off
elasticsearch_query_helper.exe
BATCH

# 4. 打包成ZIP
cd dist
zip -r elasticsearch_query_helper_windows_v1.0.0.zip elasticsearch_query_helper_windows/
cd ..

echo "✅ Windows版本已打包完成: dist/elasticsearch_query_helper_windows_v1.0.0.zip"

EOF

echo ""
echo "⚠️  Windows 构建要求:"
echo "  - Windows 10/11 操作系统"
echo "  - Visual Studio 2022 (含C++工具)"
echo "  - Windows 10/11 SDK"
echo "  - CMake工具"

echo ""
echo "📋 故障排除:"
echo "  如果构建失败，请检查:"
echo "  1. flutter doctor -v (检查环境)"
echo "  2. Visual Studio安装是否完整"
echo "  3. Windows SDK是否已安装"
echo "  4. 项目依赖是否兼容Windows"

echo ""
echo "🎉 配置完成！现在可以构建Windows版本了。"