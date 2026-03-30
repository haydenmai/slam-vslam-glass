# Running Turtlebot2 With ROS2
Turtlebot2 requires a few drivers to be installed before running, feel free to either install this on the Jetson image or in a Docker container (not tested).

## Setup
Instructions are found in the [turtlebot2_ros2](https://github.com/idorobotics/turtlebot2_ros2.git) repository. For convenience, you can copy these commands:
```
# dependencies
sudo apt-get install ros-humble-kobuki-velocity-smoother ros-humble-sophus ros-humble-teleop-twist-keyboard ros-humble-joy-teleop ros-humble-teleop-twist-joy

# Build the ROS2 drivers
mkdir -p ros2_ws/src
cd ros2_ws/src
git clone --recursive https://github.com/idorobotics/turtlebot2_ros2.git
cd ..
rosdep install -i --from-path src --rosdistro humble -y
colcon build --symlink-install --executor sequential

# udev setup
wget https://raw.githubusercontent.com/kobuki-base/kobuki_ftdi/devel/60-kobuki.rules
sudo cp 60-kobuki.rules /etc/udev/rules.d
sudo service udev reload
sudo service udev restart

# Check kobuki version
kobuki-version-info
source install/setup.bash
```
Check if `/dev/kobuki` exists before proceeding.

## Run the Robot
You can now run the turtlebot2! Either ssh into the jetson or connect a keyboard to the jetson usb port will work. Open 2 seperate terminals to begin.

In terminal 1:
```
ros2 launch kobuki_node kobuki_node-launch.py
cd ~/ros2_ws/
source install/setup.bash
```

In terminal 2:
```
source /opt/ros/humble/setup.bash
ros2 run teleop_twist_keyboard teleop_twist_keyboard --ros-args --remap cmd_vel:=commands/velocity
```

## Troubleshooting
If the `colcon build` command failed, it is likely that `empy` is incompatible:
```
pip uninstall empy
pip install empy==3.3.4

# rebuild
colcon build --symlink-install --executor sequential \
  --cmake-args \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
  -Wno-dev \
  -DCMAKE_CXX_FLAGS="-Wno-error=class-memaccess"
```

