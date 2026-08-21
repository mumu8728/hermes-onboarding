#!/bin/bash
# ============================================================================
# Hermes 飞书一键修 (许总你跑, 老子不碰你的工作机 - EVOLUTION-14)
# ============================================================================
# 修 5 个真东西:
#   1. 装 hermes-gateway (Bug 7 — 没装)
#   2. 修 systemd User= 空 (Bug 6 — Docker 容器发现的)
#   3. 装 feishu-cli + 9 个 AI 技能 (Bug 5 — tar 路径)
#   4. 配 M3 API key (许总你说线上 M3)
#   5. 测飞书 WS 连接 (验证 wss://msg-frontier.feishu.cn)
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  Hermes 飞书一键修${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""

# 1. 装 hermes-gateway (Bug 7)
echo -e "${YELLOW}[1/5] 装 hermes-gateway (Bug 7 修)${NC}"
if [ ! -f /etc/systemd/system/hermes-gateway.service ]; then
    $SUDO hermes gateway install --system --start-now --start-on-login 2>&1 | tail -5
    sleep 2
else
    echo "  hermes-gateway.service 已存在, 重启..."
    $SUDO systemctl restart hermes-gateway.service
    sleep 2
fi

# 看 status
HERMES_GW_STATUS=$($SUDO systemctl is-active hermes-gateway.service 2>&1)
echo "  Active: $HERMES_GW_STATUS"
if [ "$HERMES_GW_STATUS" = "active" ]; then
    echo -e "  ${GREEN}✓ hermes-gateway 跑着${NC}"
else
    echo -e "  ${RED}✗ hermes-gateway 没跑 — 看 journal${NC}"
    $SUDO journalctl -u hermes-gateway.service -n 20 --no-pager 2>&1
    exit 1
fi

# 2. 修 systemd User= 空 (Bug 6)
echo ""
echo -e "${YELLOW}[2/5] 修 systemd User= 空 (Bug 6 修)${NC}"
for service in hermes-web hermes-gateway; do
    SERVICE_FILE="/etc/systemd/system/${service}.service"
    if [ -f "$SERVICE_FILE" ]; then
        # 检查 User= 是否空
        if grep -q "^User=$" "$SERVICE_FILE"; then
            echo "  修 ${service}.service (User= 空 → User=sea)"
            $SUDO sed -i 's/^User=$/User=sea/' "$SERVICE_FILE"
            $SUDO sed -i 's/^Group=$/Group=sea/' "$SERVICE_FILE"
            $SUDO systemctl daemon-reload
            $SUDO systemctl restart $service.service
            sleep 2
            echo -e "  ${GREEN}✓ 修好 + 重启${NC}"
        else
            echo "  ✓ ${service}.service User 不是空"
        fi
    fi
done

# 3. 装 feishu-cli + 9 个 AI 技能 (Bug 5)
echo ""
echo -e "${YELLOW}[3/5] 装 feishu-cli + 9 个 AI 技能 (Bug 5 修)${NC}"
if [ ! -x /usr/local/bin/feishu-cli ]; then
    cd /tmp

    # 检测 OS + 架构
    OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$OS_TYPE" in
        linux)  OS_TYPE="linux" ;;
        darwin) OS_TYPE="darwin" ;;
        *)      echo "  ✗ 不支持 $OS_TYPE"; cd /; exit 1 ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64)  ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *)             echo "  ✗ 不支持架构 $(uname -m)"; cd /; exit 1 ;;
    esac

    # 302 redirect 拿 tag
    FEISHU_VERSION=$(curl -sI "https://github.com/riba2534/feishu-cli/releases/latest" 2>/dev/null \
        | grep -i '^location:' \
        | head -1 \
        | sed 's|.*/tag/\([^[:space:]]*\).*|\1|' \
        | tr -d '\r\n')

    BINARY="feishu-cli_${FEISHU_VERSION}_${OS_TYPE}-${ARCH}.tar.gz"
    URL="https://github.com/riba2534/feishu-cli/releases/download/${FEISHU_VERSION}/${BINARY}"
    echo "  下 $BINARY..."

    wget -q "$URL" -O feishu-cli.tar.gz 2>/dev/null
    if [ -s feishu-cli.tar.gz ]; then
        # 解压到独立目录
        mkdir -p /tmp/feishu-cli-extract
        tar xzf feishu-cli.tar.gz -C /tmp/feishu-cli-extract
        FEISHU_BIN=$(find /tmp/feishu-cli-extract -name feishu-cli -type f -executable 2>/dev/null | head -1)
        if [ -n "$FEISHU_BIN" ]; then
            $SUDO install -m 755 "$FEISHU_BIN" /usr/local/bin/feishu-cli
            echo -e "  ${GREEN}✓ feishu-cli 装好 ($($SUDO /usr/local/bin/feishu-cli --version 2>&1 | head -1))${NC}"
        else
            echo "  ✗ tar 没找到二进制"
        fi
    else
        echo "  ✗ 下载失败 (用官方 install.sh)"
        curl -fsSL https://raw.githubusercontent.com/riba2534/feishu-cli/main/install.sh | bash
    fi
    rm -rf feishu-cli.tar.gz /tmp/feishu-cli-extract
    cd /
