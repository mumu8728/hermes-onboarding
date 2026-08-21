#!/bin/bash
# ============================================================================
# install-smart-reset.sh - 客户机首启脚本 (售后 SSH 关键)
# ============================================================================
# 许总你的设计: 模板机 → 硬盘对拷 → 客户机首启自动跑这个
#
# 这个脚本做的事:
#   1. 生成新 SSH keypair (每个客户机唯一)
#   2. 把许总你的公钥加到 authorized_keys (售后 SSH)
#   3. 生成新 machine-id (每台机器唯一)
#   4. 生成新 hostname (hermes-<hash>)
#   5. 跑 onboarding wizard (5 类问题)
#   6. 启动 hermes-web + hermes-gateway
#
# 售後 SSH 流程:
#   许总你 → ssh user@<客户机IP>
#   不用密码 (authorized_keys 有许总你的公钥)
# ============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  Hermes 客户机首启 (install-smart-reset)${NC}"
echo -e "${CYAN}${BOLD}  许总你的模板机 → 硬盘对拷 → 自动跑这个${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"

# 检测 root
if [ "$EUID" -eq 0 ]; then
    SUDO=""
    ACTUAL_USER="root"
else
    SUDO="sudo"
    ACTUAL_USER="$USER"
fi

# ============================================================================
# Step 1: 生成新 machine-id (每台机器唯一)
# ============================================================================
echo -e "\n${CYAN}${BOLD}[1/8]${NC} ${GREEN}生成新 machine-id${NC}"
$SUDO systemd-machine-id-setup
NEW_MACHINE_ID=$(cat /etc/machine-id)
echo "  ✓ machine-id: $NEW_MACHINE_ID"

# ============================================================================
# Step 2: 生成新 hostname (hermes-<short-hash>)
# ============================================================================
echo -e "\n${CYAN}${BOLD}[2/8]${NC} ${GREEN}改 hostname${NC}"
HOST_HASH=$(echo $NEW_MACHINE_ID | cut -c1-8)
NEW_HOSTNAME="hermes-$HOST_HASH"

$SUDO hostnamectl set-hostname $NEW_HOSTNAME
echo "  ✓ hostname: $NEW_HOSTNAME"

# ============================================================================
# Step 3: 生成新 SSH keypair (每台机器唯一, 老子用许总你的公钥)
# ============================================================================
echo -e "\n${CYAN}${BOLD}[3/8]${NC} ${GREEN}生成新 SSH keypair${NC}"

# 备份老 key (如果有)
if [ -f "$HOME/.ssh/id_ed25519" ]; then
    mv $HOME/.ssh/id_ed25519 $HOME/.ssh/id_ed25519.bak.$HOST_HASH
    mv $HOME/.ssh/id_ed25519.pub $HOME/.ssh/id_ed25519.pub.bak.$HOST_HASH
fi

# 生成新 key (ed25519, 更快更安全)
ssh-keygen -t ed25519 -f $HOME/.ssh/id_ed25519 -N "" -q
echo "  ✓ SSH keypair 生成: $HOME/.ssh/id_ed25519"

# 把许总你的公钥加到 authorized_keys (售后 SSH)
mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh

# 许总你的公钥 (从 hermes-onboarding 仓库拉)
curl -fsSL https://raw.githubusercontent.com/mumu8728/hermes-onboarding/main/keys/mumu8728.pub -o /tmp/mumu8728.pub 2>/dev/null || {
    # fallback: 用 install-smart-template.sh 嵌入的公钥
    cat > /tmp/mumu8728.pub << 'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIxpKUruvDCfjziFBjkS/SiMYs5dFry97KN9Gt/M4nFGH5mjI0Q2Lo49yIwI+7q+0Q0QgL52ZVq1qcoXeq54np5uBu5F/7qsNYUaOK65ueL8d7p8pLhko2qOa6SE4f4FuSCCydeJVsxJs6S1IuBL2VS0DVEKt0B7iI mac@Mac-mini.lan
EOF
}

