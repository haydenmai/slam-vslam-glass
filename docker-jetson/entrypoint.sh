#!/bin/bash
source /opt/ros/humble/setup.bash
source ~/ros2_ws/install/setup.bash 2>/dev/null || true
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
export RCUTILS_LOGGING_SEVERITY_THRESHOLD=ERROR
exec "$@"