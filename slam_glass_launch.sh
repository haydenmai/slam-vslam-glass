#!/bin/bash

set -e

usage() {
    echo "Usage: ./slam_glass_launch.sh [build|up|down|restart|logs|shell|roscore|slam_glass|all]"
    echo ""
    echo "  Commands:"
    echo "    build       - Build the SLAM Glass Docker image"
    echo "    up          - Build and start the container"
    echo "    down        - Stop the container"
    echo "    restart     - Restart the container"
    echo "    logs        - Follow container logs"
    echo "    shell       - Open a shell inside the running container"
    echo "    roscore     - Start only ROS1 master (roscore)"
    echo "    slam_glass  - Start only SLAM Glass (requires external roscore)"
    echo "    all         - Start both ROS1 master and SLAM Glass"
    echo ""
    echo "  Examples:"
    echo "    ./slam_glass_launch.sh build"
    echo "    ./slam_glass_launch.sh up"
    echo "    ./slam_glass_launch.sh shell"
    echo "    ./slam_glass_launch.sh all"
    exit 1
}

# check args
if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1

COMPOSE_FILE="docker-slam/docker-compose.slam-glass.yml"
SERVICE_NAME="slam_glass"
IMAGE_NAME="local/slam-glass:noetic"

# check compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Error: $COMPOSE_FILE not found. Run this script from the project root."
    exit 1
fi

echo "Compose  : $COMPOSE_FILE"
echo "Service  : $SERVICE_NAME"
echo "Command  : $COMMAND"
echo ""

# run command
case $COMMAND in
    build)
        echo "Building SLAM Glass image..."
        docker build -f docker-slam/Dockerfile.slam_glass -t $IMAGE_NAME .
        ;;
    up)
        echo "Building and starting container..."
        docker build -f docker-slam/Dockerfile.slam_glass -t $IMAGE_NAME .
        docker compose -f $COMPOSE_FILE up -d $SERVICE_NAME
        echo ""
        echo "Container started. To open a shell run:"
        echo "  ./slam_glass_launch.sh shell"
        echo ""
        echo "To start SLAM Glass, run:"
        echo "  ./slam_glass_launch.sh all"
        ;;
    down)
        echo "Stopping container..."
        docker compose -f $COMPOSE_FILE down
        ;;
    restart)
        echo "Restarting container..."
        docker compose -f $COMPOSE_FILE down
        docker compose -f $COMPOSE_FILE up -d $SERVICE_NAME
        ;;
    logs)
        echo "Following container logs (Ctrl+C to exit)..."
        docker compose -f $COMPOSE_FILE logs -f $SERVICE_NAME
        ;;
    shell)
        echo "Opening shell in container..."
        docker compose -f $COMPOSE_FILE up -d $SERVICE_NAME
        docker compose -f $COMPOSE_FILE exec $SERVICE_NAME bash
        ;;
    roscore)
        echo "Starting ROS1 master (roscore)..."
        docker run --rm --network=host --name slam_glass_roscore $IMAGE_NAME roscore
        ;;
    slam_glass)
        echo "Starting SLAM Glass (requires external roscore)..."
        docker run --rm --network=host --name slam_glass_node $IMAGE_NAME slam_glass
        ;;
    all)
        echo "Starting ROS1 master and SLAM Glass..."
        docker run --rm --network=host --name slam_glass_all $IMAGE_NAME all
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'."
        usage
        ;;
esac
