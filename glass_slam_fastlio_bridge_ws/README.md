# ROS1 Container — Glass SLAM 2D Data Pipeline

This zip contains the ROS1 workspace and Docker container setup used to generate a ROS1 bag
containing 2D laser scan data (with intensity) and odometry, intended as input for `slam_glass`.

The pipeline bridges a ROS2 pointcloud processing stack back into ROS1 using `ros1_bridge`,
converting 3D Robosense Airy LiDAR data into 2D `LaserScan` messages with intensity preserved.

## Docker Image

The ROS1 environment is based on:

- **Image:** [`kenny0407/marslab_fastlio2:latest`](https://hub.docker.com/r/kenny0407/marslab_fastlio2)
- **Base OS:** Ubuntu 20.04 (Noetic)

Pull the image with:

```bash
docker pull kenny0407/marslab_fastlio2:latest
```

The catkin workspace is located at `/home/mars_ugv/catkin_ws` inside the container.

## Workspace Contents

The following packages are in `catkin_ws/src/` inside the container:

- `robosense_fast_lio/` — FAST-LIO configured for the Robosense Airy LiDAR; publishes `/Odometry` and `/tf`
- `rslidar_msg/` — Robosense LiDAR message definitions required by the SDK
- `rslidar_sdk/` — Robosense Airy ROS1 driver; publishes raw pointcloud data

## Architecture Overview

```
ROS2: rslidar_sdk → /rslidar_points
        ↓
      pointcloud_to_laserscan (patched, use_intensity:=true)
        ↓
      /scan (LaserScan with intensity)
        ↓
ros1_bridge (dynamic_bridge, 2→1)
        ↓
ROS1: rosbag record (/scan, /Odometry, /tf, /tf_static)
```

FAST-LIO runs in ROS1 and publishes `/Odometry` and `/tf`.  
The static TF (`base_link` → `rslidar`, z=0.52m, pitch=30°) is published on both sides.

## How to Run

Open the following terminals in order. ROS1 and ROS2 terminals should be in their respective
environments; the bridge runs on the host.

### ROS1 Side

```bash
# T1 — start ROS master
roscore

# T2 — enable sim time if replaying a bag
rosparam set /use_sim_time true

# T3 — start Robosense Airy driver
source ~/catkin_ws/devel/setup.bash
roslaunch rslidar_sdk start.launch

# T4 — run FAST-LIO for odometry
source ~/catkin_ws/devel/setup.bash
roslaunch fast_lio mapping_robosenseAiry.launch

# T5 — static TF: base_link → rslidar (z=0.52m, pitch=30deg)
rosrun tf2_ros static_transform_publisher 0 0 0.52 0 0.5236 0 base_link rslidar
```

### Bridge (run on host)

```bash
# T6 — bridge all ROS2 topics into ROS1
docker run -it --rm \
  --net host \
  -e ROS_MASTER_URI=http://localhost:11311 \
  osrf/ros:foxy-ros1-bridge \
  ros2 run ros1_bridge dynamic_bridge --bridge-all-2to1-topics
```

### ROS2 Side

```bash
# T7 — start ROS2 Robosense driver
ros2 launch rslidar_sdk start.launch.py

# T8 — static TF (mirror of ROS1 side)
ros2 run tf2_ros static_transform_publisher \
  --x 0 --y 0 --z 0.52 \
  --roll 0 --pitch 0.5236 --yaw 0 \
  --frame-id base_link \
  --child-frame-id rslidar

# T9 — convert pointcloud to 2D laserscan with intensity
ros2 run pointcloud_to_laserscan pointcloud_to_laserscan_node --ros-args \
  -p target_frame:=base_link \
  -p min_height:=0.0 \
  -p max_height:=0.5 \
  -p use_intensity:=true \
  --remap cloud_in:=/rslidar_points

# T10 — play back input bag (if using pre-recorded data)
ros2 bag play slam_bag2_laserscan2 --clock
```

### Verify (ROS1 side)

```bash
# T11 — confirm all required topics are publishing
rostopic hz /Odometry
rostopic hz /scan
rostopic hz /tf
rostopic echo /tf_static
```

### Record Output Bag (ROS1 side)

```bash
# T12
rosbag record -o slam_input_bag \
  /scan \
  /Odometry \
  /tf \
  /tf_static
```

## Notes

- `pointcloud_to_laserscan` was patched from source to add `use_intensity` support,
  which is absent from all upstream branches (ROS2 Humble and earlier). See the
  separate `pointcloud_to_laserscan` archive for details.
- The static TF height (z=0.52m) corrects for the physical sensor mount height,
  which was necessary for `slam_glass` to correctly interpret scan geometry.
- `--bridge-all-2to1-topics` bridges all ROS2 topics into ROS1; verify with
  `rostopic list` that `/scan` appears on the ROS1 side before recording.
- Build the workspace with `catkin_make` from `~/catkin_ws` before running.