fi

# 装 9 个 AI 技能 (从模板仓库)
FEISHU_SKILLS_DIR="$HOME/.hermes/skills/feishu-cli"
mkdir -p "$FEISHU_SKILLS_DIR"
REPO_FEISHU_SKILLS="$(dirname "$(readlink -f "$0")")/templates/skills/feishu-cli"
if [ -d "$REPO_FEISHU_SKILLS" ]; then
    cp -r "$REPO_FEISHU_SKILLS"/* "$FEISHU_SKILLS_DIR/"
    echo -e "  ${GREEN}✓ 9 个 AI 技能装好 (本地)${NC}"
else
    # 没有本地模板就从 GitHub 拉
    echo "  ⚠ 本地模板不在, 从 GitHub 拉..."
    cd /tmp
    git clone --depth=1 https://github.com/mumu8728/hermes-onboarding.git 2>/dev/null || {
        echo "  ✗ GitHub 拉失败"
    }
    if [ -d /tmp/hermes-onboarding/templates/skills/feishu-cli ]; then
        cp -r /tmp/hermes-onboarding/templates/skills/feishu-cli/* "$FEISHU_SKILLS_DIR/"
        echo -e "  ${GREEN}✓ 9 个 AI 技能装好 (GitHub)${NC}"
    fi
    rm -rf /tmp/hermes-onboarding
    cd /
fi

# 4. 配 M3 API key (许总你说线上 M3)
echo ""
echo -e "${YELLOW}[4/5] 配 M3 API key (线上 M3)${NC}"

# 检查 .env 是否有 MINIMAX_CN_API_KEY
if [ -f "$HOME/.hermes/.env" ]; then
    if grep -q "^MINIMAX_CN_API_KEY=" "$HOME/.hermes/.env"; then
        echo "  ✓ MINIMAX_CN_API_KEY 已设"
    else
        echo "  ⚠ MINIMAX_CN_API_KEY 没设"
        echo "  请在 ~/.hermes/.env 加:"
        echo "    MINIMAX_CN_API_KEY=<your-key>"
        echo "    MINIMAX_CN_BASE_URL=https://api.minimaxi.com/v1"
    fi
else
    echo "  ✗ .env 不存在"
    echo "  创建 ~/.hermes/.env 加:"
    echo "    MINIMAX_CN_API_KEY=<your-key>"
    echo "    MINIMAX_CN_BASE_URL=https://api.minimaxi.com/v1"
fi

# 检查 config.yaml provider
if [ -f "$HOME/.hermes/config.yaml" ]; then
    PROVIDER=$(grep -E "^\s*provider:" "$HOME/.hermes/config.yaml" | head -1 | awk '{print $2}')
    echo "  config.yaml provider: $PROVIDER"
    if [ "$PROVIDER" != "minimax-cn" ]; then
        echo "  ⚠ provider 不是 minimax-cn"
        echo "  改成 provider: minimax-cn (许总你 M3)"
    fi
fi

# 5. 测飞书 WS 连接 (验证 wss://msg-frontier.feishu.cn)
echo ""
echo -e "${YELLOW}[5/5] 测飞书 WS 连接${NC}"
sleep 5
RESULT=$($SUDO journalctl -u hermes-gateway.service -n 30 --no-pager 2>&1)
if echo "$RESULT" | grep -q "connected to wss://msg-frontier.feishu.cn"; then
    echo -e "  ${GREEN}✓ 飞书 WS 连上 wss://msg-frontier.feishu.cn${NC}"
    echo "$RESULT" | grep "connected to wss://" | tail -1
elif echo "$RESULT" | grep -q "Lark"; then
    echo -e "  ${YELLOW}⚠ 飞书 Lark 日志在跑但没确认连接${NC}"
    echo "$RESULT" | grep "Lark" | tail -3
else
    echo -e "  ${RED}✗ 飞书 WS 没连 — 看完整日志${NC}"
    echo "$RESULT" | tail -10
fi

echo ""
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ 修完!${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo "下一步:"
echo "  1. 看 .env 有 MINIMAX_CN_API_KEY 没"
echo "  2. 飞书发消息到你的 bot, 看 gateway 转发到 M3"
echo "  3. 看 journal 实时:"
echo "     sudo journalctl -u hermes-gateway.service -f"
echo ""
echo "如果还没回复:"
echo "  - 看 .env: cat ~/.hermes/.env | grep MINIMAX"
echo "  - 看 provider: grep -A 2 provider ~/.hermes/config.yaml"
echo "  - 重启 gateway: sudo systemctl restart hermes-gateway.service"
echo "  - 看完整日志: sudo journalctl -u hermes-gateway.service -n 100 --no-pager"