#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# CD-010 Setup Verification Script
# Checks for all required CLI tools and environment state.
# ─────────────────────────────────────────────────────────────────────────────

set -e

echo "🔍 Verifying CD-010 Environment Setup..."
echo "─────────────────────────────────────────────────────────────────────────────"

check_tool() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "✅ $1: $($1 --version | head -n 1)"
    else
        echo "❌ $1: Not found"
        return 1
    fi
}

# 1. Base tools
check_tool "git"
check_tool "python3"
check_tool "pip3"

# 2. DevOps tools
check_tool "docker"
check_tool "aws"
check_tool "terraform"
check_tool "helm"
check_tool "kubectl"

# 3. Security & Testing
check_tool "trivy"
if pip3 show pytest >/dev/null 2>&1; then
    echo "✅ pytest: $(pytest --version | head -n 1)"
else
    echo "❌ pytest: Not installed"
fi

echo "─────────────────────────────────────────────────────────────────────────────"
echo "🚀 Verification complete!"
