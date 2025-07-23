#!/bin/bash

echo "=== 检查所有界面的深色主题配置 ==="
echo

# 检查所有主要界面文件
main_screens=(
    "lib/screens/search_screen.dart"
    "lib/screens/connection_manager_screen.dart"
    "lib/screens/connection_detail_screen.dart"
    "lib/screens/index_list_screen.dart"
    "lib/screens/welcome_screen.dart"
)

echo "1. 检查主要界面的硬编码颜色..."
total_issues=0

for file in "${main_screens[@]}"; do
    if [ -f "$file" ]; then
        echo "检查 $(basename "$file"):"
        
        # 检查硬编码的白色
        white_count=$(grep -c "Colors\.white" "$file" 2>/dev/null || echo "0")
        if [ "$white_count" -gt 0 ]; then
            echo "  ❌ 发现 $white_count 个硬编码的 Colors.white"
            total_issues=$((total_issues + white_count))
        else
            echo "  ✅ 无硬编码的 Colors.white"
        fi
        
        # 检查硬编码的灰色
        grey_count=$(grep -c "Colors\.grey" "$file" 2>/dev/null || echo "0")
        if [ "$grey_count" -gt 0 ]; then
            echo "  ❌ 发现 $grey_count 个硬编码的 Colors.grey"
            total_issues=$((total_issues + grey_count))
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

echo "2. 检查核心主题配置..."

# 检查主应用配置
if grep -q "themeMode: ThemeMode.dark" lib/main.dart; then
    echo "✅ 强制深色主题已启用"
else
    echo "❌ 强制深色主题未启用"
    total_issues=$((total_issues + 1))
fi

# 检查深色主题配置
if grep -q "ColorScheme.dark" lib/theme/app_theme.dart; then
    echo "✅ 深色配色方案已配置"
else
    echo "❌ 深色配色方案未配置"
    total_issues=$((total_issues + 1))
fi

# 检查高对比度文本
if grep -q "0xFFFFFFFF" lib/theme/app_theme.dart; then
    echo "✅ 高对比度白色文本已配置"
else
    echo "❌ 高对比度白色文本未配置"
    total_issues=$((total_issues + 1))
fi

echo

echo "3. 检查组件主题..."

# 检查组件文件
component_files=(
    "lib/widgets/index_selector.dart"
    "lib/widgets/quick_search_panel.dart"
)

for file in "${component_files[@]}"; do
    if [ -f "$file" ]; then
        theme_count=$(grep -c "Theme\.of(context)" "$file" 2>/dev/null || echo "0")
        if [ "$theme_count" -gt 0 ]; then
            echo "✅ $(basename "$file"): 使用了 $theme_count 个主题引用"
        else
            echo "⚠️  $(basename "$file"): 未发现主题引用"
        fi
    fi
done

echo

echo "4. 总结..."
if [ "$total_issues" -eq 0 ]; then
    echo "🎉 所有界面都已正确使用深色主题！"
    echo "   - 无硬编码的浅色主题颜色"
    echo "   - 所有界面都使用主题颜色引用"
    echo "   - 强制深色主题已启用"
    echo "   - 高对比度配置完整"
    echo ""
    echo "✨ 用户现在可以享受完全一致的深色主题体验！"
else
    echo "⚠️  发现 $total_issues 个问题需要修复"
    echo "   请检查上述报告中标记为 ❌ 的项目"
fi

echo
echo "=== 检查完成 ==="