if [ -f /tmp/mumu8728.pub ]; then
    cat /tmp/mumu8728.pub >> $HOME/.ssh/authorized_keys
    chmod 600 $HOME/.ssh/authorized_keys
    echo "  ✓ 许总你公钥加好 (售后 SSH 能进)"
fi

# ============================================================================
# Step 4: 重置网络 (DHCP 重新获取 IP)
# ============================================================================
echo -e "\n${CYAN}${BOLD}[4/8]${NC} ${GREEN}重置网络 (新机器唯一 IP)${NC}"
$SUDO systemctl restart NetworkManager 2>/dev/null || $SUDO systemctl restart networking
sleep 5
NEW_IP=$(hostname -I | awk '{print $1}')
echo "  ✓ IP: $NEW_IP"

# ============================================================================
# Step 5: 跑 onboarding wizard (5 类问题)
# ============================================================================
echo -e "\n${CYAN}${BOLD}[5/8]${NC} ${GREEN}跑 onboarding wizard${NC}"
if [ -f $HOME/.hermes/onboarding-wizard.sh ]; then
    bash $HOME/.hermes/onboarding-wizard.sh
else
    echo "  ⚠ onboarding-wizard.sh 不在, 跳过"
fi

# ============================================================================
# Step 6: 启动 Hermes 服务 (systemd)
# ============================================================================
echo -e "\n${CYAN}${BOLD}[6/8]${NC} ${GREEN}启动 Hermes 服务${NC}"
$SUDO systemctl enable hermes-web.service
$SUDO systemctl restart hermes-web.service
$SUDO systemctl enable hermes-gateway.service
$SUDO systemctl restart hermes-gateway.service
sleep 3
echo "  ✓ hermes-web + hermes-gateway 启动"

# ============================================================================
# Step 7: 注册机器信息 (写文件, 许总你 ssh 进能看到)
# ============================================================================
echo -e "\n${CYAN}${BOLD}[7/8]${NC} ${GREEN}注册机器信息${NC}"
mkdir -p $HOME/.hermes/registry
cat > $HOME/.hermes/registry/this-machine.json << EOF
{
  "machine_id": "$NEW_MACHINE_ID",
  "hostname": "$NEW_HOSTNAME",
  "ip": "$NEW_IP",
  "user": "$ACTUAL_USER",
  "first_boot": "$(date +%Y-%m-%d\\ %H:%M:%S)",
  "ssh_port": 22,
  "hermes_web_port": 9119,
  "ssh_fingerprint": "$(ssh-keygen -lf $HOME/.ssh/id_ed25519.pub)"
}
EOF
echo "  ✓ 机器信息: $HOME/.hermes/registry/this-machine.json"

# ============================================================================
# Step 8: 显示 SSH 信息 (许总你能看到)
# ============================================================================
echo -e "\n${CYAN}${BOLD}[8/8]${NC} ${GREEN}完成${NC}"

echo ""
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ 客户机首启完成${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo -e "${CYAN}${BOLD}机器信息:${NC}"
echo "  hostname: $NEW_HOSTNAME"
echo "  IP: $NEW_IP"
echo "  user: $ACTUAL_USER"
echo ""
echo -e "${CYAN}${BOLD}许总你 SSH 进这机器:${NC}"
echo "  ssh $ACTUAL_USER@$NEW_IP"
echo "  (不用密码, 用了许总你的公钥)"
echo ""
echo -e "${CYAN}${BOLD}售后远程管理命令:${NC}"
echo "  # 看状态"
echo "  ssh $ACTUAL_USER@$NEW_IP 'systemctl status hermes-web'"
echo ""
echo "  # 看 log"
echo "  ssh $ACTUAL_USER@$NEW_IP 'journalctl -u hermes-web -n 50'"
echo ""
echo "  # 远程装包"
echo "  ssh $ACTUAL_USER@$NEW_IP 'sudo apt install -y <package>'"
echo ""
echo "  # 远程跑脚本"
echo "  ssh $ACTUAL_USER@$NEW_IP 'bash <(curl -fsSL https://...)'"