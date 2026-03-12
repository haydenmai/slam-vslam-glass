#!/bin/bash
if [ -n "${ROS_ROOT:-}" ] && [ -f "$ROS_ROOT/install/setup.bash" ]; then
	source "$ROS_ROOT/install/setup.bash"
elif [ -f "/opt/ros/${ROS_DISTRO:-humble}/setup.bash" ]; then
	source "/opt/ros/${ROS_DISTRO:-humble}/setup.bash"
fi
source ~/ros2_ws/install/setup.bash 2>/dev/null || true
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=0
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
export RCUTILS_LOGGING_SEVERITY_THRESHOLD=ERROR
exec "$@"