#!/bin/bash
# ============================================================================
# onboarding-new-machine.sh - 新机一键配置 (新机本地跑)
# ============================================================================
# 许总你说"给老子钥匙, 新机跑" — 老子写这个, 许总你在新机本地跑
#
# 步骤:
#   1. 加许总你 SSH 公钥 (让老子能 ssh 进)
#   2. 装基础包
#   3. 跑老子写的 install-smart-template.sh (一键装)
#
# 许总你用法:
#   1. scp onboarding-new-machine.sh user@<新机IP>:~/
#   2. ssh user@<新机IP> (用临时密码登录)
#   3. bash ~/onboarding-new-machine.sh
# ============================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  新机一键配置 (Onboarding)${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"

# 检测 root
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Step 1: 加许总你 SSH 公钥
echo -e "\n${CYAN}${BOLD}[1/4]${NC} ${GREEN}加许总你 SSH 公钥${NC}"
mkdir -p $HOME/.ssh
chmod 700 $HOME/.ssh

cat >> $HOME/.ssh/authorized_keys << 'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIxpKUruvDCfjziFBjkS/SiMYs5dFry97KN9Gt/M4nFGH5mjI0Q2Lo49yIwI+7q+0Q0QgL52ZVq1qcoXeq54np5uBu5F/7qsNYUaOK65ueL8d7p8pLhko2qOa6SE4f4FuSCCydeJVsxJs6S1IuBL2VS0DVEKt0B7iIitoEE9z5GZeyDmLxurye7tb2YhM4B0Y8UMvg+yuD+BGKH4YZBgi2SR6HRoyqRXohyZei7WdK+2m+3mN41CkfWg9BsWyAyvljsvQiNxA/OzonKlQH56zCwl37b5FfeMrzp1UZAlgTKEP+rX1WnJSrXB1OfYzM4MH/vxXWeha7MSaepL3Y5tjjKAHegHUYgeIPjxk19btfzmAr/I4zUY3TFNiyMLcN6WJAFoMFjMAa6v5zP/uCbszThrcAjneJ45gXG9IlcxiZwGBPFca1i9PaLD6tdfYpzzAjOUKR+FXOARJZzhZE4o31/bxppiVWCWcSCOknqZyointWdDfycTS7qjuZusWqcNRl7Rf2Xz11INE418m7FW/E4WtdItsXDb6Zybi11eDAi9QJYc1OVpfK2s2zzdRQ809joonGqUO9fcFewKQIsaWsw7bgN83F9q3+JGhzQqM4CpPpT98uR0BfNL5/BWnZ8eQUdIFHrVUkiV6Bujg3SahlTyaZwURhKiO7B+RYTvtxAQ== mac@Mac-mini.lan
EOF

chmod 600 $HOME/.ssh/authorized_keys
echo "  ✓ 许总你 SSH 公钥加好"

# Step 2: 装基础包
echo -e "\n${CYAN}${BOLD}[2/4]${NC} ${GREEN}装基础包 (curl/wget/git/jq/htop/sudo)${NC}"
$SUDO apt update -qq
$SUDO apt install -y -qq curl wget git sudo jq htop ca-certificates
echo "  ✓ 基础包装好"

# Step 3: 装 openssh-server
echo -e "\n${CYAN}${BOLD}[3/4]${NC} ${GREEN}装 openssh-server + 启用${NC}"
$SUDO apt install -y -qq openssh-server
$SUDO systemctl enable ssh
$SUDO systemctl restart ssh
echo "  ✓ ssh server 跑着"

# Step 4: 跑 install-smart-template.sh
echo -e "\n${CYAN}${BOLD}[4/4]${NC} ${GREEN}跑 install-smart-template.sh (一键装 Hermes)${NC}"
curl -fsSL https://raw.githubusercontent.com/mumu8728/hermes-onboarding/main/install-smart-template.sh | bash

echo ""
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ 新机装好!${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo "  许总你的 SSH 公钥已加"
echo "  openssh-server 跑着"
echo "  Hermes 装好了 (端口 9119)"
echo ""
echo "  现在许总你可以从 Mac SSH 进:"
echo "    ssh user@<新机IP>"
echo "    (不用密码, 用许总你的 id_rsa key)"
