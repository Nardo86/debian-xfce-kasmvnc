# Debian 12 + XFCE + KasmVNC Docker Container

A lightweight Docker container with Debian 12, XFCE desktop environment, and KasmVNC for web-based remote access.

## ⚠️ Disclaimer

This project was developed with the assistance of Claude AI (Anthropic). While functional, please be aware that:

- **Security considerations**: The configuration may not be optimized for production environments
- **Best practices**: Some settings might not follow enterprise-grade security standards  
- **Testing required**: Thoroughly test in your environment before production use
- **No warranty**: Use at your own risk - review all configurations before deployment
- **Community input welcome**: Issues and improvements are encouraged via GitHub issues/PRs

**Recommendation**: Have a security professional review the setup before production deployment.

## Features

- 🐧 **Debian 12** base system
- 🖥️ **XFCE4** desktop environment 
- 🌐 **KasmVNC** for web browser access
- 🔧 **Configurable** via environment variables
- 🔒 **Secure** with customizable passwords
- 🚀 **HTTP/HTTPS** modes for different deployment scenarios

---

# Using Pre-built Image

The easiest way to get started is using the pre-built image from Docker Hub.

### Quick Start

```bash
# Pull and run with defaults
docker run -d -p 8444:8444 nardo86/debian-xfce-kasmvnc:latest

# Access via browser: http://localhost:8444
# Username: user
# Password: password
```

### Docker Run Examples

**Basic usage:**
```bash
docker run -d \
  --name debian-xfce \
  -p 8444:8444 \
  nardo86/debian-xfce-kasmvnc:latest
```

**With custom password and shared folder:**
```bash
docker run -d \
  --name debian-xfce \
  -p 8444:8444 \
  -v /host/shared:/home/user/shared \
  -e VNC_PASSWORD="mysecretpassword" \
  -e ENABLE_HTTPS="false" \
  nardo86/debian-xfce-kasmvnc:latest
```

### Docker Compose

**Basic setup:**
```yaml
version: '3.8'
services:
  debian-xfce:
    image: nardo86/debian-xfce-kasmvnc:latest
    ports:
      - "8444:8444"
    environment:
      - VNC_PASSWORD=mysecretpassword
      - ENABLE_HTTPS=false
    volumes:
      - ./shared:/home/user/shared
    restart: unless-stopped
```

**Complete configuration:**
```yaml
version: '3.8'
services:
  debian-xfce:
    image: nardo86/debian-xfce-kasmvnc:latest
    container_name: debian-xfce-desktop
    ports:
      - "8444:8444"
    environment:
      # Required/Recommended
      - VNC_PASSWORD=your_secure_password
      - ENABLE_HTTPS=false
      
      # Optional (uncomment to customize)
      # - USER=user
      # - HOME=/home/user
      # - KASMVNC_VERBOSE=1
    volumes:
      - ./shared:/home/user/shared
      - ./config:/home/user/.vnc
    restart: unless-stopped
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VNC_PASSWORD` | `password` | Password for VNC access |
| `ENABLE_HTTPS` | `false` | Enable HTTPS mode (`true`/`false`) |
| `USER` | `user` | Username inside container |
| `HOME` | `/home/user` | User home directory |
| `KASMVNC_VERBOSE` | `1` | Enable verbose logging |

### HTTP vs HTTPS Modes

**HTTP Mode (Default - Recommended):**
- Set `ENABLE_HTTPS=false`
- Access via `http://localhost:8444`
- Ideal for reverse proxy setups
- SSL termination handled by proxy (nginx, traefik, etc.)

**HTTPS Mode:**
- Set `ENABLE_HTTPS=true`
- Access via `https://localhost:8444`
- Direct HTTPS access with self-signed certificates
- Browser will show certificate warning (accept to continue)

---

# Building from Source

If you want to customize or build the image yourself.

### Prerequisites

- Docker installed
- Git (to clone repository)
- 2GB+ free disk space

### Clone and Build

```bash
# Clone repository
git clone <repository-url>
cd <repository-name>

# Make script executable
chmod +x docker-manager.sh

# Build image
./docker-manager.sh build

# Run container
./docker-manager.sh run

# Access via browser: http://localhost:8444
```

### Custom Build Configuration

Create and configure environment variables:

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env

# Load environment
source .env

# Build with custom settings
./docker-manager.sh build
```

---

## Using docker-manager.sh

The included management script simplifies common operations.

### Available Commands

```bash
./docker-manager.sh help
```

**Main commands:**
- `build` - Build the Docker image (no cache)
- `run` - Start container with KasmVNC
- `debug` - Interactive mode for testing/troubleshooting
- `exec` - Enter running container
- `logs` - Show container logs
- `stop` - Stop and remove container
- `clean` - Remove image and container

**Publishing commands:**
- `login` - Login to Docker Hub
- `publish` - Publish image to Docker Hub
- `build-publish` - Build and publish in one step

### Usage Examples

```bash
# Development workflow
./docker-manager.sh build     # Build image
./docker-manager.sh run       # Start container
./docker-manager.sh logs      # Monitor logs
./docker-manager.sh exec      # Enter container
./docker-manager.sh stop      # Stop when done

# Troubleshooting
./docker-manager.sh debug     # Interactive shell

# Publishing (requires Docker Hub account)
export DOCKERHUB_USERNAME="yourusername"
./docker-manager.sh login
./docker-manager.sh build-publish
```

### Configuration

Set environment variables before building:

```bash
export VNC_PASSWORD="your_secure_password"
export ENABLE_HTTPS="false"
export DOCKERHUB_USERNAME="your_username"
./docker-manager.sh build
```

---

## Security Notes

**⚠️ Important Security Considerations:**

- **Change default passwords** - Never use default passwords in production
- **Use environment variables** for all sensitive configuration
- **Network security** - Consider firewall rules and network isolation
- **HTTPS certificates** - Use proper SSL certificates for production
- **User permissions** - Review sudo configuration and user privileges
- **Container security** - Consider using non-root containers in production
- **Regular updates** - Keep base images and packages updated
- **Audit configuration** - Have security professionals review before production use

**Production recommendations:**
- Use HTTPS mode with valid certificates
- Implement proper authentication/authorization 
- Use reverse proxy with SSL termination
- Enable logging and monitoring
- Regular security updates and patches

## Support & Donations

This is a community project maintained on a volunteer basis. 

**If this project helped you:**
- ⭐ Star the repository on GitHub
- 🐛 Report issues and bugs
- 🔧 Contribute improvements
- ☕ Feel free to consider donating if my work helped you! https://paypal.me/ErosNardi

**For issues:**
1. Check existing GitHub issues
2. Review security considerations
3. Test in isolated environment
4. Provide detailed reproduction steps
5. Be patient - this is maintained on volunteer basis

## Contributing

**Before contributing:**
- Review security implications of any changes
- Test thoroughly in isolated environments  
- Document any security considerations
- Follow responsible disclosure for security issues

**Process:**
1. Fork the repository
2. Create a feature branch
3. Make your changes with security in mind
4. Test thoroughly including security aspects
5. Update documentation if needed
6. Submit a pull request with detailed description

**Security issues**: Please report security vulnerabilities privately via GitHub's security advisory feature rather than public issues.

## Acknowledgments

- 🤖 Developed with assistance from Claude AI (Anthropic)
- 🐧 Based on Debian GNU/Linux
- 🖥️ Uses KasmVNC technology from Kasm Technologies
- 🎨 XFCE Desktop Environment
- 🙏 Community contributions and feedback

## License

MIT License - see LICENSE file for details.
