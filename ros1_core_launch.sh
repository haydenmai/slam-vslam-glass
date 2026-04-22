#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage: bash ./ros1_core_launch.sh

Starts ROS1 roscore with a clean environment.

Optional env:
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

set +u
source /opt/ros/noetic/setup.bash
set -u

export ROS_MASTER_URI=${ROS_MASTER_URI:-http://127.0.0.1:11311}
echo "ROS_MASTER_URI=$ROS_MASTER_URI"
roscore
