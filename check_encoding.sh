#!/bin/bash

echo "=== PowerShell编码问题检查 ==="

WORKFLOW_FILE=".github/workflows/build-windows-final.yml"

echo "检查文件: $WORKFLOW_FILE"

# 检查中文字符
echo ""
echo "=== 中文字符检查 ==="

# 检查常见的中文字符范围
chinese_count=$(grep -P '[\u4e00-\u9fff]' "$WORKFLOW_FILE" | wc -l)
if [ "$chinese_count" -gt 0 ]; then
    echo "❌ 发现中文字符 ($chinese_count 行):"
    grep -n -P '[\u4e00-\u9fff]' "$WORKFLOW_FILE" | head -5
else
    echo "✅ 无中文字符"
fi

# 检查特殊符号
echo ""
echo "=== 特殊符号检查 ==="

special_chars=("…" "—" "·" "'" "'" """ """ "！" "？" "，" "。" "；" "：")

for char in "${special_chars[@]}"; do
    if grep -q "$char" "$WORKFLOW_FILE"; then
        echo "❌ 发现特殊符号: $char"
        grep -n "$char" "$WORKFLOW_FILE"
    else
        echo "✅ 无 $char"
    fi
done

# 检查编码相关的字符串
echo ""
echo "=== 编码问题字符检查 ==="

# 检查可能导致编码问题的字符
encoding_issues=$(grep -P '[^\x00-\x7F]' "$WORKFLOW_FILE" | wc -l)
if [ "$encoding_issues" -gt 0 ]; then
    echo "⚠️  发现非ASCII字符 ($encoding_issues 行)"
    echo "这可能在PowerShell中导致编码问题"
else
    echo "✅ 所有字符都是ASCII"
fi

# 检查PowerShell字符串
echo ""
echo "=== PowerShell字符串检查 ==="

# 检查Write-Host命令中的字符串
write_host_lines=$(grep -n "Write-Host" "$WORKFLOW_FILE")
echo "Write-Host命令数量: $(echo "$write_host_lines" | wc -l)"

# 检查是否有可能导致问题的字符串
problematic_strings=$(grep "Write-Host" "$WORKFLOW_FILE" | grep -P '[^\x00-\x7F]')
if [ -n "$problematic_strings" ]; then
    echo "❌ 发现可能有问题的Write-Host字符串:"
    echo "$problematic_strings"
else
    echo "✅ 所有Write-Host字符串都是ASCII"
fi

# 检查文件编码
echo ""
echo "=== 文件编码检查 ==="

file_encoding=$(file -bi "$WORKFLOW_FILE")
echo "文件编码: $file_encoding"

if [[ "$file_encoding" == *"utf-8"* ]]; then
    echo "✅ 文件使用UTF-8编码"
else
    echo "⚠️  文件编码可能有问题"
fi

# 检查行结束符
echo ""
echo "=== 行结束符检查 ==="

if grep -q $'\r' "$WORKFLOW_FILE"; then
    echo "⚠️  发现Windows行结束符 (CRLF)"
else
    echo "✅ 使用Unix行结束符 (LF)"
fi

# 最终评估
echo ""
echo "=== PowerShell兼容性评估 ==="

if [ "$chinese_count" -eq 0 ] && [ "$encoding_issues" -eq 0 ]; then
    echo "🎉 PowerShell编码兼容性良好！"
    echo "✅ 无中文字符"
    echo "✅ 无非ASCII字符"
    echo "✅ 应该不会出现字符串解析错误"
    echo ""
    echo "这个工作流应该可以在GitHub Actions的PowerShell环境中正常运行。"
else
    echo "❌ 仍有编码问题需要解决"
    echo "中文字符: $chinese_count 行"
    echo "非ASCII字符: $encoding_issues 行"
fi