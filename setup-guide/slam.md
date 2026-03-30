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

## RoboSense SDK Setup
The Jetson Docker image clones and builds `rslidar_sdk` and `rslidar_msg` during `docker compose build`, so you do not need to run the colcon build steps manually each time. Previous commits of this file contains manual methods to install the SDK within the container if things go wrong.

Ensure that the lidar is connected. Set IP for lidar & check packets are reaching Jetson/container network:
```bash
ip a # Check where lidar is coming from
sudo ip addr add 192.168.1.102/24 dev eno1
sudo tcpdump -ni any udp port 6699 or udp port 7788
```

### Start ROS Node
Start the container:
```
./start-container.sh jetson up
./start-container.sh jetson shell
```

### Configure YAML File
If you see `ERRCODE_MSOPTIMEOUT` while running the Lidar node, the node is running but not receiving UDP packets from the lidar. We need to configure the yaml file to detect for the Airy model before running the node.
For RS-LiDAR-AIRY, edit `config.yaml`:
```
sudo nvim /opt/rslidar_ws/src/rslidar_sdk/config/config.yaml
```

```yaml
lidar:
    - driver:
            lidar_type: RSAIRY
            msop_port: 6699
            difop_port: 7788
            host_address: 0.0.0.0
            group_address: 0.0.0.0
```

### Launch Lidar Node (w/ RViz)
```bash
ros2 pkg list | grep rslidar
ros2 launch rslidar_sdk start.py 
```

### Launch Lidar Node (w/o RViz)
If launch fails with `package 'rviz2' not found`, run driver-only (no RViz):
```bash
source /opt/rslidar_ws/install/setup.bash
ros2 run rslidar_sdk rslidar_sdk_node --ros-args -p config_path:=/opt/rslidar_ws/src/rslidar_sdk/config/config.yaml
```

### Check Topic
Point cloud topic is `/rslidar_points` (not `/points`):
```bash
ros2 topic list | grep -E "rslidar|point|scan"
ros2 topic hz /rslidar_points
```

## ROS2 Verification Commands
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

## Verify Topics Outside Containers
```
# anywhere else outside container or in another container
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=0

# Check for available ROS topics running within container
ros2 topic list
ros2 topic echo /<TOPIC_NAME>
```
