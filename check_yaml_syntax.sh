#!/bin/bash

echo "=== YAML语法详细检查 ==="

WORKFLOW_FILE=".github/workflows/build-windows-final.yml"

if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ 文件不存在: $WORKFLOW_FILE"
    exit 1
fi

echo "检查文件: $WORKFLOW_FILE"

# 检查基本YAML结构
echo ""
echo "=== 基本YAML结构 ==="

# 检查必需的顶级字段
required_fields=("name:" "on:" "jobs:")
for field in "${required_fields[@]}"; do
    if grep -q "^$field" "$WORKFLOW_FILE"; then
        echo "✅ $field"
    else
        echo "❌ 缺少: $field"
    fi
done

# 检查缩进一致性
echo ""
echo "=== 缩进检查 ==="

# 检查是否有制表符
if grep -q $'\t' "$WORKFLOW_FILE"; then
    echo "❌ 发现制表符 (第$(grep -n $'\t' "$WORKFLOW_FILE" | head -1 | cut -d: -f1)行)"
    grep -n $'\t' "$WORKFLOW_FILE" | head -3
else
    echo "✅ 无制表符"
fi

# 检查行尾空格
trailing_spaces=$(grep -n ' $' "$WORKFLOW_FILE" | wc -l)
if [ "$trailing_spaces" -gt 0 ]; then
    echo "⚠️  发现 $trailing_spaces 行有行尾空格"
else
    echo "✅ 无行尾空格"
fi

# 检查YAML特殊字符问题
echo ""
echo "=== 特殊字符检查 ==="

# 检查here-string语法
if grep -q '@"' "$WORKFLOW_FILE"; then
    echo "❌ 发现here-string语法 (@\")"
    grep -n '@"' "$WORKFLOW_FILE"
else
    echo "✅ 无here-string语法"
fi

# 检查未转义的引号
if grep -q '[^\\]"[^,:]' "$WORKFLOW_FILE"; then
    echo "⚠️  可能有未正确处理的引号"
else
    echo "✅ 引号处理正确"
fi

# 检查PowerShell脚本块
echo ""
echo "=== PowerShell脚本块检查 ==="

powershell_blocks=$(grep -n "shell: powershell" "$WORKFLOW_FILE")
block_count=$(echo "$powershell_blocks" | wc -l)

if [ "$block_count" -gt 0 ]; then
    echo "发现 $block_count 个PowerShell脚本块:"
    echo "$powershell_blocks"
else
    echo "❌ 未发现PowerShell脚本块"
fi

# 检查run脚本的管道符
run_pipes=$(grep -c "run: |" "$WORKFLOW_FILE")
echo "run: | 脚本块数量: $run_pipes"

# 检查YAML值的引用
echo ""
echo "=== YAML值检查 ==="

# 检查布尔值
if grep -q "true\|false" "$WORKFLOW_FILE"; then
    echo "✅ 发现布尔值"
else
    echo "⚠️  无布尔值"
fi

# 检查数字值
if grep -q ": [0-9]" "$WORKFLOW_FILE"; then
    echo "✅ 发现数字值"
else
    echo "⚠️  无数字值"
fi

# 使用Python验证YAML语法（如果可用）
echo ""
echo "=== Python YAML验证 ==="

if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import yaml
import sys

try:
    with open('$WORKFLOW_FILE', 'r', encoding='utf-8') as f:
        content = f.read()
        data = yaml.safe_load(content)
    
    print('✅ YAML语法完全正确')
    
    # 检查基本结构
    if 'name' in data and 'on' in data and 'jobs' in data:
        print('✅ 基本结构完整')
    else:
        print('❌ 基本结构不完整')
    
    # 检查jobs结构
    if 'jobs' in data and isinstance(data['jobs'], dict):
        job_count = len(data['jobs'])
        print(f'✅ 发现 {job_count} 个job')
        
        for job_name, job_data in data['jobs'].items():
            if 'runs-on' in job_data and 'steps' in job_data:
                step_count = len(job_data['steps'])
                print(f'✅ Job \"{job_name}\": {step_count} 个步骤')
            else:
                print(f'❌ Job \"{job_name}\": 结构不完整')
    
except yaml.YAMLError as e:
    print(f'❌ YAML语法错误: {e}')
    sys.exit(1)
except Exception as e:
    print(f'❌ 其他错误: {e}')
    sys.exit(1)
"
else
    echo "⚠️  Python3不可用，跳过详细验证"
fi

echo ""
echo "=== 检查完成 ==="
echo "如果所有检查都显示 ✅，则YAML文件应该可以正常使用"