# Running SLAM (+ Intensity Filter)
## Container Script
You can run this script to build and bring up the Docker container.
```
# build and start
./slam_launch.sh up

# other commands
./slam_launch.sh build       # build only
./slam_launch.sh shell       # open a shell inside the container
./slam_launch.sh logs        # follow logs
./slam_launch.sh down        # stop the container
./slam_launch.sh restart     # stop and restart
```

## RoboSense SDK Setup
The Jetson Docker image clones and builds `rslidar_sdk` and `rslidar_msg` during `docker compose build`, so you do not need to run the colcon build steps manually each time. Previous commits of this file contains manual methods to install the SDK within the container if things go wrong.

Ensure that the lidar is connected. Check & Set IP for lidar & check packets are reaching Jetson/container network. You can set this to be permanent using Ubuntu's `Settings`->`Network` and configure a static IP address. 
```bash
ip a # Check where lidar is coming from
sudo ip addr add 192.168.1.102/24 dev eno1

# Run to check if data is being received
#sudo tcpdump -ni any udp port 6699 or udp port 7788
```

Start the container:
```
./slam_launch.sh up
./slam_launch.sh shell
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
If launch fails with `package 'rviz2' not found` or you are currently using `ssh`, run driver-only (no RViz):
```bash
source /opt/rslidar_ws/install/setup.bash
ros2 run rslidar_sdk rslidar_sdk_node --ros-args -p config_path:=/opt/rslidar_ws/src/rslidar_sdk/config/config.yaml
```

### Check Topic
In another terminal/container shell, you can check if the node is publishing to the point cloud topic `/rslidar_points`. 
```bash
ros2 topic list | grep -E "rslidar|point|scan"
ros2 topic hz /rslidar_points
```

## ROS2 Verification Commands
Below are a list of commands to check if ROS2 is properly installed in the Docker container.
```
printenv ROS_DISTRO
# expected: humble

echo $RMW_IMPLEMENTATION
# expected: rmw_cyclonedds_cpp

# terminal 1 — start a test publisher
ros2 run demo_nodes_cpp talker

# terminal 2 — open second shell into same container
./slam_launch.sh shell
ros2 run demo_nodes_cpp listener
```

### Topics
```
ros2 topic list
# expected: /chatter, /rosout, /parameter_events
```

### Verify Topics Outside Containers
```
# anywhere else outside container or in another container
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=0

# Check for available ROS topics running within container
ros2 topic list
ros2 topic echo /<TOPIC_NAME>
```
