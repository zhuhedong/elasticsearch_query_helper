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
