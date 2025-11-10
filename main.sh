!/bin/bash

 Configuration variables
VENV_DIR=".venv"                                     Virtual environment directory
PYTHON_VERSION="."                                Required Python version
PYTHON_CMD="python${PYTHON_VERSION}"                 Python command name
PYTHON_REQUIREMENTS="requirements_for_python.txt"    Python dependencies file
ANSIBLE_REQUIREMENTS="requirements_for_ansible.yml"  Ansible dependencies file
INVENTORY_FILE="./dev_inventory.ini"                 default inventory file for ansible-playbook
LOG_FILE="./ansible.log"                             default log file for ansible-playbook
ALL_YML_GROUP_VARS="./group_vars/all.yml"            default group_vars file for ansible-playbook
WHIPTAIL_MENU_HEIGHT=                              whiptail menu height
 WHIPTAIL_MENU_HEIGHT=$(( $(tput lines) -  ))       whiptail menu dynamic height
WHIPTAIL_MENU_WIDTH=  whiptail menu width
 WHIPTAIL_MENU_WIDTH=$(( $(tput cols) -  ))         whiptail menu dynamic width
WHIPTAIL_LIST_HEIGHT=  whiptail list height
BUILDSTORAGE_LINUX_SERVER_URI="https://buildstorage.aip.ooo/builds/aa/access-server-installer/refs_heads_developers-infoprotect/"
BUILDSTORAGE_LINUX_GW_URI="https://buildstorage.aip.ooo/builds/aa/gateway-server-linux/release/"

error_exit() {
    echo -e "\e[m$\e[m" >&
    exit 
}

pause() {
    echo
    echo -e "\e[;mPress Enter to continue...\e[m"
    read -r
}

read_log_file() {
    log_path=$

    if [ ! -f "$log_path" ]; then
        echo "Log file not found: $log_path"
        echo -e "\e[;mPress Enter to continue...\e[m"
        read -r
    fi

    less +G "$log_path"
}

delete_log() {
    local log_path="$"

    if [ ! -f "$log_path" ]; then
        echo "Log file not found: $log_path"
        pause

        return
    fi

    rm "$log_path"
    echo "Log deleted: $log_path"
    pause
}

install_requirements() {
    echo "Installing Python requirements from $PYTHON_REQUIREMENTS"
    pip install -r "$PYTHON_REQUIREMENTS" || error_exit "ERROR: Failed to install Python dependencies!"
    mkdir -p "$VENV_DIR/ansible_roles"
    mkdir -p "$VENV_DIR/ansible_collections"
    echo "Installing Ansible requirements from $ANSIBLE_REQUIREMENTS"
    ansible-galaxy install -r "$ANSIBLE_REQUIREMENTS" -p "$VENV_DIR/ansible_roles" || error_exit "ERROR: Failed to install Ansible content!"
    pause
}

git_pull_save() {
    SCRIPT_PATH=$(realpath "$")          Get the full path of the script
    SCRIPT_DIR=$(dirname "$SCRIPT_PATH")  Get the script's directory

    cd "$SCRIPT_DIR" || exit   Change to the script's directory
    git fetch                   Fetch changes

     Check for remote changes
    CHANGES=$(git diff --name-only ..@{upstream})

    if [ -n "$CHANGES" ]; then
        echo "Changes detected, stashing local modifications..."
        git stash --include-untracked  Stash local changes
        echo "Running git pull..."
        git pull --rebase  Pull updates
        echo "Restoring local modifications..."
        git stash pop || echo "No stashed changes to apply."  Restore changes

        if echo "$CHANGES" | grep -q "$(basename "$")"; then
            echo "Script updated, and will be restarted."
            pause
            exec "$SCRIPT_PATH"  Restart script
        fi
    else
        echo "No changes found."
        pause
    fi
}

