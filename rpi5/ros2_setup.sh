#!/usr/bin/env bash

# ==============================================================================
# This script automates the installation of ROS 2 Jazzy on a Raspberry Pi
# running Ubuntu Server 24.04 (Noble Numbat).
#
# The script is idempotent and can be run multiple times without causing
# errors or unwanted changes.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status,
# treat unset variables as an error, and exit if a command in a pipeline fails.
set -euo pipefail

# --- GLOBAL VARIABLES ---
readonly ROS_DISTRO="jazzy"
readonly ROS_SOURCE_LINE="source /opt/ros/$ROS_DISTRO/setup.bash"
readonly ROS_BASHRC_FILE="$HOME/.bashrc"
readonly LOG_FILE="./ros2_install.log"

# --- MAIN EXECUTION ---
main() {
    # Redirect all output to a log file and stdout
    exec > >(tee -a "$LOG_FILE") 2>&1

    echo "Starting ROS 2 $ROS_DISTRO installation on Raspberry Pi..."
    echo "---"

    # --- Pre-installation checks ---
    if [[ "$EUID" -eq 0 ]]; then
        echo "ERROR: This script must not be run with sudo. Please run it as a normal user."
        exit 1
    fi

    if ! grep -q "UBUNTU_CODENAME=noble" /etc/os-release; then
        echo "ERROR: This script is for Ubuntu 24.04 (Noble Numbat). Aborting."
        exit 1
    fi

    # --- Installation steps ---
    update_system
    setup_locales
    add_ros_repository
    install_ros_packages
    setup_bashrc

    echo "---"
    echo "✅ ROS 2 $ROS_DISTRO installation completed successfully!"
    echo "Please restart your shell or run 'source $ROS_BASHRC_FILE' to use ROS 2."
    echo "A log of this installation can be found in '$LOG_FILE'."
}

# --- FUNCTIONS ---

# Function to update and upgrade the system
update_system() {
    echo "--- Step 1: Updating and upgrading system packages ---"
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get autoremove -y
    echo "System packages updated."
}

# Function to set up locales
setup_locales() {
    echo "--- Step 2: Setting up locales ---"
    if ! locale -a | grep -q 'en_US.utf8'; then
        echo "Locales 'en_US.UTF-8' are not configured. Installing and setting now."
        sudo apt-get install -y locales
        sudo locale-gen en_US.UTF-8
        sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
        export LANG=en_US.UTF-8
        echo "Locales configured and set to 'en_US.UTF-8'."
    else
        echo "Locales 'en_US.UTF-8' are already configured. Skipping."
    fi
}

# Function to add the ROS 2 repository
add_ros_repository() {
    echo "--- Step 3: Adding ROS 2 repository ---"
    if [[ -f "/etc/apt/sources.list.d/ros2.list" ]]; then
        echo "ROS 2 repository is already configured. Skipping."
        return
    fi

    echo "Configuring ROS 2 repository..."
    sudo apt-get install -y software-properties-common curl
    sudo add-apt-repository universe -y

    # Download and add the GPG key
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | sudo tee /usr/share/keyrings/ros-archive-keyring.gpg > /dev/null

    # Add the repository to sources.list
    local os_codename
    os_codename=$(. /etc/os-release && echo "$UBUNTU_CODENAME")
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $os_codename main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

    sudo apt-get update
    echo "ROS 2 repository successfully added and system updated."
}

# Function to install ROS 2 Jazzy Base, build tools, and rosdep
install_ros_packages() {
    echo "--- Step 4: Installing ROS 2 packages, build tools, and rosdep ---"

    declare -a required_packages=(
        "ros-${ROS_DISTRO}-ros-base"
        "python3-colcon-common-extensions"
        "python3-pip"
        "python3-vcstool"
        "python3-rosdep"  # Added rosdep
        "ros-${ROS_DISTRO}-demo-nodes-cpp"
        "ros-${ROS_DISTRO}-demo-nodes-py"
    )

    # Use a single `apt-get` command for efficiency
    sudo apt-get install -y "${required_packages[@]}"
    echo "ROS 2 packages installed successfully."

    # Install and initialize rosdep
    echo "--- Initializing and updating rosdep ---"
    # This command may fail if it has been run before, but that is expected and safe to ignore.
    sudo rosdep init || true
    rosdep update
    echo "rosdep initialized and updated."
}

# Function to set up the environment
setup_bashrc() {
    echo "--- Step 5: Setting up .bashrc ---"
    if grep -qF "$ROS_SOURCE_LINE" "$ROS_BASHRC_FILE"; then
        echo "ROS 2 environment is already sourced in $ROS_BASHRC_FILE. Skipping."
        return
    fi
    
    echo "Sourcing ROS 2 environment in $ROS_BASHRC_FILE..."
    
    # Check if the file is writable by the current user
    if [[ ! -w "$ROS_BASHRC_FILE" ]]; then
        echo "ERROR: Cannot write to $ROS_BASHRC_FILE. Check file permissions."
        exit 1
    fi
    
    cat >> "$ROS_BASHRC_FILE" << EOF

# Source ROS 2 $ROS_DISTRO environment
$ROS_SOURCE_LINE
EOF
    
    echo ".bashrc updated successfully."
}

# Call the main function
main