# VSLAM with Rosbag
### Step 1: Terminal Environment Setup

Open two separate terminals on your host machine. Both must be logged in as the same user (admin) to share memory for the ROS 2 transport layer.

Terminal 1: Launch the container normally:

```
./scripts/run_dev.sh
```

Terminal 2: Enter the existing container session:

```
docker exec -u admin -it <container_id> /bin/bash
```
Verification: Ensure both prompts say admin@ubuntu.

### Step 2: Initialize ROS 2 Workspace

You must ensure the environment is ready in both windows.

In Terminal 1: Run the commands for VSLAM Subsequent Launches. Verify the camera is connected by running:

```
/usr/local/zed/tools/ZED_Explorer
```
In Terminal 2: You must source the workspace so this terminal can see the ROS commands:

```
source /opt/ros/humble/setup.bash
source /workspaces/isaac_ros-dev/install/setup.bash
```

### Step 3: Launch the ZED Driver (Terminal 1)
Start the camera node. 
```
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zed
```

### Step 4: Record the ROS Bag (Terminal 2)
Record only the necessary topics for VSLAM to save disk space and performance.
```
ros2 bag record -s mcap \
  /zed/zed_node/left/image_rect_color \
  /zed/zed_node/left/camera_info \
  /zed/zed_node/right/image_rect_color \
  /zed/zed_node/right/camera_info \
  -o /workspaces/isaac_ros-dev/zed_v1_vslam_data
```

Validation: In a third terminal, run 
```
ros2 topic hz /zed/zed_node/left/image_rect_color
```
 to ensure you are hitting an appropriate frame rate (~30Hz.)

### Step 5: Stop and Verify Data
Stop: Press Ctrl+C in Terminal 2. Wait until the admin@ubuntu prompt reappears before closing the terminal to avoid file corruption.
Verify: Run the info command to check message counts:
```
ros2 bag info /workspaces/isaac_ros-dev/zed_v1_vslam_data
```
Check: Duration should match your recording time; message counts should be roughly Duration×30.

### Step 6: Playback with Simulated Time
To use this data for SLAM or RViz, you must use the --clock flag so ROS 2 ignores the current system time.
```
ros2 bag play /workspaces/isaac_ros-dev/zed_v1_vslam_data --clock --loop
```
 (use loop if you want to keep replaying it)

### Step 7: Visualize in RViz2
Launch: Run 
```rviz2```
Fixed Frame: Manually type zed_left_camera_frame into the Fixed Frame field under Global Options.
Add Displays: Click Add -> By Topic and select the /image_rect_color topic. Then select image and press "OK". You should now be able to view the ROS bag. 
