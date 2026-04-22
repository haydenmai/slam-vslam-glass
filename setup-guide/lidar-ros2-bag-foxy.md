# ROS2 Foxy Lidar Rosbag Pipeline (RoboSense Airy)

This guide uses the ROS2 Foxy x64 container defined in:

- docker-slam/dockerfile.ros2-bag
- docker-slam/docker-compose.ros2-bag.yml

It covers this flow:

1. Replay raw RoboSense packet bag topics from lidar_bags.
2. Convert packets to PointCloud2 with rslidar_sdk.
3. Publish static tilt correction transform.
4. Flatten PointCloud2 to 2D LaserScan with pointcloud_to_laserscan.

## One-terminal option (recommended)

You can run the full pipeline in one command from the host terminal:

```bash
./slam_rosbag_launch.sh pipeline /home/linda/lidar_bags/slam_bag20 1.0
```

Arguments:

- First argument: bag folder path inside container (default: /home/linda/lidar_bags/slam_bag20)
- Second argument: playback rate (default: 1.0)

This command starts rslidar_sdk, static transform, pointcloud_to_laserscan, then plays the bag.
When bag playback exits, the helper nodes started by this command are stopped automatically.
This Foxy setup uses plain rosbag playback without `--clock`.
The one-command pipeline uses `rmw_fastrtps_cpp` because Foxy rosbag playback on this bag is unstable with CycloneDDS.
Press `Ctrl+C` in the pipeline terminal to stop playback and trigger cleanup of helper nodes.
If any topics remain after interrupting, run:

```bash
./slam_rosbag_launch.sh pipeline-stop
```

## Step 1: Build and start the container

From the repository root:

```bash
./slam_rosbag_launch.sh build
./slam_rosbag_launch.sh up
```

Open a shell inside the running container:

```bash
./slam_rosbag_launch.sh shell
```

## Step 2: Confirm bag mount and available topics

The compose file mounts host lidar_bags into:

```text
/home/linda/lidar_bags
```

Check available bags:

```bash
ls -lah /home/linda/lidar_bags
```

Inspect one bag before playback:

```bash
ros2 bag info /home/linda/lidar_bags/slam_bag20
```

Expected raw topics include:

- /rslidar_packets
- /rslidar_imu_data

## Step 3: Terminal 1 - Start rslidar_sdk packet decoder

In container Terminal 1:

```bash
source /opt/ros/foxy/setup.bash
source /opt/rslidar_ws/install/setup.bash

ros2 run rslidar_sdk rslidar_sdk_node \
  --ros-args \
  -p config_path:=/opt/rslidar_ws/src/rslidar_sdk/config/config.yaml
```

This node converts raw RoboSense packets into point cloud output (for example /rslidar_points).

## Step 4: Terminal 2 - Publish static transform for lidar tilt

In container Terminal 2:

```bash
source /opt/ros/foxy/setup.bash

ros2 run tf2_ros static_transform_publisher \
  0 0 0.52 0 0.523 0 map rslidar
```

## Step 5: Terminal 3 - Convert PointCloud2 to LaserScan

In container Terminal 3:

```bash
source /opt/ros/foxy/setup.bash
source /opt/lidar_tools_ws/install/setup.bash

ros2 run pointcloud_to_laserscan pointcloud_to_laserscan_node \
  --ros-args \
  -r cloud_in:=/rslidar_points \
  -r scan:=/scan \
  -p target_frame:=map
```

## Step 6: Terminal 4 - Play a rosbag

In container Terminal 4:

```bash
source /opt/ros/foxy/setup.bash

ros2 bag play /home/linda/lidar_bags/slam_bag20
```

You can replace slam_bag20 with any bag folder under /home/linda/lidar_bags.

## Step 7: Quick verification commands

Use a separate shell outside the container while the pipeline command is still running.
If the pipeline has already finished, the container publishers will exit and the host will only show local CLI topics like `/rosout` and `/parameter_events`.
If the host still does not show the lidar topics, restart the ROS 2 daemon cache first:

```bash
ros2 daemon stop
ros2 daemon start
```

In that outside shell, make sure the ROS 2 environment matches:

```bash
source /opt/ros/foxy/setup.bash
export ROS_DOMAIN_ID=0
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
```

Then check topics from the host:

```bash
ros2 topic list | grep -E "rslidar|points|scan|tf"
ros2 topic hz /rslidar_points
ros2 topic hz /scan
```

If you want to verify inside the container instead, open another shell with:

```bash
./slam_rosbag_launch.sh shell
```

and then run:

```bash
ros2 topic list | grep -E "rslidar|points|scan|tf"
ros2 topic hz /rslidar_points
ros2 topic hz /scan
```

Optional RViz check:

```bash
rviz2
```

Add displays for PointCloud2 (/rslidar_points) and LaserScan (/scan).

## Notes and troubleshooting

- If /scan is empty, verify the input topic name from rslidar_sdk matches cloud_in remap.
- If transforms are missing, keep static_transform_publisher running during playback.
- If bag playback is too fast for processing, slow it down:

```bash
ros2 bag play /home/linda/lidar_bags/slam_bag20 -r 0.5
```

- If lidar_bags does not exist on host, Docker may create an empty directory and mount it. In that case, copy or extract your bag folders into host lidar_bags first.
