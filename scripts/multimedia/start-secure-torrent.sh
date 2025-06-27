#!/bin/bash
#
# Secure Torrent Launcher with VPN Protection
# Security mechanisms inspired by haugene/docker-transmission-openvpn (GPL v3)
# https://github.com/haugene/docker-transmission-openvpn
# Adapted for qBittorrent + OpenVPN environment
#
set -e

echo "🔒 Secure Torrent Launcher with VPN Protection"
echo "=============================================="
echo "   Inspired by haugene/docker-transmission-openvpn"
echo "   Security concepts adapted for qBittorrent + OpenVPN"
echo ""
echo "⚠️  EXPERIMENTAL: Script in development phase"
echo "   - May cause VNC connection loss due to route changes"
echo "   - Use docker restart to recover if connection is lost"
echo "   - Please report issues and feedback for improvements"
echo ""

# Configuration
VPN_CONFIG_DIR="/etc/openvpn/configs"
VPN_CONFIG_FILE=""
TORRENT_CLIENT="qbittorrent"

# Auto-detect user
USERNAME=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$USERNAME" ]; then
    echo "❌ Error: Could not detect container user"
    exit 1
fi

# Check if running as root for VPN operations
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Error: This script must be run as root (VPN requires privileges)"
    echo "   Usage: sudo bash /scripts/multimedia/start-secure-torrent.sh"
    exit 1
fi

