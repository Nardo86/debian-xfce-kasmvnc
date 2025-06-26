FROM debian:12

# Variabili d'ambiente configurabili
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000
ARG VNC_PASSWORD=password
ARG ENABLE_HTTPS=false
ARG ENABLE_GPU=false

# Aggiorna sistema e installa XFCE completo + Firefox
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    xfce4 \
    firefox-esr \
    dbus-x11 \
    sudo \
    curl \
    wget \
    nano \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installa KasmVNC ultima versione da GitHub
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then \
        KASMVNC_ARCH="amd64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        KASMVNC_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    wget -O /tmp/kasmvnc.deb \
    "$(curl -s https://api.github.com/repos/kasmtech/KasmVNC/releases/latest | \
    grep browser_download_url | grep bookworm.*${KASMVNC_ARCH}.deb | head -1 | cut -d '"' -f 4)" && \
    apt-get update && \
    apt-get install -y /tmp/kasmvnc.deb && \
    rm /tmp/kasmvnc.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Crea gruppo e utente non-root
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME:$USERNAME" | chpasswd \
    && usermod -aG sudo $USERNAME \
    && usermod -aG ssl-cert $USERNAME

# Configura sudo senza password
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Crea directory VNC e file xstartup
RUN mkdir -p /home/$USERNAME/.vnc && \
    echo '#!/bin/sh' > /home/$USERNAME/.vnc/xstartup && \
    echo 'set -x' >> /home/$USERNAME/.vnc/xstartup && \
    echo 'export XDG_CURRENT_DESKTOP=XFCE' >> /home/$USERNAME/.vnc/xstartup && \
    echo 'export XDG_SESSION_DESKTOP=XFCE' >> /home/$USERNAME/.vnc/xstartup && \
    echo 'dbus-launch --exit-with-session startxfce4' >> /home/$USERNAME/.vnc/xstartup && \
    chmod +x /home/$USERNAME/.vnc/xstartup && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME/.vnc

