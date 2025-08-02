#!/bin/bash

# ==============================================================================
# This script automates the installation of ROS 2 Jazzy on a Raspberry Pi
# running Ubuntu Server 24.04 (Noble Numbat).
#
# It performs the following tasks:
# 1. Updates and upgrades the system.
# 2. Sets up the locale for ROS 2.
# 3. Adds the ROS 2 repository to the system's package list.
# 4. Installs the core ROS 2 Jazzy "ros-base" packages.
# 5. Installs essential build tools like colcon and vcs.
# 6. Installs the ROS 2 demo nodes for verification.
# 7. Configures the bash shell to automatically source the ROS 2 environment.
# 8. Initializes and updates rosdep.
#
# Usage:
# 1. Flash Ubuntu Server 24.04 to your Raspberry Pi's microSD card.
# 2. Configure SSH and WiFi using Raspberry Pi Imager.
# 3. SSH into your Raspberry Pi.
# 4. Clone your GitHub repository containing this script.
# 5. Make the script executable: `chmod +x setup_ros2_jazzy.sh`
# 6. Run the script: `./setup_ros2_jazzy.sh`
#
# Note: This script assumes you are running as a user with sudo privileges.
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status.

echo "Starting ROS 2 Jazzy installation on Raspberry Pi..."

# --- STEP 1: Update and Upgrade System ---
echo "--- Step 1: Updating system packages ---"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

# --- STEP 2: Setup Locales ---
echo "--- Step 2: Setting up locales ---"
sudo apt install locales -y
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

# --- STEP 3: Add ROS 2 Repository ---
echo "--- Step 3: Adding ROS 2 repository ---"
sudo apt install software-properties-common -y
sudo add-apt-repository universe -y
sudo apt update && sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

# --- STEP 4: Install ROS 2 Jazzy Base ---
echo "--- Step 4: Installing ros-jazzy-ros-base ---"
sudo apt update
sudo apt install ros-jazzy-ros-base -y

# --- STEP 5: Install Build Tools and Demos ---
echo "--- Step 5: Installing build tools and demo packages ---"
sudo apt install python3-colcon-common-extensions -y
sudo apt install python3-pip -y
sudo apt install python3-vcstool -y
sudo apt install ros-jazzy-demo-nodes-cpp ros-jazzy-demo-nodes-py -y

# --- STEP 6: Source ROS 2 Environment in .bashrc ---
echo "--- Step 6: Setting up .bashrc to source ROS 2 automatically ---"
LINE="source /opt/ros/jazzy/setup.bash"
FILE=~/.bashrc
if ! grep -qF -- "$LINE" "$FILE"; then
    echo "$LINE" >> "$FILE"
    echo "Added ROS 2 sourcing to ~/.bashrc"
fi
source "$FILE"

# --- STEP 7: Initialize and Update rosdep ---
echo "--- Step 7: Initializing and updating rosdep ---"
sudo rosdep init
rosdep update

echo "--- ROS 2 installation script finished. ---"
echo "To test the installation, open a new terminal and run the talker and listener nodes:"
echo "In one terminal: ros2 run demo_nodes_cpp talker"
echo "In another terminal: ros2 run demo_nodes_py listener"