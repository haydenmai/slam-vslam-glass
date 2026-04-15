# ROS1 Noetic + ROS2 Foxy Bridge: Container-Only Workflow

This guide runs everything in containers:

1. ROS1 master in container
2. slam_glass in container
3. ros1_bridge (dynamic_bridge) in container
4. ROS2 bag playback in container

No host ROS install is required.

## Host requirements

Only these are required on host:

1. Docker Desktop (Windows) or Docker Engine (Linux)
2. Docker Compose V2
3. This repository cloned locally

## Step 1: Build bridge image (one-time)

From repository root:

```bash
cd /mnt/c/ros_2wkspc/slam-vslam-glass
docker build -t local/ros1-ros2-bridge:foxy-noetic -f docker-slam/Dockerfile.bridge .
```

## Step 2: Build slam_glass workspace in a temporary ROS1 container (one-time)

Create workspace and copy package from this repository:

```bash
cd /mnt/c/ros_2wkspc/slam-vslam-glass
mkdir -p external/slam_glass_ws/src
rm -rf external/slam_glass_ws/build external/slam_glass_ws/devel
rm -rf external/slam_glass_ws/src/slam_glass
cp -r slam_glass external/slam_glass_ws/src/slam_glass
```

Build fully inside container.
Important: build at `/home/ros1/slam_glass_ws` (same path used by `docker-compose.bridge.yml`) so catkin paths match at runtime.

```bash
docker run --rm -it \
	-v "$PWD/external/slam_glass_ws:/home/ros1/slam_glass_ws" \
	ros:noetic-ros-base \
	bash -lc "
		apt-get update && apt-get install -y build-essential cmake ros-noetic-tf &&
		cd /home/ros1/slam_glass_ws/src/slam_glass &&
		sed -i 's/^#add_definitions(-DVISUALISE)/add_definitions(-DVISUALISE)/' CMakeLists.txt &&
		sed -i '/find_package(Boost REQUIRED COMPONENTS signals)/d' CMakeLists.txt &&
		cd /home/ros1/slam_glass_ws/src/slam_glass/gmapping_export && ./configure &&
		cd .. && make -f Makefile.gmapping &&
		cd /home/ros1/slam_glass_ws &&
		source /opt/ros/noetic/setup.bash &&
		catkin_make -DCATKIN_ENABLE_TESTING=OFF
	"
```

Quick verify:

```bash
docker run --rm -it \
	-v "$PWD/external/slam_glass_ws:/home/ros1/slam_glass_ws" \
	ros:noetic-ros-base \
	bash -lc "source /opt/ros/noetic/setup.bash ; source /home/ros1/slam_glass_ws/devel/setup.bash ; rospack find slam_glass"
```

## Step 3: Prepare ROS2 bags

Put your ROS2 bag folder(s) under `external/ros2_bags`.

```bash
cd /mnt/c/ros_2wkspc/slam-vslam-glass
mkdir -p external/ros2_bags
```

Example:

1. `external/ros2_bags/my_bag/metadata.yaml`
2. `external/ros2_bags/my_bag/*.db3`

## Step 4: Start full container stack

From repository root:

```bash
cd /mnt/c/ros_2wkspc/slam-vslam-glass
docker compose -f docker-slam/docker-compose.bridge.yml up -d ros1_master ros1_slam_glass ros1_bridge ros2_bag_player
```

Check containers:

```bash
docker compose -f docker-slam/docker-compose.bridge.yml ps
```

If `ros1_slam_glass` exits immediately, rebuild Step 2 and restart only that service:

```bash
docker compose -f docker-slam/docker-compose.bridge.yml up -d --force-recreate ros1_slam_glass
docker logs ros1_slam_glass --tail 100
```

Why this happens:

1. A previous build at a different path (for example `/ws`) leaves a stale `devel/.catkin` marker.
2. That can hide `slam_glass` from `rospack` at runtime.
3. The compose service now exports `ROS_PACKAGE_PATH` and `CMAKE_PREFIX_PATH` explicitly to avoid this failure.
4. The runtime container also installs `ros-noetic-tf` on startup, which may take 1-2 minutes the first time.

## Step 5: Play ROS2 bag from container

Inspect bag:

```bash
docker exec -it ros2_bag_player bash -lc "source /opt/ros/foxy/setup.bash ; ros2 bag info /bags/scan_ros2_output_bag"
```

Play bag:

```bash
docker exec -it ros2_bag_player bash -lc "source /opt/ros/foxy/setup.bash ; ros2 bag play /bags/scan_ros2_output_bag"
```

## Step 6: Validate bridge and slam outputs

ROS2 side:

```bash
docker exec -it ros1_bridge bash -lc "source /opt/ros/foxy/setup.bash ; ros2 topic list"
```

ROS1 side:

```bash
docker exec -it ros1_slam_glass bash -lc "source /opt/ros/noetic/setup.bash ; source /home/ros1/slam_glass_ws/devel/setup.bash ; rostopic list"
```

Map topic check:

```bash
docker exec -it ros1_slam_glass bash -lc "source /opt/ros/noetic/setup.bash ; source /home/ros1/slam_glass_ws/devel/setup.bash ; rostopic echo -n 1 /map"
```

