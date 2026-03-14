#!/usr/bin/env bash
set -e

ROS_DISTRO="${ROS_DISTRO:-humble}"

source "/opt/ros/$ROS_DISTRO/setup.bash"

# NVIDIA container runtime typically mounts CUDA into /usr/local/cuda.
if [ -d "/usr/local/cuda/bin" ]; then
	export PATH="/usr/local/cuda/bin:${PATH}"
fi

if [ -d "/usr/local/cuda/lib64" ]; then
	export LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}"
fi

export NVIDIA_VISIBLE_DEVICES="${NVIDIA_VISIBLE_DEVICES:-all}"
export NVIDIA_DRIVER_CAPABILITIES="${NVIDIA_DRIVER_CAPABILITIES:-compute,utility,graphics,video}"

# Source overlay workspace if available.
if [ -f "${PWD}/install/setup.bash" ]; then
	source "${PWD}/install/setup.bash"
fi

exec "$@"