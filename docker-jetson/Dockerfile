FROM dustynv/ros:humble-ros-base-l4t-r36.2.0

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble

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
RUN gpasswd -a $USERNAME video && \
    gpasswd -a $USERNAME dialout && \
    gpasswd -a $USERNAME gpio && \
    gpasswd -a $USERNAME render

# --- ROS2 packages ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-colcon-common-extensions \
    python3-rosdep \
    ros-humble-rviz2 \
    ros-humble-rqt \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-rosbag2-storage-mcap \
    ros-dev-tools \
    && rm -rf /var/lib/apt/lists/*

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
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc && \
    echo "source ~/ros2_ws/install/setup.bash 2>/dev/null || true" >> ~/.bashrc && \
    echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> ~/.bashrc && \
    echo "export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp" >> ~/.bashrc && \
    echo "export PATH=/usr/local/cuda/bin:$PATH" >> ~/.bashrc && \
    echo "export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH" >> ~/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]