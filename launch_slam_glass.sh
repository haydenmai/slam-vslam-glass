#!/usr/bin/env bash
set -euo pipefail

LAUNCH_FILE=${1:-slam_glass_pr2.launch}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_LINUX_WS="$HOME/ros1_to_ros2_ws"
REPO_WS="$SCRIPT_DIR/external/slam_glass_ws"

if [ -z "${LINUX_WS:-}" ]; then
  if [ -f "$DEFAULT_LINUX_WS/devel/setup.bash" ]; then
    LINUX_WS="$DEFAULT_LINUX_WS"
  elif [ -f "$REPO_WS/devel/setup.bash" ]; then
    LINUX_WS="$REPO_WS"
  else
    LINUX_WS="$DEFAULT_LINUX_WS"
  fi
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<EOF
Usage: bash ./launch_slam_glass.sh [launch_file]

Launches slam_glass with ROS1 environment.

Args:
  launch_file      default: slam_glass_pr2.launch

Optional env:
  LINUX_WS         default auto-detect:
                   1) $DEFAULT_LINUX_WS (if built)
                   2) $REPO_WS (if built)
                   fallback: $DEFAULT_LINUX_WS
  ROS_MASTER_URI   default: http://127.0.0.1:11311
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

if [ ! -f "$LINUX_WS/devel/setup.bash" ]; then
  echo "Missing built catkin workspace: $LINUX_WS"
  echo "Build it first with catkin_make in that workspace."
  exit 1
fi

if [ ! -f "$LINUX_WS/src/slam_glass/launch/$LAUNCH_FILE" ]; then
  echo "Launch file not found: $LINUX_WS/src/slam_glass/launch/$LAUNCH_FILE"
  exit 1
fi

set +u
source /opt/ros/noetic/setup.bash
source "$LINUX_WS/devel/setup.bash"
set -u

export ROS_MASTER_URI=${ROS_MASTER_URI:-http://127.0.0.1:11311}
echo "ROS_MASTER_URI=$ROS_MASTER_URI"
roslaunch slam_glass "$LAUNCH_FILE"
