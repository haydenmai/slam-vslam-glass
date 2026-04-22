# SLAM VSLAM Glass Setup Guide

This guide covers how to run the complete SLAM pipeline with ROS2 bag playback, ROS1-ROS2 bridge, and SLAM Glass for glass detection.

## Overview

The system consists of three main components:
1. **ROS2 Bag Pipeline** - Plays lidar data and processes sensor topics
2. **ROS1-ROS2 Bridge** - Converts ROS2 topics to ROS1 format
3. **SLAM Glass** - ROS1 SLAM with glass detection

## Prerequisites

- Docker and Docker Compose installed
- ROS2 bag files in `/home/linda/lidar_bags/` directory
- All Docker images built (see Build Instructions below)

## Build Instructions

Build all required Docker images before first use:

```bash
# Build ROS2 bag pipeline
./slam_rosbag_launch.sh build

# Build ROS1-ROS2 bridge  
./slam_ros_bridge.sh build

# Build SLAM Glass
./slam_glass_launch.sh build
```

## Complete Workflow

### Working Order

The stack is sensitive to startup order. Use this sequence:

1. Start SLAM Glass with ROS1 master.
2. Start the ROS2 bag pipeline.
3. Start the ROS1-ROS2 bridge after ROS2 topics are publishing.

If host-side `ros2 topic list` looks stale, refresh the daemon cache first:

```bash
ros2 daemon stop
ros2 daemon start
```

### Step 1: Start SLAM Glass with ROS1 Master

```bash
./slam_glass_launch.sh all
```

This starts both the ROS1 master (roscore) and SLAM Glass in one container.

### Step 2: Start ROS2 Bag Pipeline

In a second terminal:

```bash
./slam_rosbag_launch.sh pipeline /home/linda/lidar_bags/slam_bag20 1.0
```

This starts the complete ROS2 pipeline:
- rslidar_sdk node (processes lidar data)
- pointcloud_to_laserscan node (converts pointcloud to laser scan)
- ros2 bag play (plays the bag file)

If `Ctrl+C` does not stop the helper processes cleanly, run:

```bash
./slam_rosbag_launch.sh pipeline-stop
```

### Step 3: Start ROS1-ROS2 Bridge

In a third terminal:

```bash
./slam_ros_bridge.sh up
```

The bridge will automatically detect the ROS2 topics and create bridges to ROS1.

If the bridge is started before the bag pipeline is publishing topics, it may not create any bridges until the bridge is restarted after topics are available.

## Verification

### Check ROS2 Topics

```bash
./slam_rosbag_launch.sh shell
# Inside container:
source /opt/ros/foxy/setup.bash
ros2 topic list
ros2 topic hz /scan
```

You should see topics like:
- `/scan`
- `/rslidar_points`
- `/rslidar_imu_data`
- `/tf`
- `/tf_static`

If those topics are missing on the host, restart the ROS 2 daemon and re-run the check.

### Check ROS1 Topics

```bash
./slam_ros_bridge.sh shell
# Inside container:
source /opt/ros/noetic/setup.bash
rostopic list
```

You should see the same topics converted to ROS1, plus SLAM Glass topics:
- `/scan`
- `/tf`
- `/tf_static`
- `/map`
- `/slam_glass/entropy`
- `/slam_glass/robot_trajectory`

### Check Bridge Logs

```bash
./slam_ros_bridge.sh logs
```

Look for messages like:
```
created 2to1 bridge for topic '/scan' with ROS 2 type 'sensor_msgs/msg/LaserScan' and ROS 1 type 'sensor_msgs/LaserScan'
```

If you see no bridge creation messages, verify that `/scan` exists in the ROS 2 bag container first, then restart the bridge.

### Check SLAM Glass Output

```bash
./slam_glass_launch.sh logs
```

You should see SLAM Glass processing the laser scan data and generating maps.

## Alternative Workflows

### Separate ROS1 Master

If you want to run roscore separately:

