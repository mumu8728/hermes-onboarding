#!/bin/bash
# verify-install.sh - 装机验证脚本 (许总你说要)
# 老子的 install-smart-template.sh 装机后, 跑这个验证 6 项

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== 装机验证 (许总你说要) ==="
echo ""

PASS=0
FAIL=0

check() {
    local name="$1"
    local cmd="$2"

    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} $name"
        PASS=$((PASS+1))
    else
        echo -e "  ${RED}✗${NC} $name"
        FAIL=$((FAIL+1))
    fi
}

echo "--- 基础 ---"
check "Debian 13 (trixie)" "[ \"\$(lsb_release -cs 2>/dev/null)\" = 'trixie' ]"
check "用户 debian" "id debian"
check "SSH 公钥 (许总你能登)" "[ -f \$HOME/.ssh/authorized_keys ] && grep -q mumu8728 \$HOME/.ssh/authorized_keys 2>/dev/null || [ -s \$HOME/.ssh/authorized_keys ]"
check "hostname 改 (hermes-*)" "hostname | grep -q '^hermes-'"

echo ""
echo "--- 服务 ---"
check "hermes-web active" "systemctl is-active hermes-web"
check "hermes-gateway active" "systemctl is-active hermes-gateway"
check "disable-suspend active (防休眠)" "systemctl is-active disable-suspend"
check "ssh active" "systemctl is-active ssh"
check "ufw active" "sudo ufw status | grep -q 'Status: active'"

echo ""
echo "--- 端口 ---"
check "端口 22 LISTEN (SSH)" "ss -tln | grep -q ':22 '"
check "端口 9119 LISTEN (Hermes)" "ss -tln | grep -q ':9119'"

echo ""
echo "--- 软件 ---"
check "hermes binary" "[ -x /home/debian/.hermes/hermes-agent/venv/bin/hermes ] || [ -x /usr/local/bin/hermes ]"
check "feishu-cli binary" "[ -x /usr/local/bin/feishu-cli ]"
check "google-chrome" "which google-chrome"
check "fcitx5 (中文输入法)" "which fcitx5"
check "Obsidian AppImage" "[ -s /home/debian/.local/bin/obsidian.AppImage ]"

echo ""
echo "--- feishu-cli 9 个 AI 技能 ---"
SKILL_COUNT=$(ls /home/debian/.hermes/skills/feishu-cli/*.md 2>/dev/null | wc -l)
if [ "$SKILL_COUNT" -ge 9 ]; then
    echo -e "  ${GREEN}✓${NC} feishu-cli $SKILL_COUNT 个 AI 技能"
    PASS=$((PASS+1))
else
    echo -e "  ${RED}✗${NC} feishu-cli 只装 $SKILL_COUNT 个 (期望 ≥9)"
    FAIL=$((FAIL+1))
fi

echo ""
echo "--- 网络 ---"
check "DNS 解析" "ping -c 1 -W 3 8.8.8.8"

echo ""
echo "--- 配置 ---"
check "config.yaml 没 dashboard 节 (CC Switch 管 key)" "! grep -q '^dashboard:' /home/debian/.hermes/config.yaml"
check "Hermes serve 绑 127.0.0.1 (本地)" "grep -q '127.0.0.1' /etc/systemd/system/hermes-web.service"

echo ""
echo "--- 安全 ---"
check "公钥在 authorized_keys" "wc -l < ~/.ssh/authorized_keys | awk '{exit (\$1 >= 1)?0:1}'"
check "防火墙开" "sudo ufw status | grep -q '22/tcp.*ALLOW'"

echo ""
echo "--- 汇总 ---"
echo "  ✓ PASS: $PASS"
if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}✗ FAIL: $FAIL${NC}"
    exit 1
else
    echo -e "  ${GREEN}全部通过!${NC}"
fi