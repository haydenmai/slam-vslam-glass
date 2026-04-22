#!/usr/bin/env bash
# Bridge container entrypoint — sources ROS 1 Noetic and ROS 2 Foxy,
# then optionally sources a ros1_bridge overlay if present.
set -e

ROS2_DISTRO=${ROS2_DISTRO:-foxy}

source /opt/ros/noetic/setup.bash
source "/opt/ros/${ROS2_DISTRO}/setup.bash"
if [ -f /bridge_ws/install/setup.bash ]; then
  source /bridge_ws/install/setup.bash
fi

export ROS_MASTER_URI=${ROS_MASTER_URI:-http://127.0.0.1:11311}
export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp

echo "Bridge entrypoint: ROS2_DISTRO=$ROS2_DISTRO ROS_MASTER_URI=$ROS_MASTER_URI ROS_DOMAIN_ID=$ROS_DOMAIN_ID"

exec "$@"
