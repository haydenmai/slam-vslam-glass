# Running VSLAM
## 1st Launch
To start, we need to download various libraries and run commands to ensure the ZED SDK is installed. In addition, VSLAM requires to be run in isaac_ros_common, which will automatically create and launch a docker image. **Note:** This only needs be run once, subsequent runs need a different set of commands.
```
cd {$REPO_DIR}
cd isaac_ros_common/

# ZED ROS2 Wrapper
mkdir src
cd src
git clone --recurse-submodules https://github.com/stereolabs/zed-ros2-wrapper -b humble-v4.2.5

# isaac-ros-common uses git-lfs, ensure this is installed
sudo apt-get install git-lfs && git lfs install && git lfs pull
sudo nvidia-ctk cdi generate --mode=csv --output=/etc/cdi/nvidia.yaml
./scripts/run_dev.sh
```
This will download the necessary docker image and will automatically launch.

### Install ZED SDK in Docker
Now that you are in the Docker terminal, we can begin installing libraries and build ROS 
```
# Install ZED SDK in ROS
sudo chmod +x docker/scripts/install-zed-aarch64.sh 
./docker/scripts/install-zed-aarch64.sh 
```

Verify the ZED SDK is successfully installed
```
# Launch the ZED Explorer
/usr/local/zed/tools/ZED_Explorer	
```

### Download & Build ROS2 ZED Wrapper
```
# Build ROS2 wrapper
cd ${ISAAC_ROS_WS} && \
sudo apt update
rosdep update && rosdep install --from-paths src/zed-ros2-wrapper --ignore-src -r -y && \
colcon build --symlink-install --packages-up-to zed_wrapper
```

### Install dependencies for VSLAM:
```
sudo apt-get update
sudo apt-get install -y ros-humble-isaac-ros-visual-slam
sudo apt-get install -y ros-humble-isaac-ros-examples ros-humble-isaac-ros-stereo-image-proc ros-humble-isaac-ros-zed
```

### Running Isaac ROS Visual SLAM
Run the following launch file to spin up a demo of this package using a ZED Camera:
```
source install/setup.bash

ros2 launch isaac_ros_examples isaac_ros_examples.launch.py \
launch_fragments:=zed_stereo_rect,visual_slam pub_frame_rate:=30.0 \
base_frame:=zed2_camera_center camera_optical_frames:="['zed2_left_camera_optical_frame', 'zed2_right_camera_optical_frame']" \
interface_specs_file:=${ISAAC_ROS_WS}/isaac_ros_assets/isaac_ros_visual_slam/zed2_quickstart_interface_specs.json
```

### Visualizing with RViz
On another terminal, run:
```
cd {$REPO_DIR}
cd isaac_ros_common/
./scripts/run_dev.sh

# Run in docker
rviz2 -d $(ros2 pkg prefix isaac_ros_visual_slam --share)/rviz/default.cfg.rviz
```

## Subsequent Launches
Once you run through the 1st launcher instructions, files are already downloaded into the image. As a result, future launches of isaac-ros-common only requires installing ZED SDKs and dependencies, as well as building the wrapper.

### Jetson
```
cd {$REPO_DIR}
cd isaac_ros_common/
./scripts/run_dev.sh
```

### In Docker
Setup and install dependencies
```
# Install ZED SDK
./docker/scripts/install-zed-aarch64.sh 

sudo apt-get update
sudo apt-get install -y ros-humble-isaac-ros-visual-slam ros-humble-isaac-ros-examples ros-humble-isaac-ros-stereo-image-proc ros-humble-isaac-ros-zed
rosdep update && rosdep install --from-paths src/zed-ros2-wrapper --ignore-src -r -y && \
source install/setup.bash
```

Launch Demo
```
ros2 launch isaac_ros_examples isaac_ros_examples.launch.py \
launch_fragments:=zed_stereo_rect,visual_slam pub_frame_rate:=30.0 \
base_frame:=zed2_camera_center camera_optical_frames:="['zed2_left_camera_optical_frame', 'zed2_right_camera_optical_frame']" \
interface_specs_file:=${ISAAC_ROS_WS}/isaac_ros_assets/isaac_ros_visual_slam/zed2_quickstart_interface_specs.json
```

### Visualizing with RViz
On another terminal, run:
```
cd {$REPO_DIR}
cd isaac_ros_common/
./scripts/run_dev.sh

# Run in docker
rviz2 -d $(ros2 pkg prefix isaac_ros_visual_slam --share)/rviz/default.cfg.rviz
```

### Troubleshooting
If you follow everything and it still doesn't launch ros2 properly, it may be missing quickstart assets. In the docker image, run:
```
# Libraries
sudo apt-get install -y curl jq tar

# Download assets from NGC
NGC_ORG="nvidia"
NGC_TEAM="isaac"
PACKAGE_NAME="isaac_ros_visual_slam"
NGC_RESOURCE="isaac_ros_visual_slam_assets"
NGC_FILENAME="quickstart.tar.gz"
MAJOR_VERSION=3
MINOR_VERSION=2
VERSION_REQ_URL="https://catalog.ngc.nvidia.com/api/resources/versions?orgName=$NGC_ORG&teamName=$NGC_TEAM&name=$NGC_RESOURCE&isPublic=true&pageNumber=0&pageSize=100&sortOrder=CREATED_DATE_DESC"
AVAILABLE_VERSIONS=$(curl -s \
    -H "Accept: application/json" "$VERSION_REQ_URL")
LATEST_VERSION_ID=$(echo $AVAILABLE_VERSIONS | jq -r "
    .recipeVersions[]
    | .versionId as \$v
    | \$v | select(test(\"^\\\\d+\\\\.\\\\d+\\\\.\\\\d+$\"))
    | split(\".\") | {major: .[0]|tonumber, minor: .[1]|tonumber, patch: .[2]|tonumber}
    | select(.major == $MAJOR_VERSION and .minor <= $MINOR_VERSION)
    | \$v
    " | sort -V | tail -n 1
)
if [ -z "$LATEST_VERSION_ID" ]; then
    echo "No corresponding version found for Isaac ROS $MAJOR_VERSION.$MINOR_VERSION"
    echo "Found versions:"
    echo $AVAILABLE_VERSIONS | jq -r '.recipeVersions[].versionId'
else
    mkdir -p ${ISAAC_ROS_WS}/isaac_ros_assets && \
    FILE_REQ_URL="https://api.ngc.nvidia.com/v2/resources/$NGC_ORG/$NGC_TEAM/$NGC_RESOURCE/\
versions/$LATEST_VERSION_ID/files/$NGC_FILENAME" && \
    curl -LO --request GET "${FILE_REQ_URL}" && \
    tar -xf ${NGC_FILENAME} -C ${ISAAC_ROS_WS}/isaac_ros_assets && \
    rm ${NGC_FILENAME}
fi
```