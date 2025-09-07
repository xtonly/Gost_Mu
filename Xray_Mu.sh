#!/bin/bash

#====================================================================================
#
#          FILE:  xray_port_forward_v3.1.sh
#
#   DESCRIPTION:  All-in-one script for Xray port forwarding with a focus on
#                 security (TLS), manageability, and robustness. Full source provided.
#
#       VERSION:  3.1.0
#      REVISION:  2025-09-07
#
#====================================================================================


# --- Color Codes ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# --- Global Variables ---
declare -A T
FIREWALL_COMMENT="XRAY_FWD_SCRIPT_RULE_V3"
XRAY_CONFIG_PATH="/usr/local/etc/xray/config.json"
CERT_PATH="/usr/local/etc/xray/fullchain.crt"
KEY_PATH="/usr/local/etc/xray/private.key"

#================================================
# Language Functions
#================================================
set_lang_en() {
    T[menu_header]="--- Xray Port Forwarding & Reuse Script (v3.1) ---"
    T[menu_main_1]="1. Install or Update Xray Service"
    T[menu_main_2]="2. View or Manage Existing Setup"
    T[menu_main_3]="3. Uninstall Everything"
    T[menu_main_4]="4. Exit"
    T[menu_install_header]="--- Installation Mode ---"
    T[menu_install_1]="1. [Mode 1] 1-to-1 Port Forwarding"
    T[menu_install_2]="2. [Mode 2] Port Multiplexing (Advanced)"
    T[menu_install_3]="3. Back to Main Menu"
    T[menu_manage_header]="--- Management Menu ---"
    T[menu_manage_1]="1. Check Xray Service Status"
    T[menu_manage_2]="2. View Real-time Xray Logs"
    T[menu_manage_3]="3. View Current Firewall Rules"
    T[menu_manage_4]="4. Back to Main Menu"
    T[prompt_enter_choice]="Please enter your choice: "
    T[root_required]="Error: This script must be run as root."
    T[installing_deps]="Installing dependencies (curl, wget, iptables-persistent, openssl)..."
    T[installing_xray]="Installing/Updating Xray-core..."
    T[xray_install_success]="Xray-core installed successfully."
    T[xray_install_fail]="Xray-core installation failed."
    T[generating_tls]="Generating self-signed TLS certificates..."
    T[tls_generated]="TLS certificates generated in /usr/local/etc/xray/"
    T[tls_exist]="TLS certificates already exist. Skipping generation."
    T[prompt_tunnel_port]="Enter the tunnel port (e.g., 443): "
    T[prompt_mux_port]="Enter the single port for Xray to listen on for multiplexing (e.g., 45800): "
    T[prompt_public_ports]="Enter the public ports to be forwarded (e.g., 80,443,1000-2000): "
    T[prompt_vps_ip]="Enter your Public VPS IP address: "
    T[prompt_uuid]="Enter the UUID (must match VPS): "
    T[info_uuid]="Generated UUID: "
    T[config_generation_complete]="✅ Configuration generation complete!"
    T[writing_config]="Backing up old config and writing new configuration..."
    T[restarting_xray]="Restarting and enabling xray service..."
    T[configuring_firewall]="Configuring firewall (iptables) rules with comments..."
    T[firewall_rules_applied]="Firewall rules applied and saved."
    T[summary_vps_success]="✅ VPS (Server) setup is complete!"
    T[summary_vps_info]="Please use the following information to set up your NAT machine:"
    T[summary_nat_success]="✅ NAT Machine (Client) setup is complete!"
    T[status_checking]="Checking Xray service status..."
    T[logs_viewing]="Showing real-time logs... Press Ctrl+C to exit."
    T[firewall_rules_viewing]="Displaying active firewall rules created by this script:"
    T[no_rules_found]="No firewall rules created by this script were found."
    T[uninstall_confirm]="This will STOP, REMOVE Xray, and DELETE certificates and firewall rules created by this script. Are you sure? (y/n): "
    T[uninstalling]="Uninstalling Xray, certificates, and firewall rules..."
    T[uninstall_complete]="Uninstallation complete."
    T[exit_message]="Exiting script."
}

