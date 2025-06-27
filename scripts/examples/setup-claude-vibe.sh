#!/bin/bash
set -e

echo "🎯 Setting up Claude Development Environment..."
echo "   This will install: Git + Node.js + Claude Code CLI"
echo ""

# Run individual installation scripts
echo "Step 1/3: Installing Git..."
bash /scripts/base/install-git.sh

echo ""
echo "Step 2/3: Installing Node.js and npm..."
bash /scripts/base/install-nodejs.sh

echo ""
echo "Step 3/3: Installing Claude Code CLI..."
bash /scripts/development/install-claude-code.sh

echo ""
echo "🎉 Claude Development Environment setup completed!"
echo ""
echo "🚀 You're ready to code with Claude!"
echo "   - Git is configured and ready"
echo "   - Node.js and npm are installed (with proper permissions)"
echo "   - Claude Code CLI is available"
echo ""
echo "📋 Next steps:"
echo "   1. Reload PATH: source ~/.bashrc"
echo "   2. Configure Git: git config --global user.name 'Your Name'"
echo "   3. Configure Git: git config --global user.email 'your.email@example.com'"
echo "   4. Authenticate Claude: claude auth"
echo "   5. Start a new project: mkdir my-project && cd my-project"
echo "   6. Initialize with Claude: claude init"
echo ""
echo "💡 Important: Run 'source ~/.bashrc' first to access claude command!"
echo ""