# Running Lidar
## Container Script
You can run this script to build and bring up the Docker container.
```
# build and start
./lidar_launch.sh up

# other commands
./lidar_launch.sh build       # build only
./lidar_launch.sh shell       # open a shell inside the container
./lidar_launch.sh logs        # follow logs
./lidar_launch.sh down        # stop the container
./lidar_launch.sh restart     # stop and restart
```

## RoboSense SDK Setup
Ensure that the lidar is connected. Check & Set IP for lidar & check packets are reaching Jetson/container network. You can set this to be permanent using Ubuntu's `Settings`->`Network` and configure a static IP address of `192.168.1.102` with netmask of `255.255.255.0`. 
```bash
ip a # Check where lidar is coming from
sudo ip addr add 192.168.1.102/24 dev eno1 # Temporary, use Settings->Network for permanent static ip

# Run to check if data is being received
#sudo tcpdump -ni any udp port 6699 or udp port 7788 or udp port 6688

# Check each individual port
#sudo tcpdump -ni any udp port 6699 # MSOP
#sudo tcpdump -ni any udp port 7788 # DIFOP
#sudo tcpdump -ni any udp port 6688 # IMU
```

Start the container:
```
./lidar_launch.sh up
./lidar_launch.sh shell
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

**Note:** Refer to [ROS2 Bag](#ros2-bag) for recording and replaying ROS2 Bags.

### Check Topic
In another terminal/container shell, you can check if the node is publishing to the point cloud topic `/rslidar_points`. 
```bash
ros2 topic list | grep -E "rslidar|point|scan"
ros2 topic hz /rslidar_points
```

### Editing `config.yaml`
Depending on your usage, you may need to edit `config.yaml`:
```
sudo nvim /opt/rslidar_ws/src/rslidar_sdk/config/config.yaml
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
./lidar_launch.sh shell
ros2 run demo_nodes_cpp listener
```

### Topics
```
ros2 topic list
# expected: /chatter, /rosout, /parameter_events
```

### Topics Access Outside Containers
```
# anywhere else outside container or in another container
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_DOMAIN_ID=0

# Check for available ROS topics running within container
ros2 topic list
ros2 topic echo /<TOPIC_NAME>
```

## ROS2 Bag
With the container full ready for Lidar, we can now record the lidar topics. Refer to the [    rslidar_sdk/doc/howto/11_how_to_record_replay_packet_rosbag.md](https://github.com/RoboSense-LiDAR/rslidar_sdk/blob/main/doc/howto/11_how_to_record_replay_packet_rosbag.md) for use with ROS2 Bags.

The instruction may refer the configuration settings to `config.txt`:
```
sudo nvim /opt/rslidar_ws/src/rslidar_sdk/config/config.yaml
```

### Recording rosbag
Ensure these are correct in `config.yaml`
```yaml
common:
  msg_source: 1                                       
  send_packet_ros: true                                
  send_point_cloud_ros: true                                                   
```

In the instruction, the rosbag command is for ROS, not ROS2. Record with this command instead:
**NOTE: MAKE SURE `send_packet_ros` IS SET TO `true` BEFORE PROCEEDING**
```
ros2 bag record /rslidar_packets /rslidar_imu_data -o slam_bag
```



