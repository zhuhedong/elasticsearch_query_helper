#!/bin/bash

echo "=== Elasticsearch Query Helper - 深色主题验证 ==="
echo

# 检查主题文件
echo "1. 检查深色主题配置文件..."
if [ -f "lib/theme/app_theme.dart" ]; then
    echo "✅ 主题文件存在"
    
    # 检查深色主题配置
    if grep -q "ColorScheme.dark" lib/theme/app_theme.dart; then
        echo "✅ 深色配色方案已配置"
    else
        echo "❌ 深色配色方案未找到"
    fi
    
    # 检查文本主题
    if grep -q "textTheme:" lib/theme/app_theme.dart; then
        echo "✅ 文本主题已配置"
    else
        echo "❌ 文本主题未找到"
    fi
    
    # 检查高对比度颜色
    if grep -q "0xFFFFFFFF" lib/theme/app_theme.dart; then
        echo "✅ 高对比度白色文本已配置"
    else
        echo "❌ 高对比度白色文本未找到"
    fi
else
    echo "❌ 主题文件不存在"
fi

echo

# 检查主应用配置
echo "2. 检查主应用深色主题设置..."
if [ -f "lib/main.dart" ]; then
    echo "✅ 主应用文件存在"
    
    # 检查强制深色主题
    if grep -q "themeMode: ThemeMode.dark" lib/main.dart; then
        echo "✅ 强制深色主题已启用"
    else
        echo "❌ 强制深色主题未启用"
    fi
    
    # 检查深色主题引用
    if grep -q "darkTheme: AppTheme.darkTheme" lib/main.dart; then
        echo "✅ 深色主题引用已配置"
    else
        echo "❌ 深色主题引用未找到"
    fi
else
    echo "❌ 主应用文件不存在"
fi

echo

# 检查布局修复
echo "3. 检查布局修复..."
layout_files=(
    "lib/screens/connection_manager_screen.dart"
    "lib/screens/connection_detail_screen.dart"
    "lib/widgets/index_selector.dart"
    "lib/widgets/quick_search_panel.dart"
)

for file in "${layout_files[@]}"; do
    if [ -f "$file" ]; then
        if grep -q "mainAxisSize: MainAxisSize.min" "$file"; then
            echo "✅ $file - 布局约束已修复"
        else
            echo "❌ $file - 布局约束未修复"
        fi
    else
        echo "❌ $file - 文件不存在"
    fi
done

echo

# 检查新功能
echo "4. 检查新增功能..."
if [ -f "lib/screens/index_list_screen.dart" ]; then
    echo "✅ 索引列表界面已创建"
    
    # 检查搜索功能
    if grep -q "TextField" lib/screens/index_list_screen.dart; then
        echo "✅ 搜索功能已实现"
    else
        echo "❌ 搜索功能未找到"
    fi
    
    # 检查排序功能
    if grep -q "DropdownButton" lib/screens/index_list_screen.dart; then
        echo "✅ 排序功能已实现"
    else
        echo "❌ 排序功能未找到"
    fi
else
    echo "❌ 索引列表界面不存在"
fi

echo

# 统计修改的文件
echo "5. 统计修改文件..."
modified_files=0
total_files=0

check_files=(
    "lib/main.dart"
    "lib/theme/app_theme.dart"
    "lib/screens/index_list_screen.dart"
    "lib/screens/connection_manager_screen.dart"
    "lib/screens/connection_detail_screen.dart"
    "lib/screens/search_screen.dart"
    "lib/widgets/index_selector.dart"
    "lib/widgets/quick_search_panel.dart"
)

for file in "${check_files[@]}"; do
    total_files=$((total_files + 1))
    if [ -f "$file" ]; then
        modified_files=$((modified_files + 1))
    fi
done

echo "📊 文件统计: $modified_files/$total_files 个文件已处理"

echo
echo "=== 验证完成 ==="

# 检查是否所有关键配置都已完成
if grep -q "themeMode: ThemeMode.dark" lib/main.dart && \
   grep -q "ColorScheme.dark" lib/theme/app_theme.dart && \
   grep -q "0xFFFFFFFF" lib/theme/app_theme.dart && \
   [ -f "lib/screens/index_list_screen.dart" ]; then
    echo "🎉 深色主题实现完成！所有关键配置都已正确设置。"
else
    echo "⚠️  部分配置可能缺失，请检查上述报告。"
fi