# Function to check VPN connection
check_vpn_connection() {
    local max_attempts=30
    local attempt=1
    
    echo "🔍 Waiting for VPN connection..."
    
    while [ $attempt -le $max_attempts ]; do
        # Check if tun interface exists and has IP
        if ip addr show tun0 >/dev/null 2>&1; then
            local tun_ip=$(ip addr show tun0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
            if [ -n "$tun_ip" ]; then
                echo "✅ VPN connected! Tunnel IP: $tun_ip"
                return 0
            fi
        fi
        
        echo "   Attempt $attempt/$max_attempts - VPN not ready yet..."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    echo "❌ VPN connection timeout after $max_attempts attempts"
    return 1
}

# Function to test internet through VPN
test_vpn_internet() {
    echo "🌐 Testing internet connection through VPN..."
    
    # Test external IP
    local external_ip=$(curl -s --max-time 10 ifconfig.me 2>/dev/null || echo "")
    if [ -n "$external_ip" ]; then
        echo "✅ Internet working through VPN. External IP: $external_ip"
        return 0
    else
        echo "❌ No internet access through VPN"
        return 1
    fi
}

# Function to find VPN config
find_vpn_config() {
    echo "🔍 Looking for OpenVPN configuration files..."
    
    # Check if config directory exists
    if [ ! -d "$VPN_CONFIG_DIR" ]; then
        echo "❌ VPN configuration directory not found: $VPN_CONFIG_DIR"
        return 1
    fi
    
    # Find .ovpn files
    local config_files=$(find "$VPN_CONFIG_DIR" -name "*.ovpn" -type f 2>/dev/null)
    
    if [ -z "$config_files" ]; then
        echo "❌ No .ovpn configuration files found in $VPN_CONFIG_DIR"
        echo ""
        echo "📋 To fix this:"
        echo "   1. Download OpenVPN config files from your VPN provider"
        echo "   2. Copy them to: $VPN_CONFIG_DIR/"
        echo "   3. Ensure files have .ovpn extension"
        echo ""
        echo "🔗 Popular VPN providers:"
        echo "   • ProtonVPN: https://account.protonvpn.com/downloads"
        echo "   • NordVPN: Member area → OpenVPN configs"
        echo "   • ExpressVPN: Manual config section"
        echo ""
        return 1
    fi
    
    # Use first config file found
    VPN_CONFIG_FILE=$(echo "$config_files" | head -1)
    echo "✅ Found VPN config: $(basename "$VPN_CONFIG_FILE")"
    return 0
}

# Function to create route preservation script
create_route_script() {
    local script_path="/tmp/openvpn-route-up.sh"
    
    cat > "$script_path" << 'EOF'
#!/bin/bash
# OpenVPN route-up script to preserve Docker network access
echo "🔧 Preserving Docker routes after VPN connection..."

# Get original gateway (not through tunnel)
DEFAULT_GW=$(ip route show 0.0.0.0/0 | grep -v tun | awk '{print $3}' | head -1)
ORIGINAL_DEV=$(ip route show 0.0.0.0/0 | grep -v tun | awk '{print $5}' | head -1)

if [ -n "$DEFAULT_GW" ] && [ -n "$ORIGINAL_DEV" ]; then
    echo "   Original gateway: $DEFAULT_GW via $ORIGINAL_DEV"
    
    # Preserve Docker networks
    for network in 172.17.0.0/16 172.18.0.0/16 172.19.0.0/16 172.20.0.0/16; do
        ip route add $network via $DEFAULT_GW dev $ORIGINAL_DEV 2>/dev/null || true
    done
    
    echo "✅ Docker routes preserved"
else
    echo "⚠️  Could not determine original gateway"
fi
EOF
    
    chmod +x "$script_path"
    echo "$script_path"
}

# Function to start VPN
start_vpn() {
    echo "🚀 Starting OpenVPN connection..."
    echo "   Config: $(basename "$VPN_CONFIG_FILE")"
    echo "   Attempting to preserve Docker network routes..."
    echo "   Press Ctrl+C to stop VPN and exit"
    echo ""
    
    # Create route preservation script
    local route_script=$(create_route_script)
    
    # Start OpenVPN with route script
    openvpn --config "$VPN_CONFIG_FILE" \
            --daemon \
            --writepid /var/run/openvpn.pid \
            --route-up "$route_script" \
            --script-security 2
    
    # Wait for connection
    if check_vpn_connection; then
        if test_vpn_internet; then
            return 0
        else
            echo "❌ VPN connected but no internet access"
            return 1
        fi
    else
        echo "❌ Failed to establish VPN connection"
        return 1
    fi
}

# Function to start torrent client
start_torrent_client() {
    echo "🏴‍☠️ Starting $TORRENT_CLIENT with VPN protection..."
    
    # Switch to detected user and start GUI application
    sudo -u "$USERNAME" DISPLAY=:1 "$TORRENT_CLIENT" &
    local torrent_pid=$!
    
    echo "✅ $TORRENT_CLIENT started (PID: $torrent_pid)"
    echo "   Access through desktop environment"
    return 0
}

# Function to monitor and cleanup
monitor_and_cleanup() {
    echo ""
    echo "🛡️ Monitoring VPN connection..."
    echo "   Press Ctrl+C to stop VPN and torrent client"
    
    # Trap cleanup on exit
    trap cleanup_and_exit INT TERM
    
    while true; do
        if ! ip addr show tun0 >/dev/null 2>&1; then
            echo ""
            echo "⚠️ VPN connection lost! Stopping torrent client for security..."
            pkill -f "$TORRENT_CLIENT" || true
            echo "❌ Torrent client stopped due to VPN disconnection"
            break
        fi
        sleep 5
    done
}

# Cleanup function
cleanup_and_exit() {
    echo ""
    echo "🛑 Shutting down secure torrent session..."
    
    # Stop torrent client
    echo "   Stopping torrent client..."
    pkill -f "$TORRENT_CLIENT" || true
    
    # Stop VPN
    echo "   Stopping VPN connection..."
    if [ -f /var/run/openvpn.pid ]; then
        kill $(cat /var/run/openvpn.pid) || true
        rm -f /var/run/openvpn.pid
    fi
    pkill -f "openvpn.*$VPN_CONFIG_FILE" || true
    
    # Clean up temporary files
    rm -f /tmp/openvpn-route-up.sh
    
    echo "✅ Secure torrent session ended"
    exit 0
}

# Main execution
main() {
    # Check for VPN config
    if ! find_vpn_config; then
        exit 1
    fi
    
    # Start VPN
    if ! start_vpn; then
        echo "❌ Failed to start VPN. Aborting for security."
        exit 1
    fi
    
    # Start torrent client
    if ! start_torrent_client; then
        echo "❌ Failed to start torrent client"
        cleanup_and_exit
    fi
    
    # Monitor connection
    monitor_and_cleanup
}

# Run main function
main "$@"