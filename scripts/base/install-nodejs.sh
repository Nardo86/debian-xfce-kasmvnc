#!/bin/bash
set -e

echo "🚀 Installing Node.js and npm..."

# Detect the non-root user (usually UID 1000)
USERNAME=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$USERNAME" ]; then
    echo "❌ Error: Could not detect container user"
    exit 1
fi

echo "👤 Detected user: $USERNAME"

# Check if running as root, if not use sudo for system operations
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Update package list
$SUDO apt-get update

# Install required packages for Node.js repository
$SUDO apt-get install -y \
    curl \
    gnupg \
    software-properties-common

# Add NodeSource repository for latest Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | $SUDO bash -

# Install Node.js (includes npm)
$SUDO apt-get install -y nodejs

# Configure npm to avoid EACCES permission errors (following official npm docs)
# Create global directory for npm packages in user home
mkdir -p /home/$USERNAME/.npm-global

# Configure npm to use the new directory for the user
sudo -u $USERNAME npm config set prefix "/home/$USERNAME/.npm-global"

# Add npm global bin to PATH in .profile (as per npm official docs)
echo 'export PATH=/home/'$USERNAME'/.npm-global/bin:$PATH' >> /home/$USERNAME/.profile

# Also add to .bashrc for bash sessions
echo 'export PATH=/home/'$USERNAME'/.npm-global/bin:$PATH' >> /home/$USERNAME/.bashrc

# Set correct ownership
chown -R $USERNAME:$USERNAME /home/$USERNAME/.npm-global
chown $USERNAME:$USERNAME /home/$USERNAME/.profile /home/$USERNAME/.bashrc

# Install yarn globally using the user's npm configuration
sudo -u $USERNAME bash -c 'export PATH=/home/'$USERNAME'/.npm-global/bin:$PATH && npm install -g yarn'

# Export PATH for current session (if running interactively)
if [ -t 1 ]; then
    echo "🔄 Updating PATH for current session..."
    export PATH=/home/$USERNAME/.npm-global/bin:$PATH
fi

# Clean up
$SUDO apt-get clean
$SUDO rm -rf /var/lib/apt/lists/*

echo "✅ Node.js installation completed!"
echo ""
echo "📋 Installed versions:"
node --version
npm --version
sudo -u $USERNAME yarn --version
echo ""
echo "🔧 npm configured to install global packages in /home/$USERNAME/.npm-global"
echo "   (avoids EACCES permission errors)"
echo ""
echo "💡 Note: If npm global packages are not found, run:"
echo "   source ~/.bashrc"
echo ""