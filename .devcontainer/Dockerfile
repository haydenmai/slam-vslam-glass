FROM althack/ros2:humble-dev 

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
        nano \
        tmux \
        ros-humble-navigation2 \
        ros-humble-nav2-bringup \
        ros-humble-turtlebot3-msgs \
        ros-humble-turtlebot3 \
        ros-humble-turtlebot3-gazebo \
        ros-humble-rmw-cyclonedds-cpp \
 && if apt-cache show nvidia-cuda-toolkit >/dev/null 2>&1; then \
            apt-get install -y --no-install-recommends nvidia-cuda-toolkit; \
        else \
            echo "nvidia-cuda-toolkit is not available for this architecture; skipping install"; \
        fi \
 && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog

# Additional pip packages
COPY .devcontainer/requirements.txt /tmp/requirements.txt
RUN pip install --upgrade pip \
 && pip install --no-cache-dir --timeout 2000 -r /tmp/requirements.txt

# Seed workspace content into the image for non-mounted runs.
COPY src/ /opt/ros2_ws_seed/src/
COPY setup/ /opt/ros2_ws_seed/setup/

RUN chown -R ros:ros /opt/ros2_ws_seed


# Set up auto-source of workspace for ros user
ARG WORKSPACE
RUN echo "if [ -f ${WORKSPACE}/install/setup.bash ]; then source ${WORKSPACE}/install/setup.bash; fi" >> /home/ros/.bashrc

# Set env variables for Nav2
RUN echo "export TURTLEBOT3_MODEL=burger" >> /home/ros/.bashrc
RUN echo "export GAZEBO_MODEL_PATH=\$GAZEBO_MODEL_PATH:/opt/ros/humble/share/turtlebot3_gazebo/models" >> /home/ros/.bashrc
RUN echo "export GAZEBO_MODEL_PATH=\$GAZEBO_MODEL_PATH:${WORKSPACE}/install/mpc/share/mpc/models" >> /home/ros/.bashrc
RUN echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> /home/ros/.bashrc
RUN echo "export CYCLONEDDS_URI=${WORKSPACE}/setup/cyclonedds_lo.xml" >> /home/ros/.bashrc
RUN echo "export PATH=/usr/local/cuda/bin:\$PATH" >> /home/ros/.bashrc
RUN echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\${LD_LIBRARY_PATH:-}" >> /home/ros/.bashrc
RUN echo "export ROS_WS_SEED=/opt/ros2_ws_seed" >> /home/ros/.bashrc
