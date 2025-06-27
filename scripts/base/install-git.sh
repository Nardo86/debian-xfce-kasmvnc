#!/bin/bash
set -e

echo "🔧 Installing Git..."

# Check if running as root, if not use sudo
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Update package list
$SUDO apt-get update

# Install Git and SSL certificates for HTTPS
$SUDO apt-get install -y \
    git \
    ca-certificates


echo "✅ Git installation completed!"
echo ""
echo "📋 Next steps:"
echo "   Configure Git with: git config --global user.name 'Your Name'"
echo "   Configure Git with: git config --global user.email 'your.email@example.com'"
echo ""