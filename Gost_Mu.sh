#!/bin/bash

#================================================================
# Gost V3 All-in-One Helper Script (Bilingual)
# Repository: https://github.com/go-gost/gost
# Features: Bilingual (EN/ZH), V3 support, Auto-download,
#           systemd service creation, interactive setup.
#================================================================

# --- Script configuration ---
GOST_VERSION="3.0.0-rc2" # You can update this to the latest V3 version
GOST_REPO="go-gost/gost"
GOST_EXEC_PATH="/usr/local/bin/gost"
SYSTEMD_SERVICE_FILE="/etc/systemd/system/gost.service"

# --- Colors for better readability ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m' # No Color

# --- Language Strings ---
# English
EN_MSG_ROOT_REQUIRED="This script must be run as root to manage systemd services."
EN_MENU_TITLE="Gost V3 All-in-One Helper Script"
EN_MENU_SETUP="--- SETUP (Run once) ---"
EN_MENU_VPS="[VPS] Install & Configure Server"
EN_MENU_NAT="[NAT] Install & Configure Client"
EN_MENU_MANAGE="--- MANAGE (After setup) ---"
EN_MENU_START="Start Gost Service"
EN_MENU_STOP="Stop Gost Service"
EN_MENU_STATUS="Check Gost Service Status"
EN_MENU_LOG="View Gost Service Log"
EN_MENU_UNINSTALL="Uninstall Gost"
EN_MENU_EXIT="Exit"
EN_PROMPT_CHOICE="Enter your choice"
EN_PROMPT_CONTINUE="Press Enter to continue..."
EN_MSG_INVALID_OPTION="Invalid option. Please try again."
EN_MSG_GOODBYE="Goodbye!"
EN_CONFIG_SERVER_TITLE="--- Configuring Gost Server (for VPS) ---"
EN_CONFIG_CLIENT_TITLE="--- Configuring Gost Client (for NAT Machine) ---"
EN_GOST_INSTALLED="Gost is already installed."
EN_GOST_NOT_FOUND="Gost not found. Attempting to download and install..."
EN_DOWNLOAD_FROM="Downloading from:"
EN_DOWNLOAD_FAILED="Download failed. Please check the URL or your network."
EN_INSTALL_SUCCESS="Gost installed successfully!"
EN_INSTALL_FAILED="Installation failed."
EN_SYSTEMD_CREATING="Creating systemd service file..."
EN_SYSTEMD_SUCCESS="Systemd service created and enabled successfully!"
EN_SYSTEMD_MANAGE="You can now manage the service with 'systemctl [start|stop|status] gost'."
EN_PROMPT_LISTEN_PORT="Enter the port for NAT client to connect (e.g., 8080):"
EN_PROMPT_PASSWORD="Set a password for authentication (leave empty for none):"
EN_CONFIG_SERVER_DONE="✅ Server configuration complete!"
EN_CONFIG_CLIENT_GUIDE="Please use the following details on your NAT machine:"
EN_INFO_VPS_IP="VPS IP Address:"
EN_INFO_VPS_PORT="VPS Gost Port:"
EN_INFO_PASSWORD="Password:"
EN_PROMPT_START_NOW="Do you want to start the service now? (y/n):"
EN_SERVICE_STARTED="Gost service started!"
EN_PROMPT_VPS_IP="Enter VPS public IP address:"
EN_PROMPT_VPS_PORT="Enter VPS gost port (e.g., 8080):"
EN_PROMPT_PORT_RANGES="Enter port ranges to forward."
EN_PROMPT_PORT_EXAMPLE="Example: 10001-10020"
EN_PROMPT_LOCAL_RANGE="Enter LOCAL port range on this NAT machine:"
EN_PROMPT_REMOTE_RANGE="Enter REMOTE port range to expose on VPS:"
EN_ERR_RANGE_MISMATCH="Error: Port ranges must have the same number of ports."
EN_CONFIG_CLIENT_DONE="✅ Client configuration complete!"
EN_SERVICE_NOT_CONFIGURED="Gost service is not configured yet. Please run setup first."
EN_UNINSTALL_CONFIRM="This will stop the service and remove gost executable and systemd file. Are you sure? (y/n):"
EN_UNINSTALL_STOPPING="Stopping gost service..."
EN_UNINSTALL_REMOVING_FILES="Removing files..."
EN_UNINSTALL_DONE="Gost has been uninstalled."
EN_UNINSTALL_CANCELLED="Uninstallation cancelled."