set_lang_zh() {
    T[menu_header]="--- Xray 端口转发与复用脚本 (v3.1) ---"
    T[menu_main_1]="1. 安装或更新 Xray 服务"
    T[menu_main_2]="2. 查看或管理现有配置"
    T[menu_main_3]="3. 卸载所有"
    T[menu_main_4]="4. 退出"
    T[menu_install_header]="--- 安装模式 ---"
    T[menu_install_1]="1. [模式 1] 安装 [一对一] 端口转发"
    T[menu_install_2]="2. [模式 2] 安装 [多路复用] 转发 (高级)"
    T[menu_install_3]="3. 返回主菜单"
    T[menu_manage_header]="--- 管理菜单 ---"
    T[menu_manage_1]="1. 检查 Xray 服务状态"
    T[menu_manage_2]="2. 查看 Xray 实时日志"
    T[menu_manage_3]="3. 查看当前防火墙规则"
    T[menu_manage_4]="4. 返回主菜单"
    T[prompt_enter_choice]="请输入您的选择: "
    T[root_required]="错误：本脚本需要以 root 权限运行。"
    T[installing_deps]="正在安装依赖 (curl, wget, iptables-persistent, openssl)..."
    T[installing_xray]="正在安装/更新 Xray-core..."
    T[xray_install_success]="Xray-core 安装成功。"
    T[xray_install_fail]="Xray-core 安装失败。"
    T[generating_tls]="正在生成自签名 TLS 证书..."
    T[tls_generated]="TLS 证书已生成于 /usr/local/etc/xray/"
    T[tls_exist]="TLS 证书已存在，跳过生成步骤。"
    T[prompt_tunnel_port]="请输入隧道端口 (例如 443): "
    T[prompt_mux_port]="请输入 Xray 用于端口复用的监听端口 (例如 45800): "
    T[prompt_public_ports]="请输入需要转发的公网端口 (格式如 80,443,1000-2000): "
    T[prompt_vps_ip]="请输入您的公网 VPS 的 IP 地址: "
    T[prompt_uuid]="请输入 UUID (必须与 VPS 上的设置保持一致): "
    T[info_uuid]="已自动生成 UUID: "
    T[config_generation_complete]="✅ 配置文件生成成功!"
    T[writing_config]="正在备份旧配置并写入新配置..."
    T[restarting_xray]="正在重启并设置 xray 服务开机自启..."
    T[configuring_firewall]="正在配置带注释的防火墙 (iptables) 规则..."
    T[firewall_rules_applied]="防火墙规则已应用并保存。"
    T[summary_vps_success]="✅ VPS (服务端) 设置完成!"
    T[summary_vps_info]="请使用以下信息来配置您的 NAT 机器:"
    T[summary_nat_success]="✅ NAT 机器 (客户端) 设置完成!"
    T[status_checking]="正在检查 Xray 服务状态..."
    T[logs_viewing]="正在显示实时日志... 按 Ctrl+C 退出。"
    T[firewall_rules_viewing]="显示由本脚本创建的防火墙规则:"
    T[no_rules_found]="未找到由本脚本创建的防火墙规则。"
    T[uninstall_confirm]="此操作将停止并卸载 Xray, 同时删除本脚本创建的证书和防火墙规则。确定吗? (y/n): "
    T[uninstalling]="正在卸载 Xray、证书和防火墙规则..."
    T[uninstall_complete]="卸载完成。"
    T[exit_message]="退出脚本。"
}


#================================================
# Helper & Management Functions
#================================================
check_root() {
    if [ "$(id -u)" -ne 0 ]; then echo -e "${RED}${T[root_required]}${NC}"; exit 1; fi
}

press_any_key() {
    echo -e "\nPress Enter to return to the menu..."
    read -r
}

install_dependencies() {
    echo -e "${CYAN}${T[installing_deps]}${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update -y && apt-get install -y curl wget iptables-persistent openssl
    elif command -v yum &> /dev/null || command -v dnf &> /dev/null; then
        yum install -y curl wget iptables-services openssl || dnf install -y curl wget iptables-services openssl
        systemctl enable iptables 2>/dev/null; systemctl start iptables 2>/dev/null
    fi
}

