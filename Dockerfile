FROM debian:12

# Variabili d'ambiente configurabili
ARG USERNAME=user
ARG USER_UID=1000
ARG USER_GID=1000
ARG VNC_PASSWORD=password
ARG ENABLE_HTTPS=false
ARG ENABLE_GPU=false
ARG ENABLE_SSH=false

# Aggiorna sistema e installa XFCE completo + Firefox + Terminal + SSH
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    xfce4 \
    xfce4-terminal \
    firefox-esr \
    dbus-x11 \
    sudo \
    curl \
    wget \
    nano \
    locales \
    openssh-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configura locale UTF-8 per l'intero sistema
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8

# Configura xfce4-terminal con ottimizzazioni
RUN mkdir -p /etc/xdg/xfce4/terminal && \
    echo '[Configuration]' > /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'CommandLoginShell=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'FontName=Monospace 10' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscAlwaysShowTabs=FALSE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscBell=FALSE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscBidiSupportPerCell=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscDefaultGeometry=80x24' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscInheritGeometry=FALSE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscMenubarDefault=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscMouseAutohide=FALSE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscRewrapOnResize=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscScrollAlternateScreen=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscScrollOnOutput=FALSE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscScrollOnKey=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscShowRelaunchDialog=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscShowUnsafePasteDialog=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscSlimTabs=FALSE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscTabCloseButtons=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscTabCloseMiddleClick=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscTabPosition=GTK_POS_TOP' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscHighlightUrls=TRUE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscMiddleClickOpensUri=FALSE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscCopyOnSelect=FALSE' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'MiscRightClickAction=TERMINAL_RIGHT_CLICK_ACTION_CONTEXT_MENU' >> /etc/xdg/xfce4/terminal/terminalrc && \
    echo 'ScrollingBar=TERMINAL_SCROLLBAR_RIGHT' >> /etc/xdg/xfce4/terminal/terminalrc

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

# Crea gruppo e utente non-root con bash come shell predefinita
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo "$USERNAME:$VNC_PASSWORD" | chpasswd \
    && usermod -aG sudo $USERNAME \
    && usermod -aG ssl-cert $USERNAME

# Configura sudo senza password
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configura SSH server (sempre installato, avvio condizionale)
RUN mkdir -p /var/run/sshd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config && \
    echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config

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
    echo '# Start SSH server if enabled' >> /home/$USERNAME/start-vnc.sh && \
    echo 'if [ "$ENABLE_SSH" = "true" ]; then' >> /home/$USERNAME/start-vnc.sh && \
    echo '    echo "Starting SSH server..."' >> /home/$USERNAME/start-vnc.sh && \
    echo '    sudo /usr/sbin/sshd -D &' >> /home/$USERNAME/start-vnc.sh && \
    echo '    echo "SSH server started on port 22"' >> /home/$USERNAME/start-vnc.sh && \
    echo '    echo "SSH access: ssh $USER@localhost -p 22"' >> /home/$USERNAME/start-vnc.sh && \
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
RUN chmod +x /scripts/base/*.sh /scripts/development/*.sh /scripts/multimedia/*.sh /scripts/examples/*.sh

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
ENV ENABLE_SSH=$ENABLE_SSH
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Esponi porta KasmVNC e SSH (condizionale)
EXPOSE 8444
EXPOSE 22

# Comando di default - avvia lo script di startup
CMD ["./start-vnc.sh"]
