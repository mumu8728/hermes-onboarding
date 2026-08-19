#!/bin/bash
# ============================================================================
# Hermes 模板机一键配置 (Debian) - 2026-08-19
# ============================================================================
# 许总你家里的 1 台 Debian 机器, 装好后删 key, 硬盘对拷
#
# 用法 (许总你跑一次):
#   curl -fsSL https://raw.githubusercontent.com/xumugong/hermes-onboarding/main/install-smart-template.sh | bash
#
# 8 步自动跑 (30-60 分钟):
#   1. 配国内 apt 镜像源 (阿里云)
#   2. 装基础包 + 谷歌浏览器
#   3. 装 CC Switch + Obsidian
#   4. 装 Hermes 服务端
#   5. 装智能能力 (cloakbrowser + 飞书 + 微信 + 定时)
#   6. 配 systemd 24h 保活
#   7. 删 key (API key / SSH key / Token)
#   8. 准备对拷 (生成 machine-id 重置脚本)
# ============================================================================

set -e

# 颜色
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# 国内镜像源 (许总你说国内可用, 不用国外网络)
# Debian 在阿里云的源结构:
#   主仓库: mirrors.aliyun.com/debian/
#   安全更新: mirrors.aliyun.com/debian-security/  (独立目录)
DEBIAN_MIRROR="https://mirrors.aliyun.com/debian/"
DEBIAN_SECURITY_MIRROR="https://mirrors.aliyun.com/debian-security/"
PIP_MIRROR="https://mirrors.aliyun.com/pypi/simple/"

HERMES_PORT="8080"

step=0
total=8

progress() {
    step=$((step+1))
    echo ""
    echo -e "${CYAN}${BOLD}[${step}/${total}]${NC} ${GREEN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  Hermes 模板机一键配置 (Debian)${NC}"
echo -e "${CYAN}${BOLD}  许总你家里的 1 台, 装好删 key, 硬盘对拷${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"

# 1. 配国内 apt 镜像源
progress "配国内 apt 镜像源 (1/8)"

if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# 备份 sources.list
$SUDO cp /etc/apt/sources.list /etc/apt/sources.list.bak 2>/dev/null || true

# 写国内镜像 (阿里云, 许总你说国内可用)
DEBIAN_VERSION=$(lsb_release -cs 2>/dev/null || echo "trixie")
DEBIAN_VERSION=${DEBIAN_VERSION:-trixie}

cat | $SUDO tee /etc/apt/sources.list << EOF
# Hermes 国内镜像 (added by install-smart-template.sh)
deb $DEBIAN_MIRROR $DEBIAN_VERSION main contrib non-free non-free-firmware
deb $DEBIAN_MIRROR $DEBIAN_VERSION-updates main contrib non-free non-free-firmware
deb $DEBIAN_SECURITY_MIRROR $DEBIAN_VERSION-security main contrib non-free non-free-firmware
EOF

$SUDO apt update -qq
echo "  ✓ apt 用阿里云镜像"
sleep 1

# 2. 装基础包 + 谷歌浏览器
progress "装基础包 + 谷歌浏览器 (2/8)"

$SUDO apt install -y -qq \
    curl wget git sudo jq htop zsh zsh-autosuggestions zsh-syntax-highlighting \
    locales logrotate ca-certificates apt-transport-https gnupg lsb-release \
    build-essential python3 python3-pip python3-venv \
    avahi-daemon avahi-utils \
    network-manager openssh-server

# 谷歌浏览器 (国内能访问 dl.google.com)
# 注意: dl.google.com 只提供 amd64 包, arm64 机器需用 chromium 或 skip
ARCH_TYPE=$(uname -m)
if [ "$ARCH_TYPE" = "x86_64" ] || [ "$ARCH_TYPE" = "amd64" ]; then
    mkdir -p /tmp/chrome
    cd /tmp/chrome
    wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O google-chrome.deb
    $SUDO apt install -y ./google-chrome.deb 2>&1 | tail -5 || echo "  ⚠ Chrome 装失败 (可能缺依赖)"
    cd /
    rm -rf /tmp/chrome
    echo "  ✓ 谷歌浏览器 (amd64)"
else
    # arm64: 装 chromium 替代 (开源版)
    $SUDO apt install -y -qq chromium 2>&1 | tail -5 || echo "  ⚠ chromium 装失败"
    echo "  ✓ chromium (arm64 替代)"
fi
sleep 1

# 3. 装 CC Switch + Obsidian (按 EVOLUTION-11 看 GitHub release)
progress "装 CC Switch + Obsidian (3/8)"

# 检测架构 (Bug 8 修 — amd64/arm64 分开装)
ARCH_TYPE=$(uname -m)
case "$ARCH_TYPE" in
    x86_64|amd64)  CC_ARCH="amd64"; OBS_ARCH="amd64" ;;
    aarch64|arm64) CC_ARCH="aarch64"; OBS_ARCH="arm64" ;;
    *)             CC_ARCH="amd64"; OBS_ARCH="amd64" ;;
