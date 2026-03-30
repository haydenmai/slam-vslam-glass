# Running SLAM (+ Intensity Filter)
## Run container script
```
# build and start
./start-container.sh jetson up

# other commands
./start-container.sh jetson build       # build only
./start-container.sh jetson shell       # open a shell inside the container
./start-container.sh jetson logs        # follow logs
./start-container.sh jetson down        # stop the container
./start-container.sh jetson restart     # stop and restart
```

## RoboSense SDK - Automated in Docker Build
The Jetson Docker image now clones and builds `rslidar_sdk` and `rslidar_msg` during `docker compose build`, so you do not need to run the colcon build steps manually each time. The following instructions are to support if the lidar doesn't work afterwards.

Ensure that the lidar is connected. Set IP for lidar & check packets are reaching Jetson/container network:
```bash
ip a # Check where lidar is coming from
sudo ip addr add 192.168.1.102/24 dev eno1
sudo tcpdump -ni any udp port 6699 or udp port 7788
```

Start the container:
```
./start-container.sh jetson up
./start-container.sh jetson shell
```

Build rslidar_sdk in the container:
```bash
unset AMENT_PREFIX_PATH CMAKE_PREFIX_PATH COLCON_PREFIX_PATH
source /opt/ros/humble/install/setup.bash
cd /opt/rslidar_ws
colcon build --symlink-install --cmake-args -DBUILD_TESTING=OFF -Wno-dev
```

Source the built packages:
```bash
source /opt/rslidar_ws/install/setup.bash
```

Verify and launch:
```bash
ros2 pkg list | grep rslidar
ros2 launch rslidar_sdk start.py # Also launches RViz
```

If launch fails with `package 'rviz2' not found`, run driver-only (no RViz):
```bash
source /opt/rslidar_ws/install/setup.bash
ros2 run rslidar_sdk rslidar_sdk_node --ros-args -p config_path:=/opt/rslidar_ws/src/rslidar_sdk/config/config.yaml
```

Point cloud topic is `/rslidar_points` (not `/points`):
```bash
source /opt/ros/humble/setup.bash
source /opt/rslidar_ws/install/setup.bash
export ROS_DOMAIN_ID=0
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
#export RMW_IMPLEMENTATION=rmw_fastrtps_cpp
ros2 topic list | grep -E "rslidar|point|scan"
ros2 topic hz /rslidar_points
```

If you see `ERRCODE_MSOPTIMEOUT`, the node is running but not receiving UDP packets from the lidar.
For RS-LiDAR-AIRY, edit config and set:
```yaml
lidar:
    - driver:
            lidar_type: RSAIRY
            msop_port: 6699
            difop_port: 7788
            host_address: 0.0.0.0
            group_address: 0.0.0.0
```

## Verify
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

## Topics
```
ros2 topic list
# expected: /chatter, /rosout, /parameter_events
```

## Verify nodes outside containers
```
# in container
ros2 run demo_nodes_cpp talker

# anywhere else outside container or in another container
ros2 run demo_nodes_cpp listener
```
