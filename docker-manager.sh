#!/bin/bash

# Configurazione
IMAGE_NAME="debian-xfce-clean"
CONTAINER_NAME="debian-xfce-container"
USERNAME="myuser"
VNC_PASSWORD="${VNC_PASSWORD:-mypassword}"  # Usa variabile d'ambiente o default
ENABLE_HTTPS="${ENABLE_HTTPS:-false}"       # Usa variabile d'ambiente o default

# Configurazione Docker Hub (usa variabili d'ambiente)
DOCKERHUB_USERNAME="${DOCKERHUB_USERNAME:-}"  # Imposta con: export DOCKERHUB_USERNAME="your_username"
DOCKERHUB_REPO="${DOCKERHUB_REPO:-debian-xfce-kasmvnc}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Funzione per build senza cache
build() {
    echo "=== BUILDING DOCKER IMAGE (NO CACHE) ==="
    echo "Username: $USERNAME"
    echo "HTTPS Mode: $ENABLE_HTTPS"
    echo "Password: [hidden for security]"
    
    docker build --no-cache \
        --build-arg USERNAME=$USERNAME \
        --build-arg VNC_PASSWORD="$VNC_PASSWORD" \
        --build-arg ENABLE_HTTPS=$ENABLE_HTTPS \
        -t $IMAGE_NAME .
    echo "Build completed!"
}

# Funzione per avvio container
run_container() {
    echo "=== STARTING CONTAINER WITH KASMVNC ==="
    
    # Determina il protocollo per i messaggi
    if [ "$ENABLE_HTTPS" = "true" ]; then
        PROTOCOL="https"
    else
        PROTOCOL="http"
    fi
    
    docker run -d \
        --name $CONTAINER_NAME \
        -p 8444:8444 \
        -v $HOME/docker-shared:/home/$USERNAME/shared \
        -e VNC_PASSWORD="$VNC_PASSWORD" \
        -e ENABLE_HTTPS="$ENABLE_HTTPS" \
        $IMAGE_NAME
    
    echo "KasmVNC started!"
    echo "Access: $PROTOCOL://localhost:8444"
    echo "Username: $USERNAME"
    echo "Password: [configured]"
    echo ""
    echo "Use 'logs' to see startup progress"
    echo "Use 'exec' to enter the container"
}

# Funzione per debug interattivo
debug() {
    echo "=== DEBUG MODE - INTERACTIVE ==="
    docker run -it --rm \
        --name $CONTAINER_NAME-debug \
        -p 8444:8444 \
        -v $HOME/docker-shared:/home/$USERNAME/shared \
        -e VNC_PASSWORD="$VNC_PASSWORD" \
        -e ENABLE_HTTPS="$ENABLE_HTTPS" \
        $IMAGE_NAME /bin/bash
}

# Funzione per entrare nel container
exec_container() {
    echo "=== ENTERING CONTAINER ==="
    if ! docker ps | grep -q $CONTAINER_NAME; then
        echo "Error: Container $CONTAINER_NAME is not running"
        echo "Start it first with: $0 run"
        exit 1
    fi
    docker exec -it $CONTAINER_NAME /bin/bash
}

# Funzione per vedere i logs
show_logs() {
    echo "=== CONTAINER LOGS ==="
    if ! docker ps -a | grep -q $CONTAINER_NAME; then
        echo "Error: Container $CONTAINER_NAME not found"
        exit 1
    fi
    docker logs -f $CONTAINER_NAME
}

# Funzione per fermare
stop() {
    echo "=== STOPPING CONTAINER ==="
    docker stop $CONTAINER_NAME 2>/dev/null || echo "Container not running"
    docker rm $CONTAINER_NAME 2>/dev/null || echo "Container not found"
}

# Funzione per pulizia completa
clean() {
    echo "=== CLEANING UP ==="
    # Ferma e rimuovi container
    docker stop $CONTAINER_NAME 2>/dev/null
    docker rm $CONTAINER_NAME 2>/dev/null
    docker stop $CONTAINER_NAME-debug 2>/dev/null
    docker rm $CONTAINER_NAME-debug 2>/dev/null
    
    # Rimuovi immagine
    docker rmi $IMAGE_NAME 2>/dev/null || echo "Image not found"
    
    echo "Cleanup completed!"
}

