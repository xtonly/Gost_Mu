#!/bin/bash

#====================================================================================
#
#          FILE:  xray_port_forward.sh
#
#   DESCRIPTION:  An all-in-one script for setting up Xray-based port forwarding.
#                 It provides a menu to install and configure Xray for both a
#                 public VPS (server) and a NAT machine (client).
#
#       VERSION:  1.1.0
#      REVISION:  2025-09-07
#
#====================================================================================


# --- Color Codes ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# --- Global Variables for Language Strings ---
declare -A T

#================================================
# Language Functions
#================================================
set_lang_en() {
    T[choose_lang]="Please choose your language"
    T[menu_header]="--- Xray Port Forwarding & Reuse Setup Script ---"
    T[menu_option_1]="1. Install on Public VPS (Server Role)"
    T[menu_option_2]="2. Install on NAT Machine (Client Role)"
    T[menu_option_3]="3. Exit"
    T[menu_prompt]="Please enter your choice [1-3]: "
    T[invalid_choice]="Invalid choice. Please try again."
    T[root_required]="Error: This script must be run as root. Please use sudo."
    T[installing_deps]="Installing dependencies (curl, wget)..."
    T[installing_xray]="Installing/Updating Xray-core..."
    T[xray_install_success]="Xray-core installed successfully."
    T[xray_install_fail]="Xray-core installation failed."
    T[starting_config]="--- Starting Configuration ---"
    T[prompt_tunnel_port]="Enter the tunnel port for NAT machine to connect (e.g., 443): "
    T[prompt_vps_ip]="Enter your Public VPS IP address: "
    T[prompt_uuid]="Enter the UUID (must match the one on VPS): "
    T[invalid_port]="Error: Invalid port number."
    T[info_uuid]="Generated UUID: "
    T[config_port_rules]="--- Configure Port Forwarding Rules (Max 20) ---"
    T[prompt_protocol]="Enter the protocol (tcp/udp/both): "
    T[prompt_vps_port_fwd]="[Rule %s] Enter the public port on VPS to forward (leave blank to finish): "
    T[prompt_nat_addr]="[Rule %s] Enter the internal NAT destination address:port (e.g., 127.0.0.1:80): "
    T[rule_added]="Rule %s added: VPS(%s:%s) -> NAT(%s)"
    T[invalid_protocol]="Error: Invalid protocol. Please enter 'tcp', 'udp', or 'both'."
    T[addr_empty]="Error: Internal destination address cannot be empty."
    T[config_generation_complete]="✅ Configuration generation complete!"
    T[writing_config]="Writing configuration to /usr/local/etc/xray/config.json..."
    T[restarting_xray]="Restarting and enabling xray service..."
    T[summary_vps_success]="✅ VPS (Server) setup is complete!"
    T[summary_vps_info]="Please use the following information to set up your NAT machine:"
    T[summary_vps_ip]="Your VPS Public IP"
    T[summary_tunnel_port]="Tunnel Port"
    T[summary_uuid]="UUID"
    T[summary_forwarded_ports]="Forwarded Ports on VPS:"
    T[summary_nat_success]="✅ NAT Machine (Client) setup is complete!"
    T[checking_status]="Checking xray service status..."
    T[exit_message]="Exiting script."
}

set_lang_zh() {
    T[choose_lang]="请选择您的语言"
    T[menu_header]="--- Xray 端口转发与复用安装脚本 ---"
    T[menu_option_1]="1. 在公网 VPS 上安装 (服务端)"
    T[menu_option_2]="2. 在 NAT 机器上安装 (客户端)"
    T[menu_option_3]="3. 退出"
    T[menu_prompt]="请输入您的选择 [1-3]: "
    T[invalid_choice]="无效的选择，请重试。"
    T[root_required]="错误：本脚本需要以 root 权限运行，请使用 sudo。"
    T[installing_deps]="正在安装依赖 (curl, wget)..."
    T[installing_xray]="正在安装/更新 Xray-core..."
    T[xray_install_success]="Xray-core 安装成功。"
    T[xray_install_fail]="Xray-core 安装失败。"
    T[starting_config]="--- 开始配置 ---"
    T[prompt_tunnel_port]="请输入用于 NAT 机连接 VPS 的隧道端口 (例如 443): "
    T[prompt_vps_ip]="请输入您的公网 VPS 的 IP 地址: "
    T[prompt_uuid]="请输入 UUID (必须与 VPS 上的设置保持一致): "
    T[invalid_port]="错误：无效的端口号。"
    T[info_uuid]="已自动生成 UUID: "
    T[config_port_rules]="--- 配置端口转发规则 (最多 20 条) ---"
    T[prompt_protocol]="请输入使用的协议 (tcp/udp/both): "
    T[prompt_vps_port_fwd]="[规则 %s] 请输入 VPS 对外服务的端口 (留空则结束): "
    T[prompt_nat_addr]="[规则 %s] 请输入 NAT 机内网目标地址:端口 (如 127.0.0.1:80): "
    T[rule_added]="规则 %s 添加成功: VPS(%s:%s) -> NAT(%s)"
    T[invalid_protocol]="错误：无效的协议，请输入 'tcp', 'udp', 或 'both'。"
    T[addr_empty]="错误：内网目标地址不能为空。"
    T[config_generation_complete]="✅ 配置文件生成成功!"
    T[writing_config]="正在写入配置到 /usr/local/etc/xray/config.json..."
    T[restarting_xray]="正在重启并设置 xray 服务开机自启..."
    T[summary_vps_success]="✅ VPS (服务端) 设置完成!"
    T[summary_vps_info]="请使用以下信息来配置您的 NAT 机器:"
    T[summary_vps_ip]="您的 VPS 公网 IP"
    T[summary_tunnel_port]="隧道端口"
    T[summary_uuid]="UUID"
    T[summary_forwarded_ports]="VPS 上已转发的端口:"
    T[summary_nat_success]="✅ NAT 机器 (客户端) 设置完成!"
    T[checking_status]="正在检查 xray 服务状态..."
    T[exit_message]="退出脚本。"
}


