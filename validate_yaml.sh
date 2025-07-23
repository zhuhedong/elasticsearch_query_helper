#!/bin/bash

echo "🔍 YAML 语法验证"
echo "================"

# 检查是否安装了 yamllint
if ! command -v yamllint &> /dev/null; then
    echo "📦 安装 yamllint..."
    if command -v pip &> /dev/null; then
        pip install yamllint
    elif command -v pip3 &> /dev/null; then
        pip3 install yamllint
    else
        echo "❌ 请先安装 Python 和 pip"
        echo "或者使用在线 YAML 验证器: https://www.yamllint.com/"
        exit 1
    fi
fi

echo "🔍 验证 GitHub Actions 工作流文件..."

# 验证主构建工作流
if [ -f ".github/workflows/build-windows.yml" ]; then
    echo "📄 检查 build-windows.yml..."
    if yamllint .github/workflows/build-windows.yml; then
        echo "✅ build-windows.yml 语法正确"
    else
        echo "❌ build-windows.yml 有语法错误"
    fi
else
    echo "❌ build-windows.yml 文件不存在"
fi

# 验证测试工作流
if [ -f ".github/workflows/test-windows-build.yml" ]; then
    echo "📄 检查 test-windows-build.yml..."
    if yamllint .github/workflows/test-windows-build.yml; then
        echo "✅ test-windows-build.yml 语法正确"
    else
        echo "❌ test-windows-build.yml 有语法错误"
    fi
else
    echo "❌ test-windows-build.yml 文件不存在"
fi

echo ""
echo "📋 YAML 语法检查完成"
echo ""
echo "💡 如果有语法错误，请修复后重新提交"
echo "🌐 在线验证器: https://www.yamllint.com/"