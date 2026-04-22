#!/usr/bin/env bash
# SLAM Glass container entrypoint - starts roscore and optionally slam_glass
set -e

USERNAME=${USERNAME:-linda}
ROS_DISTRO=${ROS_DISTRO:-noetic}

# Source ROS and workspace
source /opt/ros/${ROS_DISTRO}/setup.bash
source /home/$USERNAME/slam_glass_ws/devel/setup.bash

# Set ROS environment variables
export ROS_MASTER_URI=${ROS_MASTER_URI:-http://127.0.0.1:11311}
export ROS_IP=${ROS_IP:-127.0.0.1}
export LD_LIBRARY_PATH=/home/$USERNAME/slam_glass_ws/src/slam_glass/gmapping_export/lib:$LD_LIBRARY_PATH

echo "SLAM Glass entrypoint: ROS_DISTRO=$ROS_DISTRO ROS_MASTER_URI=$ROS_MASTER_URI ROS_IP=$ROS_IP"

# Ensure .ros directory has proper permissions
mkdir -p $HOME/.ros
chmod 755 $HOME/.ros

# Check if we should start roscore
if [ "$1" = "roscore" ] || [ "$1" = "master" ]; then
    echo "Starting ROS1 master (roscore)..."
    exec roscore
elif [ "$1" = "slam_glass" ]; then
    echo "Starting SLAM Glass..."
    # Wait a moment for roscore to be available
    sleep 2
    exec roslaunch slam_glass slam_glass_pr2.launch
elif [ "$1" = "all" ]; then
    echo "Starting ROS1 master and SLAM Glass..."
    # Start roscore in background
    roscore &
    ROSCORE_PID=$!
    # Wait for roscore to be ready
    sleep 5
    # Start slam_glass
    exec roslaunch slam_glass slam_glass_pr2.launch
else
    # Default: just start a bash shell
    echo "Starting bash shell. Use 'roscore' to start master, 'slam_glass' to start SLAM Glass, or 'all' for both."
    exec "$@"
fi