# Chinese
ZH_MSG_ROOT_REQUIRED="此脚本需要以 root 权限运行才能管理 systemd 服务。"
ZH_MENU_TITLE="Gost V3 一站式助手脚本"
ZH_MENU_SETUP="--- 安装配置 (仅需运行一次) ---"
ZH_MENU_VPS="[VPS端] 安装并配置服务端"
ZH_MENU_NAT="[NAT端] 安装并配置客户端"
ZH_MENU_MANAGE="--- 日常管理 (配置后使用) ---"
ZH_MENU_START="启动 Gost 服务"
ZH_MENU_STOP="停止 Gost 服务"
ZH_MENU_STATUS="检查 Gost 服务状态"
ZH_MENU_LOG="查看 Gost 服务日志"
ZH_MENU_UNINSTALL="卸载 Gost"
ZH_MENU_EXIT="退出"
ZH_PROMPT_CHOICE="请输入你的选择"
ZH_PROMPT_CONTINUE="按回车键继续..."
ZH_MSG_INVALID_OPTION="无效选项，请重试。"
ZH_MSG_GOODBYE="再见!"
ZH_CONFIG_SERVER_TITLE="--- 正在配置 Gost 服务端 (VPS) ---"
ZH_CONFIG_CLIENT_TITLE="--- 正在配置 Gost 客户端 (NAT) ---"
ZH_GOST_INSTALLED="Gost 已安装。"
ZH_GOST_NOT_FOUND="未找到 Gost。正在尝试下载并安装..."
ZH_DOWNLOAD_FROM="下载地址:"
ZH_DOWNLOAD_FAILED="下载失败。请检查 URL 或您的网络连接。"
ZH_INSTALL_SUCCESS="Gost 安装成功！"
ZH_INSTALL_FAILED="安装失败。"
ZH_SYSTEMD_CREATING="正在创建 systemd 服务文件..."
ZH_SYSTEMD_SUCCESS="Systemd 服务已成功创建并启用！"
ZH_SYSTEMD_MANAGE="您现在可以使用 'systemctl [start|stop|status] gost' 来管理服务。"
ZH_PROMPT_LISTEN_PORT="请输入用于 NAT 客户端连接的端口 (例如 8080):"
ZH_PROMPT_PASSWORD="请为连接设置密码 (留空则不设密码):"
ZH_CONFIG_SERVER_DONE="✅ 服务端配置完成！"
ZH_CONFIG_CLIENT_GUIDE="请在您的 NAT 设备上使用以下信息进行配置:"
ZH_INFO_VPS_IP="VPS 公网IP:"
ZH_INFO_VPS_PORT="VPS Gost 端口:"
ZH_INFO_PASSWORD="密码:"
ZH_PROMPT_START_NOW="是否现在启动服务? (y/n):"
ZH_SERVICE_STARTED="Gost 服务已启动！"
ZH_PROMPT_VPS_IP="请输入 VPS 的公网 IP 地址:"
ZH_PROMPT_VPS_PORT="请输入 VPS 上的 Gost 端口 (例如 8080):"
ZH_PROMPT_PORT_RANGES="请输入需要转发的端口范围。"
ZH_PROMPT_PORT_EXAMPLE="格式示例: 10001-10020"
ZH_PROMPT_LOCAL_RANGE="输入此 NAT 机器上的 [本地] 端口范围:"
ZH_PROMPT_REMOTE_RANGE="输入希望在 VPS 上暴露的 [远程] 端口范围:"
ZH_ERR_RANGE_MISMATCH="错误：本地和远程的端口数量必须一致。"
ZH_CONFIG_CLIENT_DONE="✅ 客户端配置完成！"
ZH_SERVICE_NOT_CONFIGURED="Gost 服务尚未配置。请先运行安装配置。"
ZH_UNINSTALL_CONFIRM="此操作将停止服务、删除 Gost 执行文件和 systemd 配置文件。确定要继续吗? (y/n):"
ZH_UNINSTALL_STOPPING="正在停止 gost 服务..."
ZH_UNINSTALL_REMOVING_FILES="正在删除文件..."
ZH_UNINSTALL_DONE="Gost 已被卸载。"
ZH_UNINSTALL_CANCELLED="已取消卸载。"

# --- Helper Functions ---
# Usage: lang_get MSG_KEY
lang_get() {
    local key="${LANG_PREFIX}_$1"
    echo -e "${!key}"
}

print_msg() {
    local color="$1"
    local key="$2"
    echo -e "${color}$(lang_get "$key")${C_NC}"
}

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

