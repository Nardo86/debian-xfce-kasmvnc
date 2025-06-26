#!/bin/bash
set -e

echo "🔧 Installing Git..."

# Update package list
apt-get update

# Install Git and SSL certificates for HTTPS
apt-get install -y \
    git \
    ca-certificates

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "✅ Git installation completed!"
echo ""
echo "📋 Next steps:"
echo "   Configure Git with: git config --global user.name 'Your Name'"
echo "   Configure Git with: git config --global user.email 'your.email@example.com'"
echo ""