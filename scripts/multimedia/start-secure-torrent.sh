#!/bin/bash
#
# Secure Torrent Launcher with VPN Protection
# Preserves KasmVNC access while routing torrent traffic through VPN
# Based on haugene/docker-transmission-openvpn concepts
#
set -e

echo "🔒 Secure Torrent Launcher with VPN Protection"
echo "==============================================="
echo "   🎯 Routes torrent traffic through VPN"
echo "   🌐 Preserves KasmVNC HTTP access"
echo "   🛡️ Enhanced security with kill switch"
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

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ Error: This script must be run as root"
    echo "   Usage: sudo $0"
    exit 1
fi

# Function to find VPN config
find_vpn_config() {
    echo "🔍 Looking for OpenVPN configuration files..."
    
    if [ ! -d "$VPN_CONFIG_DIR" ]; then
        echo "❌ VPN configuration directory not found: $VPN_CONFIG_DIR"
        return 1
    fi
    
    local config_files=$(find "$VPN_CONFIG_DIR" -name "*.ovpn" -type f 2>/dev/null)
    
    if [ -z "$config_files" ]; then
        echo "❌ No .ovpn configuration files found in $VPN_CONFIG_DIR"
        return 1
    fi
    
    VPN_CONFIG_FILE=$(echo "$config_files" | head -1)
    echo "✅ Found VPN config: $(basename "$VPN_CONFIG_FILE")"
    return 0
}

# Function to create IMPROVED route preservation script
create_improved_route_script() {
    local script_path="/tmp/openvpn-route-up-improved.sh"
    
    cat > "$script_path" << 'EOF'
#!/bin/bash
# IMPROVED OpenVPN route-up script to preserve Docker and KasmVNC access
echo "🔧 [IMPROVED] Preserving network routes after VPN connection..."

# Get original gateway and device BEFORE any tunnel changes
DEFAULT_GW=$(ip route show 0.0.0.0/0 | grep -v tun | awk '{print $3}' | head -1)
ORIGINAL_DEV=$(ip route show 0.0.0.0/0 | grep -v tun | awk '{print $5}' | head -1)

if [ -n "$DEFAULT_GW" ] && [ -n "$ORIGINAL_DEV" ]; then
    echo "   Original gateway: $DEFAULT_GW via $ORIGINAL_DEV"
    
    # Preserve ALL Docker networks
    echo "   Adding Docker network routes..."
    for network in 172.16.0.0/12 192.168.0.0/16 10.0.0.0/8; do
        ip route add $network via $DEFAULT_GW dev $ORIGINAL_DEV 2>/dev/null || true
        echo "     Added: $network via $DEFAULT_GW dev $ORIGINAL_DEV"
    done
    
    # Specifically preserve the container's network
    CONTAINER_NETWORK=$(ip route show dev $ORIGINAL_DEV | grep kernel | head -1 | awk '{print $1}')
    if [ -n "$CONTAINER_NETWORK" ]; then
        ip route add $CONTAINER_NETWORK dev $ORIGINAL_DEV 2>/dev/null || true
        echo "     Preserved container network: $CONTAINER_NETWORK"
    fi
    
    # Preserve localhost
    ip route add 127.0.0.0/8 dev lo 2>/dev/null || true
    echo "     Preserved localhost routing"
    
    echo "✅ Enhanced Docker and KasmVNC routes preserved"
else
    echo "❌ Could not determine original gateway"
fi

echo "📋 Current routing table after VPN:"
ip route show | head -10
EOF
    
    chmod +x "$script_path"
    echo "$script_path"
}

# Function to check VPN connection
check_vpn_connection() {
    local max_attempts=30
    local attempt=1
    
    echo "🔍 Waiting for VPN connection..."
    
    while [ $attempt -le $max_attempts ]; do
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
    
    echo "❌ VPN connection timeout"
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

# Function to test KasmVNC access
test_kasmvnc_access() {
    echo "🌐 Testing KasmVNC accessibility..."
    
    if curl -s --connect-timeout 5 http://localhost:8444 >/dev/null 2>&1; then
        echo "✅ KasmVNC accessible on localhost:8444"
    else
        echo "⚠️  KasmVNC NOT accessible on localhost:8444"
    fi
    
    local container_ip=$(ip addr show eth0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)
    if [ -n "$container_ip" ]; then
        if curl -s --connect-timeout 5 http://$container_ip:8444 >/dev/null 2>&1; then
            echo "✅ KasmVNC accessible on $container_ip:8444"
        else
            echo "⚠️  KasmVNC NOT accessible on $container_ip:8444"
        fi
    fi
    echo ""
}

# Function to start VPN (like original but with improved routing)
start_vpn() {
    echo "🚀 Starting OpenVPN connection..."
    echo "   Config: $(basename "$VPN_CONFIG_FILE")"
    echo "   Will prompt for credentials..."
    echo ""
    
    # Create improved route preservation script
    local route_script=$(create_improved_route_script)
    
    # Start OpenVPN EXACTLY like the original script that works
    openvpn --config "$VPN_CONFIG_FILE" \
            --daemon \
            --writepid /var/run/openvpn.pid \
            --route-up "$route_script" \
            --script-security 2
    
    # Wait for connection
    if check_vpn_connection; then
        if test_vpn_internet; then
            echo "✅ VPN started successfully"
            test_kasmvnc_access
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
    
    sudo -u "$USERNAME" DISPLAY=:1 "$TORRENT_CLIENT" &
    local torrent_pid=$!
    
    echo "✅ $TORRENT_CLIENT started (PID: $torrent_pid)"
    return 0
}

# Function to monitor and cleanup
monitor_and_cleanup() {
    echo ""
    echo "🛡️ Monitoring VPN connection..."
    echo "   Press Ctrl+C to stop VPN and torrent client"
    
    trap cleanup_and_exit INT TERM
    
    while true; do
        if ! ip addr show tun0 >/dev/null 2>&1; then
            echo ""
            echo "⚠️ VPN connection lost! Stopping torrent client..."
            pkill -f "$TORRENT_CLIENT" || true
            echo "❌ Torrent client stopped due to VPN disconnection"
            break
        fi
        
        # Test KasmVNC every 30 seconds
        if [ $(($(date +%s) % 30)) -eq 0 ]; then
            if ! curl -s --connect-timeout 3 http://localhost:8444 >/dev/null 2>&1; then
                echo "⚠️ Warning: KasmVNC not accessible"
            fi
        fi
        
        sleep 5
    done
}

# Cleanup function
cleanup_and_exit() {
    echo ""
    echo "🛑 Shutting down secure torrent session..."
    
    echo "   Stopping torrent client..."
    pkill -f "$TORRENT_CLIENT" || true
    
    echo "   Stopping VPN connection..."
    if [ -f /var/run/openvpn.pid ]; then
        kill $(cat /var/run/openvpn.pid) || true
        rm -f /var/run/openvpn.pid
    fi
    pkill -f "openvpn" || true
    
    echo "   Cleaning up temporary files..."
    rm -f /tmp/openvpn-route-up-improved.sh
    
    echo "✅ Secure torrent session ended"
    exit 0
}

# Main execution
main() {
    echo "🎯 Starting procedure..."
    echo ""
    
    # Test KasmVNC access before VPN
    echo "📊 Testing KasmVNC accessibility BEFORE VPN:"
    test_kasmvnc_access
    
    # Find VPN config
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