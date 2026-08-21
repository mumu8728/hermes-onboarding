#!/bin/bash
# ============================================================================
# install-smart-mac.sh - Mac arm64 客户版 (v0.3.0 新加)
# ============================================================================
# 用途: 给许总你自己的 Mac mini (arm64) 装 Hermes
# 用法: bash install-smart-mac.sh
#
# 跟 install-smart-template.sh 的差别:
# - 系统是 macOS (arm64), 不是 Debian 13
# - 用 brew 装基础包, 不是 apt
# - 浏览器用 Chrome (macOS 自带)
# - CC Switch + Obsidian 都用 arm64 原生包
# - systemd → launchd (Mac 自己的后台服务)
# ============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

step=0
total=7

progress() {
    step=$((step+1))
    echo ""
    echo -e "${CYAN}${BOLD}[${step}/${total}]${NC} ${GREEN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  Hermes 模板机 (Mac arm64) 一键配置${NC}"
echo -e "${CYAN}${BOLD}  许总你自己 Mac mini 用的${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"

# 1. 装 Homebrew (如果没有)
progress "检查 Homebrew (1/7)"
if ! command -v brew >/dev/null 2>&1; then
    echo "  装 Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo "  brew 在: $(brew --prefix)"

# 2. 装基础包
progress "装基础包 (2/7)"
brew install jq curl wget git htop zsh zsh-autosuggestions zsh-syntax-highlighting
echo "  基础包装好"

# 3. 装 Chrome + CC Switch + Obsidian (macOS 原生包)
progress "装 Chrome + CC Switch + Obsidian (3/7)"
if ! brew list --cask google-chrome >/dev/null 2>&1; then
    brew install --cask google-chrome
fi
echo "  Chrome"

# CC Switch (macOS)
if [ ! -d "$HOME/.local/bin/cc-switch.app" ]; then
    curl -fsSL https://github.com/xumugong/cc-switch/releases/latest/download/cc-switch_macOS.zip -o /tmp/cc-switch.zip
    unzip -q /tmp/cc-switch.zip -d "$HOME/.local/bin/"
fi
echo "  CC Switch"

# Obsidian (macOS)
if ! brew list --cask obsidian >/dev/null 2>&1; then
    brew install --cask obsidian
fi
echo "  Obsidian"

# 4. 装 Hermes
progress "装 Hermes (4/7)"
if [ ! -d "$HOME/.hermes/hermes-agent" ]; then
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive
fi
echo "  Hermes"

# 5. 装 feishu-cli + 9 个 AI 技能
progress "装 feishu-cli + 9 个 AI 技能 (5/7)"
if [ ! -x /usr/local/bin/feishu-cli ]; then
    cd /tmp
    OS_TYPE="darwin"
    ARCH="arm64"
    FEISHU_VERSION=$(curl -sI "https://github.com/riba2534/feishu-cli/releases/latest" 2>/dev/null | grep -i '^location:' | head -1 | sed 's|.*/tag/\([^[:space:]]*\).*|\1|' | tr -d '\r\n')
    BINARY="feishu-cli_${FEISHU_VERSION}_${OS_TYPE}-${ARCH}.tar.gz"
    URL="https://github.com/riba2534/feishu-cli/releases/download/${FEISHU_VERSION}/${BINARY}"
    wget -q "$URL" -O feishu-cli.tar.gz
    mkdir -p /tmp/feishu-cli-extract
    tar xzf feishu-cli.tar.gz -C /tmp/feishu-cli-extract
    FEISHU_BIN=$(find /tmp/feishu-cli-extract -name feishu-cli -type f -executable | head -1)
    sudo install -m 755 "$FEISHU_BIN" /usr/local/bin/feishu-cli
    rm -rf feishu-cli.tar.gz /tmp/feishu-cli-extract
fi
echo "  feishu-cli"

# 装 9 个 AI 技能
mkdir -p "$HOME/.hermes/skills/feishu-cli"
REPO_FEISHU_SKILLS="$(dirname "${BASH_SOURCE[0]}")/templates/skills/feishu-cli"
if [ -d "$REPO_FEISHU_SKILLS" ]; then
    cp -r "$REPO_FEISHU_SKILLS"/* "$HOME/.hermes/skills/feishu-cli/"
fi
echo "  9 个 AI 技能"

# 6. 配 launchd (Mac 自己的后台服务)
progress "配 launchd 24h 保活 (6/7)"

HERMES_BIN=$(find "$HOME/.hermes/hermes-agent/.venv/bin/hermes" "$HOME/.local/bin/hermes" 2>/dev/null | head -1)
if [ -z "$HERMES_BIN" ]; then
    HERMES_BIN="$HOME/.local/bin/hermes"
fi

mkdir -p "$HOME/Library/LaunchAgents"
cat > "$HOME/Library/LaunchAgents/com.hermes.web.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.hermes.web</string>
    <key>ProgramArguments</key>
    <array>
        <string>${HERMES_BIN}</string>
        <string>serve</string>
        <string>--host</string>
        <string>0.0.0.0</string>
        <string>--port</string>
        <string>9119</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/.hermes/logs/hermes-web.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.hermes/logs/hermes-web-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>$HOME</string>
        <key>PATH</key>
        <string>$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
</dict>
</plist>
EOF

mkdir -p "$HOME/.hermes/logs"

launchctl unload "$HOME/Library/LaunchAgents/com.hermes.web.plist" 2>/dev/null || true
launchctl load -w "$HOME/Library/LaunchAgents/com.hermes.web.plist"

sleep 5
if launchctl list | grep -q com.hermes.web; then
    echo "  launchd 24h 保活 (Mac)"
else
    echo "  ⚠ 没起来 — 看 log: cat $HOME/.hermes/logs/hermes-web-error.log"
fi

# 7. 准备对拷
progress "准备对拷 (7/7)"
echo "  Mac arm64 装机完成"
echo ""
echo "验证:"
echo "  launchctl list | grep com.hermes.web"
echo "  curl http://localhost:9119"
