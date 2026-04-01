# Running VSLAM
## 1st Launch
To start, we need download various libraries and run commands to ensure the ZED SDK is installed. In addition, VSLAM requires to be run in isaac_ros_common, `scripts/run_dev.sh` automatically create and launch a docker image. **Note:** This only needs be run once, subsequent launches can be done with `vslam_subsequent_launch.sh`.

Run `vslam_first_launch.sh` script from the repository root, ensure that the isaac_ros_common submodule is cloned:
```
cd {$REPO_DIR}
git submodule update --init --recursive 
./vslam_first_launch.sh
```

This script automates:
- cloning `zed-ros2-wrapper` (if missing)
- `git-lfs` setup on host
- NVIDIA CDI generation (`nvidia-ctk cdi generate`)
- launching `isaac_ros_common/scripts/run_dev.sh`
- installing ZED SDK in container (if missing)
- installing VSLAM apt dependencies
- rosdep install + `colcon build --packages-up-to zed_wrapper`
- `source install/setup.bash` and opens an interactive shell ready to launch VSLAM

Test if ZED SDK successfully installed
```
# Launch the ZED Explorer
/usr/local/zed/tools/ZED_Explorer	
```

### Running Isaac ROS Visual SLAM
Run the following launch file to spin up a demo of this package with a ZED Camera:
```
ros2 launch isaac_ros_examples isaac_ros_examples.launch.py \
launch_fragments:=zed_stereo_rect,visual_slam pub_frame_rate:=30.0 \
base_frame:=zed2_camera_center camera_optical_frames:="['zed2_left_camera_optical_frame', 'zed2_right_camera_optical_frame']" \
interface_specs_file:=${ISAAC_ROS_WS}/isaac_ros_assets/isaac_ros_visual_slam/zed2_quickstart_interface_specs.json
```

To visualize the VSLAM result, refer to the [Subsequent Launches](#subsequent-launches) section below.

## Subsequent Launches
Once you run through the 1st launcher instructions, files are already mounted into the image. As a result, future launches of isaac-ros-common only requires installing ZED SDKs and dependencies, as well as building the wrapper.

```
cd {$REPO_DIR}
./vslam_subsequent_launch.sh
```

Options:
```
# launch ZED VSLAM demo
./vslam_subsequent_launch.sh --launch

# run RViz only
./vslam_subsequent_launch.sh --rviz

# for both, run in two terminals
./vslam_subsequent_launch.sh --launch
./vslam_subsequent_launch.sh --rviz
```

## Troubleshooting
If you ran `vslam_first_launch.sh` and compiling or launch issues occur, it may be missing the quickstart assets. In the `isaac_ros_common` directory:
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