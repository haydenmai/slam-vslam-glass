#!/bin/bash

set -e

usage() {
    echo "Usage: ./start-container.sh [jetson|pi] [build|up|down|restart|logs]"
    echo ""
    echo "  Platform:"
    echo "    jetson    - Build/run for Jetson Orin Nano"
    echo "    pi        - Build/run for Raspberry Pi 5"
    echo ""
    echo "  Commands:"
    echo "    build     - Build the Docker image"
    echo "    up        - Build and start the container"
    echo "    down      - Stop the container"
    echo "    restart   - Restart the container"
    echo "    logs      - Follow container logs"
    echo "    shell     - Open a shell inside the running container"
    echo ""
    echo "  Examples:"
    echo "    ./start-container.sh pi up"
    echo "    ./start-container.sh jetson build"
    echo "    ./start-container.sh pi shell"
    exit 1
}

# check args
if [ $# -lt 2 ]; then
    usage
fi

PLATFORM=$1
COMMAND=$2

# set compose file based on platform
case $PLATFORM in
    jetson)
        COMPOSE_FILE="docker-jetson/docker-compose.yml"
        ;;
    pi)
        COMPOSE_FILE="docker-pi/docker-compose.yml"
        ;;
    *)
        echo "Error: Unknown platform '$PLATFORM'. Use 'jetson' or 'pi'."
        usage
        ;;
esac

# check compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: $COMPOSE_FILE not found. Run this script from the project root."
    exit 1
fi

echo "Platform : $PLATFORM"
echo "Compose  : $COMPOSE_FILE"
echo "Command  : $COMMAND"
echo ""

# run command
case $COMMAND in
    build)
        echo "Building $PLATFORM image..."
        docker compose -f $COMPOSE_FILE build
        ;;
    up)
        echo "Building and starting $PLATFORM container..."
        docker compose -f $COMPOSE_FILE build
        docker compose -f $COMPOSE_FILE up -d
        echo ""
        echo "Container started. To open a shell run:"
        echo "  ./start-container.sh $PLATFORM shell"
        ;;
    down)
        echo "Stopping $PLATFORM container..."
        docker compose -f $COMPOSE_FILE down
        ;;
    restart)
        echo "Restarting $PLATFORM container..."
        docker compose -f $COMPOSE_FILE down
        docker compose -f $COMPOSE_FILE up -d
        ;;
    logs)
        echo "Following $PLATFORM container logs (Ctrl+C to exit)..."
        docker compose -f $COMPOSE_FILE logs -f
        ;;
    shell)
        echo "Opening shell in $PLATFORM container..."
        docker compose -f $COMPOSE_FILE exec ros2 bash
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'."
        usage
        ;;
esac