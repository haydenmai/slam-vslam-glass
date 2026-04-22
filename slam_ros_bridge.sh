#!/bin/bash

set -e

usage() {
    echo "Usage: ./slam_ros_bridge.sh [build|up|down|restart|logs|shell]"
    echo ""
    echo "  Commands:"
    echo "    build    - Build the ros1_bridge Docker image"
    echo "    up       - Build and start ros1_bridge"
    echo "    down     - Stop ros1_bridge container"
    echo "    restart  - Restart ros1_bridge"
    echo "    logs     - Follow ros1_bridge logs"
    echo "    shell    - Open a shell inside ros1_bridge"
    echo ""
    echo "  Examples:"
    echo "    ./slam_ros_bridge.sh up"
    echo "    ./slam_ros_bridge.sh shell"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1
COMPOSE_FILE="docker-slam/docker-compose.bridge.yml"
SERVICE_NAME="ros1_bridge"

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: $COMPOSE_FILE not found. Run this script from the project root."
    exit 1
fi

echo "Compose  : $COMPOSE_FILE"
echo "Service  : $SERVICE_NAME"
echo "Command  : $COMMAND"
echo ""

case $COMMAND in
    build)
        echo "Building bridge image..."
        docker compose -f $COMPOSE_FILE build $SERVICE_NAME
        ;;
    up)
        echo "Building and starting ros1_bridge..."
        docker compose -f $COMPOSE_FILE build $SERVICE_NAME
        docker compose -f $COMPOSE_FILE up -d $SERVICE_NAME
        ;;
    down)
        echo "Stopping ros1_bridge..."
        docker compose -f $COMPOSE_FILE down
        ;;
    restart)
        echo "Restarting ros1_bridge..."
        docker compose -f $COMPOSE_FILE up -d --build $SERVICE_NAME
        ;;
    logs)
        echo "Following ros1_bridge logs (Ctrl+C to exit)..."
        docker compose -f $COMPOSE_FILE logs -f $SERVICE_NAME
        ;;
    shell)
        echo "Opening shell in ros1_bridge..."
        docker compose -f $COMPOSE_FILE up -d $SERVICE_NAME
        docker compose -f $COMPOSE_FILE exec $SERVICE_NAME bash
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'."
        usage
        ;;
esac
