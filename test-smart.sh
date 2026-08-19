#!/bin/bash
# ============================================================================
# Hermes 安装前测试 (2026-08-19)
# ============================================================================
# 在跑 install-smart.sh 前, 测试环境
#
# 用法:
#   bash ~/.hermes/hermes-onboarding/test-smart.sh
#
# 检查:
#   - 系统 (Mac/Debian)
#   - 用户权限 (不是 root)
#   - 网络 (能连 github.com)
#   - 磁盘空间 (≥ 5GB)
#   - 依赖 (curl / wget / git)
#   - 已装 (如果有, 警告)
# ============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

PASS=0
FAIL=0
WARN=0

check_pass() {
    echo -e "  ${GREEN}✓${NC} $1"
    PASS=$((PASS+1))
}

check_fail() {
    echo -e "  ${RED}✗${NC} $1"
    FAIL=$((FAIL+1))
}

check_warn() {
    echo -e "  ${YELLOW}⚠${NC} $1"
    WARN=$((WARN+1))
}

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  Hermes 安装前测试${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"

# 1. 系统
echo -e "\n${BOLD}[1/8] 系统检查${NC}"
if [[ "$OSTYPE" == "darwin"* ]]; then
    check_pass "Mac 系统 (macOS)"
    DEBIAN=false
elif grep -qi "Debian" /etc/os-release 2>/dev/null || [ -f /etc/debian_version ]; then
    check_pass "Debian 系统"
    DEBIAN=true
else
    check_fail "不支持的系统: $(uname -s)"
    exit 1
fi

# 2. 权限
echo -e "\n${BOLD}[2/8] 权限检查${NC}"
if [ "$EUID" -eq 0 ]; then
    check_fail "不要用 root 用户 (用普通用户 + sudo)"
    exit 1
fi
check_pass "普通用户: $(whoami)"

# 3. 网络
echo -e "\n${BOLD}[3/8] 网络检查${NC}"
if curl -sf -o /dev/null --max-time 5 https://github.com 2>/dev/null; then
    check_pass "能连 github.com"
else
    check_fail "不能连 github.com (网络问题)"
fi

if curl -sf -o /dev/null --max-time 5 https://hermes-agent.nousresearch.com 2>/dev/null; then
    check_pass "能连 hermes-agent.nousresearch.com"
else
    check_warn "不能连 hermes-agent.nousresearch.com (可能官方 CDN 慢)"
fi

# 4. 磁盘
echo -e "\n${BOLD}[4/8] 磁盘检查${NC}"
FREE_GB=$(df -g "$HOME" | tail -1 | awk '{print $4}')
if [ "$FREE_GB" -ge 5 ]; then
    check_pass "磁盘空间: ${FREE_GB}GB (≥ 5GB)"
else
    check_fail "磁盘空间不够: ${FREE_GB}GB (< 5GB)"
fi

# 5. 依赖
echo -e "\n${BOLD}[5/8] 依赖检查${NC}"
for cmd in curl wget git; do
    if command -v "$cmd" &> /dev/null; then
        check_pass "$cmd: 已装"
    else
        check_fail "$cmd: 没装"
    fi
done

# Debian 额外依赖
if [ "$DEBIAN" = true ]; then
    for cmd in sudo apt systemctl; do
        if command -v "$cmd" &> /dev/null; then
            check_pass "$cmd: 已装"
        else
            check_fail "$cmd: 没装 (Debian 必须)"
        fi
    done
fi

# 6. 已装检查
echo -e "\n${BOLD}[6/8] 已装检查 (如有, 警告)${NC}"
if [ -d "$HOME/.hermes" ]; then
    check_warn "~/.hermes 已存在 (升级?卸载?)"
else
    check_pass "~/.hermes 没装 (全新安装)"
fi

if [ -d "$HOME/Documents/ObsidianVault" ]; then
    check_warn "Obsidian vault 已存在 (会保留)"
else
    check_pass "Obsidian vault 没建 (新建)"
fi

if [ -f "/Applications/Google Chrome.app" ] || command -v google-chrome &> /dev/null; then
    check_warn "Chrome 已装 (会跳过)"
else
    check_pass "Chrome 没装 (待装)"
fi

# 7. 端口检查
echo -e "\n${BOLD}[7/8] 端口检查${NC}"
for port in 8080 7860; do
    if lsof -i ":$port" &> /dev/null; then
        check_warn "端口 $port 被占用 (可能影响 Hermes)"
    else
        check_pass "端口 $port 空闲"
    fi
done

# 8. 总结
echo -e "\n${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  测试结果${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo -e "  ${GREEN}通过: $PASS${NC}"
echo -e "  ${YELLOW}警告: $WARN${NC}"
echo -e "  ${RED}失败: $FAIL${NC}"
echo ""

if [ $FAIL -gt 0 ]; then
    echo -e "${RED}❌ 测试失败, 不能装${NC}"
    echo ""
    echo -e "${YELLOW}修复失败项:${NC}"
    echo "  - 网络: 检查 VPN / DNS / 防火墙"
    echo "  - 磁盘: 清理 ~/Downloads / ~/Desktop"
    echo "  - 依赖: brew install curl wget git (Mac)"
    echo "  - 依赖: sudo apt install curl wget git (Debian)"
    exit 1
fi

if [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}⚠ 有警告, 但可以装${NC}"
fi

echo -e "${GREEN}✅ 测试通过, 可以跑 install-smart.sh${NC}"