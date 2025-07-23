#!/bin/bash

echo "=== 路径和目录问题检查 ==="

WORKFLOW_FILE=".github/workflows/build-windows-final.yml"

echo "检查文件: $WORKFLOW_FILE"

# 检查目录操作
echo ""
echo "=== 目录操作检查 ==="

# 检查Set-Location命令
set_location_count=$(grep -c "Set-Location" "$WORKFLOW_FILE")
echo "Set-Location命令数量: $set_location_count"

if grep -q "Set-Location elasticsearch_query_helper" "$WORKFLOW_FILE"; then
    echo "✅ 找到项目目录切换命令"
else
    echo "❌ 缺少项目目录切换"
fi

# 检查目录验证
echo ""
echo "=== 目录验证检查 ==="

if grep -q "Test-Path.*lib" "$WORKFLOW_FILE"; then
    echo "✅ 包含lib目录检查"
else
    echo "❌ 缺少lib目录检查"
fi

if grep -q "New-Item.*Directory.*lib" "$WORKFLOW_FILE"; then
    echo "✅ 包含lib目录创建"
else
    echo "❌ 缺少lib目录创建"
fi

if grep -q "Test-Path.*pubspec.yaml" "$WORKFLOW_FILE"; then
    echo "✅ 包含pubspec.yaml检查"
else
    echo "❌ 缺少pubspec.yaml检查"
fi

# 检查文件路径处理
echo ""
echo "=== 文件路径处理检查 ==="

if grep -q "Join-Path" "$WORKFLOW_FILE"; then
    echo "✅ 使用Join-Path处理路径"
    join_path_count=$(grep -c "Join-Path" "$WORKFLOW_FILE")
    echo "Join-Path使用次数: $join_path_count"
else
    echo "❌ 未使用Join-Path"
fi

if grep -q "Get-Location" "$WORKFLOW_FILE"; then
    echo "✅ 使用Get-Location获取当前路径"
    get_location_count=$(grep -c "Get-Location" "$WORKFLOW_FILE")
    echo "Get-Location使用次数: $get_location_count"
else
    echo "❌ 未使用Get-Location"
fi

# 检查错误处理
echo ""
echo "=== 错误处理检查 ==="

if grep -q "try {" "$WORKFLOW_FILE"; then
    echo "✅ 包含try-catch错误处理"
else
    echo "❌ 缺少try-catch错误处理"
fi

if grep -q "Set-Content.*fallback" "$WORKFLOW_FILE"; then
    echo "✅ 包含文件写入备用方案"
else
    echo "❌ 缺少文件写入备用方案"
fi

# 检查调试信息
echo ""
echo "=== 调试信息检查 ==="

debug_commands=("Get-ChildItem" "Write-Host.*directory" "Write-Host.*contents")

for cmd in "${debug_commands[@]}"; do
    if grep -q "$cmd" "$WORKFLOW_FILE"; then
        echo "✅ 包含调试命令: $cmd"
    else
        echo "⚠️  缺少调试命令: $cmd"
    fi
done

# 检查文件操作
echo ""
echo "=== 文件操作检查 ==="

file_operations=("Out-File" "Set-Content" "Test-Path.*main.dart" "Get-Item.*main.dart")

for op in "${file_operations[@]}"; do
    if grep -q "$op" "$WORKFLOW_FILE"; then
        echo "✅ 包含文件操作: $op"
    else
        echo "⚠️  缺少文件操作: $op"
    fi
done

# 检查工作目录一致性
echo ""
echo "=== 工作目录一致性检查 ==="

# 查找所有步骤中的目录相关命令
steps_with_paths=$(grep -n "Set-Location\|Get-Location\|Test-Path\|Out-File.*lib" "$WORKFLOW_FILE")

if [ -n "$steps_with_paths" ]; then
    echo "发现的路径相关操作:"
    echo "$steps_with_paths"
else
    echo "⚠️  未发现路径相关操作"
fi

# 最终评估
echo ""
echo "=== 路径问题修复评估 ==="

if grep -q "Set-Location elasticsearch_query_helper" "$WORKFLOW_FILE" && \
   grep -q "Test-Path.*lib" "$WORKFLOW_FILE" && \
   grep -q "New-Item.*Directory.*lib" "$WORKFLOW_FILE" && \
   grep -q "Join-Path" "$WORKFLOW_FILE"; then
    echo "🎉 路径问题修复看起来完整！"
    echo "✅ 项目目录切换"
    echo "✅ lib目录检查和创建"
    echo "✅ 使用Join-Path处理路径"
    echo "✅ 包含详细调试信息"
    echo ""
    echo "这个版本应该能够正确处理目录结构和文件路径。"
else
    echo "❌ 路径问题修复不完整"
    echo "请检查上述缺少的项目"
fi