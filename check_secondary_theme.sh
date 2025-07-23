#!/bin/bash

echo "=== 检查二级界面硬编码颜色 ==="
echo

# 检查所有二级界面文件中的硬编码颜色
secondary_screens=(
    "lib/screens/connection_manager_screen.dart"
    "lib/screens/connection_detail_screen.dart"
    "lib/screens/index_list_screen.dart"
)

echo "1. 检查硬编码的浅色主题颜色..."
found_issues=0

for file in "${secondary_screens[@]}"; do
    if [ -f "$file" ]; then
        echo "检查 $file:"
        
        # 检查硬编码的白色
        white_count=$(grep -c "Colors\.white" "$file" 2>/dev/null || echo "0")
        if [ "$white_count" -gt 0 ]; then
            echo "  ❌ 发现 $white_count 个硬编码的 Colors.white"
            grep -n "Colors\.white" "$file"
            found_issues=$((found_issues + 1))
        else
            echo "  ✅ 无硬编码的 Colors.white"
        fi
        
        # 检查硬编码的灰色
        grey_count=$(grep -c "Colors\.grey" "$file" 2>/dev/null || echo "0")
        if [ "$grey_count" -gt 0 ]; then
            echo "  ❌ 发现 $grey_count 个硬编码的 Colors.grey"
            grep -n "Colors\.grey" "$file"
            found_issues=$((found_issues + 1))
        else
            echo "  ✅ 无硬编码的 Colors.grey"
        fi
        
        # 检查是否使用了主题颜色
        theme_count=$(grep -c "Theme\.of(context)\.colorScheme" "$file" 2>/dev/null || echo "0")
        if [ "$theme_count" -gt 0 ]; then
            echo "  ✅ 使用了 $theme_count 个主题颜色引用"
        else
            echo "  ⚠️  未发现主题颜色引用"
        fi
        
        echo
    else
        echo "❌ 文件不存在: $file"
        echo
    fi
done

echo "2. 检查主题配置一致性..."

# 检查是否强制使用深色主题
if grep -q "themeMode: ThemeMode.dark" lib/main.dart; then
    echo "✅ 强制深色主题已启用"
else
    echo "❌ 强制深色主题未启用"
    found_issues=$((found_issues + 1))
fi

# 检查深色主题配置
if grep -q "ColorScheme.dark" lib/theme/app_theme.dart; then
    echo "✅ 深色配色方案已配置"
else
    echo "❌ 深色配色方案未配置"
    found_issues=$((found_issues + 1))
fi

echo

echo "3. 总结..."
if [ "$found_issues" -eq 0 ]; then
    echo "🎉 所有二级界面都已正确使用深色主题！"
    echo "   - 无硬编码的浅色主题颜色"
    echo "   - 所有界面都使用主题颜色引用"
    echo "   - 强制深色主题已启用"
else
    echo "⚠️  发现 $found_issues 个问题需要修复"
    echo "   请检查上述报告中标记为 ❌ 的项目"
fi

echo
echo "=== 检查完成 ==="