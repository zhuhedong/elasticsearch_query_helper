#!/bin/bash

echo "🐧➡️🪟 Linux 下准备 Windows 构建"
echo "================================="

# 检查项目
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 请在 Flutter 项目根目录运行"
    exit 1
fi

PROJECT_NAME=$(grep '^name:' pubspec.yaml | cut -d' ' -f2)
echo "📦 项目名称: $PROJECT_NAME"

# 创建 .github/workflows 目录
mkdir -p .github/workflows

# 创建 GitHub Actions 工作流
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
    - uses: actions/checkout@v4
    
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
        echo. >> dist\elasticsearch-query-helper-windows\README.txt
        echo Double-click elasticsearch_query_helper.exe to run the application >> dist\elasticsearch-query-helper-windows\README.txt
        echo. >> dist\elasticsearch-query-helper-windows\README.txt
        echo System Requirements: Windows 10 or later >> dist\elasticsearch-query-helper-windows\README.txt
        
    - name: Upload Windows Executable
      uses: actions/upload-artifact@v4
      with:
        name: elasticsearch-query-helper-windows
        path: dist/elasticsearch-query-helper-windows/
        
    - name: Create ZIP Package
      shell: powershell
      run: |
        Compress-Archive -Path dist\elasticsearch-query-helper-windows\* -DestinationPath elasticsearch-query-helper-windows-v1.0.0.zip
        
    - name: Upload ZIP Package
      uses: actions/upload-artifact@v4
      with:
        name: elasticsearch-query-helper-windows-zip
        path: elasticsearch-query-helper-windows-v1.0.0.zip

    - name: Create Release (on tag)
      if: startsWith(github.ref, 'refs/tags/')
      uses: softprops/action-gh-release@v1
      with:
        files: elasticsearch-query-helper-windows-v1.0.0.zip
        body: |
          ## Elasticsearch Query Helper - Windows Release
          
          ### 📦 Installation
          1. Download the ZIP file
          2. Extract to any folder
          3. Double-click `elasticsearch_query_helper.exe`
          
          ### 🔧 System Requirements
          - Windows 10 or later
          - No additional dependencies required
          
          ### ✨ Features
          - Dark theme interface
          - Support for Elasticsearch v6, v7, v8
          - Connection management
          - Quick search functionality
          - Index browsing
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF

echo "✅ GitHub Actions 工作流已创建: .github/workflows/build-windows.yml"

# 创建本地测试脚本
cat > test_github_actions_locally.sh << 'EOF'
#!/bin/bash
echo "🧪 本地测试 GitHub Actions 工作流"
echo "================================="

# 检查 act 是否安装
if ! command -v act &> /dev/null; then
    echo "📦 安装 act (GitHub Actions 本地运行器)..."
    
    # 检测系统类型
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        brew install act
    else
        echo "❌ 请手动安装 act: https://github.com/nektos/act"
        exit 1
    fi
fi

echo "🚀 运行本地测试..."
echo "注意: 这将在 Docker 中模拟 GitHub Actions"

# 运行 Windows 构建工作流
act -j build-windows --platform windows-latest=catthehacker/ubuntu:act-latest

echo "✅ 本地测试完成"
echo "注意: 由于平台限制，本地测试可能无法完全模拟 Windows 构建"
EOF

chmod +x test_github_actions_locally.sh
echo "✅ 本地测试脚本已创建: test_github_actions_locally.sh"

# 创建 Docker 实验性构建脚本
cat > docker_windows_build_experimental.sh << 'EOF'
#!/bin/bash
echo "🐳 Docker Windows 构建 (实验性)"
echo "==============================="
echo "⚠️  警告: 这是实验性功能，可能无法正常工作"

# 创建 Dockerfile
cat > Dockerfile.windows-experimental << 'DOCKERFILE'
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
    ca-certificates \
    gnupg \
    lsb-release

# 安装 Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"

# 预下载 Flutter 依赖
RUN flutter precache

WORKDIR /app

# 设置入口点
COPY . .

# 尝试构建 (可能失败)
RUN flutter config --enable-windows-desktop || true
RUN flutter create --platforms=windows . || true
RUN flutter pub get || true

CMD ["bash", "-c", "echo '尝试构建 Windows 版本...'; flutter build windows --release || echo '构建失败，这是预期的，因为缺少 Windows 工具链'"]
DOCKERFILE

echo "📁 Dockerfile.windows-experimental 已创建"

# 构建镜像
echo "🏗️  构建 Docker 镜像..."
docker build -f Dockerfile.windows-experimental -t flutter-windows-experimental .

echo "🚀 运行实验性构建..."
docker run --rm -v $(pwd):/app flutter-windows-experimental

echo "✅ 实验性构建完成"
echo "💡 如果失败，请使用 GitHub Actions 方案"
EOF

chmod +x docker_windows_build_experimental.sh
echo "✅ Docker 实验性构建脚本已创建: docker_windows_build_experimental.sh"

# 创建使用说明
cat > WINDOWS_BUILD_INSTRUCTIONS.md << 'EOF'
# 🐧➡️🪟 Linux 下构建 Windows 包说明

## 🎯 推荐方案: GitHub Actions

### 1. 提交代码到 GitHub
```bash
# 初始化 Git 仓库 (如果还没有)
git init
git add .
git commit -m "Add Windows build workflow"

# 推送到 GitHub
git remote add origin https://github.com/yourusername/elasticsearch-query-helper.git
git push -u origin main
```

### 2. 触发构建
- 进入 GitHub 仓库页面
- 点击 "Actions" 标签
- 选择 "Build Windows Release" 工作流
- 点击 "Run workflow" 按钮

### 3. 下载构建产物
- 构建完成后，在 Actions 页面下载 artifacts
- 解压获得 Windows 可执行文件

## 🔄 自动发布

### 创建版本标签自动发布
```bash
# 创建版本标签
git tag v1.0.0
git push origin v1.0.0

# 这将自动触发构建并创建 GitHub Release
```

## 🧪 本地测试 (可选)

```bash
# 使用 act 本地测试 GitHub Actions
./test_github_actions_locally.sh

# 或尝试 Docker 实验性构建
./docker_windows_build_experimental.sh
```

## 📋 文件说明

- `.github/workflows/build-windows.yml` - GitHub Actions 工作流
- `test_github_actions_locally.sh` - 本地测试脚本
- `docker_windows_build_experimental.sh` - Docker 实验性构建
- `WINDOWS_BUILD_INSTRUCTIONS.md` - 本说明文件

## ✅ 成功标志

构建成功后，您将获得：
- `elasticsearch_query_helper.exe` - Windows 可执行文件
- `data/` 目录 - 应用资源文件
- 运行时 DLL 文件
- README.txt - 使用说明

文件大小约 50-100MB，可在 Windows 10/11 上直接运行。
EOF

echo "✅ 使用说明已创建: WINDOWS_BUILD_INSTRUCTIONS.md"

echo ""
echo "🎉 Windows 构建准备完成！"
echo ""
echo "📋 下一步操作："
echo "1. 提交代码到 GitHub 仓库"
echo "2. 在 GitHub Actions 中触发构建"
echo "3. 下载构建产物"
echo ""
echo "📁 创建的文件："
echo "  - .github/workflows/build-windows.yml (GitHub Actions 工作流)"
echo "  - test_github_actions_locally.sh (本地测试)"
echo "  - docker_windows_build_experimental.sh (Docker 实验)"
echo "  - WINDOWS_BUILD_INSTRUCTIONS.md (详细说明)"
echo ""
echo "🚀 推荐使用 GitHub Actions 进行自动化构建！"