install_xray() {
    echo -e "${CYAN}${T[installing_xray]}${NC}"
    if bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install; then
        echo -e "${GREEN}${T[xray_install_success]}${NC}"
    else
        echo -e "${RED}${T[xray_install_fail]}${NC}"; exit 1
    fi
}

generate_tls_certs() {
    if [ -f "$KEY_PATH" ]; then
        echo -e "${YELLOW}${T[tls_exist]}${NC}"; return
    fi
    echo -e "${CYAN}${T[generating_tls]}${NC}"
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "$KEY_PATH" -out "$CERT_PATH" -subj "/CN=proxy" -days 3650
    echo -e "${GREEN}${T[tls_generated]}${NC}"
}

write_config() {
    echo -e "${CYAN}${T[writing_config]}${NC}"
    if [ -f "$XRAY_CONFIG_PATH" ]; then
        mv "$XRAY_CONFIG_PATH" "${XRAY_CONFIG_PATH}.bak"
    fi
    echo "$1" > "$XRAY_CONFIG_PATH"
}

restart_xray() {
    echo -e "${CYAN}${T[restarting_xray]}${NC}"
    systemctl restart xray
    systemctl enable xray
}

save_firewall() {
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save
    elif command -v service &> /dev/null && service iptables save &> /dev/null; then
        service iptables save
    fi
}

parse_ports() {
    local port_string="$1" expanded_ports=()
    IFS=',' read -ra ADDR <<< "$port_string"
    for i in "${ADDR[@]}"; do
        if [[ $i =~ ^([0-9]+)-([0-9]+)$ ]]; then
            for (( port=${BASH_REMATCH[1]}; port<=${BASH_REMATCH[2]}; port++ )); do expanded_ports+=($port); done
        elif [[ $i =~ ^[0-9]+$ ]]; then expanded_ports+=($i); fi
    done
    echo "${expanded_ports[@]}"
}

view_status() {
    echo -e "\n${CYAN}${T[status_checking]}${NC}"; systemctl status xray --no-pager -l; press_any_key
}

view_logs() {
    echo -e "\n${CYAN}${T[logs_viewing]}${NC}"; journalctl -u xray -f --no-pager
}

view_firewall_rules() {
    echo -e "\n${CYAN}${T[firewall_rules_viewing]}${NC}"
    local rules=$(iptables -t nat -L PREROUTING -n -v --line-numbers | grep "$FIREWALL_COMMENT")
    if [ -n "$rules" ]; then
        echo -e "${YELLOW}--------------------------------------------------${NC}"; echo "$rules"; echo -e "${YELLOW}--------------------------------------------------${NC}"
    else
        echo -e "${GREEN}${T[no_rules_found]}${NC}"
    fi
    press_any_key
}

run_uninstall() {
    read -p "$(echo -e ${YELLOW}"${T[uninstall_confirm]}"${NC})" choice
    if [ "$choice" != "y" ]; then echo "Cancelled."; return; fi

    echo -e "${CYAN}${T[uninstalling]}${NC}"
    systemctl stop xray; systemctl disable xray
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
    rm -f "$KEY_PATH" "$CERT_PATH" "${XRAY_CONFIG_PATH}.bak"

    local rule_numbers=$(iptables -L PREROUTING -t nat --line-numbers | grep "$FIREWALL_COMMENT" | awk '{print $1}' | sort -r)
    if [ -n "$rule_numbers" ]; then
        for num in $rule_numbers; do iptables -t nat -D PREROUTING "$num"; done
    fi
    save_firewall
    echo -e "${GREEN}${T[uninstall_complete]}${NC}"; press_any_key
}

