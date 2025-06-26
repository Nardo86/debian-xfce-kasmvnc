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

# Update package list
apt-get update

# Install required packages for Node.js repository
apt-get install -y \
    curl \
    gnupg \
    software-properties-common

# Add NodeSource repository for latest Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -

# Install Node.js (includes npm)
apt-get install -y nodejs

# Configure npm to avoid EACCES permission errors
# Create global directory for npm packages in user home
mkdir -p /home/$USERNAME/.npm-global

# Configure npm to use the new directory
npm config set prefix "/home/$USERNAME/.npm-global"

# Update PATH in .bashrc for detected user
echo 'export PATH=/home/'$USERNAME'/.npm-global/bin:$PATH' >> /home/$USERNAME/.bashrc

# Set correct ownership
chown -R $USERNAME:$USERNAME /home/$USERNAME/.npm-global
chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

# Install yarn globally using the new configuration
sudo -u $USERNAME npm install -g yarn

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

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