git_pull_reset() {
    SCRIPT_PATH=$(realpath "$")          Get the full path of the script
    SCRIPT_DIR=$(dirname "$SCRIPT_PATH")  Get the script's directory

    cd "$SCRIPT_DIR" || exit   Change to the script's directory
    git fetch                   Fetch changes

     Check for remote changes
    CHANGES=$(git diff --name-only ..@{upstream})

    if [ -n "$CHANGES" ]; then
        echo "Changes detected, discarding local modifications..."
        git reset --hard  Discard local changes
        echo "Running git pull..."
        git pull --rebase  Pull updates

        if echo "$CHANGES" | grep -q "$(basename "$")"; then
            echo "Script updated, and will be restarted."
            pause
            exec "$SCRIPT_PATH"  Restart script
        fi
    else
        echo "No changes found."
        pause
    fi
}

change_inventory_file() {
    mapfile -t inventory_files < <(find . -maxdepth  -type f -name 'inventory.ini')
    if [ ${inventory_files[@]} -eq  ]; then
        error_exit "ERROR: the project's root directory does not contain inventory.ini files."
    fi

    while true; do
        submenu_choice=$(whiptail --title "$INVENTORY_FILE" --notags --cancel-button "Back" --menu "Choose an ansible inventory file:" "$WHIPTAIL_MENU_HEIGHT" "$WHIPTAIL_MENU_WIDTH" "$WHIPTAIL_LIST_HEIGHT" \
            $(for i in "${!inventory_files[@]}"; do echo "$((i + ))" "${inventory_files[$i]}"; done) \
            >& >& >&)

        submenu_exit_status=$?
        if [ $submenu_exit_status -ne  ]; then
            break
        fi

        INVENTORY_FILE="${inventory_files[$((submenu_choice - ))]}"
    done
}

menu_invalid_choice() {
    whiptail --title "Error" --msgbox "Invalid choice, please try again."  
}

menu_run_playbook() {
    playbook=$

    if [ ! -f "$playbook" ]; then
        error_exit "ERROR: Playbook not found at $playbook"
    fi

    ansible-playbook -i "$INVENTORY_FILE" "$playbook"
    pause
}

menu_run_playbook_dynamically() {
    target_dir=$

     array to store menu (user can see) and playbook paths (paths for ansible-playbook)
    declare -a menu_items=()
    declare -a playbook_paths=()

     directory scan for .playbook.yml files
    shopt -s nullglob
    for full_path in "$target_dir"/.playbook.yml; do
        menu_items+=("$(basename "$full_path")")
        playbook_paths+=("$full_path")
    done
    shopt -u nullglob

     if no playbooks found, exit
    if [ ${menu_items[@]} -eq  ]; then
        error_exit "ERROR: No playbooks found in $target_dir"
    fi

     create menu options
    options=()
    for index in "${!menu_items[@]}"; do
        options+=("$((index + ))" "${menu_items[$index]}")
    done

     show menu and run playbook
    while true; do
        submenu_choice=$(whiptail --title "$INVENTORY_FILE" --notags --cancel-button "Back" --menu "Select playbook to run:" "$WHIPTAIL_MENU_HEIGHT" "$WHIPTAIL_MENU_WIDTH" "$WHIPTAIL_LIST_HEIGHT" "${options[@]}" >& >& >&)

        submenu_exit_status=$?
        if [ $submenu_exit_status -ne  ]; then
            break
        fi

        selected_index=$((submenu_choice - ))
        menu_run_playbook "${playbook_paths[$selected_index]}"
    done
}