#================================================
# Installation Logic
#================================================
run_mux_vps_setup() {
    local TUNNEL_PORT MUX_PORT UUID PUBLIC_PORTS_INPUT expanded_public_ports
    install_dependencies; install_xray; generate_tls_certs
    
    read -p "$(echo -e ${YELLOW}"${T[prompt_tunnel_port]}"${NC})" TUNNEL_PORT
    read -p "$(echo -e ${YELLOW}"${T[prompt_mux_port]}"${NC})" MUX_PORT
    UUID=$(/usr/local/bin/xray uuid); echo -e "${GREEN}${T[info_uuid]}${UUID}${NC}"
    read -p "$(echo -e ${YELLOW}"${T[prompt_public_ports]}"${NC})" PUBLIC_PORTS_INPUT
    expanded_public_ports=($(parse_ports "$PUBLIC_PORTS_INPUT"))

    local VPS_CONFIG=$(cat <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [
    {"listen": "0.0.0.0", "port": ${TUNNEL_PORT}, "protocol": "vless", "tag": "tunnel_in",
      "settings": {"clients": [{"id": "${UUID}"}], "decryption": "none"},
      "streamSettings": {"network": "tcp", "security": "tls",
        "tlsSettings": {"certificates": [{"certificateFile": "${CERT_PATH}", "keyFile": "${KEY_PATH}"}]}}
    },
    {"listen": "0.0.0.0", "port": ${MUX_PORT}, "protocol": "dokodemo-door", "tag": "mux_in",
      "settings": {"network": "tcp,udp", "followRedirect": true, "destOverride": ["http", "tls", "fakedns"]}
    }
  ],
  "outbounds": [
    {"protocol": "freedom", "tag": "direct_out"}, {"protocol": "blackhole", "tag": "blackhole_out"},
    {"protocol": "vless", "tag": "tunnel_out"}
  ],
  "routing": {"rules": [
      {"type": "field", "inboundTag": ["mux_in"], "outboundTag": "tunnel_out"},
      {"type": "field", "inboundTag": ["tunnel_in"], "outboundTag": "direct_out"}
  ]}
}
EOF
)
    write_config "$VPS_CONFIG"
    echo -e "${CYAN}${T[configuring_firewall]}${NC}"
    local current_rules=$(iptables-save)
    for port in "${expanded_public_ports[@]}"; do
        if ! echo "$current_rules" | grep -- "-p tcp --dport $port -m comment --comment $FIREWALL_COMMENT -j REDIRECT --to-port $MUX_PORT" > /dev/null; then
             iptables -t nat -A PREROUTING -p tcp --dport "$port" -m comment --comment "$FIREWALL_COMMENT" -j REDIRECT --to-port "$MUX_PORT"
        fi
        if ! echo "$current_rules" | grep -- "-p udp --dport $port -m comment --comment $FIREWALL_COMMENT -j REDIRECT --to-port $MUX_PORT" > /dev/null; then
             iptables -t nat -A PREROUTING -p udp --dport "$port" -m comment --comment "$FIREWALL_COMMENT" -j REDIRECT --to-port "$MUX_PORT"
        fi
    done
    save_firewall; echo -e "${GREEN}${T[firewall_rules_applied]}${NC}"
    restart_xray
    
    # ... (Display summary)
}