install_gost() {
    if [ -f "$GOST_EXEC_PATH" ]; then
        print_msg "$C_GREEN" "GOST_INSTALLED"
        return
    fi
    
    print_msg "$C_BLUE" "GOST_NOT_FOUND"
    detect_arch
    local download_url="https://github.com/${GOST_REPO}/releases/download/v${GOST_VERSION}/gost-linux-${ARCH}-${GOST_VERSION}.tgz"
    
    print_msg "$C_YELLOW" "$(lang_get 'DOWNLOAD_FROM') $download_url"
    
    if ! curl -sSL -o /tmp/gost.tgz "$download_url"; then
        print_msg "$C_RED" "DOWNLOAD_FAILED"
        exit 1
    fi
    
    tar -zxf /tmp/gost.tgz -C /tmp
    # Find the executable in the extracted folder and move it
    find /tmp -name "gost-linux-${ARCH}" -exec mv {} "$GOST_EXEC_PATH" \;
    chmod +x "$GOST_EXEC_PATH"
    rm -rf /tmp/gost.tgz /tmp/gost-linux-*
    
    if [ -f "$GOST_EXEC_PATH" ]; then
        print_msg "$C_GREEN" "INSTALL_SUCCESS"
    else
        print_msg "$C_RED" "INSTALL_FAILED"
        exit 1
    fi
}

create_systemd_service() {
    local exec_command="$1"
    print_msg "$C_BLUE" "SYSTEMD_CREATING"
    
    cat > "$SYSTEMD_SERVICE_FILE" << EOF
[Unit]
Description=Gost Tunnel Service (v3)
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
    print_msg "$C_GREEN" "SYSTEMD_SUCCESS"
    print_msg "$C_YELLOW" "SYSTEMD_MANAGE"
}

# --- Menu Functions ---
configure_server() {
    print_msg "$C_BLUE" "CONFIG_SERVER_TITLE"
    install_gost
    
    read -p "$(lang_get 'PROMPT_LISTEN_PORT') " LISTEN_PORT
    read -p "$(lang_get 'PROMPT_PASSWORD') " AUTH_PASS
    
    local auth_str=""
    if [ -n "$AUTH_PASS" ]; then
        auth_str="user:$AUTH_PASS@"
    fi
    
    local command="$GOST_EXEC_PATH -L \"rtun://$auth_str:$LISTEN_PORT\""
    
    create_systemd_service "$command"
    
    local public_ip=$(curl -s4 ip.sb || wget -qO- -t1 -T2 ipv4.icanhazip.com)
    print_msg "$C_GREEN" "\n$(lang_get 'CONFIG_SERVER_DONE')"
    echo "--------------------------------------------------"
    print_msg "$C_YELLOW" "$(lang_get 'CONFIG_CLIENT_GUIDE')"
    print_msg "$C_BLUE" "$(lang_get 'INFO_VPS_IP') $public_ip"
    print_msg "$C_BLUE" "$(lang_get 'INFO_VPS_PORT')  $LISTEN_PORT"
    print_msg "$C_BLUE" "$(lang_get 'INFO_PASSWORD')       $AUTH_PASS"
    echo "--------------------------------------------------"
    
    read -p "$(lang_get 'PROMPT_START_NOW') " start_now
    if [[ "$start_now" == "y" || "$start_now" == "Y" ]]; then
        systemctl start gost
        print_msg "$C_GREEN" "SERVICE_STARTED"
        sleep 1; systemctl status gost --no-pager
    fi
}

configure_client() {
    print_msg "$C_BLUE" "CONFIG_CLIENT_TITLE"
    install_gost

    read -p "$(lang_get 'PROMPT_VPS_IP') " SERVER_IP
    read -p "$(lang_get 'PROMPT_VPS_PORT') " SERVER_PORT
    read -p "$(lang_get 'PROMPT_PASSWORD') " AUTH_PASS
    
    print_msg "$C_YELLOW" "\n$(lang_get 'PROMPT_PORT_RANGES')"
    print_msg "$C_YELLOW" "$(lang_get 'PROMPT_PORT_EXAMPLE')"
    read -p "$(lang_get 'PROMPT_LOCAL_RANGE') " LOCAL_PORTS_RANGE
    read -p "$(lang_get 'PROMPT_REMOTE_RANGE') " REMOTE_PORTS_RANGE

    local local_start=$(echo $LOCAL_PORTS_RANGE | cut -d'-' -f1)
    local local_end=$(echo $LOCAL_PORTS_RANGE | cut -d'-' -f2)
    local remote_start=$(echo $REMOTE_PORTS_RANGE | cut -d'-' -f1)
    local remote_end=$(echo $REMOTE_PORTS_RANGE | cut -d'-' -f2)

    if [ $((local_end - local_start)) -ne $((remote_end - remote_start)) ]; then
        print_msg "$C_RED" "ERR_RANGE_MISMATCH"
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

    print_msg "$C_GREEN" "\n$(lang_get 'CONFIG_CLIENT_DONE')"
    read -p "$(lang_get 'PROMPT_START_NOW') " start_now
    if [[ "$start_now" == "y" || "$start_now" == "Y" ]]; then
        systemctl start gost
        print_msg "$C_GREEN" "SERVICE_STARTED"
        sleep 1; systemctl status gost --no-pager
    fi
}

