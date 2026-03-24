# SLAM/VSLAM in Glass Environments
## Overview

## Cloning this repository
To download/clone this repo, run either commands:
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

## Testing docker container
### Run script
```
# build and start
./start.sh pi up
./start.sh jetson up

# other commands
./start.sh pi build       # build only
./start.sh pi shell       # open a shell inside the container
./start.sh pi logs        # follow logs
./start.sh pi down        # stop the container
./start.sh pi restart     # stop and restart
```
### Export variables for Jetson
```
# In terminal:
export ROS_DOMAIN_ID=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
```
### Verify
```
printenv ROS_DISTRO
# expected: humble

echo $RMW_IMPLEMENTATION
# expected: rmw_cyclonedds_cpp

# terminal 1 — start a test publisher
ros2 run demo_nodes_cpp talker

# terminal 2 — open second shell into same container
docker compose -f docker-compose.jetson.yml exec ros2 bash
ros2 run demo_nodes_cpp listener
```

### Topics
```
ros2 topic list
# expected: /chatter, /rosout, /parameter_events
```

### Verify nodes outside containers
```
# in container
ros2 run demo_nodes_cpp talker

# anywhere else outside container or in another container
ros2 run demo_nodes_cpp listener
```

## Running SLAM (+ Intensity Filter)

## Running VSLAM
To start, some commands are required to get the ZED cameras working:
```
xhost +si:localuser:root
```

VSLAM requires to run in isaac_ros_common, which will automatically create and launch a docker image.
```
cd {$REPO_DIR}
cd isaac_ros_command/
./scripts/run_dev.sh
```

In the docker image terminal, run:
```
cd /workspaces/isaac_ros-dev
source /opt/ros/humble/setup.bash
source install/setup.bash
export ISAAC_ROS_WS=/workspaces/isaac_ros-dev

whoami
ls -l /dev/nvmap
echo $NVIDIA_VISIBLE_DEVICES
```