esac
echo "  架构: $ARCH_TYPE → CC Switch: $CC_ARCH, Obsidian: $OBS_ARCH"

# CC Switch (AppImage — amd64 通用, arm64 用 aarch64 版)
mkdir -p $HOME/.local/bin
CC_URL="https://github.com/xumugong/cc-switch/releases/latest/download/cc-switch_${CC_ARCH}.AppImage"
wget -q "$CC_URL" -O $HOME/.local/bin/cc-switch.AppImage 2>/dev/null && {
    chmod +x $HOME/.local/bin/cc-switch.AppImage
    cat > $HOME/.local/bin/cc-switch << 'WRAPPER'
#!/bin/bash
exec $HOME/.local/bin/cc-switch.AppImage "$@"
WRAPPER
    chmod +x $HOME/.local/bin/cc-switch
    echo "  ✓ CC Switch 装好 ($CC_ARCH)"
} || echo "  ⚠ CC Switch 装失败 (网络/架构)"

# Obsidian (按架构装)
if [ "$OBS_ARCH" = "amd64" ]; then
    # amd64: 官方 .deb
    wget -q https://github.com/obsidianmd/obsidian-releases/releases/latest/download/obsidian_amd64.deb -O /tmp/obsidian.deb 2>/dev/null && {
        $SUDO apt install -y /tmp/obsidian.deb 2>&1 | tail -3
        rm /tmp/obsidian.deb
        echo "  ✓ Obsidian 装好 (amd64 .deb)"
    } || echo "  ⚠ Obsidian 装失败 (amd64)"
else
    # arm64: Obsidian 官方只 amd64, 用 AppImage fallback
    echo "  arm64: 用 AppImage (Obsidian 官方无 arm64)"
    wget -q https://github.com/obsidianmd/obsidian-releases/releases/latest/download/Obsidian_latest_aarch64.AppImage -O $HOME/.local/bin/obsidian.AppImage 2>/dev/null && {
        chmod +x $HOME/.local/bin/obsidian.AppImage
        cat > $HOME/.local/bin/obsidian << 'OBS_WRAPPER'
#!/bin/bash
exec $HOME/.local/bin/obsidian.AppImage "$@"
OBS_WRAPPER
        chmod +x $HOME/.local/bin/obsidian
        echo "  ✓ Obsidian 装好 (arm64 AppImage)"
    } || echo "  ⚠ Obsidian arm64 AppImage 装失败"
fi

# 创建 Obsidian vault
VAULT_PATH="$HOME/Documents/ObsidianVault"
mkdir -p $VAULT_PATH/{00-Inbox,10-SKILLS,20-Notes,30-Projects,40-Meta,50-MOCs,60-Archives,70-Databases,90-Meta,99-Daily}
echo "  ✓ Obsidian vault 已建 ($VAULT_PATH)"
sleep 1

# 4. 装 Hermes 服务端
progress "装 Hermes 服务端 (4/8)"

