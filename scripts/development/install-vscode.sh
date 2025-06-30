#!/bin/bash
set -e

echo "📝 Installing Visual Studio Code..."

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
echo "📦 Updating package list..."
$SUDO apt-get update

# Install required dependencies
echo "🔧 Installing dependencies..."
$SUDO apt-get install -y \
    wget \
    gpg \
    software-properties-common \
    apt-transport-https

# Add Microsoft GPG key
echo "🔑 Adding Microsoft GPG key..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
$SUDO install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
$SUDO sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Clean up temporary GPG key file
rm -f packages.microsoft.gpg

# Update package list with new repository
echo "🔄 Updating package list with VS Code repository..."
$SUDO apt-get update

# Install Visual Studio Code
echo "💻 Installing Visual Studio Code..."
$SUDO apt-get install -y code

# Verify installation
if command -v code >/dev/null 2>&1; then
    echo "✅ Visual Studio Code installed successfully!"
    echo "📍 Version: $(code --version | head -1)"
else
    echo "❌ VS Code installation failed"
    exit 1
fi

# Create desktop shortcut
echo "🖥️ Creating desktop shortcut..."
DESKTOP_DIR="/home/$USERNAME/Desktop"
$SUDO mkdir -p "$DESKTOP_DIR"

cat > "/tmp/vscode.desktop" << EOF
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=/usr/bin/code --no-sandbox --unity-launch %F
Icon=vscode
Type=Application
StartupNotify=false
StartupWMClass=Code
Categories=Utility;TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-code-workspace;
Actions=new-empty-window;
Keywords=vscode;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=/usr/bin/code --no-sandbox --new-window %F
Icon=vscode
EOF

$SUDO mv "/tmp/vscode.desktop" "$DESKTOP_DIR/Visual Studio Code.desktop"
$SUDO chmod +x "$DESKTOP_DIR/Visual Studio Code.desktop"
$SUDO chown $USERNAME:$USERNAME "$DESKTOP_DIR/Visual Studio Code.desktop"

# Install common VS Code extensions for container development
echo "🔌 Installing useful VS Code extensions..."
$SUDO -u $USERNAME code --install-extension ms-vscode-remote.remote-containers || echo "⚠️  Remote Containers extension install failed"
$SUDO -u $USERNAME code --install-extension ms-vscode.vscode-json || echo "⚠️  JSON extension install failed"
$SUDO -u $USERNAME code --install-extension ms-vscode-remote.remote-ssh || echo "⚠️  Remote SSH extension install failed"
$SUDO -u $USERNAME code --install-extension ms-python.python || echo "⚠️  Python extension install failed"
$SUDO -u $USERNAME code --install-extension ms-vscode.cpptools || echo "⚠️  C/C++ extension install failed"

echo ""
echo "✅ Visual Studio Code installation completed!"
echo ""
echo "📋 Installation Summary:"
echo "   • VS Code installed from official Microsoft repository"
echo "   • Desktop shortcut created"
echo "   • Common development extensions installed"
echo ""
echo "🚀 Usage:"
echo "   • Launch from desktop: Double-click 'Visual Studio Code' icon"
echo "   • Launch from terminal: code"
echo "   • Launch with file: code /path/to/file"
echo "   • Launch in directory: code /path/to/directory"
echo ""
echo "🔧 Container-specific notes:"
echo "   • VS Code runs with --no-sandbox flag for container compatibility"
echo "   • Remote development extensions included for advanced workflows"
echo "   • Integrated terminal works within the container environment"
echo ""
echo "💡 Recommended next steps:"
echo "   • Configure VS Code settings: code --install-extension settings-sync"
echo "   • Install language-specific extensions as needed"
echo "   • Set up integrated Git workflow"
echo ""