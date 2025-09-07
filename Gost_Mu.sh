#!/bin/bash

#================================================================
# Gost All-in-One Helper Script
# Description: A menu-driven script to easily set up gost
#              port forwarding for both server (VPS) and
#              client (NAT machine).
# Features: Auto-download, systemd service creation,
#           interactive setup, status management.
#================================================================

# --- Colors for better readability ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m' # No Color

# --- Global Variables ---
GOST_VERSION="2.11.5" # You can update this to the latest version
GOST_EXEC_PATH="/usr/local/bin/gost"
SYSTEMD_SERVICE_FILE="/etc/systemd/system/gost.service"

# --- Helper Functions ---

# Function to print messages
print_msg() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${C_NC}"
}

# Function to detect system architecture
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64) ARCH="arm64" ;;
        *)
            print_msg "$C_RED" "Error: Unsupported architecture: $ARCH. Exiting."
            exit 1
            ;;
    esac
}

# Function to download and install gost
install_gost() {
    if [ -f "$GOST_EXEC_PATH" ]; then
        print_msg "$C_GREEN" "Gost is already installed at $GOST_EXEC_PATH."
        return
    fi
    
    print_msg "$C_BLUE" "Gost not found. Attempting to download and install..."
    detect_arch
    local download_url="https://github.com/ginuerzh/gost/releases/download/v${GOST_VERSION}/gost-linux-${ARCH}-${GOST_VERSION}.gz"
    
    print_msg "$C_YELLOW" "Downloading from: $download_url"
    
    # Using curl with follow redirects, fail silently on error, and show progress bar
    if ! curl -sSL -o /tmp/gost.gz "$download_url"; then
        print_msg "$C_RED" "Download failed. Please check the URL or your network connection."
        exit 1
    fi
    
    gunzip /tmp/gost.gz
    mv /tmp/gost "$GOST_EXEC_PATH"
    chmod +x "$GOST_EXEC_PATH"
    
    if [ -f "$GOST_EXEC_PATH" ]; then
        print_msg "$C_GREEN" "Gost v$($GOST_EXEC_PATH -V | awk '{print $3}') installed successfully!"
    else
        print_msg "$C_RED" "Installation failed."
        exit 1
    fi
}

# Function to create systemd service file
create_systemd_service() {
    local exec_command="$1"
    print_msg "$C_BLUE" "Creating systemd service file..."
    
    cat > "$SYSTEMD_SERVICE_FILE" << EOF
[Unit]
Description=Gost Tunnel Service
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=$exec_command
Restart=always
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable gost
    print_msg "$C_GREEN" "Systemd service created and enabled successfully!"
    print_msg "$C_YELLOW" "You can now manage the service with 'systemctl [start|stop|status] gost'."
}

# --- Menu Functions ---

# 1. Configure Server (VPS)
configure_server() {
    print_msg "$C_BLUE" "--- Configuring Gost Server (for VPS) ---"
    install_gost
    
    read -p "Enter the port for NAT client to connect (e.g., 8080): " LISTEN_PORT
    read -p "Set a password for authentication (leave empty for none): " AUTH_PASS
    
    local auth_str=""
    if [ -n "$AUTH_PASS" ]; then
        auth_str="user:$AUTH_PASS"
    fi
    
    local command="$GOST_EXEC_PATH -L \"rtun://$auth_str@:$LISTEN_PORT?bind=true\""
    
    create_systemd_service "$command"
    
    local public_ip=$(curl -s4 ip.sb)
    print_msg "$C_GREEN" "\n✅ Server configuration complete!"
    echo "--------------------------------------------------"
    print_msg "$C_YELLOW" "Please use the following details on your NAT machine:"
    print_msg "$C_BLUE" "VPS IP Address: $public_ip"
    print_msg "$C_BLUE" "VPS Gost Port:  $LISTEN_PORT"
    print_msg "$C_BLUE" "Password:       $AUTH_PASS"
    echo "--------------------------------------------------"
    
    read -p "Do you want to start the service now? (y/n): " start_now
    if [[ "$start_now" == "y" || "$start_now" == "Y" ]]; then
        systemctl start gost
        print_msg "$C_GREEN" "Gost service started!"
        sleep 1
        systemctl status gost --no-pager
    fi
}

