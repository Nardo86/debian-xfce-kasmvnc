#!/bin/bash
set -e

echo "🔒 Installing ProtonVPN and qBittorrent..."

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

# Install dependencies for ProtonVPN
echo "📦 Installing ProtonVPN dependencies..."
$SUDO apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    lsb-release

# Add ProtonVPN repository
echo "🔑 Adding ProtonVPN repository..."
wget -qO - https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.3-3_all.deb -O /tmp/protonvpn-stable-release.deb
$SUDO dpkg -i /tmp/protonvpn-stable-release.deb
$SUDO apt-get update

# Install ProtonVPN CLI
echo "🛡️ Installing ProtonVPN CLI..."
$SUDO apt-get install -y protonvpn-cli

# Install qBittorrent from official Debian repository
echo "📥 Installing qBittorrent..."
$SUDO apt-get install -y qbittorrent

# Clean up
$SUDO rm -f /tmp/protonvpn-stable-release.deb
$SUDO apt-get clean
$SUDO rm -rf /var/lib/apt/lists/*

echo "✅ ProtonVPN and qBittorrent installation completed!"
echo ""
echo "📋 Next steps:"
echo "   1. Login to ProtonVPN: protonvpn-cli login"
echo "   2. Connect to VPN: protonvpn-cli connect --fastest"
echo "   3. Check VPN status: protonvpn-cli status"
echo "   4. Launch qBittorrent from Applications menu or run: qbittorrent"
echo ""
echo "🔧 ProtonVPN Commands:"
echo "   protonvpn-cli login          # Login with ProtonVPN credentials"
echo "   protonvpn-cli connect        # Connect to VPN"
echo "   protonvpn-cli disconnect     # Disconnect from VPN"
echo "   protonvpn-cli status         # Check connection status"
echo "   protonvpn-cli configure      # Configure settings"
echo ""
echo "⚠️  Security Notes:"
echo "   - Always connect to VPN before starting torrent downloads"
echo "   - Configure qBittorrent to bind to VPN interface only"
echo "   - Consider using kill switch: protonvpn-cli configure"
echo ""