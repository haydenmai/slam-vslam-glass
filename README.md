# SLAM/VSLAM in Glass Environments
## Overview
`slam-vslam-glass` attempts to recreate glass detection in the environment using papers (sources needed) using SLAM and Visual SLAM. 

### Our Hardware
- Jetson Orin NX (JetPack 6.2.2)
- RoboSense Airy Lidar 
- StereoLabs ZED Stereo Camera
- Kobuki Turtlebot 2

### Guides
This repository also contains a list of guides found in the `setup-guide` folder to help setup SLAM & VSLAM on the Jetson Orin NX (16GB). 

## Cloning this repository
To download/clone this repo, run either set of commands:
```
# Download repo & submodules 
git clone --recursive git@github.com:haydenmai/slam-vslam-glass.git
```

```
# Download the without submodules
git clone git@github.com:haydenmai/slam-vslam-glass.git 

# Run this in the future to get the submodules
git submodule update --init --recursive 
```

## References
references needed