#!/bin/bash
# ============================================================================
# Hermes 卸载脚本 (2026-08-19)
# ============================================================================
# 卸载 Hermes + 智能 + Chrome / CC Switch / Obsidian
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/mumu8728/hermes-onboarding/main/uninstall.sh | bash
#
# 或带配置:
#   bash uninstall.sh --keep-vault      # 保留 Obsidian vault
#   bash uninstall.sh --keep-config     # 保留 ~/.hermes/config
#   bash uninstall.sh --all              # 全部卸载 (包括 vault)
# ============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

KEEP_VAULT=false
KEEP_CONFIG=false
KEEP_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --keep-vault) KEEP_VAULT=true; shift ;;
        --keep-config) KEEP_CONFIG=true; shift ;;
        --all) KEEP_ALL=false; KEEP_VAULT=false; KEEP_CONFIG=false; shift ;;
        -h|--help) echo "用法见顶部"; exit 0 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

if [ "$KEEP_VAULT" = false ] && [ "$KEEP_CONFIG" = false ]; then
    KEEP_VAULT=false
    KEEP_CONFIG=false
fi

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  Hermes 卸载${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"

# 1. 停 Hermes
echo -e "\n${YELLOW}[1/8] 停 Hermes 24h 保活${NC}"

PLIST=$HOME/Library/LaunchAgents/com.deepseek.harness.web.plist
if [ -f "$PLIST" ]; then
    launchctl unload "$PLIST" 2>/dev/null || true
    launchctl stop com.deepseek.harness.web 2>/dev/null || true
    rm "$PLIST"
    echo "  ✓ Hermes daemon 已停"
fi

# Debian
SYSTEMD=$HOME/.config/systemd/user/hermes-web.service
if [ -f "$SYSTEMD" ]; then
    systemctl --user stop hermes-web.service 2>/dev/null || true
    systemctl --user disable hermes-web.service 2>/dev/null || true
    rm "$SYSTEMD"
    echo "  ✓ Hermes systemd daemon 已停"
fi

# 2. 删 cron
echo -e "\n${YELLOW}[2/8] 删 cron 任务${NC}"
(crontab -l 2>/dev/null | grep -v "hermes" | grep -v "ObsidianVault") | crontab - 2>/dev/null || true
echo "  ✓ cron 任务已删"

# 3. 卸脚本
echo -e "\n${YELLOW}[3/8] 卸脚本 (auto-backup / doctor / weekly)${NC}"
SCRIPTS=(
    "$HOME/.hermes/scripts/auto-backup.sh"
    "$HOME/.hermes/scripts/auto-doctor.sh"
    "$HOME/.hermes/scripts/weekly-report.sh"
    "$HOME/.hermes/scripts/weekly-aggregator.sh"
    "$HOME/.hermes/scripts/post-task-prompt.sh"
    "$HOME/.hermes/scripts/learn-loop.sh"
    "$HOME/.hermes/scripts/ask-me.sh"
    "$HOME/.hermes/scripts/startup-hook.sh"
    "$HOME/.hermes/scripts/auto-persist.sh"
)
for s in "${SCRIPTS[@]}"; do
    [ -f "$s" ] && rm "$s"
done
echo "  ✓ 脚本已删"

# 4. 卸 skills
echo -e "\n${YELLOW}[4/8] 卸 skills (cloakbrowser / cron / feishu / wechat)${NC}"
SKILLS=(
    "$HOME/.hermes/skills/web/cloakbrowser-web-search"
    "$HOME/.hermes/skills/cron-strip-rules"
    "$HOME/.hermes/skills/feishu-msg"
    "$HOME/.hermes/skills/wechat-msg"
    "$HOME/.hermes/skills/dev/readme-first-sop"
    "$HOME/.hermes/skills/dev/user-privacy-and-emotion-boundary"
    "$HOME/.hermes/skills/dev/multi-agent-audit"
    "$HOME/.hermes/skills/dev/hermes-platform-operations"
    "$HOME/.hermes/skills/dev/feishu-messaging"
    "$HOME/.hermes/skills/dev/bash-pitfalls"
    "$HOME/.hermes/skills/dev/heuristic-questioning"
    "$HOME/.hermes/skills/dev/logic-learning"
    "$HOME/.hermes/skills/dev/llm-code-delegation"
    "$HOME/.hermes/skills/dev/continuous-learning"
    "$HOME/.hermes/skills/dev/hermes-agent-skill-authoring"
    "$HOME/.hermes/skills/dev/technical-writing"
    "$HOME/.hermes/skills/dev/requesting-code-review"
    "$HOME/.hermes/skills/dev/systematic-debugging"
    "$HOME/.hermes/skills/dev/test-driven-development"
    "$HOME/.hermes/skills/dev/simplify-code"
    "$HOME/.hermes/skills/dev/document-to-action-items"
    "$HOME/.hermes/skills/dev/kanban-orchestrator"
    "$HOME/.hermes/skills/dev/lock-advisory"
    "$HOME/.hermes/skills/dev/humanizer-zh"
)
for s in "${SKILLS[@]}"; do
    [ -d "$s" ] && rm -rf "$s"
done
echo "  ✓ skills 已卸"

# 5. 卸 Hermes (可选, 默认保留 ~/.hermes)
echo -e "\n${YELLOW}[5/8] 卸 Hermes 二进制${NC}"
if [ -d "$HOME/.hermes/hermes-agent" ]; then
    rm -rf "$HOME/.hermes/hermes-agent"
    echo "  ✓ Hermes 代码已卸"
fi

if [ "$KEEP_CONFIG" = false ]; then
    if [ -d "$HOME/.hermes" ]; then
        rm -rf "$HOME/.hermes"
        echo "  ✓ ~/.hermes 已删"
    fi
else
    echo "  ⚠ ~/.hermes 保留 (--keep-config)"
fi

# 6. 卸 Obsidian vault
echo -e "\n${YELLOW}[6/8] 卸 Obsidian vault${NC}"
if [ "$KEEP_VAULT" = false ]; then
    if [ -d "$HOME/Documents/ObsidianVault" ]; then
        rm -rf "$HOME/Documents/ObsidianVault"
        echo "  ✓ Obsidian vault 已删"
    fi
else
    echo "  ⚠ vault 保留 (--keep-vault)"
fi

# 7. 卸 Chrome / CC Switch / Obsidian (Mac)
echo -e "\n${YELLOW}[7/8] 卸 Mac 软件 (Chrome / CC Switch / Obsidian)${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Chrome
    if [ -d "/Applications/Google Chrome.app" ]; then
        rm -rf "/Applications/Google Chrome.app"
        echo "  ✓ Google Chrome 已卸"
    fi
    # CC Switch
    if [ -d "/Applications/CC Switch.app" ]; then
        rm -rf "/Applications/CC Switch.app"
        echo "  ✓ CC Switch 已卸"
    fi
    # Obsidian
    if [ -d "/Applications/Obsidian.app" ]; then
        rm -rf "/Applications/Obsidian.app"
        echo "  ✓ Obsidian 已卸"
    fi
fi

# Debian
if [[ "$OSTYPE" == "linux"* ]]; then
    if command -v google-chrome &> /dev/null; then
        sudo apt remove -y google-chrome-stable 2>/dev/null || true
        echo "  ✓ Google Chrome 已卸"
    fi
    if [ -f "$HOME/.local/bin/cc-switch" ]; then
        rm -f "$HOME/.local/bin/cc-switch"
        rm -f "$HOME/.local/bin/cc-switch.AppImage"
        echo "  ✓ CC Switch 已卸"
    fi
    if command -v obsidian &> /dev/null; then
        sudo apt remove -y obsidian 2>/dev/null || true
        echo "  ✓ Obsidian 已卸"
    fi
fi

# 8. 清残留
echo -e "\n${YELLOW}[8/8] 清残留 (backups / logs)${NC}"
[ -d "$HOME/.hermes/backups" ] && rm -rf "$HOME/.hermes/backups"
[ -d "$HOME/.hermes/logs" ] && rm -rf "$HOME/.hermes/logs"

# 验证
echo -e "\n${CYAN}${BOLD}===========================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ 卸载完成!${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo -e "${YELLOW}残留检查:${NC}"
if [ -d "$HOME/.hermes" ]; then
    echo "  ⚠ ~/.hermes 还有内容"
    ls $HOME/.hermes
else
    echo "  ✓ ~/.hermes 已删"
fi

if [ "$KEEP_VAULT" = false ] && [ -d "$HOME/Documents/ObsidianVault" ]; then
    echo "  ⚠ vault 还有内容"
else
    echo "  ✓ vault 已删"
fi

echo ""
echo -e "${CYAN}如需保留 vault/config, 重跑时加 --keep-vault 或 --keep-config${NC}"
echo -e "${CYAN}如全部重装, 跑 install-smart.sh 重装${NC}"