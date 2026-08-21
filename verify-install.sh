#!/bin/bash
# verify-install.sh - 装机验证脚本 (许总你说要)
# 老子的 install-smart-template.sh 装机后, 跑这个验证 22 项

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== 装机验证 (许总你说要) ==="
echo ""
echo "⚠️  装机前必读: README.zh-CN.md (官方教程)"
echo "   https://hermes-agent.nousresearch.com/docs/getting-started/installation"
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
# fcitx5 拼音输入法 — 5 维验证 (pkg / bin / conf / profile / autostart)
# 8-21 实战教训: 之前只 check `which fcitx5` = 不够, 实战暴露拼音"装了但用不了"
# (env vars 没配 + Autostart 缺失, fcitx5 进程在但开机不自启)
check "fcitx5 pkg (官方)" "dpkg -l | grep -q '^ii.*fcitx5 '"
check "fcitx5 binary" "which fcitx5"
check "fcitx5 config (profile + pinyin.conf)" "[ -f /home/debian/.config/fcitx5/profile ] && [ -f /home/debian/.config/fcitx5/conf/pinyin.conf ]"
check "fcitx5 env vars (官方 GTK_IM_MODULE)" "grep -q GTK_IM_MODULE=fcitx /etc/profile.d/fcitx5.sh 2>/dev/null || grep -q GTK_IM_MODULE /etc/profile.d/im-config_wayland.sh 2>/dev/null"
check "fcitx5 XDG Autostart" "[ -f /home/debian/.config/autostart/fcitx5.desktop ]"
check "Obsidian (官网 v1.13.7)" "dpkg -l | grep -q '^ii.*obsidian.*1\.13'" || [ -s /home/debian/.local/bin/obsidian.AppImage ]
check "CC Switch (官方 farion1231/cc-switch v3.20)" "dpkg -l | grep -q '^ii.*cc-switch'" || [ -s /home/debian/.local/bin/cc-switch.AppImage ]
check "FUSE 库 (Obsidian AppImage 要)" "dpkg -l | grep -q libfuse2"
check "node (Hermes CLI 要)" "[ -x /home/debian/.hermes/node/bin/node ]"
check "npx" "[ -x /home/debian/.hermes/node/bin/npx ]"

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
echo "--- 开机自启 (按 EVOLUTION-23 严守, 实战经验) ---"
check "hermes-web.service enabled (systemd)" "systemctl is-enabled hermes-web.service"
check "hermes-gateway.service enabled (systemd)" "systemctl is-enabled hermes-gateway.service"
check "hermes-web.service Restart=always" "systemctl show hermes-web.service | grep -q 'Restart=always'"
check "hermes-gateway.service Restart=always" "systemctl show hermes-gateway.service | grep -q 'Restart=always'"
check "hermes-web.service WantedBy=multi-user.target" "systemctl show hermes-web.service | grep -q 'WantedBy=multi-user.target'"
check "hermes-gateway.service WantedBy=multi-user.target" "systemctl show hermes-gateway.service | grep -q 'WantedBy=multi-user.target'"
check "disable-suspend.service enabled (防休眠)" "systemctl is-enabled disable-suspend.service"
check "soft-link 在 multi-user.target.wants (boot 拉起)" "ls /etc/systemd/system/multi-user.target.wants/hermes-web.service && ls /etc/systemd/system/multi-user.target.wants/hermes-gateway.service"

echo ""
echo "--- Provider (CC Switch 在客户机本地管 key) ---"
check "hermes MiniMax provider 装" "[ -d /home/debian/.hermes/hermes-agent/plugins/model-providers/minimax ]"
check "hermes OpenRouter provider 装" "[ -d /home/debian/.hermes/hermes-agent/plugins/model-providers/openrouter ]"
check "hermes DeepSeek provider 装" "[ -d /home/debian/.hermes/hermes-agent/plugins/model-providers/deepseek ]"

echo ""
echo "--- 监控 ---"
check "health-check.sh 装" "[ -x /home/debian/.local/bin/health-check.sh ]"
check "unattended-upgrades 装" "which unattended-upgrade"

echo ""
echo "--- 技能 (按 EVOLUTION-23 实战经验) ---"
SKILL_COUNT=$(find /home/debian/.hermes/skills -name 'SKILL.md' -type f 2>/dev/null | wc -l)
if [ "$SKILL_COUNT" -ge 80 ]; then
    echo -e "  ${GREEN}✓${NC} 总技能数: $SKILL_COUNT (≥80 实战经验)"
    PASS=$((PASS+1))
else
    echo -e "  ${RED}✗${NC} 总技能数: $SKILL_COUNT (期望 ≥80)"
    FAIL=$((FAIL+1))
fi
check "business 类 (许总你 14 年老板实战经验必备)" "[ -d /home/debian/.hermes/skills/business ]"
check "individual-merchant-tax-advisor" "[ -d /home/debian/.hermes/skills/business/individual-merchant-tax-advisor ]"
check "merchant-rights-protection" "[ -d /home/debian/.hermes/skills/business/merchant-rights-protection ]"
check "legal-risk-precheck" "[ -d /home/debian/.hermes/skills/business/legal-risk-precheck ]"
check "natural-person-ecommerce-tax-cn" "[ -d /home/debian/.hermes/skills/business/natural-person-ecommerce-tax-cn ]"
check "biz-research" "[ -d /home/debian/.hermes/skills/business/biz-research ]"
check "ad-spillover-evaluation" "[ -d /home/debian/.hermes/skills/business/ad-spillover-evaluation ]"
check "factory-group-no-thinking" "[ -d /home/debian/.hermes/skills/business/factory-group-no-thinking ]"
check "feishu-cli 9 个 AI 技能" "[ \$(ls /home/debian/.hermes/skills/feishu-cli/*.md 2>/dev/null | wc -l) -ge 9 ]"
check "web (cloakbrowser / crawl4ai / firecrawl)" "[ -d /home/debian/.hermes/skills/web/cloakbrowser-web-search ]"
check "wechat-msg skill (官方 Weixin docs)" "[ -s /home/debian/.hermes/skills/wechat-msg/SKILL.md ]"
check "wechat-msg skill 内容 (实战经验 ≥50 行)" "[ \$(wc -l < /home/debian/.hermes/skills/wechat-msg/SKILL.md) -ge 50 ]"

echo ""
echo "--- 汇总 ---"
echo "  ✓ PASS: $PASS"
if [ "$FAIL" -gt 0 ]; then
    echo -e "  ${RED}✗ FAIL: $FAIL${NC}"
    echo ""
    echo "装错项, 许总你说先看 README.zh-CN.md 再干:"
    echo "  /home/debian/.hermes/hermes-agent/README.zh-CN.md"
    echo "  https://hermes-agent.nousresearch.com/docs/getting-started/installation"
    exit 1
else
    echo -e "  ${GREEN}全部通过! 装机完整!${NC}"
    echo ""
    echo "下一步 (许总你说):"
    echo "  1. hermes setup --portal  # 走 Nous Portal OAuth (300+ 模型)"
    echo "  2. 或者 hermes model       # 手动选 provider + 配 key"
    echo "  3. feishu-cli auth login   # 配飞书 client credentials"
fi