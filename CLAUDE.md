# Claude Code Assistant Memory

This file contains patterns, guidelines, and technical details to assist Claude Code when working on this project.

## Project Overview

**debian-xfce-kasmvnc** is a Docker container providing a full Debian desktop environment with XFCE and KasmVNC for web-based remote access.

### Key Characteristics:
- **Base**: Debian 12 (Bookworm)
- **Desktop**: XFCE4 
- **Remote Access**: KasmVNC (web-based VNC)
- **User**: Configurable via `ARG USERNAME=user` (default: "user", UID: 1000)
- **Target**: Development environments, remote workstations

## Container User Management

### Critical Pattern: Auto-User Detection
```bash
# Always use this pattern in scripts that modify user files
USERNAME=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$USERNAME" ]; then
    echo "❌ Error: Could not detect container user"
    exit 1
fi
echo "👤 Detected user: $USERNAME"
```

### When to Use Auto-Detection:
- ✅ Scripts that create/modify files in `/home/$USERNAME/`
- ✅ Scripts that change user permissions
- ✅ Scripts that configure user-specific settings
- ❌ Scripts that only install system packages
- ❌ Orchestrator scripts that call other scripts

### User Context:
- **Username**: Configurable (default: `user`)
- **UID/GID**: 1000:1000 
- **Home**: `/home/$USERNAME/`
- **Sudo**: NOPASSWD:ALL enabled
- **Groups**: sudo, ssl-cert

## Customization Scripts Guidelines

### Script Template:
```bash
#!/bin/bash
set -e

echo "🔧 Installing [TOOL_NAME]..."

# Auto-detect user if script modifies user files
USERNAME=$(getent passwd 1000 | cut -d: -f1)
if [ -z "$USERNAME" ]; then
    echo "❌ Error: Could not detect container user"
    exit 1
fi
echo "👤 Detected user: $USERNAME"

# Update package list
apt-get update

# Install packages
apt-get install -y package1 package2

# User-specific configuration
chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "✅ [TOOL_NAME] installation completed!"
echo ""
echo "📋 Next steps:"
echo "   - Additional configuration steps"
echo ""
```

## README Documentation Standards

### Required Sections:
1. **Project Status** - Community-maintained disclaimer
2. **Features** - Bullet points with emojis
3. **Quick Start** - Docker run + Docker Compose examples
4. **Configuration** - Environment variables table
5. **Troubleshooting** - Common issues and solutions
6. **AI Disclaimer** - Claude assistance acknowledgment
7. **Support & Donations** - PayPal link: https://paypal.me/ErosNardi

### Style Guidelines:
- Use emojis for visual organization (🔧 🚀 ✅ ❌ 📋)
- Include Docker Compose examples
- Provide troubleshooting sections
- Add "Next steps" in installation outputs
k
This memory file should be updated as new patterns emerge or existing ones evolve.