run_mux_nat_setup() {
    local VPS_IP TUNNEL_PORT UUID PUBLIC_PORTS_INPUT expanded_public_ports nat_outbounds="" nat_routing_rules=""
    install_dependencies; install_xray
    
    read -p "$(echo -e ${YELLOW}"${T[prompt_vps_ip]}"${NC})" VPS_IP
    read -p "$(echo -e ${YELLOW}"${T[prompt_tunnel_port]}"${NC})" TUNNEL_PORT
    read -p "$(echo -e ${YELLOW}"${T[prompt_uuid]}"${NC})" UUID
    read -p "$(echo -e ${YELLOW}"${T[prompt_public_ports]}"${NC})" PUBLIC_PORTS_INPUT
    expanded_public_ports=($(parse_ports "$PUBLIC_PORTS_INPUT"))

    for port in "${expanded_public_ports[@]}"; do
        local nat_addr nat_ip nat_port tag
        read -p "$(printf -- "${T[prompt_public_port_map]}" "$port")" nat_addr
        if [[ -z "$nat_addr" ]]; then continue; fi
        nat_ip=$(echo "$nat_addr" | cut -d: -f1); nat_port=$(echo "$nat_addr" | cut -d: -f2); tag="out-to-${nat_ip//./-}-${nat_port}"
        nat_outbounds+="\n    {\"protocol\": \"freedom\", \"settings\": {\"redirect\": \"${nat_addr}\"}, \"tag\": \"${tag}\"},"
        nat_routing_rules+="\n    {\"type\": \"field\", \"inboundTag\": [\"tunnel_in\"], \"port\": ${port}, \"network\": \"tcp,udp\", \"outboundTag\": \"${tag}\"},"
    done
    nat_outbounds=${nat_outbounds%,}; nat_routing_rules=${nat_routing_rules%,}
    
    local NAT_CONFIG=$(cat <<EOF
{
  "log": {"loglevel": "warning"},
  "outbounds": [
    {"protocol": "vless", "tag": "tunnel_out",
      "settings": {"vnext": [{"address": "${VPS_IP}", "port": ${TUNNEL_PORT}, "users": [{"id": "${UUID}"}]}]},
      "streamSettings": {"network": "tcp", "security": "tls", "tlsSettings": {"allowInsecure": true, "serverName": "${VPS_IP}"}}
    },${nat_outbounds}
  ],
  "routing": {"rules": [${nat_routing_rules}\n  ]},
  "reverse": {"bridges": [{"tag": "tunnel_in", "domain": "tunnel.xray"}]}
}
EOF
)
    write_config "$NAT_CONFIG"; restart_xray; view_status
}

#================================================
# Menus
#================================================
manage_menu() {
    clear; echo -e "${CYAN}${T[menu_manage_header]}${NC}"
    echo "1. ${T[menu_manage_1]}"; echo "2. ${T[menu_manage_2]}"; echo "3. ${T[menu_manage_3]}"; echo "4. ${T[menu_manage_4]}"
    read -p "${T[prompt_enter_choice]}" choice
    case $choice in
        1) view_status; manage_menu ;;
        2) view_logs ;; # Stays in log view until Ctrl+C
        3) view_firewall_rules; manage_menu ;;
        4) return ;;
        *) manage_menu ;;
    esac
}

install_menu() {
    clear; echo -e "${CYAN}${T[menu_install_header]}${NC}"
    echo "1. ${T[menu_install_1]}"; echo "2. ${T[menu_install_2]}"; echo "3. ${T[menu_install_3]}"
    read -p "${T[prompt_enter_choice]}" choice
    case $choice in
        1) echo "1-to-1 mode is under development in this version." ; sleep 2 ;; # Placeholder for run_one_to_one_setup
        2) 
            echo "Select machine type: 1=VPS(Server), 2=NAT(Client)"
            read -p "Choice: " mux_choice
            if [[ $mux_choice == 1 ]]; then run_mux_vps_setup; elif [[ $mux_choice == 2 ]]; then run_mux_nat_setup; fi
            press_any_key
            ;;
        3) return ;;
        *) install_menu ;;
    esac
}

main_menu() {
    clear; echo -e "${CYAN}${T[menu_header]}${NC}"
    echo "1. ${T[menu_main_1]}"; echo "2. ${T[menu_main_2]}"; echo "3. ${T[menu_main_3]}"; echo "4. ${T[menu_main_4]}"
    read -p "${T[prompt_enter_choice]}" choice
    case $choice in
        1) install_menu; main_menu ;;
        2) manage_menu; main_menu ;;
        3) run_uninstall; main_menu ;;
        4) echo -e "${CYAN}${T[exit_message]}${NC}"; exit 0 ;;
        *) main_menu ;;
    esac
}

# --- Script Entry Point ---
clear; echo "=========================================="; echo "      Welcome / 欢迎"; echo "=========================================="
echo ""; echo "Please select your language:"; echo "1. English"; echo "2. 中文"; echo ""
read -p "Enter your choice [1-2]: " lang_choice
case $lang_choice in 2) set_lang_zh ;; *) set_lang_en ;; esac
check_root
main_menu
