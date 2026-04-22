#!/bin/bash

set -e

usage() {
    echo "Usage: ./slam_rosbag_launch.sh [build|up|down|restart|logs|shell|pipeline|pipeline-stop]"
    echo ""
    echo "  Commands:"
    echo "    build     - Build the Docker image"
    echo "    up        - Build and start the container"
    echo "    down      - Stop the container"
    echo "    restart   - Restart the container"
    echo "    logs      - Follow container logs"
    echo "    shell     - Open a shell inside the running container"
    echo "    pipeline  - Run full rosbag pipeline in one command"
    echo "    pipeline-stop - Stop any leftover pipeline processes"
    echo ""
    echo "  Examples:"
    echo "    ./slam_rosbag_launch.sh up"
    echo "    ./slam_rosbag_launch.sh build"
    echo "    ./slam_rosbag_launch.sh shell"
    echo "    ./slam_rosbag_launch.sh pipeline /home/linda/lidar_bags/slam_bag20 1.0"
    echo "    ./slam_rosbag_launch.sh pipeline-stop"
    exit 1
}

# check args
if [ $# -lt 1 ]; then
    usage
fi

COMMAND=$1

COMPOSE_FILE="docker-slam/docker-compose.ros2-bag.yml"
SERVICE_NAME="ros2_bag"
DEFAULT_BAG_PATH="/home/linda/lidar_bags/slam_bag20"
DEFAULT_BAG_RATE="1.0"

cleanup_pipeline_processes() {
    docker compose -f "$COMPOSE_FILE" exec -T "$SERVICE_NAME" bash -lc "
pkill -f 'rslidar_sdk_node' >/dev/null 2>&1 || true
pkill -f 'static_transform_publisher' >/dev/null 2>&1 || true
pkill -f 'pointcloud_to_laserscan_node' >/dev/null 2>&1 || true
pkill -f 'ros2 bag play' >/dev/null 2>&1 || true
" >/dev/null 2>&1 || true
}

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
        echo "Building image..."
        docker compose -f $COMPOSE_FILE build
        ;;
    up)
        echo "Building and starting container..."
        docker compose -f $COMPOSE_FILE build
        docker compose -f $COMPOSE_FILE up -d
        echo ""
        echo "Container started. To open a shell run:"
        echo "  ./slam_rosbag_launch.sh shell"
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
        docker compose -f $COMPOSE_FILE logs -f $SERVICE_NAME
        ;;
    shell)
        echo "Opening shell in container..."
        docker compose -f $COMPOSE_FILE up -d $SERVICE_NAME
        docker compose -f $COMPOSE_FILE exec $SERVICE_NAME bash
        ;;
    pipeline)
        BAG_PATH=${2:-$DEFAULT_BAG_PATH}
        BAG_RATE=${3:-$DEFAULT_BAG_RATE}

        echo "Starting full pipeline in one command..."
        echo "Bag path : $BAG_PATH"
        echo "Bag rate : $BAG_RATE"
        echo ""

        docker compose -f $COMPOSE_FILE up -d $SERVICE_NAME
    trap cleanup_pipeline_processes EXIT INT TERM
        PIPELINE_CMD="set -e; export RMW_IMPLEMENTATION=rmw_fastrtps_cpp; source /opt/ros/foxy/setup.bash; source /opt/rslidar_ws/install/setup.bash; source /opt/lidar_tools_ws/install/setup.bash; echo '[pipeline] starting rslidar_sdk_node'; ros2 run rslidar_sdk rslidar_sdk_node --ros-args -p config_path:=/opt/rslidar_ws/src/rslidar_sdk/config/config.yaml >/tmp/rslidar_sdk.log 2>&1 & PID_RSLIDAR=\$!; echo '[pipeline] starting static_transform_publisher'; ros2 run tf2_ros static_transform_publisher 0 0 0.52 0 0.523 0 map rslidar >/tmp/static_tf.log 2>&1 & PID_TF=\$!; echo '[pipeline] starting pointcloud_to_laserscan_node'; ros2 run pointcloud_to_laserscan pointcloud_to_laserscan_node --ros-args -r cloud_in:=/rslidar_points -r scan:=/scan -p target_frame:=map >/tmp/pointcloud_to_laserscan.log 2>&1 & PID_P2L=\$!; cleanup() { kill \"\$PID_P2L\" \"\$PID_TF\" \"\$PID_RSLIDAR\" 2>/dev/null || true; }; trap cleanup EXIT INT TERM; sleep 2; echo '[pipeline] playing rosbag'; ros2 bag play \"\$BAG_PATH\" -r \"\$BAG_RATE\"; echo '[pipeline] rosbag playback completed'"
        docker compose -f $COMPOSE_FILE exec -e BAG_PATH="$BAG_PATH" -e BAG_RATE="$BAG_RATE" $SERVICE_NAME bash -lc "$PIPELINE_CMD"
    trap - EXIT INT TERM
        ;;
    pipeline-stop)
        echo "Stopping pipeline processes inside container..."
        cleanup_pipeline_processes
        echo "Pipeline processes stopped."
        ;;
    *)
        echo "Error: Unknown command '$COMMAND'."
        usage
        ;;
esac