#================================================
# Helper Functions
#================================================
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}${T[root_required]}${NC}"
        exit 1
    fi
}

install_dependencies() {
    echo -e "${CYAN}${T[installing_deps]}${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update -y && apt-get install -y curl wget
    elif command -v yum &> /dev/null; then
        yum install -y curl wget
    elif command -v dnf &> /dev/null; then
        dnf install -y curl wget
    else
        # Fallback for systems without common package managers
        echo -e "${YELLOW}Warning: Could not detect package manager. Please ensure curl and wget are installed.${NC}"
    fi
}

install_xray() {
    echo -e "${CYAN}${T[installing_xray]}${NC}"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}${T[xray_install_success]}${NC}"
    else
        echo -e "${RED}${T[xray_install_fail]}${NC}"
        exit 1
    fi
}

#================================================
# Configuration and Installation Logic
#================================================
run_vps_setup() {
    check_root
    install_dependencies
    install_xray

    echo -e "\n${CYAN}${T[starting_config]}${NC}"

    local TUNNEL_PORT
    while true; do
        read -p "$(echo -e ${YELLOW}"${T[prompt_tunnel_port]}"${NC})" TUNNEL_PORT
        if [[ "$TUNNEL_PORT" =~ ^[0-9]+$ ]] && [ "$TUNNEL_PORT" -ge 1 ] && [ "$TUNNEL_PORT" -le 65535 ]; then
            break
        else
            echo -e "${RED}${T[invalid_port]}${NC}"
        fi
    done

    local UUID
    if command -v /usr/local/bin/xray &> /dev/null; then
        UUID=$(/usr/local/bin/xray uuid)
    else
        UUID=$(cat /proc/sys/kernel/random/uuid)
    fi
    echo -e "${GREEN}${T[info_uuid]}${UUID}${NC}"

    declare -a vps_ports
    declare -a protocols
    
    echo -e "\n${CYAN}${T[config_port_rules]}${NC}"
    for i in {1..20}; do
        local vps_port protocol
        printf "${YELLOW}"
        read -p "$(printf -- "${T[prompt_vps_port_fwd]}" "$i")" vps_port
        printf "${NC}"

        if [[ -z "$vps_port" ]]; then break; fi
        
        read -p "$(echo -e ${YELLOW}"[Rule $i] ${T[prompt_protocol]}"${NC})" protocol
        protocol=$(echo "$protocol" | tr '[:upper:]' '[:lower:]')
        if [[ "$protocol" != "tcp" && "$protocol" != "udp" && "$protocol" != "both" ]]; then
            echo -e "${RED}${T[invalid_protocol]}${NC}"
            continue
        fi
        
        vps_ports+=("$vps_port")
        protocols+=("$protocol")
        echo -e "${GREEN}$(printf -- "${T[rule_added]}" "$i" "$protocol" "$vps_port" "tunnel")${NC}"
    done

    # --- Generate VPS Config JSON ---
    local vps_inbounds="
    {
      \"listen\": \"0.0.0.0\",
      \"port\": ${TUNNEL_PORT},
      \"protocol\": \"vless\",
      \"settings\": {
        \"clients\": [{\"id\": \"${UUID}\"}],
        \"decryption\": \"none\"
      },
      \"streamSettings\": {\"network\": \"tcp\"},
      \"tag\": \"tunnel-in\"
    }"

    local forward_tags=""
    for i in "${!vps_ports[@]}"; do
        local vps_port=${vps_ports[$i]}
        local protocol=${protocols[$i]}
        
        if [[ "$protocol" == "tcp" || "$protocol" == "both" ]]; then
            local tag="tcp-in-${vps_port}"
            forward_tags="\"${tag}\", ${forward_tags}"
            vps_inbounds="${vps_inbounds},
    {
      \"listen\": \"0.0.0.0\",
      \"port\": ${vps_port},
      \"protocol\": \"dokodemo-door\",
      \"settings\": {\"network\": \"tcp\", \"followRedirect\": false},
      \"tag\": \"${tag}\"
    }"
        fi

        if [[ "$protocol" == "udp" || "$protocol" == "both" ]]; then
            local tag="udp-in-${vps_port}"
            forward_tags="\"${tag}\", ${forward_tags}"
            vps_inbounds="${vps_inbounds},
    {
      \"listen\": \"0.0.0.0\",
      \"port\": ${vps_port},
      \"protocol\": \"dokodemo-door\",
      \"settings\": {\"network\": \"udp\", \"followRedirect\": false},
      \"tag\": \"${tag}\"
    }"
        fi
    done
    forward_tags=${forward_tags%??}

    local VPS_CONFIG=$(cat <<EOF
{
  "log": {"loglevel": "warning"},
  "inbounds": [ ${vps_inbounds} ],
  "outbounds": [
    {"protocol": "freedom", "tag": "direct-out"},
    {"protocol": "blackhole", "tag": "blackhole-out"},
    {"protocol": "vless", "tag": "tunnel-out"}
  ],
  "routing": {
    "rules": [
      {"type": "field", "inboundTag": [${forward_tags}], "outboundTag": "tunnel-out"}
    ]
  }
}
EOF
)
    echo -e "\n${GREEN}${T[config_generation_complete]}${NC}"
    echo -e "${CYAN}${T[writing_config]}${NC}"
    echo "$VPS_CONFIG" > /usr/local/etc/xray/config.json
    
    echo -e "${CYAN}${T[restarting_xray]}${NC}"
    systemctl restart xray
    systemctl enable xray

    local public_ip
    public_ip=$(curl -s4 ip.sb || curl -s4 ifconfig.me)

    echo -e "\n${CYAN}====================================================${NC}"
    echo -e "${GREEN}${T[summary_vps_success]}${NC}"
    echo -e "${YELLOW}${T[summary_vps_info]}${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${GREEN}${T[summary_vps_ip]}:      ${YELLOW}${public_ip}${NC}"
    echo -e "${GREEN}${T[summary_tunnel_port]}: ${YELLOW}${TUNNEL_PORT}${NC}"
    echo -e "${GREEN}${T[summary_uuid]}:         ${YELLOW}${UUID}${NC}"
    echo -e "${GREEN}${T[summary_forwarded_ports]}${NC}"
    for i in "${!vps_ports[@]}"; do
        echo -e "  - ${YELLOW}${vps_ports[$i]} (${protocols[$i]})${NC}"
    done
    echo -e "${CYAN}====================================================${NC}\n"
}