# 2. Configure Client (NAT Machine)
configure_client() {
    print_msg "$C_BLUE" "--- Configuring Gost Client (for NAT Machine) ---"
    install_gost

    read -p "Enter VPS public IP address: " SERVER_IP
    read -p "Enter VPS gost port (e.g., 8080): " SERVER_PORT
    read -p "Enter the password (leave empty if none): " AUTH_PASS
    
    print_msg "$C_YELLOW" "\nEnter port ranges to forward."
    print_msg "$C_YELLOW" "Example: 10001-10020"
    read -p "Enter LOCAL port range on this NAT machine: " LOCAL_PORTS_RANGE
    read -p "Enter REMOTE port range to expose on VPS: " REMOTE_PORTS_RANGE

    local local_start=$(echo $LOCAL_PORTS_RANGE | cut -d'-' -f1)
    local local_end=$(echo $LOCAL_PORTS_RANGE | cut -d'-' -f2)
    local remote_start=$(echo $REMOTE_PORTS_RANGE | cut -d'-' -f1)
    local remote_end=$(echo $REMOTE_PORTS_RANGE | cut -d'-' -f2)

    if [ $((local_end - local_start)) -ne $((remote_end - remote_start)) ]; then
        print_msg "$C_RED" "Error: Port ranges must have the same number of ports."
        exit 1
    fi

    local auth_str=""
    if [ -n "$AUTH_PASS" ]; then
        auth_str="user:$AUTH_PASS@"
    fi
    
    local forward_chain=""
    local current_remote=$remote_start
    for (( i=$local_start; i<=$local_end; i++ )); do
        forward_chain+=" -F forward+tcp://:$current_remote/127.0.0.1:$i"
        forward_chain+=" -F forward+udp://:$current_remote/127.0.0.1:$i?ttl=0"
        current_remote=$((current_remote + 1))
    done

    local command="$GOST_EXEC_PATH -F rtun://$auth_str$SERVER_IP:$SERVER_PORT$forward_chain"

    create_systemd_service "$command"

    print_msg "$C_GREEN" "\n✅ Client configuration complete!"
    read -p "Do you want to start the service now? (y/n): " start_now
    if [[ "$start_now" == "y" || "$start_now" == "Y" ]]; then
        systemctl start gost
        print_msg "$C_GREEN" "Gost service started!"
        sleep 1
        systemctl status gost --no-pager
    fi
}

# --- Service Management Functions ---
manage_service() {
    local action=$1
    if [ ! -f "$SYSTEMD_SERVICE_FILE" ]; then
        print_msg "$C_RED" "Gost service is not configured yet. Please run setup first."
        return
    fi
    
    case $action in
        start) systemctl start gost ;;
        stop) systemctl stop gost ;;
        status) systemctl status gost --no-pager ;;
        log) journalctl -u gost -f --no-pager ;;
    esac
    
    if [ "$action" != "status" ] && [ "$action" != "log" ]; then
         systemctl status gost --no-pager
    fi
}

# --- Main Menu ---
show_menu() {
    clear
    print_msg "$C_BLUE" "======================================"
    print_msg "$C_BLUE" "   Gost All-in-One Helper Script    "
    print_msg "$C_BLUE" "======================================"
    echo ""
    print_msg "$C_YELLOW" "--- SETUP (Run once) ---"
    print_msg "$C_GREEN" "1. [VPS] Install & Configure Gost Server"
    print_msg "$C_GREEN" "2. [NAT] Install & Configure Gost Client"
    echo ""
    print_msg "$C_YELLOW" "--- MANAGE (After setup) ---"
    print_msg "$C_GREEN" "3. Start Gost Service"
    print_msg "$C_GREEN" "4. Stop Gost Service"
    print_msg "$C_GREEN" "5. Check Gost Service Status"
    print_msg "$C_GREEN" "6. View Gost Service Log"
    echo ""
    print_msg "$C_RED"   "0. Exit"
    echo ""
}

# Check for root user
if [ "$(id -u)" -ne 0 ]; then
    print_msg "$C_RED" "This script must be run as root to manage systemd services."
    exit 1
fi

while true; do
    show_menu
    read -p "Enter your choice [0-6]: " choice
    
    case $choice in
        1) configure_server ;;
        2) configure_client ;;
        3) manage_service "start" ;;
        4) manage_service "stop" ;;
        5) manage_service "status" ;;
        6) manage_service "log" ;;
        0) break ;;
        *) print_msg "$C_RED" "Invalid option. Please try again." ;;
    esac
    
    if [ "$choice" != "0" ]; then
        read -p $'\nPress Enter to continue...'
    fi
done

print_msg "$C_GREEN" "Goodbye!"
