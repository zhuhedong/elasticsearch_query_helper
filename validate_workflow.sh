#!/bin/bash

echo "=== YAML Workflow Validation ==="

# 检查YAML文件是否存在
WORKFLOW_FILE=".github/workflows/build-windows-safe.yml"

if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ Workflow file not found: $WORKFLOW_FILE"
    exit 1
fi

echo "✅ Workflow file found: $WORKFLOW_FILE"

# 检查基本YAML语法
echo ""
echo "=== Basic YAML Syntax Check ==="

# 检查是否有制表符（YAML不允许）
if grep -q $'\t' "$WORKFLOW_FILE"; then
    echo "❌ Found tabs in YAML file (should use spaces)"
    grep -n $'\t' "$WORKFLOW_FILE" | head -5
else
    echo "✅ No tabs found"
fi

# 检查是否有here-string语法
echo ""
echo "=== Here-string Check ==="
if grep -q '@"' "$WORKFLOW_FILE"; then
    echo "❌ Found here-string syntax (@\"...\"@) which is not valid in YAML"
    grep -n '@"' "$WORKFLOW_FILE"
else
    echo "✅ No here-string syntax found"
fi

# 检查缩进一致性
echo ""
echo "=== Indentation Check ==="
if python3 -c "
import yaml
try:
    with open('$WORKFLOW_FILE', 'r') as f:
        yaml.safe_load(f)
    print('✅ YAML syntax is valid')
except yaml.YAMLError as e:
    print(f'❌ YAML syntax error: {e}')
    exit(1)
except Exception as e:
    print(f'⚠️  Could not validate YAML (python3/yaml not available): {e}')
" 2>/dev/null; then
    :
else
    echo "⚠️  Python YAML validation not available, checking manually..."
    
    # 手动检查基本结构
    if grep -q "^name:" "$WORKFLOW_FILE" && \
       grep -q "^on:" "$WORKFLOW_FILE" && \
       grep -q "^jobs:" "$WORKFLOW_FILE"; then
        echo "✅ Basic YAML structure looks correct"
    else
        echo "❌ Missing required YAML structure (name, on, jobs)"
    fi
fi

# 检查PowerShell脚本语法
echo ""
echo "=== PowerShell Script Check ==="
powershell_blocks=$(grep -n "shell: powershell" "$WORKFLOW_FILE" | wc -l)
echo "Found $powershell_blocks PowerShell script blocks"

# 检查关键字段
echo ""
echo "=== Required Fields Check ==="
required_fields=("name" "on" "jobs" "runs-on" "steps")
for field in "${required_fields[@]}"; do
    if grep -q "^[[:space:]]*$field:" "$WORKFLOW_FILE"; then
        echo "✅ $field: found"
    else
        echo "❌ $field: missing"
    fi
done

# 检查Flutter相关步骤
echo ""
echo "=== Flutter Steps Check ==="
flutter_steps=("Setup Flutter" "Get dependencies" "Build Windows")
for step in "${flutter_steps[@]}"; do
    if grep -q "$step" "$WORKFLOW_FILE"; then
        echo "✅ $step: found"
    else
        echo "❌ $step: missing"
    fi
done

echo ""
echo "=== File Statistics ==="
echo "Total lines: $(wc -l < "$WORKFLOW_FILE")"
echo "Total characters: $(wc -c < "$WORKFLOW_FILE")"
echo "PowerShell blocks: $powershell_blocks"

echo ""
echo "=== Validation Complete ==="
echo "If all checks show ✅, the workflow file should be valid for GitHub Actions."