run_nat_setup() {
    check_root
    install_dependencies
    install_xray

    echo -e "\n${CYAN}${T[starting_config]}${NC}"
    
    local VPS_IP TUNNEL_PORT UUID
    read -p "$(echo -e ${YELLOW}"${T[prompt_vps_ip]}"${NC})" VPS_IP
    read -p "$(echo -e ${YELLOW}"${T[prompt_tunnel_port]}"${NC})" TUNNEL_PORT
    read -p "$(echo -e ${YELLOW}"${T[prompt_uuid]}"${NC})" UUID

    declare -a vps_ports
    declare -a nat_addrs
    declare -a protocols

    echo -e "\n${CYAN}${T[config_port_rules]}${NC}"
    for i in {1..20}; do
        local vps_port nat_addr protocol
        printf "${YELLOW}"
        read -p "$(printf -- "${T[prompt_vps_port_fwd]}" "$i")" vps_port
        printf "${NC}"
        if [[ -z "$vps_port" ]]; then break; fi

        read -p "$(echo -e ${YELLOW}"$(printf -- "${T[prompt_nat_addr]}" "$i")"${NC})" nat_addr
        if [[ -z "$nat_addr" ]]; then echo -e "${RED}${T[addr_empty]}${NC}"; continue; fi
        
        read -p "$(echo -e ${YELLOW}"[Rule $i] ${T[prompt_protocol]}"${NC})" protocol
        protocol=$(echo "$protocol" | tr '[:upper:]' '[:lower:]')
        if [[ "$protocol" != "tcp" && "$protocol" != "udp" && "$protocol" != "both" ]]; then
            echo -e "${RED}${T[invalid_protocol]}${NC}"; continue;
        fi

        vps_ports+=("$vps_port")
        nat_addrs+=("$nat_addr")
        protocols+=("$protocol")
        echo -e "${GREEN}$(printf -- "${T[rule_added]}" "$i" "$protocol" "$vps_port" "$nat_addr")${NC}"
    done

    # --- Generate NAT Config JSON ---
    local nat_outbounds=""
    local nat_routing_rules=""

    for i in "${!vps_ports[@]}"; do
        local vps_port=${vps_ports[$i]}
        local nat_addr=${nat_addrs[$i]}
        local protocol=${protocols[$i]}
        local nat_ip=$(echo "$nat_addr" | cut -d: -f1)
        local nat_port=$(echo "$nat_addr" | cut -d: -f2)

        if [[ "$protocol" == "tcp" || "$protocol" == "both" ]]; then
            local tag="tcp-out-${vps_port}"
            nat_outbounds="${nat_outbounds}
    {\"protocol\": \"freedom\", \"settings\": {\"redirect\": \"${nat_ip}:${nat_port}\"}, \"tag\": \"${tag}\"},"
            nat_routing_rules="${nat_routing_rules}
    {\"type\": \"field\", \"inboundTag\": [\"tunnel-in\"], \"port\": ${vps_port}, \"network\": \"tcp\", \"outboundTag\": \"${tag}\"},"
        fi
        if [[ "$protocol" == "udp" || "$protocol" == "both" ]]; then
            local tag="udp-out-${vps_port}"
            nat_outbounds="${nat_outbounds}
    {\"protocol\": \"freedom\", \"settings\": {\"redirect\": \"${nat_ip}:${nat_port}\"}, \"tag\": \"${tag}\"},"
            nat_routing_rules="${nat_routing_rules}
    {\"type\": \"field\", \"inboundTag\": [\"tunnel-in\"], \"port\": ${vps_port}, \"network\": \"udp\", \"outboundTag\": \"${tag}\"},"
        fi
    done
    nat_outbounds=${nat_outbounds%,}
    nat_routing_rules=${nat_routing_rules%,}

    local NAT_CONFIG=$(cat <<EOF
{
  "log": {"loglevel": "warning"},
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {"address": "${VPS_IP}", "port": ${TUNNEL_PORT}, "users": [{"id": "${UUID}"}]}
        ]
      },
      "streamSettings": {"network": "tcp"},
      "tag": "tunnel-out"
    },
    ${nat_outbounds}
  ],
  "routing": {
    "rules": [${nat_routing_rules}]
  },
  "reverse": {
     "bridges": [{"tag": "tunnel-in", "domain": "tunnel.xray"}]
  }
}
EOF
)
    echo -e "\n${GREEN}${T[config_generation_complete]}${NC}"
    echo -e "${CYAN}${T[writing_config]}${NC}"
    echo "$NAT_CONFIG" > /usr/local/etc/xray/config.json
    
    echo -e "${CYAN}${T[restarting_xray]}${NC}"
    systemctl restart xray
    systemctl enable xray

    echo -e "\n${CYAN}====================================================${NC}"
    echo -e "${GREEN}${T[summary_nat_success]}${NC}"
    echo -e "${CYAN}====================================================${NC}"
    echo -e "${YELLOW}${T[checking_status]}${NC}"
    sleep 2
    systemctl status xray --no-pager
    echo -e "${CYAN}====================================================${NC}\n"
}


#================================================
# Main Menu
#================================================
main_menu() {
    clear
    echo -e "${CYAN}${T[menu_header]}${NC}"
    echo -e "${GREEN}${T[menu_option_1]}${NC}"
    echo -e "${GREEN}${T[menu_option_2]}${NC}"
    echo -e "${GREEN}${T[menu_option_3]}${NC}"
    echo -e "${CYAN}---------------------------------------------------${NC}"
    read -p "$(echo -e ${YELLOW}"${T[menu_prompt]}"${NC})" menu_choice

    case $menu_choice in
        1) run_vps_setup ;;
        2) run_nat_setup ;;
        3) echo -e "${CYAN}${T[exit_message]}${NC}"; exit 0 ;;
        *) echo -e "${RED}${T[invalid_choice]}${NC}"; sleep 2; main_menu ;;
    esac
}

# --- Script Entry Point ---
clear
echo "=========================================="
echo "      Welcome / 欢迎"
echo "=========================================="
echo ""
echo "Please select your language:"
echo "1. English"
echo "2. 中文"
echo ""
read -p "Enter your choice [1-2]: " lang_choice

case $lang_choice in
    2) set_lang_zh ;;
    *) set_lang_en ;;
esac

main_menu
