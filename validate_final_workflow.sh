#!/bin/bash

echo "=== Windows构建工作流验证 ==="

WORKFLOW_FILE=".github/workflows/build-windows-final.yml"

if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ 工作流文件不存在: $WORKFLOW_FILE"
    exit 1
fi

echo "✅ 工作流文件: $WORKFLOW_FILE"

# 检查Git相关问题
echo ""
echo "=== Git问题检查 ==="
if grep -q "git config" "$WORKFLOW_FILE"; then
    echo "❌ 发现Git配置命令 (可能导致exit code 128)"
    grep -n "git config" "$WORKFLOW_FILE"
else
    echo "✅ 无Git配置命令"
fi

if grep -q "Configure Git" "$WORKFLOW_FILE"; then
    echo "❌ 发现Git配置步骤"
else
    echo "✅ 无Git配置步骤"
fi

# 检查YAML语法问题
echo ""
echo "=== YAML语法检查 ==="
if grep -q '@"' "$WORKFLOW_FILE" && grep -q '"@' "$WORKFLOW_FILE"; then
    echo "⚠️  发现here-string语法 (应该在PowerShell中正常工作)"
    echo "Here-string数量: $(grep -c '@"' "$WORKFLOW_FILE")"
else
    echo "✅ 无here-string语法"
fi

# 检查制表符
if grep -q $'\t' "$WORKFLOW_FILE"; then
    echo "❌ 发现制表符 (YAML应使用空格)"
else
    echo "✅ 无制表符"
fi

# 检查PowerShell脚本
echo ""
echo "=== PowerShell脚本检查 ==="
powershell_count=$(grep -c "shell: powershell" "$WORKFLOW_FILE")
echo "PowerShell脚本块数量: $powershell_count"

# 检查关键构建步骤
echo ""
echo "=== 构建步骤检查 ==="
steps=(
    "Checkout code"
    "Setup Flutter"
    "Enable Windows Desktop"
    "Get dependencies"
    "Clean build"
    "Build Windows Release"
    "Create Release Package"
    "Create ZIP Archive"
    "Upload.*Package"
)

for step in "${steps[@]}"; do
    if grep -q "$step" "$WORKFLOW_FILE"; then
        echo "✅ $step"
    else
        echo "❌ 缺少: $step"
    fi
done

# 检查错误处理
echo ""
echo "=== 错误处理检查 ==="
if grep -q "throw" "$WORKFLOW_FILE"; then
    echo "✅ 包含错误处理 (throw语句)"
else
    echo "⚠️  无错误处理"
fi

if grep -q "Test-Path" "$WORKFLOW_FILE"; then
    echo "✅ 包含文件检查 (Test-Path)"
else
    echo "⚠️  无文件检查"
fi

# 检查中文支持
echo ""
echo "=== 中文支持检查 ==="
if grep -q "UTF8" "$WORKFLOW_FILE"; then
    echo "✅ UTF8编码支持"
else
    echo "⚠️  无UTF8编码"
fi

if grep -q "启动" "$WORKFLOW_FILE"; then
    echo "✅ 包含中文内容"
else
    echo "⚠️  无中文内容"
fi

# 文件统计
echo ""
echo "=== 文件统计 ==="
echo "总行数: $(wc -l < "$WORKFLOW_FILE")"
echo "总字符: $(wc -c < "$WORKFLOW_FILE")"
echo "PowerShell块: $powershell_count"

# 最终评估
echo ""
echo "=== 最终评估 ==="
if ! grep -q "git config" "$WORKFLOW_FILE" && \
   ! grep -q "Configure Git" "$WORKFLOW_FILE" && \
   ! grep -q $'\t' "$WORKFLOW_FILE" && \
   grep -q "Build Windows Release" "$WORKFLOW_FILE"; then
    echo "🎉 工作流看起来可以避免Git问题并正常运行!"
else
    echo "⚠️  工作流可能仍有问题，请检查上述警告"
fi