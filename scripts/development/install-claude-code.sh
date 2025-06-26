#!/bin/bash
set -e

echo "🤖 Installing Claude Code CLI..."

# Detect the non-root user (usually UID 1000)
USERNAME=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$USERNAME" ]; then
    echo "❌ Error: Could not detect container user"
    exit 1
fi

echo "👤 Detected user: $USERNAME"

# Check if npm is available
if ! command -v npm &> /dev/null; then
    echo "❌ Error: npm is required but not installed."
    echo "   Please run scripts/base/install-nodejs.sh first"
    exit 1
fi

# Install Claude Code CLI globally
echo "📦 Installing Claude Code CLI via npm..."
sudo -u $USERNAME npm install -g @anthropic-ai/claude-code

# Verify installation
echo "✅ Claude Code CLI installation completed!"
echo ""
echo "📋 Installed version:"
sudo -u $USERNAME claude --version 2>/dev/null || echo "   Run 'claude --version' to verify installation"
echo ""
echo "🔧 Next steps:"
echo "   1. Run 'claude auth' to authenticate with your Anthropic API key"
echo "   2. Run 'claude --help' to see available commands"
echo "   3. Start coding with Claude assistance!"
echo ""