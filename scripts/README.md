# Customization Scripts

This directory contains modular scripts to customize your Debian XFCE KasmVNC container with development tools and applications.

## 📂 Directory Structure

```
scripts/
├── base/              # Core development tools
├── development/       # Specialized development environments  
├── examples/          # Ready-to-use combinations
└── README.md         # This file
```

## 🚀 Quick Start

### Run individual scripts:
```bash
# Install Git
docker exec container-name bash /scripts/base/install-git.sh

# Install Node.js + npm
docker exec container-name bash /scripts/base/install-nodejs.sh

# Install Claude Code CLI
docker exec container-name bash /scripts/development/install-claude-code.sh
```

### Run example combinations:
```bash
# Complete Claude development environment
docker exec container-name bash /scripts/examples/setup-claude-vibe.sh
```

## 📋 Available Scripts

### Base Tools (`base/`)
- **`install-git.sh`** - Git version control + SSL certificates
- **`install-nodejs.sh`** - Node.js LTS + npm + yarn (with proper permissions)

### Development Tools (`development/`)
- **`install-claude-code.sh`** - Claude Code CLI for AI-assisted development

### Example Setups (`examples/`)
- **`setup-claude-vibe.sh`** - Complete environment: Git + Node.js + Claude Code

## 🔧 Usage Tips

1. **Run scripts as root** - Scripts auto-detect the container user (configurable username)
2. **Modular approach** - Install only what you need
3. **Safe to re-run** - Scripts check for existing installations
4. **Permission handling** - npm configured to avoid EACCES errors
5. **User detection** - Scripts automatically find the non-root user (UID 1000)

## 🤝 Contributing

We welcome contributions for additional development environments!

**Planned scripts:**
- `install-vscode.sh` - Visual Studio Code
- `install-dotnet.sh` - .NET development environment  
- `install-flutter.sh` - Flutter + Dart + Android SDK

**To contribute:**
1. Fork the repository
2. Create your script following the existing patterns
3. Test thoroughly in a container
4. Submit a pull request

## 📝 Script Guidelines

When creating new scripts:
- Start with `#!/bin/bash` and `set -e`
- Include user auto-detection: `USERNAME=$(getent passwd 1000 | cut -d: -f1)`
- Include descriptive echo messages with emojis
- Handle permissions correctly (use detected `$USERNAME`)
- Clean up package lists after apt operations
- Provide "Next steps" guidance
- Test for existing installations when possible