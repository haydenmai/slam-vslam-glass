FROM dustynv/ros:humble-ros-base-l4t-r36.2.0

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble
ENV ROS_DOMAIN_ID=0

# --- User setup ---
ARG UID=1000
ARG GID=1000
ENV USERNAME=linda
ENV HOME=/home/$USERNAME

RUN useradd -m $USERNAME && \
    echo "$USERNAME:$USERNAME" | chpasswd && \
    usermod --shell /bin/bash $USERNAME && \
    usermod -aG sudo $USERNAME && \
    mkdir -p /etc/sudoers.d && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    usermod --uid $UID $USERNAME && \
    groupmod --gid $GID $USERNAME

# --- Hardware access ---
RUN groupadd -f render && \
	gpasswd -a $USERNAME video && \
    gpasswd -a $USERNAME dialout && \
    gpasswd -a $USERNAME render

# --- Fix ROS2 GPG key ---
RUN rm -f /usr/share/keyrings/ros-archive-keyring.gpg && \
    rm -f /etc/apt/sources.list.d/ros2.list && \
    apt-get update && apt-get install -y curl gnupg2 && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | \
    gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" \
    > /etc/apt/sources.list.d/ros2.list

# --- ROS2 packages ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-colcon-common-extensions \
    python3-rosdep \
    ros-humble-rviz2 \
    ros-humble-rqt \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-rosbag2-storage-mcap \
    ros-humble-demo-nodes-cpp \
    ros-dev-tools \
    && rm -rf /var/lib/apt/lists/*

# --- Log directory ---
RUN mkdir -p $HOME/.ros/log && \
	chown -R $USERNAME:$USERNAME $HOME/.ros

# --- rosdep ---
RUN rosdep init 2>/dev/null || true && rosdep update

# --- Entrypoint script ---
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# --- Switch to non-root user ---
USER $USERNAME
WORKDIR $HOME/ros2_ws
RUN mkdir -p src

SHELL ["/bin/bash", "-l", "-c"]

# --- Environment ---
RUN echo "source \$ROS_ROOT/install/setup.bash" >> ~/.bashrc && \
    echo "source ~/ros2_ws/install/setup.bash 2>/dev/null || true" >> ~/.bashrc && \
    echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ~/.bashrc && \
    echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc && \
    echo "export ROS_DOMAIN_ID=0" >> ~/.bashrc && \
    echo "export PATH=/usr/local/cuda/bin:$PATH" >> ~/.bashrc && \
    echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH" >> ~/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]