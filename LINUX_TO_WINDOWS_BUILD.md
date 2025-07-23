# 🐧➡️🪟 Linux 下构建 Windows 包指南

## ❌ 直接构建的限制

**简短回答：不能直接构建**

Flutter **不支持**在 Linux 下直接构建 Windows 包，因为：
- Windows 构建需要 Visual Studio 和 Windows SDK
- 需要 Windows 特定的编译工具链
- CMake 构建过程依赖 Windows 环境

## ✅ 可行的解决方案

### 方案1: Docker + Wine (推荐)

#### 🐳 使用 Docker 构建

```bash
# 创建 Dockerfile
cat > Dockerfile.windows << 'EOF'
FROM ubuntu:22.04

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    wget \
    software-properties-common

# 安装 Wine
RUN dpkg --add-architecture i386 && \
    wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
    apt-key add winehq.key && \
    add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ jammy main' && \
    apt-get update && \
    apt-get install -y winehq-stable

# 安装 Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

# 配置 Wine
RUN winecfg

WORKDIR /app
EOF

# 构建 Docker 镜像
docker build -f Dockerfile.windows -t flutter-windows-builder .

# 运行构建
docker run -v $(pwd):/app flutter-windows-builder bash -c "
    flutter config --enable-windows-desktop
    flutter pub get
    flutter build windows --release
"
```

### 方案2: GitHub Actions (最推荐)

#### 🚀 自动化 CI/CD 构建

```yaml
# .github/workflows/build-windows.yml
name: Build Windows Release

on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:

jobs:
  build-windows:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.13.0'
        channel: 'stable'
    
    - name: Enable Windows Desktop
      run: flutter config --enable-windows-desktop
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Build Windows Release
      run: flutter build windows --release
    
    - name: Create Release Package
      run: |
        mkdir release-package
        xcopy build\windows\runner\Release\* release-package\ /E /I /Y
        
    - name: Upload Release Artifact
      uses: actions/upload-artifact@v3
      with:
        name: elasticsearch-query-helper-windows
        path: release-package/
        
    - name: Create ZIP
      run: |
        Compress-Archive -Path release-package\* -DestinationPath elasticsearch-query-helper-windows.zip
        
    - name: Upload ZIP Artifact
      uses: actions/upload-artifact@v3
      with:
        name: elasticsearch-query-helper-windows-zip
        path: elasticsearch-query-helper-windows.zip
```

### 方案3: 虚拟机

#### 💻 使用 VirtualBox/VMware

```bash
# 安装 VirtualBox
sudo apt update
sudo apt install virtualbox virtualbox-ext-pack

# 下载 Windows 10/11 ISO
# 创建 Windows 虚拟机
# 在虚拟机中安装 Flutter 和 Visual Studio
# 构建 Windows 包
```

### 方案4: 远程构建服务

#### ☁️ 使用云服务

```bash
# 使用 Azure DevOps, AWS CodeBuild, 或 Google Cloud Build
# 配置 Windows 构建环境
# 自动化构建流程
```

## 🛠️ 实用脚本

### Linux 下的准备脚本

```bash
#!/bin/bash
# prepare_windows_build.sh

echo "🐧 Linux 下准备 Windows 构建"
echo "============================="

# 检查项目
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 请在 Flutter 项目根目录运行"
    exit 1
fi

# 创建 GitHub Actions 工作流
mkdir -p .github/workflows
cat > .github/workflows/build-windows.yml << 'EOF'
name: Build Windows Release

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]
  workflow_dispatch:

jobs:
  build-windows:
    runs-on: windows-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.13.0'
        channel: 'stable'
    
    - name: Enable Windows Desktop
      run: flutter config --enable-windows-desktop
    
    - name: Create Windows Platform
      run: flutter create --platforms=windows .
    
    - name: Get dependencies
      run: flutter pub get
    
    - name: Build Windows Release
      run: flutter build windows --release
    
    - name: Create Release Package
      shell: cmd
      run: |
        mkdir dist
        xcopy build\windows\runner\Release\* dist\elasticsearch-query-helper-windows\ /E /I /Y
        echo Elasticsearch Query Helper - Windows Version > dist\elasticsearch-query-helper-windows\README.txt
        echo Double-click elasticsearch_query_helper.exe to run >> dist\elasticsearch-query-helper-windows\README.txt
        
    - name: Upload Artifact
      uses: actions/upload-artifact@v3
      with:
        name: elasticsearch-query-helper-windows
        path: dist/elasticsearch-query-helper-windows/
        
    - name: Create ZIP
      shell: powershell
      run: |
        Compress-Archive -Path dist\elasticsearch-query-helper-windows\* -DestinationPath elasticsearch-query-helper-windows.zip
        
    - name: Upload ZIP
      uses: actions/upload-artifact@v3
      with:
        name: elasticsearch-query-helper-windows-zip
        path: elasticsearch-query-helper-windows.zip
EOF

echo "✅ GitHub Actions 工作流已创建"
echo "📁 文件位置: .github/workflows/build-windows.yml"

# 创建 Docker 构建文件
cat > docker-build-windows.sh << 'EOF'
#!/bin/bash
echo "🐳 Docker Windows 构建 (实验性)"
echo "================================"

# 创建 Dockerfile
cat > Dockerfile.windows-build << 'DOCKERFILE'
FROM cirrusci/flutter:stable

USER root

# 安装 Wine 和依赖
RUN apt-get update && apt-get install -y \
    wine \
    winetricks \
    xvfb

# 设置 Wine 环境
RUN winecfg

USER cirrus
WORKDIR /app

# 复制项目文件
COPY . .

# 构建
RUN flutter config --enable-windows-desktop
RUN flutter create --platforms=windows .
RUN flutter pub get

# 注意：这可能不会完全工作，因为需要 Windows 特定工具
RUN flutter build windows --release || echo "构建可能失败，这是预期的"
DOCKERFILE

echo "Dockerfile 已创建"
echo "注意：Docker 方案可能不完全工作，推荐使用 GitHub Actions"
EOF

chmod +x docker-build-windows.sh
echo "✅ Docker 构建脚本已创建"

echo ""
echo "🎯 推荐使用方案："
echo "1. GitHub Actions (最简单) - 提交代码到 GitHub 自动构建"
echo "2. 虚拟机 - 安装 Windows 虚拟机进行构建"
echo "3. 远程 Windows 机器 - 使用远程桌面连接"

echo ""
echo "📋 下一步："
echo "1. 提交代码到 GitHub 仓库"
echo "2. 进入 Actions 标签页"
echo "3. 手动触发 'Build Windows Release' 工作流"
echo "4. 下载构建产物"
```

## 🎯 最佳实践建议

### 推荐方案排序：

1. **GitHub Actions** ⭐⭐⭐⭐⭐
   - 免费、自动化、可靠
   - 无需本地 Windows 环境
   - 支持自动发布

2. **虚拟机** ⭐⭐⭐⭐
   - 完全控制构建环境
   - 可以调试问题
   - 需要 Windows 许可证

3. **远程构建服务** ⭐⭐⭐
   - 云端构建
   - 按需付费
   - 配置复杂

4. **Docker + Wine** ⭐⭐
   - 实验性方案
   - 可能不稳定
   - 仅作备选

## 🚀 快速开始

```bash
# 1. 创建 GitHub 仓库并推送代码
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/yourusername/elasticsearch-query-helper.git
git push -u origin main

# 2. 在 GitHub 上触发 Actions 构建
# 3. 下载构建产物
```

**结论：虽然不能直接在 Linux 下构建 Windows 包，但通过 GitHub Actions 可以实现自动化的跨平台构建！**