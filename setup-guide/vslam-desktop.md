
on desktop, 
```
cd {REPO_DIR/isaac_ros_common}
git lfs install
git lfs pull
```

then run the `run_dev.sh` script:
```
./scripts/run_dev.sh
```

in the container, run:
```
cd /workspaces/isaac_ros-dev/src

# For ZED Camera conversion
git clone https://github.com/dungrup/custom-isaac-ros.git
```

```
sudo apt-get update
sudo apt-get install -y \
    ros-humble-isaac-ros-visual-slam \
    ros-humble-isaac-ros-image-proc
```

```
cd /workspaces/isaac_ros-dev
source /opt/ros/humble/setup.bash
colcon build --packages-select custom-isaac-ros
source install/setup.bash
```

```
ros2 launch custom-isaac-ros custom_vslam.launch.py
```

on another terminal in isaac_ros_common:
```
# In $REPO_DIR/isaac_ros_common
./scripts/run_dev.sh
```

```
rviz2 -d $(ros2 pkg prefix isaac_ros_visual_slam --share)/rviz/default.cfg.rviz
```

on terminal 3 inside the container:
```
ros2 bag play <path_to_bag_folder> --clock -r 1 
```