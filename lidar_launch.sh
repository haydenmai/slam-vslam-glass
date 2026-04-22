#!/bin/bash

set -e

usage() {
    echo "Usage: ./lidar_launch.sh [build|up|down|restart|logs|shell]"
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
    echo "    ./lidar_launch.sh up"
    echo "    ./lidar_launch.sh build"
    echo "    ./lidar_launch.sh shell"
    exit 1
}

# check args
if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1

COMPOSE_FILE="docker-slam/docker-compose.lidar.yml"

# check compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: $COMPOSE_FILE not found. Run this script from the project root."
    exit 1
fi

echo "Compose  : $COMPOSE_FILE"
echo "Command  : $COMMAND"
echo ""

# run command
case $COMMAND in
    build)
        echo "Building image..."
        docker compose -f $COMPOSE_FILE build
        ;;
    up)
        echo "Building and starting container..."
        docker compose -f $COMPOSE_FILE build
        docker compose -f $COMPOSE_FILE up -d
        echo ""
        echo "Container started. To open a shell run:"
        echo "  ./lidar_launch.sh shell"
        ;;
    down)
        echo "Stopping container..."
        docker compose -f $COMPOSE_FILE down
        ;;
    restart)
        echo "Restarting container..."
        docker compose -f $COMPOSE_FILE down
        docker compose -f $COMPOSE_FILE up -d
        ;;
    logs)
        echo "Following container logs (Ctrl+C to exit)..."
        docker compose -f $COMPOSE_FILE logs -f
        ;;
    shell)
        echo "Opening shell in container..."
        docker compose -f $COMPOSE_FILE exec ros2 bash
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'."
        usage
        ;;
esac