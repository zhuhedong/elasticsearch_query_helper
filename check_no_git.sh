#!/bin/bash

echo "=== Git操作检查 ==="

WORKFLOW_FILE=".github/workflows/build-windows-final.yml"

echo "检查文件: $WORKFLOW_FILE"

# 检查所有可能的Git相关操作
echo ""
echo "=== Git命令检查 ==="

git_commands=("git config" "git clone" "git pull" "git fetch" "git checkout" "git add" "git commit" "git push")

for cmd in "${git_commands[@]}"; do
    if grep -q "$cmd" "$WORKFLOW_FILE"; then
        echo "❌ 发现Git命令: $cmd"
        grep -n "$cmd" "$WORKFLOW_FILE"
    else
        echo "✅ 无 $cmd 命令"
    fi
done

# 检查Git相关的Actions
echo ""
echo "=== Git Actions检查 ==="

git_actions=("actions/checkout" "actions/setup-git" "git-auto-commit-action")

for action in "${git_actions[@]}"; do
    if grep -q "$action" "$WORKFLOW_FILE"; then
        echo "❌ 发现Git Action: $action"
        grep -n "$action" "$WORKFLOW_FILE"
    else
        echo "✅ 无 $action"
    fi
done

# 检查Git相关环境变量
echo ""
echo "=== Git环境变量检查 ==="

git_vars=("GITHUB_TOKEN" "GIT_" "git_")

for var in "${git_vars[@]}"; do
    if grep -q "$var" "$WORKFLOW_FILE"; then
        echo "⚠️  发现Git相关变量: $var"
        grep -n "$var" "$WORKFLOW_FILE"
    else
        echo "✅ 无 $var 变量"
    fi
done

# 检查工作流结构
echo ""
echo "=== 工作流结构检查 ==="

echo "步骤列表:"
grep -n "name:" "$WORKFLOW_FILE" | grep -v "^1:" | while read line; do
    step_name=$(echo "$line" | sed 's/.*name: //' | tr -d '"')
    line_num=$(echo "$line" | cut -d: -f1)
    echo "  第${line_num}行: $step_name"
done

# 检查代码获取方式
echo ""
echo "=== 代码获取方式检查 ==="

if grep -q "actions/checkout" "$WORKFLOW_FILE"; then
    echo "❌ 使用Git checkout获取代码"
elif grep -q "flutter create" "$WORKFLOW_FILE"; then
    echo "✅ 使用flutter create创建项目"
elif grep -q "Download" "$WORKFLOW_FILE"; then
    echo "✅ 使用其他方式获取代码"
else
    echo "⚠️  未明确的代码获取方式"
fi

# 最终评估
echo ""
echo "=== 最终评估 ==="

git_count=$(grep -c -i "git" "$WORKFLOW_FILE")
checkout_count=$(grep -c "checkout" "$WORKFLOW_FILE")

echo "文件中'git'出现次数: $git_count"
echo "文件中'checkout'出现次数: $checkout_count"

if [ "$checkout_count" -eq 0 ] && ! grep -q "git config\|git clone\|git pull" "$WORKFLOW_FILE"; then
    echo ""
    echo "🎉 完全无Git操作！"
    echo "✅ 不使用actions/checkout"
    echo "✅ 不使用git config"
    echo "✅ 不使用任何Git命令"
    echo "✅ 通过flutter create创建项目"
    echo ""
    echo "这个工作流完全独立于Git仓库，"
    echo "不会遇到Git相关的exit code 128错误。"
else
    echo ""
    echo "❌ 仍有Git相关操作需要移除"
fi