parse_build_from_uri() {
    local input_url cleaned_url
    unset base_url
    unset build_number
    unset full_version

    input_url="$"
    cleaned_url="${input_url%/}"   Удаляем trailing slash если есть

    echo "DEBUG: Input URL: $input_url" >&
    echo "DEBUG: Cleaned URL: $cleaned_url" >&

     Проверяем формат ..x
    if [[ "$cleaned_url" =~ ^(.)/([-]+\.[-]+\.[-]+x[-]+)/?$ ]]; then
        base_url="${BASH_REMATCH[]}"
        full_version="${BASH_REMATCH[]}"
        build_number=$(echo "$full_version" | awk -F'x' '{print $}')
        
        echo "DEBUG: Pattern ..xXXXX matched" >&
        echo "DEBUG: Base URL: $base_url" >&
        echo "DEBUG: Full version: $full_version" >&
        echo "DEBUG: Build number: $build_number" >&
        return 
    fi

     Проверяем формат с простым номером сборки (XXXX)
    if [[ "$cleaned_url" =~ ^(.)/([-]+)/?$ ]]; then
        base_url="${BASH_REMATCH[]}"
        build_number="${BASH_REMATCH[]}"
        full_version="$build_number"
        
        echo "DEBUG: Simple build number pattern matched" >&
        echo "DEBUG: Base URL: $base_url" >&
        echo "DEBUG: Build number: $build_number" >&
        return 
    fi

     Если ничего не совпало
    echo "DEBUG: URL format not recognized" >&
    echo "DEBUG: URL must end with either:" >&
    echo "DEBUG:   ) /..xXXXX (e.g. /..x)" >&
    echo "DEBUG:   ) /XXXX (e.g. /)" >&
    error_exit "ERROR: Invalid URL format - must end with version (..xXXXX) or build number"
}

