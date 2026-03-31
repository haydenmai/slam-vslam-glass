#!/bin/bash
set -euo pipefail

# Subsequent-launch helper for VSLAM after first-time setup is complete.
# Usage:
#   bash vslam_subsequent_launch.sh
#   bash vslam_subsequent_launch.sh --launch
#   bash vslam_subsequent_launch.sh --launch --rviz
#   bash vslam_subsequent_launch.sh --launch --rebuild

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"
ISAAC_DIR="${REPO_ROOT}/isaac_ros_common"

DO_LAUNCH=0
DO_RVIZ=0
DO_REBUILD=0

usage() {
  echo "Usage: bash vslam_subsequent_launch.sh [--launch] [--rviz] [--rebuild]"
  echo ""
  echo "  --launch   Launch Isaac ROS Visual SLAM demo inside container"
  echo "  --rviz     Start rviz2 with visual_slam config (implies --launch not required)"
  echo "  --rebuild  Rebuild zed_wrapper in container before launching"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --launch)
      DO_LAUNCH=1
      shift
      ;;
    --rviz)
      DO_RVIZ=1
      shift
      ;;
    --rebuild)
      DO_REBUILD=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [ ! -d "${ISAAC_DIR}" ]; then
  echo "Error: isaac_ros_common not found at ${ISAAC_DIR}"
  exit 1
fi

read -r -d '' BASE_CMD <<'EOF' || true
set -euo pipefail
cd "${ISAAC_ROS_WS}"

if [ ! -d /usr/local/zed ]; then
  echo "[container] ZED SDK not found at /usr/local/zed."
  echo "[container] Run: bash vslam_first_launch.sh"
  exit 1
fi

if [ ! -d src/zed-ros2-wrapper ]; then
  echo "[container] src/zed-ros2-wrapper not found in workspace."
  echo "[container] Run: bash vslam_first_launch.sh"
  exit 1
fi

set +u
source /opt/ros/humble/setup.bash
source install/setup.bash 2>/dev/null || true
set -u

echo "[container] Environment ready."
echo "[container] You are now in ${ISAAC_ROS_WS}."
EOF

LAUNCH_CMD=""
if [[ ${DO_LAUNCH} -eq 1 ]]; then
  read -r -d '' LAUNCH_CMD <<'EOF' || true
ros2 launch isaac_ros_examples isaac_ros_examples.launch.py \
launch_fragments:=zed_stereo_rect,visual_slam pub_frame_rate:=30.0 \
base_frame:=zed2_camera_center camera_optical_frames:="['zed2_left_camera_optical_frame', 'zed2_right_camera_optical_frame']" \
interface_specs_file:=${ISAAC_ROS_WS}/isaac_ros_assets/isaac_ros_visual_slam/zed2_quickstart_interface_specs.json
EOF
fi

RVIZ_CMD=""
if [[ ${DO_RVIZ} -eq 1 ]]; then
  read -r -d '' RVIZ_CMD <<'EOF' || true
rviz2 -d $(ros2 pkg prefix isaac_ros_visual_slam --share)/rviz/default.cfg.rviz
EOF
fi

REBUILD_CMD=""
if [[ ${DO_REBUILD} -eq 1 ]]; then
  read -r -d '' REBUILD_CMD <<'EOF' || true
echo "[container] Rebuilding zed_wrapper..."
set +u
source /opt/ros/humble/setup.bash
set -u
colcon build --symlink-install --packages-up-to zed_wrapper
set +u
source install/setup.bash
set -u
EOF
fi

FULL_CMD="${BASE_CMD}"
if [[ ${DO_REBUILD} -eq 1 ]]; then
  FULL_CMD+=$'\n'
  FULL_CMD+="${REBUILD_CMD}"
fi

CONTAINER_SCRIPT_HOST_PATH="${ISAAC_DIR}/.vslam_subsequent_cmd.sh"

run_container_script() {
  local cmd_content="$1"

  cat > "${CONTAINER_SCRIPT_HOST_PATH}" <<'EOF'
#!/bin/bash
EOF
  printf "%s\n" "${cmd_content}" >> "${CONTAINER_SCRIPT_HOST_PATH}"
  chmod +x "${CONTAINER_SCRIPT_HOST_PATH}"

  # Use a single-token command string to avoid run_dev.sh splitting multiline -lc args.
  "${ISAAC_DIR}/scripts/run_dev.sh" -d "${ISAAC_DIR}" -- -lc '${ISAAC_ROS_WS}/.vslam_subsequent_cmd.sh'
}

if [[ ${DO_LAUNCH} -eq 0 && ${DO_RVIZ} -eq 0 ]]; then
  if [[ ${DO_REBUILD} -eq 1 ]]; then
    echo "[host] Rebuild requested: zed_wrapper will be built before opening shell."
  fi
  echo "[host] Starting/attaching isaac_ros_common dev container shell..."
  FULL_CMD+=$'\nexec bash'
  run_container_script "${FULL_CMD}"
  exit 0
fi

if [[ ${DO_LAUNCH} -eq 1 && ${DO_RVIZ} -eq 0 ]]; then
  if [[ ${DO_REBUILD} -eq 1 ]]; then
    echo "[host] Rebuild requested: zed_wrapper will be built before VSLAM launch."
  fi
  echo "[host] Starting/attaching container and launching VSLAM..."
  FULL_CMD+=$'\n'
  FULL_CMD+="${LAUNCH_CMD}"
  run_container_script "${FULL_CMD}"
  exit 0
fi

if [[ ${DO_LAUNCH} -eq 0 && ${DO_RVIZ} -eq 1 ]]; then
  if [[ ${DO_REBUILD} -eq 1 ]]; then
    echo "[host] Rebuild requested: zed_wrapper will be built before rviz2 launch."
  fi
  echo "[host] Starting/attaching container and launching rviz2..."
  FULL_CMD+=$'\n'
  FULL_CMD+="${RVIZ_CMD}"
  run_container_script "${FULL_CMD}"
  exit 0
fi

echo "[host] --launch and --rviz requested."
echo "[host] Start VSLAM in one terminal and rviz2 in another terminal with the commands below:"
echo "  Terminal 1: bash vslam_subsequent_launch.sh --launch"
echo "  Terminal 2: bash vslam_subsequent_launch.sh --rviz"
