#!/bin/bash
set -euo pipefail

# One-shot bootstrap for first-time VSLAM setup with isaac_ros_common.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR}"
ISAAC_DIR="${REPO_ROOT}/isaac_ros_common"
WRAPPER_DIR="${ISAAC_DIR}/src/zed-ros2-wrapper"

if [ ! -d "${ISAAC_DIR}" ]; then
  echo "Error: isaac_ros_common not found at ${ISAAC_DIR}"
  exit 1
fi

echo "[host] Preparing zed-ros2-wrapper source..."
mkdir -p "${ISAAC_DIR}/src"
if [ ! -d "${WRAPPER_DIR}" ]; then
  git clone --recurse-submodules https://github.com/stereolabs/zed-ros2-wrapper -b humble-v4.2.5 "${WRAPPER_DIR}"
else
  echo "[host] zed-ros2-wrapper already exists, skipping clone"
fi

echo "[host] Ensuring git-lfs is installed..."
if ! command -v git-lfs >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y git-lfs
fi

cd "${ISAAC_DIR}"
git lfs install
# Ignore errors here in case there are no LFS pointers to pull.
git lfs pull || true

echo "[host] Ensuring NVIDIA CDI spec exists..."
if command -v nvidia-ctk >/dev/null 2>&1; then
  sudo nvidia-ctk cdi generate --mode=csv --output=/etc/cdi/nvidia.yaml
else
  echo "[host] Warning: nvidia-ctk not found. Install nvidia-container-toolkit if needed."
fi

read -r -d '' CONTAINER_SETUP_CMD <<'EOF' || true
set -euo pipefail

cd "${ISAAC_ROS_WS}"

sanitize_apt_sources() {
  # Yarn is not required for this VSLAM flow; disable it to avoid apt signature failures.
  if [ -f /etc/apt/sources.list.d/yarn.list ] || [ -f /etc/apt/sources.list.d/yarn.sources ]; then
    echo "[container] Disabling Yarn APT source(s) for reliable apt updates"
    if [ -f /etc/apt/sources.list.d/yarn.list ]; then
      sudo mv -f /etc/apt/sources.list.d/yarn.list /etc/apt/sources.list.d/yarn.list.disabled || true
    fi
    if [ -f /etc/apt/sources.list.d/yarn.sources ]; then
      sudo mv -f /etc/apt/sources.list.d/yarn.sources /etc/apt/sources.list.d/yarn.sources.disabled || true
    fi
  fi
}

if [ -x docker/scripts/install-zed-aarch64.sh ]; then
  if [ ! -d /usr/local/zed ]; then
    echo "[container] Installing ZED SDK..."
    sudo chmod +x docker/scripts/install-zed-aarch64.sh
    ./docker/scripts/install-zed-aarch64.sh
  else
    echo "[container] ZED SDK already detected at /usr/local/zed, skipping install"
  fi
else
  echo "[container] Error: docker/scripts/install-zed-aarch64.sh not found"
  exit 1
fi

echo "[container] Installing VSLAM apt dependencies..."
sanitize_apt_sources
sudo apt-get update
sudo apt-get install -y \
  ros-humble-isaac-ros-visual-slam \
  ros-humble-isaac-ros-examples \
  ros-humble-isaac-ros-stereo-image-proc \
  ros-humble-isaac-ros-zed

echo "[container] Installing zed-ros2-wrapper rosdeps..."
rosdep update
rosdep install --from-paths src/zed-ros2-wrapper --ignore-src -r -y

echo "[container] Building zed_wrapper..."
set +u
source /opt/ros/humble/setup.bash
set -u
colcon build --symlink-install --packages-up-to zed_wrapper
set +u
source install/setup.bash
set -u

echo "[container] First-launch setup complete."
echo "[container] Workspace sourced. You can launch isaac_ros_examples visual_slam demo now."
exec bash
EOF

echo "[host] Launching isaac_ros_common dev container and running first-launch setup..."
"${ISAAC_DIR}/scripts/run_dev.sh" -d "${ISAAC_DIR}" -- -lc "${CONTAINER_SETUP_CMD}"
