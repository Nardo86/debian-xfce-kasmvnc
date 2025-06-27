#!/bin/bash
set -e

echo "🔒 Installing OpenVPN, qBittorrent for secure torrenting..."

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

# Install OpenVPN and dependencies
echo "📦 Installing OpenVPN and network tools..."
$SUDO apt-get install -y \
    openvpn \
    wget \
    curl \
    unzip \
    iproute2

# Create OpenVPN configuration directory
echo "📁 Creating OpenVPN configuration directories..."
$SUDO mkdir -p /etc/openvpn/configs
$SUDO chown root:$USERNAME /etc/openvpn/configs
$SUDO chmod 775 /etc/openvpn/configs

# Create TUN device for OpenVPN (required in Docker containers)
echo "🔧 Setting up TUN device for OpenVPN..."
$SUDO mkdir -p /dev/net
$SUDO mknod /dev/net/tun c 10 200 2>/dev/null || echo "TUN device already exists"
$SUDO chmod 600 /dev/net/tun

# Install qBittorrent from official Debian repository
echo "📥 Installing qBittorrent..."
$SUDO apt-get install -y qbittorrent


echo "✅ OpenVPN and qBittorrent installation completed!"
echo ""
echo "📋 VPN Configuration (works with any OpenVPN provider):"
echo "   • ProtonVPN: https://account.protonvpn.com/downloads"
echo "   • NordVPN: Download OpenVPN configs from account"
echo "   • ExpressVPN: Manual configuration section"
echo "   • Any OpenVPN provider: Download .ovpn files"
echo ""
echo "🔧 Configuration steps:"
echo "   1. Download .ovpn config files from your VPN provider"
echo "   2. Copy files to: /etc/openvpn/configs/"
echo "   3. Connect: sudo openvpn --config [config-file].ovpn"
echo "   4. Test connection: curl ifconfig.me (check IP changed)"
echo ""
echo "📱 Usage commands:"
echo "   sudo openvpn --config [file].ovpn    # Connect to VPN"
echo "   sudo pkill openvpn                   # Disconnect VPN"
echo "   ip route                             # Check routing table"
echo "   qbittorrent                          # Launch torrent client"
echo ""
echo "⚠️  Security Notes:"
echo "   - Always test VPN connection before torrenting"
echo "   - Configure qBittorrent to bind to VPN interface (tun0)"
echo "   - Monitor connection: VPN disconnection exposes real IP"
echo "   - Use kill switch if available from your VPN provider"
echo ""
echo "🔧 Docker/Container Notes:"
echo "   - TUN device automatically created for container compatibility"
echo "   - See main README for required Docker flags (--cap-add=NET_ADMIN)"
echo ""