```bash
# Terminal 1: Start roscore only
./slam_glass_launch.sh roscore

# Terminal 2: Start SLAM Glass
./slam_glass_launch.sh slam_glass

# Terminal 3: Start ROS2 bag pipeline
./slam_rosbag_launch.sh pipeline /home/linda/lidar_bags/slam_bag20 1.0

# Terminal 4: Start bridge
./slam_ros_bridge.sh up
```

### Interactive Development

For debugging or development:

```bash
# Open shell in each container
./slam_glass_launch.sh shell
./slam_rosbag_launch.sh shell  
./slam_ros_bridge.sh shell
```

## Troubleshooting

### Bridge Connection Errors

**Error:** `XmlRpcClient::writeRequest: write error (Connection refused)`

**Solution:** Make sure the ROS1 master is running before starting the bridge. The bridge needs roscore to connect to.

```bash
# Check if roscore is running in the SLAM Glass container
./slam_glass_launch.sh roscore
```

### No Topic Conversion

**Error:** Bridge logs show no topic creation messages

**Solution:** Ensure ROS2 topics are actively publishing data before starting the bridge.

```bash
# Check ROS2 topics are publishing
./slam_rosbag_launch.sh shell
# Inside container:
ros2 topic hz /scan
```

### ROS2 Pipeline Errors

**Error:** `ERRCODE_MSOPTIMEOUT` from rslidar_sdk

**Solution:** The rslidar_sdk is configured for online lidar mode. The updated Dockerfile should fix this with `msg_source: 2`.

```bash
# Rebuild ROS2 bag container
./slam_rosbag_launch.sh down
./slam_rosbag_launch.sh build
./slam_rosbag_launch.sh pipeline /home/linda/lidar_bags/slam_bag20 1.0
```

### Segmentation Faults

**Error:** `ros2 topic echo` crashes with segfault

**Solution:** This indicates issues with the ROS2 pipeline. Check component logs:

```bash
./slam_rosbag_launch.sh shell
# Inside container:
cat /tmp/rslidar_sdk.log
cat /tmp/pointcloud_to_laserscan.log
```

## Data Flow

```
ROS2 Bag File
    |
    v
rslidar_sdk_node (processes raw lidar data)
    |
    v
pointcloud_to_laserscan_node (/rslidar_points -> /scan)
    |
    v
ROS1-ROS2 Bridge (/scan ROS2 -> /scan ROS1)
    |
    v
SLAM Glass (processes /scan for SLAM with glass detection)
    |
    v
Map Output (/map, /slam_glass/* topics)
```

## Environment Variables

All containers use consistent environment variables:

- `ROS_MASTER_URI=http://127.0.0.1:11311` (ROS1)
- `ROS_DOMAIN_ID=0` (ROS2)
- `RMW_IMPLEMENTATION=rmw_fastrtps_cpp` (ROS2)

## Network Configuration

All containers use `network_mode: host` to ensure:
- ROS1 master communication on port 11311
- ROS2 DDS communication
- Bridge can connect to both ROS1 and ROS2

## File Locations

- **ROS2 bag files:** `/home/linda/lidar_bags/`
- **SLAM Glass source:** `./slam_glass/`
- **Docker files:** `./docker-slam/`
- **Launch scripts:** `./slam_*_launch.sh`

## Performance Tips

1. **Use SSD storage** for bag files to improve playback performance
2. **Monitor CPU usage** - the pipeline can be CPU intensive
3. **Check memory usage** - pointcloud processing can use significant RAM
4. **Adjust bag playback rate** if needed (default is 1.0x)

## Stopping the System

To stop all components:

```bash
# Stop each component
./slam_glass_launch.sh down
./slam_rosbag_launch.sh down  
./slam_ros_bridge.sh down

# Or use Ctrl+C in each terminal if running interactively
```

## Next Steps

Once everything is running:
1. Use RViz to visualize the SLAM output: `rviz -d slam_glass/config/slam_glass.rviz`
2. Monitor the map generation and glass detection
3. Save the generated map for later use
4. Experiment with different bag files and parameters