uninstall_gost() {
    if [ ! -f "$GOST_EXEC_PATH" ] && [ ! -f "$SYSTEMD_SERVICE_FILE" ]; then
        print_msg "$C_YELLOW" "Gost is not installed."
        return
    fi
    read -p "$(lang_get 'UNINSTALL_CONFIRM') " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_msg "$C_YELLOW" "UNINSTALL_CANCELLED"
        return
    fi
    print_msg "$C_YELLOW" "UNINSTALL_STOPPING"
    systemctl stop gost
    systemctl disable gost
    print_msg "$C_YELLOW" "UNINSTALL_REMOVING_FILES"
    rm -f "$SYSTEMD_SERVICE_FILE"
    rm -f "$GOST_EXEC_PATH"
    systemctl daemon-reload
    print_msg "$C_GREEN" "UNINSTALL_DONE"
}

manage_service() {
    local action=$1
    if [ ! -f "$SYSTEMD_SERVICE_FILE" ]; then
        print_msg "$C_RED" "SERVICE_NOT_CONFIGURED"
        return
    fi
    case $action in
        start) systemctl start gost ;;
        stop) systemctl stop gost ;;
        status) systemctl status gost --no-pager ;;
        log) journalctl -u gost -f --no-pager ;;
    esac
    if [ "$action" != "status" ] && [ "$action" != "log" ]; then
         sleep 1; systemctl status gost --no-pager
    fi
}

show_menu() {
    clear
    print_msg "$C_BLUE" "======================================="
    print_msg "$C_BLUE" "   $(lang_get 'MENU_TITLE')   "
    print_msg "$C_BLUE" "======================================="
    echo ""
    print_msg "$C_YELLOW" "$(lang_get 'MENU_SETUP')"
    echo -e "${C_GREEN}1. $(lang_get 'MENU_VPS')${C_NC}"
    echo -e "${C_GREEN}2. $(lang_get 'MENU_NAT')${C_NC}"
    echo ""
    print_msg "$C_YELLOW" "$(lang_get 'MENU_MANAGE')"
    echo -e "${C_GREEN}3. $(lang_get 'MENU_START')${C_NC}"
    echo -e "${C_GREEN}4. $(lang_get 'MENU_STOP')${C_NC}"
    echo -e "${C_GREEN}5. $(lang_get 'MENU_STATUS')${C_NC}"
    echo -e "${C_GREEN}6. $(lang_get 'MENU_LOG')${C_NC}"
    echo ""
    echo -e "${C_RED}7. $(lang_get 'MENU_UNINSTALL')${C_NC}"
    echo -e "${C_RED}0. $(lang_get 'MENU_EXIT')${C_NC}"
    echo ""
}

# --- Main Execution ---
# Check for root user
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${C_RED}This script must be run as root. Please use sudo.${C_NC}"
    echo -e "${C_RED}此脚本需要 root 权限，请使用 sudo 运行。${C_NC}"
    exit 1
fi

# Language Selection
if [ -z "$LANG_PREFIX" ]; then
    echo "----------------------------------------"
    echo "Please select a language / 请选择语言:"
    echo "1. English"
    echo "2. 中文"
    echo "----------------------------------------"
    read -p "Enter your choice [1-2]: " lang_choice
    case $lang_choice in
        1) LANG_PREFIX="EN" ;;
        2) LANG_PREFIX="ZH" ;;
        *) LANG_PREFIX="EN" ;;
    esac
fi

while true; do
    show_menu
    read -p "$(lang_get 'PROMPT_CHOICE') [0-7]: " choice
    
    case $choice in
        1) configure_server ;;
        2) configure_client ;;
        3) manage_service "start" ;;
        4) manage_service "stop" ;;
        5) manage_service "status" ;;
        6) manage_service "log" ;;
        7) uninstall_gost ;;
        0) break ;;
        *) print_msg "$C_RED" "MSG_INVALID_OPTION" ;;
    esac
    
    if [ "$choice" != "0" ]; then
        read -p $'\n'"$(lang_get 'PROMPT_CONTINUE')"
    fi
done

print_msg "$C_GREEN" "MSG_GOODBYE"
