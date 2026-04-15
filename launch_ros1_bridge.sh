#!/usr/bin/env bash
set -euo pipefail

ROS2_DISTRO=${ROS2_DISTRO:-foxy}
BRIDGE_MODE=${BRIDGE_MODE:-dynamic}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRIDGE_TOPICS_FILE=${BRIDGE_TOPICS_FILE:-$SCRIPT_DIR/setup-guide/bridge_topics.yaml}

BRIDGE_WS_SETUP=${BRIDGE_WS_SETUP:-$HOME/bridge_ws/install/setup.bash}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<EOF
Usage: bash ./launch_ros1_bridge.sh

Starts ros1_bridge with a clean environment.

Optional env:
  ROS2_DISTRO        default: foxy
  BRIDGE_MODE        dynamic | parameter   (default: dynamic)
  BRIDGE_TOPICS_FILE default: $SCRIPT_DIR/setup-guide/bridge_topics.yaml
  BRIDGE_WS_SETUP    default: $HOME/bridge_ws/install/setup.bash
  ROS_MASTER_URI     default: http://127.0.0.1:11311
  ROS_DOMAIN_ID      default: 0
EOF
  exit 0
fi

# Start from a clean ROS environment to avoid distro path mixing
unset ROS_DISTRO ROS_VERSION ROS_PYTHON_VERSION ROS_ETC_DIR ROS_ROOT ROS_PACKAGE_PATH
unset AMENT_PREFIX_PATH CMAKE_PREFIX_PATH COLCON_PREFIX_PATH CATKIN_PREFIX_PATH
unset PYTHONPATH PYTHONHOME
export PYTHONPATH=""

if [ ! -f /opt/ros/noetic/setup.bash ]; then
  echo "Missing ROS1 setup: /opt/ros/noetic/setup.bash"
  exit 1
fi

if [ ! -f "/opt/ros/${ROS2_DISTRO}/setup.bash" ]; then
  echo "Missing ROS2 setup: /opt/ros/${ROS2_DISTRO}/setup.bash"
  echo "This launcher defaults to ROS2 Foxy. Install Foxy or set ROS2_DISTRO explicitly."
  exit 1
fi

set +u
source /opt/ros/noetic/setup.bash
source "/opt/ros/${ROS2_DISTRO}/setup.bash"
if [ -f "$BRIDGE_WS_SETUP" ]; then
  source "$BRIDGE_WS_SETUP"
fi
set -u

export ROS_MASTER_URI=${ROS_MASTER_URI:-http://127.0.0.1:11311}
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}

echo "ROS2_DISTRO=$ROS2_DISTRO"
echo "BRIDGE_MODE=$BRIDGE_MODE"
echo "ROS_MASTER_URI=$ROS_MASTER_URI"
echo "ROS_DOMAIN_ID=$ROS_DOMAIN_ID"

if [ "$BRIDGE_MODE" = "parameter" ]; then
  if [ ! -f "$BRIDGE_TOPICS_FILE" ]; then
    echo "Missing bridge topics config: $BRIDGE_TOPICS_FILE"
    exit 1
  fi
  rosparam load "$BRIDGE_TOPICS_FILE"
  ros2 run ros1_bridge parameter_bridge
else
  ros2 run ros1_bridge dynamic_bridge -- --bridge-all-2to1-topics
fi
