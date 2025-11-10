!/bin/bash

 Enable strict mode to stop execution on any error
set -e

 Check if the script is running with root privileges
if [ "$(id -u)" -ne  ]; then
    echo "This script must be run as root (or with sudo)."
    exit 
fi

 Function to execute a command with logging
run_command() {
    echo "Executing: $"
    eval $
}

 Update package lists
run_command "apt update"

 Install required packages
run_command "apt install -y mc yq git curl whiptail sed grep openssh-client sshpass openssl python.-venv python.-distutils python-pip"

echo "Installation completed successfully."
