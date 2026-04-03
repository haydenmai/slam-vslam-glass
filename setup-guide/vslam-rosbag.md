# VSLAM with Rosbag
### Step 1: Terminal Environment Setup

Follow the steps in steup-guide/vslam.md to open two terminals in the Isaac ROS container.


### Step 2: Initialize ROS 2 Workspace

Verify the camera is connected by running:

```
/usr/local/zed/tools/ZED_Explorer
```

### Step 3: Launch the ZED Driver (Terminal 1)
Start the camera node. 
```
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zed
```

### Step 4: Record the ROS Bag (Terminal 2)
Record only the necessary topics for VSLAM to save disk space and performance.
```
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
Tip: To verify data integrity during recording, you can optionally run 
```
ros2 topic hz /zed/zed_node/left/image_rect_color 
```
in another terminal to ensure you are maintaining ~30Hz.

### Step 5: Stop and Verify Data
Stop: Press Ctrl+C in Terminal 2. 
Verify: Run the info command to check message counts:
```
# Verify the most recent recording in your bags folder
ros2 bag info "${BAG_OUT_DIR:-.}"/zed_v1_*
```
Check: Duration should match your recording time; message counts should be roughly Duration×30.

### Step 6: Running the bag in VSLAM

To run the Visual SLAM pipeline, you will need a total of four terminals running inside the container:

Terminal 1: Static Transform
Set up the base coordinate frame for the transform tree.
```
ros2 run tf2_ros static_transform_publisher 0 0 0.6 0 0 0 odom base_link --ros-args -p use_sim_time:=true
```
Argument Description:
x y z yaw pitch roll frame_id child_frame_id

We use 0.6 because that is how high the camera is mounted. 

use_sim_time:=true: This flag is mandatory for rosbag playback. It forces this node to ignore your computer's real-time clock and instead listen to the timestamps recorded inside the bag file. If this isn't set, the transform will be out of sync with your video frames, and the map will fail to render.


Terminal 2: Visualization (RViz)
Launch RViz with the default Isaac ROS Visual SLAM configuration.
```
rviz2 -d $(ros2 pkg prefix isaac_ros_visual_slam --share)/rviz/default.cfg.rviz
```

Terminal 3: Launch VSLAM
Start the VSLAM node. 
```
ros2 launch custom-isaac-ros custom_vslam.launch.py
```
Terminal 4: Play ROS Bag
Replace <path_to_bag_folder> with your specific bag directory.
```
ros2 bag play <path_to_bag_folder> --clock -r 0.5
```

Flag Explanation:

--clock: This tells ROS to publish the timestamps recorded inside the bag to the /clock topic. This ensures the Static Transform and the VSLAM node stay perfectly synchronized with the image frames.

-r 0.5: This plays the bag at half-speed.

### Step 7: Visualize in RViz2
Once RViz is open, you need to add the image displays to see the camera feed from the bag:
Add Image Display: In the Displays panel (left side), click Add -> By topic -> /zed/zed_node/left/image_rect_color -> Image.
Repeat for Right: Follow the same steps for /zed/zed_node/right/image_rect_color to view the stereo pair.
