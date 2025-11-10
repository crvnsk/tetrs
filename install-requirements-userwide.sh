!/bin/bash

 Enable strict mode to stop execution on any error
set -e

 Define files for dependencies
PYTHON_REQUIREMENTS="requirements_for_python.txt"    Python dependencies file
ANSIBLE_REQUIREMENTS="requirements_for_ansible.yml"  Ansible dependencies file

 Function to print errors in red and exit
error_exit() {
    echo -e "\e[m$\e[m" >&
    exit 
}

 Ensure the script is not run as root
if [ "$(id -u)" -eq  ]; then
    error_exit "ERROR: This script should not be run as root or with sudo."
fi

 Check if Python dependencies file exists
if [ ! -f "$PYTHON_REQUIREMENTS" ]; then
    error_exit "ERROR: File '$PYTHON_REQUIREMENTS' not found!"
fi

 Check if Ansible dependencies file exists
if [ ! -f "$ANSIBLE_REQUIREMENTS" ]; then
    error_exit "ERROR: File '$ANSIBLE_REQUIREMENTS' not found!"
fi

 Install Python dependencies
echo "Installing Python requirements from '$PYTHON_REQUIREMENTS'..."
pip install -r "$PYTHON_REQUIREMENTS"

 Install Ansible dependencies
echo "Installing Ansible requirements from '$ANSIBLE_REQUIREMENTS'..."
ansible-galaxy install -r "$ANSIBLE_REQUIREMENTS"

echo -e "\e[mInstallation completed successfully.\e[m"