# Crea file .Xauthority e script di avvio completo
RUN touch /home/$USERNAME/.Xauthority && \
    chown $USERNAME:$USERNAME /home/$USERNAME/.Xauthority && \
    echo '#!/bin/bash' > /home/$USERNAME/start-vnc.sh && \
    echo 'echo "=== KasmVNC Startup Script ==="' >> /home/$USERNAME/start-vnc.sh && \
    echo 'echo "User: $USER"' >> /home/$USERNAME/start-vnc.sh && \
    echo 'echo "HTTPS Mode: $ENABLE_HTTPS"' >> /home/$USERNAME/start-vnc.sh && \
    echo '' >> /home/$USERNAME/start-vnc.sh && \
    echo '# Create VNC user if not exists' >> /home/$USERNAME/start-vnc.sh && \
    echo 'if ! strings ~/.kasmpasswd 2>/dev/null | grep -q "$USER"; then' >> /home/$USERNAME/start-vnc.sh && \
    echo '    echo "Creating VNC user: $USER"' >> /home/$USERNAME/start-vnc.sh && \
    echo '    echo -e "$VNC_PASSWORD\n$VNC_PASSWORD\n" | vncpasswd -u "$USER" -w' >> /home/$USERNAME/start-vnc.sh && \
    echo '    echo "VNC user created successfully"' >> /home/$USERNAME/start-vnc.sh && \
    echo 'else' >> /home/$USERNAME/start-vnc.sh && \
    echo '    echo "VNC user already exists"' >> /home/$USERNAME/start-vnc.sh && \
    echo 'fi' >> /home/$USERNAME/start-vnc.sh && \
    echo '' >> /home/$USERNAME/start-vnc.sh && \
    echo '# Create kasmvnc.yaml configuration' >> /home/$USERNAME/start-vnc.sh && \
    echo 'mkdir -p ~/.vnc' >> /home/$USERNAME/start-vnc.sh && \
    echo 'if [ "$ENABLE_HTTPS" = "false" ]; then' >> /home/$USERNAME/start-vnc.sh && \
    echo '    echo "Creating HTTP configuration (SSL disabled)"' >> /home/$USERNAME/start-vnc.sh && \
    echo '    cat > ~/.vnc/kasmvnc.yaml << EOF' >> /home/$USERNAME/start-vnc.sh && \
    echo 'logging:' >> /home/$USERNAME/start-vnc.sh && \
    echo '  log_writer_name: all' >> /home/$USERNAME/start-vnc.sh && \
    echo '  log_dest: logfile' >> /home/$USERNAME/start-vnc.sh && \
    echo '  level: 100' >> /home/$USERNAME/start-vnc.sh && \
    echo 'network:' >> /home/$USERNAME/start-vnc.sh && \
    echo '  interface: 0.0.0.0' >> /home/$USERNAME/start-vnc.sh && \
    echo '  ssl:' >> /home/$USERNAME/start-vnc.sh && \
    echo '    require_ssl: false' >> /home/$USERNAME/start-vnc.sh && \
    echo '  udp:' >> /home/$USERNAME/start-vnc.sh && \
    echo '    public_ip: 127.0.0.1' >> /home/$USERNAME/start-vnc.sh && \
    echo 'EOF' >> /home/$USERNAME/start-vnc.sh && \
    echo '    # Add GPU configuration if enabled' >> /home/$USERNAME/start-vnc.sh && \
    echo '    if [ "$ENABLE_GPU" = "true" ]; then' >> /home/$USERNAME/start-vnc.sh && \
    echo '        echo "desktop:" >> ~/.vnc/kasmvnc.yaml' >> /home/$USERNAME/start-vnc.sh && \
    echo '        echo "  gpu:" >> ~/.vnc/kasmvnc.yaml' >> /home/$USERNAME/start-vnc.sh && \
    echo '        echo "    hw3d: true" >> ~/.vnc/kasmvnc.yaml' >> /home/$USERNAME/start-vnc.sh && \
    echo '        echo "    drinode: /dev/dri/renderD128" >> ~/.vnc/kasmvnc.yaml' >> /home/$USERNAME/start-vnc.sh && \
    echo '        echo "GPU acceleration enabled (DRI3)"' >> /home/$USERNAME/start-vnc.sh && \
    echo '    else' >> /home/$USERNAME/start-vnc.sh && \
    echo '        echo "GPU acceleration disabled"' >> /home/$USERNAME/start-vnc.sh && \
    echo '    fi' >> /home/$USERNAME/start-vnc.sh && \
    echo '    PROTOCOL="http"' >> /home/$USERNAME/start-vnc.sh && \
    echo 'else' >> /home/$USERNAME/start-vnc.sh && \
    echo '    echo "Using default HTTPS configuration"' >> /home/$USERNAME/start-vnc.sh && \
    echo '    # Let KasmVNC create its default config' >> /home/$USERNAME/start-vnc.sh && \
    echo '    PROTOCOL="https"' >> /home/$USERNAME/start-vnc.sh && \
    echo 'fi' >> /home/$USERNAME/start-vnc.sh && \
    echo '' >> /home/$USERNAME/start-vnc.sh && \
    echo '# Start VNC server' >> /home/$USERNAME/start-vnc.sh && \
    echo 'echo "Starting VNC server..."' >> /home/$USERNAME/start-vnc.sh && \
    echo 'echo "Access: ${PROTOCOL}://localhost:8444"' >> /home/$USERNAME/start-vnc.sh && \
    echo 'echo "Username: $USER"' >> /home/$USERNAME/start-vnc.sh && \
    echo 'echo "Password: [hidden for security]"' >> /home/$USERNAME/start-vnc.sh && \
    echo 'echo ""' >> /home/$USERNAME/start-vnc.sh && \
    echo 'exec vncserver -select-de xfce -fg' >> /home/$USERNAME/start-vnc.sh && \
    chmod +x /home/$USERNAME/start-vnc.sh && \
    chown $USERNAME:$USERNAME /home/$USERNAME/start-vnc.sh

# Copy customization scripts
COPY scripts/ /scripts/
RUN chmod +x /scripts/base/*.sh /scripts/development/*.sh /scripts/examples/*.sh

# Imposta directory di lavoro e proprietario
WORKDIR /home/$USERNAME
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

# Passa all'utente non-root
USER $USERNAME

# Imposta le variabili d'ambiente
ENV USER=$USERNAME
ENV HOME=/home/$USERNAME
ENV VNC_PASSWORD=$VNC_PASSWORD
ENV ENABLE_HTTPS=$ENABLE_HTTPS
ENV ENABLE_GPU=$ENABLE_GPU

# Esponi porta KasmVNC
EXPOSE 8444

# Comando di default - avvia lo script di startup
CMD ["./start-vnc.sh"]
