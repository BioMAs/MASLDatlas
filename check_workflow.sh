#!/bin/bash

# GitHub Actions Workflow Validator
# Validates YAML syntax and GitHub Actions specific syntax

set -e

WORKFLOW_FILE=".github/workflows/deploy.yml"

echo "🔍 Validating GitHub Actions workflow: $WORKFLOW_FILE"

# Check if file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "❌ Workflow file not found: $WORKFLOW_FILE"
    exit 1
fi

# Basic YAML syntax check using Python
echo "📋 Checking YAML syntax..."
python3 -c "
import sys
try:
    import yaml
    with open('$WORKFLOW_FILE', 'r') as f:
        yaml.safe_load(f)
    print('✅ YAML syntax is valid')
except ImportError:
    print('⚠️ PyYAML not installed, skipping detailed YAML validation')
    # Basic check - just try to read the file
    with open('$WORKFLOW_FILE', 'r') as f:
        content = f.read()
    if 'name:' in content and 'on:' in content and 'jobs:' in content:
        print('✅ Basic workflow structure looks good')
    else:
        print('❌ Missing required workflow sections')
        sys.exit(1)
except Exception as e:
    print(f'❌ YAML syntax error: {e}')
    sys.exit(1)
"

# Check for common GitHub Actions issues
echo "🔎 Checking for common issues..."

# Check for required fields
if ! grep -q "name:" "$WORKFLOW_FILE"; then
    echo "❌ Missing 'name' field"
    exit 1
fi

if ! grep -q "on:" "$WORKFLOW_FILE"; then
    echo "❌ Missing 'on' field"
    exit 1
fi

if ! grep -q "jobs:" "$WORKFLOW_FILE"; then
    echo "❌ Missing 'jobs' field"
    exit 1
fi

# Check for proper indentation (basic check)
if grep -q "^[[:space:]]\{1\}[^[:space:]]" "$WORKFLOW_FILE"; then
    echo "⚠️ Warning: Found lines with single space indentation (should use 2+ spaces)"
fi

# Check for shell commands that might have issues
if grep -q "python3 -c.*\".*\".*\"" "$WORKFLOW_FILE"; then
    echo "⚠️ Warning: Complex multi-line Python commands detected (consider using separate script files)"
fi

echo "✅ GitHub Actions workflow validation completed"
echo "📝 Workflow summary:"
echo "   - File: $WORKFLOW_FILE"
echo "   - Jobs: $(grep -c "^[[:space:]]*[a-zA-Z_-]*:" "$WORKFLOW_FILE" | head -1) detected"
echo "   - Steps: $(grep -c "name:" "$WORKFLOW_FILE") detected"
