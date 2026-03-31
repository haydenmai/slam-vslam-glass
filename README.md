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

If these scripts does fail in the future, checkout to the commit below. After checking out to the branch, `setup-guide` will contain a list of commands you can run manually to investigate point of failure.
```
git checkout 10a2f06a4bdd8e94f80935966f03edde8c3d024f

# Airy Lidar Instructions in slam.md
git checkout b1876c1eac62ce9a5072228c4efe656318846db8
```

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

```text
slam-vslam-glass/
├── README.md
│
├── slam_launch.sh
├── vslam_first_launch.sh
├── vslam_subsequent_launch.sh
│
├── docker-slam/
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── entrypoint.sh
│
├── setup-guide/
│   ├── slam.md
│   ├── turtlebot2.md
│   ├── vslam-rosbag.md
│   └── vslam.md
│
├── isaac_ros_common/ 	# submodule
└── spark-fast-lio/ 	# submodule
```

## References
### Papers
references needed

### Repositories
- [turtlebot2_ros2](https://github.com/idorobotics/turtlebot2_ros2.git) - Turtlebot 2 ROS2 packages
- [zed-ros2-wrapper](https://github.com/stereolabs/zed-ros2-wrapper.git) - StereoLabs ZED camera ROS2 interfaces
- [isaac_ros_common](https://github.com/NVIDIA-ISAAC-ROS/isaac_ros_common.git) - NVIDIA Isaac ROS common utilities
- [rslidar_sdk](https://github.com/RoboSense-LiDAR/rslidar_sdk.git) - RoboSense LiDAR SDK
- [spark-fast-lio](https://github.com/MIT-SPARK/spark-fast-lio.git) - MIT Spark Fast LIO (LIDAR-Inertial Odometry)