# Funzione per login Docker Hub
docker_login() {
    echo "=== DOCKER HUB LOGIN ==="
    
    if [ -z "$DOCKERHUB_USERNAME" ]; then
        echo "Error: DOCKERHUB_USERNAME not set"
        echo "Set with: export DOCKERHUB_USERNAME='your_username'"
        exit 1
    fi
    
    echo "Logging in to Docker Hub as: $DOCKERHUB_USERNAME"
    docker login -u $DOCKERHUB_USERNAME
}

# Funzione per tag e push
docker_publish() {
    echo "=== PUBLISHING TO DOCKER HUB ==="
    
    # Verifica configurazione
    if [ -z "$DOCKERHUB_USERNAME" ]; then
        echo "Error: DOCKERHUB_USERNAME not set"
        echo "Set with: export DOCKERHUB_USERNAME='your_username'"
        exit 1
    fi
    
    # Controlla se l'immagine esiste
    if ! docker images | grep -q $IMAGE_NAME; then
        echo "Error: Image $IMAGE_NAME not found. Run 'build' first."
        exit 1
    fi
    
    # Crea il tag per Docker Hub
    FULL_IMAGE_NAME="$DOCKERHUB_USERNAME/$DOCKERHUB_REPO:$IMAGE_TAG"
    echo "Tagging image as: $FULL_IMAGE_NAME"
    docker tag $IMAGE_NAME $FULL_IMAGE_NAME
    
    # Push dell'immagine
    echo "Pushing to Docker Hub..."
    docker push $FULL_IMAGE_NAME
    
    echo "✅ Image published successfully!"
    echo "Pull command: docker pull $FULL_IMAGE_NAME"
    echo "Docker Hub URL: https://hub.docker.com/r/$DOCKERHUB_USERNAME/$DOCKERHUB_REPO"
}

# Help
show_help() {
    echo "Docker XFCE + KasmVNC Manager"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build        - Build image (no cache)"
    echo "  run          - Start container with KasmVNC"
    echo "  debug        - Start interactive container for testing"
    echo "  exec         - Enter running container"
    echo "  logs         - Show container logs"
    echo "  stop         - Stop and remove container"
    echo "  clean        - Remove everything (image + container)"
    echo "  login        - Login to Docker Hub"
    echo "  publish      - Tag and push image to Docker Hub"
    echo "  build-publish - Build and publish in one command"
    echo "  help         - Show this help"
    echo ""
    echo "Configuration:"
    echo "  USERNAME: $USERNAME"
    echo "  VNC_PASSWORD: $([ -n "$VNC_PASSWORD" ] && echo '[set via env]' || echo '[using default]')"
    echo "  ENABLE_HTTPS: $ENABLE_HTTPS"
    echo "  IMAGE: $IMAGE_NAME"
    echo "  PORT: 8444"
    echo ""
    echo "Docker Hub (set via environment variables):"
    echo "  DOCKERHUB_USERNAME: $([ -n "$DOCKERHUB_USERNAME" ] && echo "$DOCKERHUB_USERNAME" || echo '[not set]')"
    echo "  DOCKERHUB_REPO: $DOCKERHUB_REPO"
    echo "  IMAGE_TAG: $IMAGE_TAG"
    echo ""
    echo "Environment variables:"
    echo "  export DOCKERHUB_USERNAME='your_username'"
    echo "  export VNC_PASSWORD='your_secure_password'"
    echo "  export ENABLE_HTTPS='true'  # or 'false'"
}

# Menu principale
case "$1" in
    build)
        build
        ;;
    run)
        run_container
        ;;
    debug)
        debug
        ;;
    exec)
        exec_container
        ;;
    logs)
        show_logs
        ;;
    stop)
        stop
        ;;
    clean)
        clean
        ;;
    login)
        docker_login
        ;;
    publish)
        docker_publish
        ;;
    build-publish)
        build
        docker_publish
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo "Error: Unknown command '$1'"
        echo ""
        show_help
        exit 1
        ;;
esac
