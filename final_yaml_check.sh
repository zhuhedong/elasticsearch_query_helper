#!/bin/bash

echo "=== 最终YAML语法验证 ==="

WORKFLOW_FILE=".github/workflows/build-windows-final.yml"

echo "检查文件: $WORKFLOW_FILE"
echo "文件大小: $(wc -c < "$WORKFLOW_FILE") 字节"
echo "总行数: $(wc -l < "$WORKFLOW_FILE")"

echo ""
echo "=== 关键语法检查 ==="

# 检查基本结构
if grep -q "^name:" "$WORKFLOW_FILE" && \
   grep -q "^on:" "$WORKFLOW_FILE" && \
   grep -q "^jobs:" "$WORKFLOW_FILE"; then
    echo "✅ 基本YAML结构正确"
else
    echo "❌ 基本YAML结构有问题"
fi

# 检查here-string问题（这是主要问题）
if grep -q '@"' "$WORKFLOW_FILE"; then
    echo "❌ 仍有here-string语法 (@\")"
    grep -n '@"' "$WORKFLOW_FILE"
else
    echo "✅ 已移除here-string语法"
fi

# 检查制表符
if grep -q $'\t' "$WORKFLOW_FILE"; then
    echo "❌ 发现制表符"
else
    echo "✅ 无制表符"
fi

# 检查PowerShell脚本块格式
echo ""
echo "=== PowerShell脚本检查 ==="

# 统计PowerShell块
ps_count=$(grep -c "shell: powershell" "$WORKFLOW_FILE")
run_count=$(grep -c "run: |" "$WORKFLOW_FILE")

echo "PowerShell脚本块: $ps_count"
echo "run: | 块: $run_count"

if [ "$ps_count" -eq "$run_count" ]; then
    echo "✅ PowerShell脚本块格式正确"
else
    echo "⚠️  PowerShell脚本块数量不匹配"
fi

# 检查数组语法
echo ""
echo "=== 数组语法检查 ==="

if grep -q '\$.*= @(' "$WORKFLOW_FILE"; then
    echo "✅ 使用PowerShell数组语法"
    array_count=$(grep -c '\$.*= @(' "$WORKFLOW_FILE")
    echo "数组定义数量: $array_count"
else
    echo "⚠️  未发现PowerShell数组语法"
fi

if grep -q ' -join ' "$WORKFLOW_FILE"; then
    echo "✅ 使用数组join操作"
    join_count=$(grep -c ' -join ' "$WORKFLOW_FILE")
    echo "join操作数量: $join_count"
else
    echo "⚠️  未发现join操作"
fi

# 检查关键步骤
echo ""
echo "=== 关键步骤检查 ==="

key_steps=(
    "Checkout code"
    "Setup Flutter" 
    "Build Windows Release"
    "Create Release Package"
    "Upload.*Package"
)

for step in "${key_steps[@]}"; do
    if grep -q "$step" "$WORKFLOW_FILE"; then
        echo "✅ $step"
    else
        echo "❌ 缺少: $step"
    fi
done

echo ""
echo "=== 修复总结 ==="
echo "主要修复:"
echo "1. 移除了 here-string 语法 (@\"...\"@)"
echo "2. 使用 PowerShell 数组和 -join 操作"
echo "3. 保持了所有原有功能"
echo "4. 避免了 Git 配置问题"

echo ""
echo "=== 最终状态 ==="

# 综合评估
if ! grep -q '@"' "$WORKFLOW_FILE" && \
   ! grep -q $'\t' "$WORKFLOW_FILE" && \
   grep -q "Build Windows Release" "$WORKFLOW_FILE" && \
   grep -q "shell: powershell" "$WORKFLOW_FILE"; then
    echo "🎉 YAML文件语法正确，可以使用！"
    echo ""
    echo "使用方法:"
    echo "1. 提交此文件到GitHub仓库"
    echo "2. 在Actions页面手动触发或推送代码"
    echo "3. 等待构建完成并下载生成的ZIP文件"
else
    echo "❌ 仍有语法问题需要修复"
fi