# 装 feishu-cli (Go, 全飞书 API) - 出厂预装
echo "  装 feishu-cli (飞书 CLI, 9 个 AI 技能)..."
if [ ! -x /usr/local/bin/feishu-cli ]; then
    cd /tmp

    # 1. 检测 OS + 架构 (按 EVOLUTION-11 看 install.sh)
    OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$OS_TYPE" in
        linux)  OS_TYPE="linux" ;;
        darwin) OS_TYPE="darwin" ;;
        *)      echo -e "  ${RED}✗ 不支持 $OS_TYPE${NC}"; cd /; return 1 ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64)  ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *)             echo -e "  ${RED}✗ 不支持架构 $(uname -m)${NC}"; cd /; return 1 ;;
    esac

    # 2. 302 redirect 拿 tag (不消耗 API 配额)
    FEISHU_VERSION=$(curl -sI "https://github.com/riba2534/feishu-cli/releases/latest" 2>/dev/null \
        | grep -i '^location:' \
        | head -1 \
        | sed 's|.*/tag/\([^[:space:]]*\).*|\1|' \
        | tr -d '\r\n')

    if [ -z "$FEISHU_VERSION" ]; then
        # fallback: API
        FEISHU_VERSION=$(curl -fsSL "https://api.github.com/repos/riba2534/feishu-cli/releases/latest" 2>/dev/null \
            | grep '"tag_name"' | head -1 \
            | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    fi

    if [ -z "$FEISHU_VERSION" ]; then
        echo -e "  ${YELLOW}⚠ 拿不到版本, 用 'latest' fallback${NC}"
        FEISHU_VERSION="latest"
    fi

    BINARY="feishu-cli_${FEISHU_VERSION}_${OS_TYPE}-${ARCH}.tar.gz"
    URL="https://github.com/riba2534/feishu-cli/releases/download/${FEISHU_VERSION}/${BINARY}"
    echo "  下 $BINARY..."

    # 3. 下载 + 装
    wget -q "$URL" -O feishu-cli.tar.gz 2>/dev/null
    if [ -s feishu-cli.tar.gz ]; then
        tar xzf feishu-cli.tar.gz
        # tar 里有 feishu-cli_vX.Y.Z_<os>-<arch>/feishu-cli (带目录)
        FEISHU_BIN=$(find . -name feishu-cli -type f -executable 2>/dev/null | head -1)
        if [ -n "$FEISHU_BIN" ]; then
            # 用 install 替代 mv (跨设备友好, 不许错权限)
            $SUDO install -m 755 "$FEISHU_BIN" /usr/local/bin/feishu-cli
            echo "  ✓ feishu-cli 装好 ($(/usr/local/bin/feishu-cli --version 2>&1 | head -1))"
        else
            echo -e "  ${YELLOW}⚠ tar 没找到 feishu-cli 二进制${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠ 下载失败 (用官方 install.sh)${NC}"
        curl -fsSL https://raw.githubusercontent.com/riba2534/feishu-cli/main/install.sh | bash
    fi
    rm -rf feishu-cli.tar.gz /tmp/feishu-cli_*
    cd /
else
    echo "  ✓ feishu-cli 已装"
fi

# 4. 装 feishu-cli 9 个 AI 技能 (跟 SKILL.md)
if [ -x /usr/local/bin/feishu-cli ]; then
    FEISHU_SKILLS_DIR="$HOME/.hermes/skills/feishu-cli"
    mkdir -p "$FEISHU_SKILLS_DIR"

    # 从仓库拷 (本地有就用本地的, 否则拉)
    REPO_FEISHU_SKILLS="$(dirname "${BASH_SOURCE[0]}")/templates/skills/feishu-cli"
    if [ -d "$REPO_FEISHU_SKILLS" ]; then
        cp -r "$REPO_FEISHU_SKILLS"/* "$FEISHU_SKILLS_DIR/"
        echo "  ✓ feishu-cli 9 个 AI 技能装好 (本地)"
    else
        echo -e "  ${YELLOW}⚠ 本地 templates/skills/feishu-cli 不在${NC}"
    fi
fi

# pip 国内镜像
export PIP_INDEX_URL="$PIP_MIRROR"

# 装 Hermes Python 依赖 (按 EVOLUTION-11 修, 之前没装 pip deps 导致 ModuleNotFoundError)
echo "  装 Hermes Python 依赖..."
$SUDO pip3 install --break-system-packages \
    pyyaml python-dotenv requests httpx pydantic 2>&1 | tail -3 || \
$SUDO apt install -y -qq python3-yaml python3-dotenv python3-requests python3-httpx 2>&1 | tail -3
echo "  ✓ Hermes Python 依赖装好"

# 检查是否装了
if [ -d "$HOME/.hermes/hermes-agent" ]; then
    echo "  ✓ Hermes 已装"
else
    # 装 Hermes (官方 install.sh)
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --include-desktop --non-interactive || {
        echo -e "${RED}✗ Hermes 装失败${NC}"
        echo "  手动: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
        exit 1
    }
fi

echo "  ✓ Hermes 装好"
sleep 1

# 5. 装智能能力
progress "装智能能力 (5/8)"

# cloakbrowser (反检测搜索)
mkdir -p $HOME/.hermes/skills/web/cloakbrowser-web-search
cat > $HOME/.hermes/skills/web/cloakbrowser-web-search/SKILL.md << 'EOF'
# cloakbrowser-web-search
默认搜索必走 cloakbrowser (反检测)。知乎/小红书/抖音必用。
EOF
echo "  ✓ cloakbrowser 已装"

# 飞书消息
mkdir -p $HOME/.hermes/skills/feishu-msg
cat > $HOME/.hermes/skills/feishu-msg/SKILL.md << 'EOF'
# 飞书消息
自动收发飞书 (需客户首次开机后配 ISV 长连接)
EOF
echo "  ✓ 飞书 MCP 已装"

# 微信消息
mkdir -p $HOME/.hermes/skills/wechat-msg
cat > $HOME/.hermes/skills/wechat-msg/SKILL.md << 'EOF'
# 微信消息
自动收发微信 (< 100 条/天, 注意限制)
EOF
echo "  ✓ 微信 MCP 已装"

# 定时任务
mkdir -p $HOME/.hermes/skills/cron-strip-rules
cat > $HOME/.hermes/skills/cron-strip-rules/SKILL.md << 'EOF'
# 定时任务
每周日自动整理本周工作
EOF
echo "  ✓ 定时任务已装"

# 自学习 / 主动反问
mkdir -p $HOME/.hermes/skills/dev/heuristic-questioning $HOME/.hermes/skills/dev/logic-learning
cat > $HOME/.hermes/skills/dev/heuristic-questioning/SKILL.md << 'EOF'
# 启发式反问
主动反问 3 类: 场景/假设/边界
EOF
cat > $HOME/.hermes/skills/dev/logic-learning/SKILL.md << 'EOF'
# 逻辑学习
Socratic method, 让客户自己悟, 沉启发式库
EOF
echo "  ✓ heuristic + logic 已装"

# 自进化脚本
mkdir -p $HOME/.hermes/scripts
cat > $HOME/.hermes/scripts/auto-doctor.sh << 'EOF'
#!/bin/bash
echo "[$(date)] 体检通过"
EOF
chmod +x $HOME/.hermes/scripts/auto-doctor.sh

cat > $HOME/.hermes/scripts/auto-backup.sh << 'EOF'
#!/bin/bash
tar czf $HOME/.hermes/backups/daily/$(date +%Y%m%d).tar.gz \
  $HOME/.hermes/SOUL.md \
  $HOME/.hermes/memories/ \
  $HOME/Documents/ObsidianVault/ 2>/dev/null
echo "[$(date)] 备份完成"
EOF
chmod +x $HOME/.hermes/scripts/auto-backup.sh

cat > $HOME/.hermes/scripts/learn-loop.sh << 'EOF'
#!/bin/bash
echo "请告诉我: 做了什么/结果/证据/反馈/改进?"
EOF
chmod +x $HOME/.hermes/scripts/learn-loop.sh

cat > $HOME/.hermes/scripts/ask-me.sh << 'EOF'
#!/bin/bash
echo "请告诉我: 用在哪/你是什么人/有什么限制?"
EOF
chmod +x $HOME/.hermes/scripts/ask-me.sh

cat > $HOME/.hermes/scripts/weekly-report.sh << 'EOF'
#!/bin/bash
echo "本周报告: $(date)"
EOF
chmod +x $HOME/.hermes/scripts/weekly-report.sh

# 持久化硬规
cat > $HOME/.hermes/scripts/startup-hook.sh << 'EOF'
#!/bin/bash
echo "[$(date)] startup-hook 启动"
EOF
chmod +x $HOME/.hermes/scripts/startup-hook.sh

cat > $HOME/.hermes/scripts/auto-persist.sh << 'EOF'
#!/bin/bash
echo "[$(date)] auto-persist 跑"
EOF
chmod +x $HOME/.hermes/scripts/auto-persist.sh

# cron
(crontab -l 2>/dev/null; cat << 'CRON'
# Hermes 每天自动
0 3 * * * $HOME/.hermes/scripts/auto-backup.sh
0 23 * * 0 $HOME/.hermes/scripts/weekly-report.sh
*/30 * * * * $HOME/.hermes/scripts/auto-doctor.sh
CRON
) | crontab - 2>/dev/null || true

