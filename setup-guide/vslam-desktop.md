# VSLAM on Desktop (Ubuntu 24.04)
This guide runs Isaac ROS VSLAM from a desktop using the dev container with a ZED camera rosbag.
It assumes your repository root is in REPO_DIR and you are launching from isaac_ros_common folder.

## Notes
- Verified for Ubuntu 24.04 Desktop
- Docker Engine installed
- A rosbag with ZED Depth Camera topics compatible
- An NVIDIA GPU with CUDA 

## Terminal 1: Start Dev Container and Launch VSLAM
On host:

```bash
cd ${REPO_DIR}/isaac_ros_common
git lfs install
git lfs pull
./scripts/run_dev.sh
```

Inside the container, clone the `custom-isaac-ros` repo:
```bash
cd /workspaces/isaac_ros-dev/src

# For ZED camera conversion
git clone https://github.com/dungrup/custom-isaac-ros.git
```

Install necessary packages:
```bash
sudo apt-get update
sudo apt-get install -y \
    ros-humble-isaac-ros-visual-slam \
    ros-humble-isaac-ros-image-proc
```

Build:
```bash
cd /workspaces/isaac_ros-dev
source /opt/ros/humble/setup.bash
colcon build --packages-select custom-isaac-ros
source install/setup.bash
```

Launch VSLAM:

```bash
ros2 launch custom-isaac-ros custom_vslam.launch.py
```

## Terminal 2a: Open RViz in a Second Dev Container Shell
On host:

```bash
cd ${REPO_DIR}/isaac_ros_common
./scripts/run_dev.sh
```

Inside the container:
```bash
rviz2 -d $(ros2 pkg prefix isaac_ros_visual_slam --share)/rviz/default.cfg.rviz
```

## Terminal 2b: Foxglove Bridge
You may also run a Foxglove bridge to view the VSLAM result via Foxglove visualization instead of RViz.
```
ros2 launch foxglove_bridge foxglove_bridge_launch.xml
```

Outside your container, run [Foxglove](https://foxglove.dev/).

## Terminal 3: Play Rosbag
Inside the container:
```bash
ros2 bag play <path_to_bag_folder> --clock -r 1
```
# Troubleshoot & Notes
For future launches:
- `run_dev.sh` will reuse a cached image to launch the container
- You will still need to re-install the `ros-humble-isaac-ros-visual-slam` and `ros-humble-isaac-ros-image-proc` packages.
- Ensure ROS packages are activated via `source /opt/ros/humble/setup.bash && source install/setup.bash`

# Links
[custom-isaac-ros](https://github.com/dungrup/custom-isaac-ros.git) - Custom repository to run ZED Camera rogbags