# VSLAM with Rosbag

## Step 1: Terminal Environment Setup
Follow the steps in `setup-guide/vslam.md` to open two terminals in the Isaac ROS container.

## Step 2: Initialize ROS 2 Workspace
Verify that the camera is connected:

```bash
/usr/local/zed/tools/ZED_Explorer
```

## Step 3: Launch the ZED Driver (Terminal 1)
Start the camera node:

```bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zed
```

## Step 4: Record the ROS Bag (Terminal 2)
Record only required topics to save disk space and improve performance:

```bash
# Define your workspace path (or leave as '.' for current directory)
export BAG_OUT_DIR=${ISAAC_ROS_WS:-.}/bags

ros2 bag record -s mcap \
  --max-cache-size 1000000000 \
  /zed/zed_node/left/image_rect_color \
  /zed/zed_node/right/image_rect_color \
  /zed/zed_node/left/camera_info \
  /zed/zed_node/right/camera_info \
  /tf \
  /tf_static \
  /zed/zed_node/point_cloud/cloud_registered \
  -o "${BAG_OUT_DIR}/zed_v1_$(date +%Y%m%d_%H%M%S)"
```

Optional integrity check (run in another terminal while recording):

```bash
ros2 topic hz /zed/zed_node/left/image_rect_color
```

Target rate is approximately `30 Hz`.

## Step 5: Stop and Verify Data
1. Stop recording with `Ctrl+C` in Terminal 2.
2. Verify the bag info:

```bash
# Verify the most recent recording in your bags folder
ros2 bag info "${BAG_OUT_DIR:-.}"/zed_v1_*
```

Check that:
- Duration matches your recording time.
- Message counts are roughly `duration x 30` for image topics.

## Step 6: Run the Bag in VSLAM
To run the Visual SLAM pipeline, use four terminals inside the container.

### Terminal 1: Static Transform
Set up the base coordinate frame for the transform tree:

```bash
ros2 run tf2_ros static_transform_publisher 0 0 0.6 0 0 0 odom base_link --ros-args -p use_sim_time:=true
```

Argument order:
`x y z yaw pitch roll frame_id child_frame_id`

Notes:
- `0.6` is used because that is the approximate camera mount height.
- `use_sim_time:=true` is required for rosbag playback so transforms align with bag timestamps.

### Terminal 2: Visualization (RViz)
Launch RViz with the default Isaac ROS Visual SLAM config:

```bash
rviz2 -d $(ros2 pkg prefix isaac_ros_visual_slam --share)/rviz/default.cfg.rviz
```

### Terminal 3: Launch VSLAM
Start the VSLAM node:

```bash
ros2 launch custom-isaac-ros custom_vslam.launch.py
```

### Terminal 4: Play ROS Bag
Replace `<path_to_bag_folder>` with your bag directory:

```bash
ros2 bag play <path_to_bag_folder> --clock -r 0.5
```

Flags:
- `--clock`: Publishes recorded timestamps to `/clock` for synchronization.
- `-r 0.5`: Plays back at half speed.

## Step 7: Visualize in RViz2
After RViz opens, add image displays to view the camera feed:
- Add the left image: `Add -> By topic -> /zed/zed_node/left/image_rect_color -> Image`
- Add the right image: `Add -> By topic -> /zed/zed_node/right/image_rect_color -> Image`

## Notes
Some useful topics may not be recorded by default. This can affect downstream visualization tasks, such as projecting point clouds onto camera output, if topics like depth are missing.