# Testing docker container

### Build & Run
```
# Jetson
docker compose -f docker-compose.jetson.yml build
docker compose -f docker-compose.jetson.yml up -d

# Pi
docker compose -f docker-compose.pi.yml build
docker compose -f docker-compose.pi.yml up -d
```

### Open a shell
```
# Jetson
docker compose -f docker-compose.jetson.yml exec ros2 bash

# Pi
docker compose -f docker-compose.pi.yml exec ros2 bash
```

### Verify
```
ros2 --version
# expected: ros2 humble

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
# on Jetson container
ros2 run demo_nodes_cpp talker

# on Pi container
ros2 run demo_nodes_cpp listener
# expected: Pi listener receives messages published from Jetson
```