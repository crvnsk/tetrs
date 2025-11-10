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

 Detect Ubuntu or Debian version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
    ubuntu)
        UBUNTU_CODENAME=$UBUNTU_CODENAME
        ;;
    debian)
        case "$VERSION_CODENAME" in
        bookworm) UBUNTU_CODENAME="jammy" ;;
        bullseye) UBUNTU_CODENAME="focal" ;;
        buster) UBUNTU_CODENAME="bionic" ;;
        )
            echo "Unsupported Debian version: $VERSION_CODENAME"
            exit 
            ;;
        esac
        ;;
    )
        echo "Unsupported OS: $ID"
        exit 
        ;;
    esac
else
    echo "Cannot determine OS version."
    exit 
fi

echo "Detected OS: $PRETTY_NAME"
echo "Mapped Ubuntu codename: $UBUNTU_CODENAME"

 Add Ansible GPG key
run_command "wget -O- 'https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=xEACFFBBDBCAFDBBC' | gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg"

 Add Ansible repository
run_command "echo 'deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main' | tee /etc/apt/sources.list.d/ansible.list"

 Update package lists and install Ansible
run_command "apt update && apt install -y ansible"

echo "Ansible installation completed successfully."