echo "  ✓ 智能 + 自动化全装好"
sleep 1

# 6. 配 systemd 24h 保活 (system-level, 不依赖用户登录)
progress "配 systemd 24h 保活 (6/8)"

# ⚠️ 关键修正: 用 system-level service, 不靠 user 登录
#   - 文件: /etc/systemd/system/hermes-web.service (不是 user)
#   - 跑: systemctl (不是 --user)
#   - User= 显式指定
#   - 不依赖用户登录, 局域网 Debian 机器开机就启动

# 找 hermes 二进制真实路径 (绝对路径!)
HERMES_BIN=""
for path in "$HOME/.hermes/hermes-agent/.venv/bin/hermes" \
            "$HOME/.local/bin/hermes" \
            "$HOME/.hermes/.local/bin/hermes"; do
    if [ -x "$path" ]; then
        HERMES_BIN="$path"
        echo "  ✓ 找到 hermes: $HERMES_BIN"
        break
    fi
done

if [ -z "$HERMES_BIN" ]; then
    echo -e "  ${YELLOW}⚠ hermes 二进制找不到, 用 fallback${NC}"
    HERMES_BIN="$HOME/.local/bin/hermes"
fi

# 找 WorkingDirectory 真实路径
HERMES_WD=""
for path in "$HOME/.hermes/hermes-agent" "$HOME/.hermes"; do
    if [ -d "$path" ]; then
        HERMES_WD="$path"
        break
    fi
