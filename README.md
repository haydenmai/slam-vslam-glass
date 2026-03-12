# SLAM/VSLAM in Glass Environments
## Overview

## Misc.

## Testing docker container
### Run script
```
# build and start
./start.sh pi up
./start.sh jetson up

# other commands
./start.sh pi build       # build only
./start.sh pi shell       # open a shell inside the container
./start.sh pi logs        # follow logs
./start.sh pi down        # stop the container
./start.sh pi restart     # stop and restart
```

### Verify
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

### Topics
```
ros2 topic list
# expected: /chatter, /rosout, /parameter_events
```

### Verify nodes outside containers
```
# in container
ros2 run demo_nodes_cpp talker

# anywhere else outside container or in another container
ros2 run demo_nodes_cpp listener
```