#!/bin/bash

# ==============================================================================
# This script automates the installation of ROS 2 Jazzy on a Raspberry Pi
# running Ubuntu Server 24.04 (Noble Numbat).
#
# It includes checks to make the script idempotent and resumable.
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status.

echo "Starting ROS 2 Jazzy installation on Raspberry Pi..."

# Function to check for command success
check_success() {
  if [ $? -ne 0 ]; then
    echo "ERROR: The last command failed. Exiting script."
    exit 1
  fi
}

# --- STEP 1: Update and Upgrade System ---
echo "--- Step 1: Updating system packages ---"
sudo apt update
check_success
sudo apt upgrade -y
check_success
sudo apt autoremove -y
check_success

# --- STEP 2: Setup Locales ---
echo "--- Step 2: Setting up locales ---"
if locale | grep -q "LANG=en_US.UTF-8"; then
    echo "Locales are already configured. Skipping."
else
    sudo apt install locales -y
    check_success
    sudo locale-gen en_US en_US.UTF-8
    check_success
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    check_success
    export LANG=en_US.UTF-8
fi

# --- STEP 3: Add ROS 2 Repository ---
echo "--- Step 3: Adding ROS 2 repository ---"
if [ -f /etc/apt/sources.list.d/ros2.list ]; then
    echo "ROS 2 repository is already configured. Skipping."
else
    sudo apt install software-properties-common -y
    check_success
    sudo add-apt-repository universe -y
    check_success
    sudo apt update && sudo apt install curl -y
    check_success
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    check_success
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
    check_success
fi

# --- STEP 4: Install ROS 2 Jazzy Base ---
echo "--- Step 4: Installing ros-jazzy-ros-base ---"
if dpkg -s ros-jazzy-ros-base &>/dev/null; then
    echo "ROS 2 Jazzy ros-base is already installed. Skipping."
else
    sudo apt update
    check_success
    sudo apt install ros-jazzy-ros-base -y
    check_success
fi

# --- STEP 5: Install Build Tools and Demos ---
echo "--- Step 5: Installing build tools and demo packages ---"
# Check and install python3-colcon-common-extensions
if dpkg -s python3-colcon-common-extensions &>/dev/null; then
    echo "python3-colcon-common-extensions is already installed. Skipping."
else
    sudo apt install python3-colcon-common-extensions -y
    check_success
fi

# Check and install python3-pip
if dpkg -s python3-pip &>/dev/null; then
    echo "python3-pip is already installed. Skipping."
else
    sudo apt install python3-pip -y
    check_success
fi

# Check and install python3-vcstool
if dpkg -s python3-vcstool &>/dev/null; then
    echo "python3-vcstool is already installed. Skipping."
else
    sudo apt install python3-vcstool -y
    check_success
fi

# Check and install demo nodes
if dpkg -s ros-jazzy-demo-nodes-cpp ros-jazzy-demo-nodes-py &>/dev/null; then
    echo "ROS 2 demo packages are already installed. Skipping."
else
    sudo apt install ros-jazzy-demo-nodes-cpp ros-jazzy-demo-nodes-py -y
    check_success
fi

# --- STEP 6: Source ROS 2 Environment in .bashrc ---
echo "--- Step 6: Setting up .bashrc to source ROS 2 automatically ---"
LINE="source /opt/ros/jazzy/setup.bash"
FILE=~/.bashrc
if grep -qF -- "$LINE" "$FILE"; then
    echo "ROS 2 sourcing line already exists in ~/.bashrc. Skipping."
else
    echo "$LINE" >> "$FILE"
    echo "Added ROS 2 sourcing to ~/.bashrc"
fi
source "$FILE"

# --- STEP 7: Install and Initialize rosdep ---
echo "--- Step 7: Installing and initializing rosdep ---"
# Check if rosdep is already installed
if dpkg -s python3-rosdep &>/dev/null; then
    echo "rosdep is already installed. Skipping installation."
else
    sudo apt install python3-rosdep -y
    check_success
fi

# Check if rosdep has been initialized
if [ -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then
    echo "rosdep has already been initialized. Skipping."
else
    sudo rosdep init
    check_success
fi

rosdep update
check_success

echo "--- ROS 2 installation script finished. ---"
echo "To test the installation, open a new terminal and run the talker and listener nodes:"
echo "In one terminal: ros2 run demo_nodes_cpp talker"
echo "In another terminal: ros2 run demo_nodes_py listener"