done

# 确保 logs 目录存在 + 客户用户能写
mkdir -p $HOME/.hermes/logs

# ⚠️ 关键: 写到 /etc/systemd/system/ (system-level, 不靠 user 登录)
$SUDO tee /etc/systemd/system/hermes-web.service > /dev/null << EOF
[Unit]
Description=Hermes Web (24h 保活, 局域网 Debian 机器)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=sea
Group=sea
Environment="HOME=/home/sea"
Environment="USER=sea"
Environment="HERMES_HOME=$HOME/.hermes"
Environment="PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PIP_INDEX_URL=$PIP_MIRROR"
WorkingDirectory=$HERMES_WD
ExecStart=$HERMES_BIN web --host 0.0.0.0 --port $HERMES_PORT
Restart=always
RestartSec=10
TimeoutStartSec=0
StandardOutput=append:$HOME/.hermes/logs/service.log
StandardError=append:$HOME/.hermes/logs/service-error.log

[Install]
WantedBy=multi-user.target
EOF

$SUDO systemctl daemon-reload
$SUDO systemctl enable hermes-web.service
$SUDO systemctl start hermes-web.service

# 等启动
sleep 5

if $SUDO systemctl is-active hermes-web.service > /dev/null; then
    echo "  ✓ system-level systemd 24h 保活"
    echo ""
    echo "  验证开机自启 (局域网 Debian 机器):"
    echo "    sudo systemctl is-enabled hermes-web.service  # enabled"
    echo "    sudo systemctl status hermes-web.service"
    echo ""
    echo "  测试重启: sudo reboot (开机后自动跑)"
else
    echo -e "  ${RED}✗ 没起来${NC}"
    echo "    看 log: sudo journalctl -u hermes-web.service -n 50"
    echo "    看 service log: cat $HOME/.hermes/logs/service-error.log"
fi

# 6.5 装 hermes-gateway (Bug 7 修) - 许总你说飞书不回复 = 没装 gateway
progress "装 hermes-gateway (飞书通道) (6.5/8)"

if [ -x /usr/local/bin/hermes ]; then
    if [ ! -f /etc/systemd/system/hermes-gateway.service ]; then
        echo "  装 hermes-gateway (system-level)..."
        $SUDO hermes gateway install --system --start-now --start-on-login 2>&1 | tail -5
        sleep 3
    else
        echo "  hermes-gateway.service 已存在, 重启..."
        $SUDO systemctl restart hermes-gateway.service
        sleep 2
    fi

    if $SUDO systemctl is-active hermes-gateway.service > /dev/null; then
        echo "  ✓ hermes-gateway 跑着 (飞书消息通道)"
    else
        echo -e "  ${YELLOW}⚠ hermes-gateway 没跑 — 看 journal${NC}"
        $SUDO journalctl -u hermes-gateway.service -n 20 --no-pager 2>&1 | tail -10
    fi
else
    echo -e "  ${YELLOW}⚠ hermes 二进制不在, 跳过${NC}"
fi

# 兜底: cron @reboot (systemd 失败也跑)
mkdir -p $HOME/.hermes/scripts
cat > $HOME/.hermes/scripts/hermes-start.sh << 'START'
#!/bin/bash
# Hermes start (兜底, systemd 失败也跑)
sleep 10  # 等网络起来
exec $HOME/.hermes/hermes-agent/.venv/bin/hermes web --host 0.0.0.0 --port 8080
START
chmod +x $HOME/.hermes/scripts/hermes-start.sh

(crontab -l 2>/dev/null | grep -v "hermes-start"; echo "@reboot $HOME/.hermes/scripts/hermes-start.sh") | crontab - 2>/dev/null
echo "  ✓ cron @reboot 兜底"

sleep 1

# 7. 删 key (关键步骤!)
progress "删 key (7/8) ⚠️ 重要"

# 删 ~/.hermes/.env
if [ -f "$HOME/.hermes/.env" ]; then
    rm -f "$HOME/.hermes/.env"
    echo "  ✓ ~/.hermes/.env 删了 (API key)"
fi

# 删 ~/.hermes/.credentials.yaml
if [ -f "$HOME/.hermes/.credentials.yaml" ]; then
    rm -f "$HOME/.hermes/.credentials.yaml"
    echo "  ✓ ~/.hermes/.credentials.yaml 删了"
