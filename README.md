# SLAM/VSLAM in Glass Environments
## Our Team! 
| Team Member     | Role                      | Contact 				  |
| --------------- | ------------------------- | ------------------------- |
| April Nguyen    | SLAM & Glass Filter       | axn@sfu.ca			      |
| Kaiden Palmers  | SLAM & Glass Filter       | kaiden_palmer@sfu.ca      |
| Michael Chandra | Hardware Setup & VSLAM    | michael_chandra@sfu.ca    |
| Hayden Mai      | Hardware & Software Setup | hgm2@sfu.ca 			  |

## Overview
`slam-vslam-glass` attempts to recreate glass detection in environments using papers (sources needed) using SLAM and Visual SLAM.

### Our Hardware
- Jetson Orin NX 16GB (JetPack 6.2.2)
- RoboSense Airy Lidar 
- StereoLabs ZED Stereo Camera
- Kobuki Turtlebot 2

### Guides
This repository also contains a list of guides found in the `setup-guide` folder to help setup SLAM & VSLAM on the Jetson Orin NX. Feel free to fork this repository and make edits to the markdown files if methods change.

## Cloning this repository
To download/clone this repo, run either set of commands:

### Download repo & submodules 
```
git clone --recursive git@github.com:haydenmai/slam-vslam-glass.git
```

### Download without submodules
```
git clone git@github.com:haydenmai/slam-vslam-glass.git 

# Run this in the future to get the submodules
git submodule update --init --recursive 
```

## Directory

## References
### Papers
references needed

### Repositories
- [turtlebot2_ros2](https://github.com/idorobotics/turtlebot2_ros2.git) - Turtlebot 2 ROS2 packages
- [zed-ros2-interfaces](https://github.com/stereolabs/zed-ros2-interfaces.git) - StereoLabs ZED camera ROS2 interfaces
- [isaac_ros_common](https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common.git) - NVIDIA Isaac ROS common utilities
- [rslidar_sdk](https://github.com/RoboSense-LiDAR/rslidar_sdk.git) - RoboSense LiDAR SDK
- [spark-fast-lio](https://github.com/MIT-SPARK/spark-fast-lio.git) - MIT Spark Fast LIO (LIDAR-Inertial Odometry)
