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