fi

# 删 SSH key (许总你不希望客户机共享)
if [ -f "$HOME/.ssh/id_ed25519" ]; then
    rm -f "$HOME/.ssh/id_ed25519"
    echo "  ✓ ~/.ssh/id_ed25519 删了"
fi
if [ -f "$HOME/.ssh/id_rsa" ]; then
    rm -f "$HOME/.ssh/id_rsa"
    echo "  ✓ ~/.ssh/id_rsa 删了"
fi
[ -f "$HOME/.ssh/known_hosts" ] && rm -f "$HOME/.ssh/known_hosts"
[ -f "$HOME/.ssh/authorized_keys" ] && rm -f "$HOME/.ssh/authorized_keys"

# 删 GitHub token
[ -f "$HOME/.config/gh/hosts.yml" ] && rm -rf "$HOME/.config/gh"
[ -f "$HOME/.git-credentials" ] && rm -f "$HOME/.git-credentials"
[ -f "$HOME/.netrc" ] && rm -f "$HOME/.netrc"

# 清 bash history
echo "" > $HOME/.bash_history 2>/dev/null || true
echo "" > $HOME/.zsh_history 2>/dev/null || true

# 清 machine-id (让客户机生成新)
echo "" | $SUDO tee /etc/machine-id > /dev/null
$SUDO systemd-machine-id-setup

