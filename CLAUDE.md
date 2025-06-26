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

### Critical Rule: Dual Privilege Management
Scripts must handle both execution contexts:
- **System operations** (apt-get, file cleanup): Use `$SUDO` variable
- **User operations** (npm, user configs): Always target detected user with `sudo -u $USERNAME`

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

# Check if running as root, if not use sudo for system operations
if [ "$EUID" -ne 0 ]; then
    SUDO="sudo"
else
    SUDO=""
fi

# Update package list (system operation)
$SUDO apt-get update

# Install packages (system operation)
$SUDO apt-get install -y package1 package2

# User-specific configuration (always as target user)
$SUDO chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

# Clean up (system operation)
$SUDO apt-get clean
$SUDO rm -rf /var/lib/apt/lists/*

echo "✅ [TOOL_NAME] installation completed!"
echo ""
echo "📋 Next steps:"
echo "   - Additional configuration steps"
echo ""
```

### npm/Node.js Specific Pattern:
```bash
# CRITICAL: npm operations must ALWAYS run as target user, never as root
if [ "$EUID" -eq 0 ]; then
    # Running as root, switch to target user for npm
    sudo -u $USERNAME bash -c 'export PATH=/home/'$USERNAME'/.npm-global/bin:$PATH && npm install -g package'
else
    # Running as user, install directly
    export PATH=/home/$USERNAME/.npm-global/bin:$PATH && npm install -g package
fi
```

### Execution Context Support:
- ✅ `docker exec container bash /scripts/script.sh` (as root)
- ✅ `docker exec --user user container bash /scripts/script.sh` (as user)
- ❌ Never assume execution context - always detect and adapt

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
