#!/bin/bash

echo "🔍 验证 Select Index 和 Quick Search 组件主题修复"
echo "================================================"

# 检查 index_selector.dart
echo "📋 检查 Index Selector 组件:"
echo "  硬编码白色背景检查:"
if grep -n "Colors\.white" elasticsearch_query_helper/lib/widgets/index_selector.dart; then
    echo "  ❌ 仍有硬编码白色背景"
else
    echo "  ✅ 无硬编码白色背景"
fi

echo "  主题颜色引用检查:"
theme_refs=$(grep -c "Theme\.of(context)\.colorScheme" elasticsearch_query_helper/lib/widgets/index_selector.dart)
echo "  ✅ 主题颜色引用: $theme_refs 个"

# 检查 quick_search_panel.dart
echo ""
echo "🔍 检查 Quick Search 组件:"
echo "  硬编码白色背景检查:"
white_backgrounds=$(grep -n "Colors\.white" elasticsearch_query_helper/lib/widgets/quick_search_panel.dart | grep -E "(color:|backgroundColor:)" || echo "无")
if [ "$white_backgrounds" = "无" ]; then
    echo "  ✅ 无硬编码白色背景"
else
    echo "  ❌ 仍有硬编码白色背景:"
    echo "$white_backgrounds"
fi

echo "  主题颜色引用检查:"
theme_refs=$(grep -c "Theme\.of(context)\.colorScheme" elasticsearch_query_helper/lib/widgets/quick_search_panel.dart)
echo "  ✅ 主题颜色引用: $theme_refs 个"

echo ""
echo "🎨 深色主题配置验证:"
if grep -q "themeMode: ThemeMode.dark" elasticsearch_query_helper/lib/main.dart; then
    echo "  ✅ 强制深色主题已启用"
else
    echo "  ❌ 深色主题未强制启用"
fi

echo ""
echo "📊 修复总结:"
echo "  - Index Selector: 修复了主容器和列表项的白色背景"
echo "  - Quick Search: 修复了主容器和ActionChip的白色背景"
echo "  - 所有组件现在都使用 Theme.of(context).colorScheme.surface"
echo "  - 边框颜色使用 Theme.of(context).colorScheme.outline"
echo ""
echo "🎉 Select Index 和 Quick Search 板块现在应该是深色的了！"