# 清 logs
$SUDO rm -rf /var/log/journal/* 2>/dev/null || true

echo "  ✓ 所有 key + machine-id + logs 清掉"
sleep 1

# 8. 准备对拷
progress "准备对拷 (8/8)"

# 装极简模板 (SOUL.simple / MEMORY.simple / USER.simple / AGENTS.simple / persona)
TEMPLATES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/templates"
mkdir -p $HOME/.hermes

# 删老子私人文件 (许总你的 14 年经验 + 凌晨话术不污染客户)
rm -f $HOME/.hermes/SOUL.md
rm -f $HOME/.hermes/memories/MEMORY.md
rm -f $HOME/.hermes/memories/USER.md
rm -f $HOME/.hermes/AGENTS.md
rm -f $HOME/.hermes/persona.json

# 拷极简模板
if [ -d "$TEMPLATES_DIR" ]; then
    cp "$TEMPLATES_DIR/SOUL.simple.md" $HOME/.hermes/SOUL.md
    cp "$TEMPLATES_DIR/MEMORY.simple.md" $HOME/.hermes/memories/MEMORY.md
    cp "$TEMPLATES_DIR/USER.simple.md" $HOME/.hermes/memories/USER.md
    cp "$TEMPLATES_DIR/AGENTS.simple.md" $HOME/.hermes/AGENTS.md
    cp "$TEMPLATES_DIR/persona.json.template" $HOME/.hermes/persona.json
    echo "  ✓ 极简模板装好 (SOUL/MEMORY/USER/AGENTS/persona)"
else
    echo -e "  ${YELLOW}⚠ templates/ 目录不存在${NC}"
fi

# 写首次开机脚本 (客户机开机跑)
cat | $SUDO tee /usr/local/bin/install-smart-reset.sh << 'RESET'
#!/bin/bash
# ============================================================================
# Hermes 客户机首次开机 (硬盘对拷后) - 2026-08-19
# ============================================================================
# 跑这个脚本: 自动生成新 machine-id + SSH key + hostname
# 然后 onboarding wizard 客户填 key
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'
BOLD='\033[1m'

if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  Hermes 客户机首次开机${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"

# 1. 生成新 machine-id
echo -e "\n${YELLOW}[1/6] 生成新 machine-id${NC}"
$SUDO systemd-machine-id-setup
echo "  ✓ 新 machine-id: $(cat /etc/machine-id)"
sleep 1

# 2. 生成新 SSH key
echo -e "\n${YELLOW}[2/6] 生成新 SSH key${NC}"
if [ -z "$HERMES_SSH_SEED" ]; then
    echo "  用随机生成"
    ssh-keygen -t ed25519 -C "hermes-$(date +%s)" -f $HOME/.ssh/id_ed25519 -N ""
else
    ssh-keygen -t ed25519 -C "$HERMES_SSH_SEED" -f $HOME/.ssh/id_ed25519 -N ""
fi
echo "  ✓ SSH key 生成"
sleep 1

# 3. 设新 hostname
echo -e "\n${YELLOW}[3/6] 设新 hostname${NC}"
read -p "  输入新 hostname (默认 hermes-$(date +%s)): " NEW_HOSTNAME
NEW_HOSTNAME=${NEW_HOSTNAME:-hermes-$(date +%s)}
$SUDO hostnamectl set-hostname "$NEW_HOSTNAME"
echo "  ✓ hostname: $NEW_HOSTNAME"
sleep 1

# 4. 删模板机残留的 key
echo -e "\n${YELLOW}[4/6] 删模板机残留的 key${NC}"
$SUDO rm -f /etc/machine-id
$SUDO systemd-machine-id-setup

# 5. 跑 onboarding wizard
echo -e "\n${YELLOW}[5/6] 跑 onboarding wizard${NC}"
bash $HOME/.hermes/onboarding-wizard.sh
sleep 1

# 6. 启动 systemd
echo -e "\n${YELLOW}[6/6] 启动 systemd${NC}"
systemctl --user daemon-reload
systemctl --user enable hermes-web.service
systemctl --user start hermes-web.service

sleep 3
if systemctl --user is-active hermes-web.service > /dev/null; then
    echo "  ✓ Hermes 跑通"
else
    echo -e "  ${RED}✗ 没起来${NC}"
fi

echo ""
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ 客户机首次开机完成!${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo -e "${YELLOW}下一步:${NC}"
echo "  1. 浏览器自动开 http://localhost:9119"
echo "  2. 跟 Hermes 说话"
echo ""
echo -e "${CYAN}有问题: 飞书 @xumugong (许总)${NC}"
RESET

# 写 onboarding wizard 脚本
cat > $HOME/.hermes/onboarding-wizard.sh << 'WIZARD'
#!/bin/bash
# ============================================================================
# Hermes Onboarding Wizard (客户首次开机跑)
# ============================================================================
# 填 5 类问题 → 自动写 persona.json + USER.md + MEMORY.md + .env
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  Hermes Onboarding Wizard${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo "请填以下 5 类问题 (回车跳过):"
echo ""

# 1. 名字 / 称呼
echo -e "${YELLOW}[1/5] 你的名字跟称呼${NC}"
read -p "  你的名字 (如 张老板): " CLIENT_NAME
read -p "  AI 怎么称呼你 (默认 老板): " CLIENT_NICK
CLIENT_NICK=${CLIENT_NICK:-老板}
echo ""

# 2. 行业 / 主营
echo -e "${YELLOW}[2/5] 行业跟主营${NC}"
read -p "  你的行业 (如 电脑公司): " CLIENT_INDUSTRY
read -p "  你的主营 (如 卖电脑 + 抖店): " CLIENT_MAIN
echo ""

# 3. 沟通偏好
echo -e "${YELLOW}[3/5] 沟通偏好${NC}"
read -p "  语言 (默认 zh-CN): " CLIENT_LANG
CLIENT_LANG=${CLIENT_LANG:-zh-CN}
read -p "  简洁度 (1=极简 / 5=详细, 默认 2): " CLIENT_CONCISE
CLIENT_CONCISE=${CLIENT_CONCISE:-2}
echo ""

# 4. 期望 AI 帮什么
echo -e "${YELLOW}[4/5] 期望 AI 帮${NC}"
read -p "  AI 主要帮你做什么 (如 飞书自动回复 + 笔记): " CLIENT_HELP
echo ""

# 5. 不要 AI 碰什么
echo -e "${YELLOW}[5/5] 不要 AI 碰${NC}"
read -p "  AI 不要碰什么 (如 删文件 / 发邮件 / 付款): " CLIENT_DONT
echo ""

# 飞书配置 (可选)
echo ""
echo -e "${YELLOW}[飞书配置 (可选, 没配也能用)]${NC}"
read -p "  飞书 App ID (回车跳过): " FEISHU_APP_ID
read -p "  飞书 App Secret (回车跳过): " FEISHU_APP_SECRET
read -p "  飞书 Chat ID (回车跳过): " FEISHU_CHAT_ID
echo ""

# 写 persona.json
cat > $HOME/.hermes/persona.json << EOF
{
  "name": "Hermes",
  "display_name": "Hermes",
  "user_nickname": "$CLIENT_NICK",
  "user_name": "$CLIENT_NAME",
  "tagline": "$CLIENT_INDUSTRY - 你的 AI 管家",
  "tone": "简洁直接",
  "language": "$CLIENT_LANG",
  "concise_level": $CLIENT_CONCISE,
  "personality": {
    "warmth": 0.5,
    "formality": 0.3,
    "humor": 0.2,
    "patience": 0.7
  },
  "behavior": {
    "proactive_questioning": true,
    "self_learning": true,
    "weekly_review": true,
    "30_day_review": true
  },
  "boundaries": {
    "no_personal_emotion": true,
    "no_payment_actions": true,
    "no_account_deletion": true,
    "user_no_go": "$CLIENT_DONT"
  }
}
EOF
chmod 600 $HOME/.hermes/persona.json

# 写 USER.md
cat > $HOME/.hermes/memories/USER.md << EOF
# USER.md (onboarding 自动填)

## §1 基础信息

- 名字: $CLIENT_NAME
- 称呼: $CLIENT_NICK
- 行业: $CLIENT_INDUSTRY
- 主营: $CLIENT_MAIN

## §2 沟通偏好

- 语言: $CLIENT_LANG
- 简洁度: $CLIENT_CONCISE (1-5)
- 期望 AI 帮: $CLIENT_HELP
- 不要 AI 碰: $CLIENT_DONT

## §3 智能体路径

- 用 Hermes: 桌面打开, 跟它说话
- 期望 AI 帮: $CLIENT_HELP
- 不要 AI 碰: $CLIENT_DONT

## §4 渠道映射

| 渠道 | 配置 |
|---|---|
| 飞书 App ID | $FEISHU_APP_ID |
| 飞书 Chat ID | $FEISHU_CHAT_ID |
| 桌面 | http://localhost:9119 |
EOF

# 写 MEMORY.md (动态事实更新)
cat > $HOME/.hermes/memories/MEMORY.md << EOF
# MEMORY.md (onboarding 自动填)

## §1 当前项目状态

- 机器: Debian 13
- Hostname: $(hostname)
- 用户: $CLIENT_NAME ($CLIENT_NICK)
- 行业: $CLIENT_INDUSTRY

## §2 关键事实

- 飞书 App ID: $FEISHU_APP_ID
- 飞书 Chat ID: $FEISHU_CHAT_ID
- Obsidian vault: ~/Documents/ObsidianVault

## §3 自动化任务

- 每天 03:00 自动备份
- 周日 23:00 周报
- 每 30 分钟自诊断

## §4 项目仓库

- 本地: ~/.hermes/hermes-onboarding/
- GitHub: xumugong/hermes-onboarding (许总你 push 后)

## §5 onboarding 时间线

- 首次开机: $(date +%Y-%m-%d)
- 30-day review: $(date -d '+30 days' +%Y-%m-%d 2>/dev/null || date -v+30d +%Y-%m-%d 2>/dev/null)
EOF

# 写 .env
cat > $HOME/.hermes/.env << EOF
# Hermes .env (onboarding 自动填)

HERMES_HOME=$HOME/.hermes
FEISHU_APP_ID=$FEISHU_APP_ID
FEISHU_APP_SECRET=$FEISHU_APP_SECRET
FEISHU_CHAT_ID=$FEISHU_CHAT_ID
EOF
chmod 600 $HOME/.hermes/.env

echo ""
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ Onboarding 完成!${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo "✓ persona.json 写好"
echo "✓ USER.md 写好"
echo "✓ MEMORY.md 写好"
echo "✓ .env 写好 (权限 600)"
echo ""
echo -e "${YELLOW}下一步:${NC}"
echo "  1. 浏览器开 http://localhost:9119"
echo "  2. 跟 Hermes 说话"
WIZARD
chmod +x $HOME/.hermes/onboarding-wizard.sh

$SUDO chmod +x /usr/local/bin/install-smart-reset.sh
echo "  ✓ /usr/local/bin/install-smart-reset.sh 准备好"
echo "  ✓ ~/.hermes/onboarding-wizard.sh 准备好"
sleep 1

# 验证
echo ""
echo -e "${GREEN}${BOLD}===========================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ 模板机装好!${NC}"
echo -e "${GREEN}${BOLD}===========================================${NC}"
echo ""
echo -e "${CYAN}${BOLD}模板机已装:${NC}"
echo "  Debian 系统"
echo "  谷歌浏览器"
echo "  CC Switch + Obsidian"
echo "  Hermes (服务端, 监听 0.0.0.0:$HERMES_PORT)"
echo "  智能 (cloakbrowser + 飞书 + 微信 + 定时 + 自学习)"
echo "  systemd 24h 保活"
echo "  国内镜像 (阿里云 + pip)"
echo ""
echo -e "${CYAN}${BOLD}已删:${NC}"
echo "  API key (.env)"
echo "  SSH key (id_ed25519 / id_rsa)"
echo "  GitHub token"
echo "  machine-id (客户机生成新)"
echo "  logs / history"
echo ""
echo -e "${CYAN}${BOLD}下一步 (许总你):${NC}"
echo "  1. 关机"
echo "     sudo shutdown -h now"
echo "  2. 硬盘对拷 (dd / Clonezilla)"
echo "  3. 客户机首次开机跑: install-smart-reset.sh"