combine_uri() {
    local uri uri scheme_host result
    uri="$"
    uri="$"

    if [[ -z "$uri" ]]; then
        echo "$uri"
        return 
    fi

    if [[ "$uri" =~ ^https?:// ]]; then
        echo "$uri"
        return 
    fi

    scheme_host=$(echo "$uri" | sed -E 's|^(https?://[^/]+)/.|\|')
    result="${scheme_host}${uri}"
    result=$(echo "$result" | sed -E 's|([^:])//|\/|g')

    echo "$result"
    return 
}

browse_uri() {
    local uri html submenu_choice links options i

    if [ -z "$" ]; then
        error_exit "ERROR: no base URI provided"
    fi

    uri=$(combine_uri "$" "$")
    html=$(curl -s "$uri")
    if [ $? -ne  ]; then
        error_exit "ERROR: failed to send request to '$uri'"
    fi

    links=()
    options=()
    i=
    while IFS= read -r line; do
        href=$(echo "$line" | sed -E 's/.[hH][rR][eE][fF]="([^"])"./\/')
        text=$(echo "$line" | sed -E 's/.[hH][rR][eE][fF]="[^"]">(.)<\/[aA]>./\/' | sed 's/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g')
        if [[ "$href" == / ]]; then
         If link ends with a slash, it's a folder
            links+=("$href")
        else
             Else - file
            links+=("$uri")
        fi
        
        options+=("$i" "$text")
        i=$((i + ))
    done < <(echo "$html" | grep -Eio '<a [^>]href="[^"]"[^>]>[^<]</a>')

    while true; do
        unset base_url      global vars, using to pass values between functions
        unset build_number  global vars, using to pass values between functions
        submenu_choice=$(whiptail --title "$uri" --notags --ok-button "Go" --cancel-button "Use this build" --menu "Directory browser (ESC. for exit):" "$WHIPTAIL_MENU_HEIGHT" "$WHIPTAIL_MENU_WIDTH" "$WHIPTAIL_LIST_HEIGHT" "${options[@]}" >& >& >&)

        exit_status=$?
        if [ $exit_status -eq  ]; then
            parse_build_from_uri "$uri"
            break
        fi

        if [ $exit_status -eq  ]; then
            break
        fi

        browse_uri "$" "${links[$submenu_choice]}"
        break
    done
}

set_linux_cf_server_build() {
    local base_uri build_number
    base_uri="${%/}/"
    full_version="$"   Теперь принимаем полную версию (..x)
    build_number=$(echo "$full_version" | awk -F'x' '{print $}')

    yq -y -i --arg val "$base_uri" '.["product"]["cf_server"]["linux"]["base_uri"] = $val' "$ALL_YML_GROUP_VARS"
    if [ $? -ne  ]; then
        error_exit "ERROR: failed to set linux cf_server build base_uri in $ALL_YML_GROUP_VARS"
    fi

    if [ -z "$build_number" ]; then
        yq -y -i '.["product"]["cf_server"]["linux"]["version"] = null' "$ALL_YML_GROUP_VARS"
    else
        yq -y -i --arg val "$build_number" '.["product"]["cf_server"]["linux"]["version"] = ($val | tonumber)' "$ALL_YML_GROUP_VARS"
    fi || {
        error_exit "ERROR: failed to set linux cf_server build version in $ALL_YML_GROUP_VARS"
    }

    yq -y -i '.["product"]["cf_server"]["linux"]["installers"] = null' "$ALL_YML_GROUP_VARS"
    if [ $? -ne  ]; then
        error_exit "ERROR: failed to set linux cf_server installers path in $ALL_YML_GROUP_VARS"
    fi

    return 
}

set_linux_gw_server_build() {
    local base_uri build_number
    base_uri="${%/}/"
    full_version="$"   Теперь принимаем полную версию (..x)
    build_number=$(echo "$full_version" | awk -F'x' '{print $}')

    yq -y -i --arg val "$base_uri" '.["product"]["gw_server"]["linux"]["base_uri"] = $val' "$ALL_YML_GROUP_VARS"
    if [ $? -ne  ]; then
        error_exit "ERROR: failed to set linux gw_server build base_uri in $ALL_YML_GROUP_VARS"
    fi

    if [ -z "$build_number" ]; then
        yq -y -i '.["product"]["gw_server"]["linux"]["version"] = null' "$ALL_YML_GROUP_VARS"
    else
        yq -y -i --arg val "$build_number" '.["product"]["gw_server"]["linux"]["version"] = ($val | tonumber)' "$ALL_YML_GROUP_VARS"
    fi || {
        error_exit "ERROR: failed to set linux gw_server build version in $ALL_YML_GROUP_VARS"
    }

    yq -y -i '.["product"]["gw_server"]["linux"]["installers"] = null' "$ALL_YML_GROUP_VARS"
    if [ $? -ne  ]; then
        error_exit "ERROR: failed to set linux gw_server installers path in $ALL_YML_GROUP_VARS"
    fi

    return 
}

 Check for Python
if ! command -v $PYTHON_CMD &>/dev/null; then
    error_exit "ERROR: Python $PYTHON_VERSION is not installed!"
fi

 Check for pip
if ! $PYTHON_CMD -m pip --version &>/dev/null; then
    error_exit "ERROR: pip for Python $PYTHON_VERSION is missing!"
fi

 Check venv module
if ! $PYTHON_CMD -c "import venv" &>/dev/null; then
    error_exit "ERROR: venv module missing. Install python$PYTHON_VERSION-venv package!"
fi

 Check Python dependencies file
if [ ! -f "$PYTHON_REQUIREMENTS" ]; then
    error_exit "ERROR: $PYTHON_REQUIREMENTS not found!"
fi

 Check Ansible dependencies file
if [ ! -f "$ANSIBLE_REQUIREMENTS" ]; then
    error_exit "ERROR: $ANSIBLE_REQUIREMENTS not found!"
fi

 Check default inventory file exists
if [ ! -f "$INVENTORY_FILE" ]; then
    error_exit "ERROR: Ansible default inventory file $INVENTORY_FILE not found!"
fi

 Check whiptail is installed
if ! command -v whiptail &>/dev/null; then
    error_exit "ERROR: whiptail is not installed!"
fi

 Check .venv directory exists otherwise create it
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating new virtual environment in $VENV_DIR..."
    $PYTHON_CMD -m venv "$VENV_DIR" || error_exit "ERROR: Failed to create virtual environment!"
fi

 Activate .venv environment
source "$VENV_DIR/bin/activate"

 Verify Python version in .venv
venv_python_version=$(python --version >&)
if [[ ! $venv_python_version =~ ^Python\ $PYTHON_VERSION ]]; then
    echo "ERROR: Virtual environment has $venv_python_version (required $PYTHON_VERSION)"
    deactivate
    error_exit "Please remove $VENV_DIR and try again"
fi

while true; do
    choice=$(whiptail --title "$INVENTORY_FILE" --cancel-button "Exit" --menu "Main menu:" "$WHIPTAIL_MENU_HEIGHT" "$WHIPTAIL_MENU_WIDTH" "$WHIPTAIL_LIST_HEIGHT" \
        "" "product installation" \
        "" "product uninstallation" \
        "" "product builds" \
        "" "NOT USED new database setup" \
        "" "NOT USED api actions" \
        "" "NOT USED synthetic events generation" \
        "" "dbg" \
        "" "misc" \
        >& >& >&)

    exit_status=$?
    if [ $exit_status -ne  ]; then
        clear
        exit 
    fi

    case $choice in
    )
         product installation
        while true; do
            submenu_choice=$(whiptail --title "$INVENTORY_FILE" --cancel-button "Back" --menu "Product installation options:" "$WHIPTAIL_MENU_HEIGHT" "$WHIPTAIL_MENU_WIDTH" "$WHIPTAIL_LIST_HEIGHT" \
                "" "CF Server + GW Server" \
                "" "CF Server" \
                "" "GW Server" \
                >& >& >&)

            submenu_exit_status=$?
            if [ $submenu_exit_status -ne  ]; then
                break
            fi

            case $submenu_choice in
            ) menu_run_playbook "playbooks/product_full_install.playbook.yml" ;;
            ) menu_run_playbook "playbooks/product_cf_server_install.playbook.yml" ;;
            ) menu_run_playbook "playbooks/product_gw_server_install.playbook.yml" ;;
            ) menu_invalid_choice ;;
            esac
        done
        ;;
    )
         product uninstallation
        while true; do
            submenu_choice=$(whiptail --title "$INVENTORY_FILE" --cancel-button "Back" --menu "Product uninstallation options:" "$WHIPTAIL_MENU_HEIGHT" "$WHIPTAIL_MENU_WIDTH" "$WHIPTAIL_LIST_HEIGHT" \
                "" "CF Server + GW Server" \
                "" "CF Server" \
                "" "GW Server" \
                >& >& >&)

            submenu_exit_status=$?
            if [ $submenu_exit_status -ne  ]; then
                break
            fi

            case $submenu_choice in
            ) menu_run_playbook "playbooks/product_full_uninstall.playbook.yml" ;;
            ) menu_run_playbook "playbooks/product_cf_server_uninstall_playbook.yml" ;;
            ) menu_run_playbook "playbooks/product_gw_server_uninstall_playbook.yml" ;;
            ) menu_invalid_choice ;;
            esac
        done
        ;;
    )
         product builds
        while true; do
            submenu_choice=$(whiptail --title "$INVENTORY_FILE" --cancel-button "Back" --menu "Product builds:" "$WHIPTAIL_MENU_HEIGHT" "$WHIPTAIL_MENU_WIDTH" "$WHIPTAIL_LIST_HEIGHT" \
                "" "Select linux CF Server build" \
                "" "Select linux GW Server build" \
                "" "Download CF Server + GW Server" \
                >& >& >&)

            submenu_exit_status=$?
            if [ $submenu_exit_status -ne  ]; then
                break
            fi

            case $submenu_choice in
             Set linux cf_server build
            )
                buildstorage_linux_cf_server_base_uri=$(yq -r '.["product"]["cf_server"]["linux"]["base_uri"]' "$ALL_YML_GROUP_VARS")
                unset base_url      global vars, using to pass values between functions
                unset build_number  global vars, using to pass values between functions
                browse_uri "$buildstorage_linux_cf_server_base_uri"
                if [ -n "$base_url" ] && [ -n "$build_number" ]; then
                    set_linux_cf_server_build "$base_url" "$build_number"
                    echo "Linux cf server build set to $build_number"
                    pause
                fi
                ;;
                 Set linux gw_server build
            )
                buildstorage_linux_gw_server_base_uri=$(yq -r '.["product"]["gw_server"]["linux"]["base_uri"]' "$ALL_YML_GROUP_VARS")
                unset base_url      global vars, using to pass values between functions
                unset build_number  global vars, using to pass values between functions
                browse_uri "$buildstorage_linux_gw_server_base_uri"
                if [ -n "$base_url" ] && [ -n "$build_number" ]; then
                    set_linux_gw_server_build "$base_url" "$build_number"
                    echo "Linux gw_server build set to $build_number"
                    pause
                fi
                ;;
            ) menu_run_playbook "playbooks/downloader/product_download_installers.playbook.yml" ;;
            ) menu_invalid_choice ;;
            esac
        done
        ;;
    )
         new database setup
        while true; do
            submenu_choice=$(whiptail --title "$INVENTORY_FILE" --cancel-button "Back" --menu "Create new database:" "$WHIPTAIL_MENU_HEIGHT" "$WHIPTAIL_MENU_WIDTH" "$WHIPTAIL_LIST_HEIGHT" \
                "" "DLES" \
                "" "SDB" \
                >& >& >&)

            submenu_exit_status=$?
            if [ $submenu_exit_status -ne  ]; then
                break
            fi

            case $submenu_choice in
            ) menu_run_playbook "playbooks/databases/db_dles_create_new_and_use.playbook.yml" ;;
            ) menu_run_playbook "playbooks/databases/db_sdb_create_new_and_use.playbook.yml" ;;
            ) menu_invalid_choice ;;
            esac
        done
        ;;
    )
         api actions
        while true; do
            submenu_choice=$(whiptail --title "$INVENTORY_FILE" --cancel-button "Back" --menu "API actions::" "$WHIPTAIL_MENU_HEIGHT" "$WHIPTAIL_MENU_WIDTH" "$WHIPTAIL_LIST_HEIGHT" \
                "" "Set management server (default policy)" \
                "" "Register agents (computer list + default policy)" \
                "" "Set LDAP connection settings" \
                "" "Licenses" \
                >& >& >&)

            submenu_exit_status=$?
            if [ $submenu_exit_status -ne  ]; then
                break
            fi

            case $submenu_choice in
            ) menu_run_playbook "playbooks/web_api/api_set_management_server.playbook.yml" ;;
            ) menu_run_playbook "playbooks/web_api/api_register_agents.playbook.yml" ;;
            ) menu_run_playbook "playbooks/web_api/api_set_ldap_connection_settings.playbook.yml" ;;
            ) menu_run_playbook_dynamically "playbooks/web_api/licenses" ;;
            ) menu_invalid_choice ;;
            esac
        done
        ;;
    )
         synthetic events
        menu_run_playbook_dynamically "playbooks/synthetics"
        ;;
    )
         dbg
        menu_run_playbook_dynamically "playbooks/debug"
        ;;
    )
         misc
        while true; do
            submenu_choice=$(whiptail --title "$INVENTORY_FILE" --cancel-button "Back" --menu "Misc:" "$WHIPTAIL_MENU_HEIGHT" "$WHIPTAIL_MENU_WIDTH" "$WHIPTAIL_LIST_HEIGHT" \
                "" "Change ansible inventory file" \
                "" "Show ./ansible.log (q - to quit)" \
                "" "Delete ./ansible.log" \
                "" "Git pull (save local changes)" \
                "" "Git pull (reset local changes)" \
                "" "Install requirements (.venv)" \
                >& >& >&)

            submenu_exit_status=$?
            if [ $submenu_exit_status -ne  ]; then
                break
            fi

            case $submenu_choice in
            ) change_inventory_file ;;
            ) read_log_file "$LOG_FILE" ;;
            ) delete_log "$LOG_FILE" ;;
            ) git_pull_save ;;
            ) git_pull_reset ;;
            ) install_requirements ;;
            ) menu_invalid_choice ;;
            esac
        done
        ;;
    ) menu_invalid_choice ;;
    esac
done
