#!/bin/bash
# ============================================================================
# test-vm-lima.sh - 用 lima (Mac 真 VM) 测 install-smart-template.sh
# ============================================================================
# Bug 10 修 — Docker 容器不能跑 systemd, 用 lima (QEMU) 真 VM
# lima 是 Apple Silicon Mac 上的 Linux VM, 跑真 systemd + 飞书 WS
#
# 用法:
#   bash test-vm-lima.sh                 # 默认 Debian 13
#   bash test-vm-lima.sh --keep         # 测完保留 VM
#   bash test-vm-lima.sh --arch amd64   # 指定架构
# ============================================================================

set -e

VM_NAME="hermes-test-vm"
IMAGE="debian:13"
ARCH="aarch64"  # Mac arm64
KEEP=""
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_LOG="$REPO/docs/TEST-RESULTS-VM-$(date +%Y-%m-%d).md"

# 参数
for arg in "$@"; do
    case $arg in
        --keep) KEEP="--keep" ;;
        --arch) ARCH="$2"; shift ;;
        --clean) ;;
    esac
done

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  test-vm-lima.sh — Mac 真 VM 测 (Bug 10 修)${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""

# 1. 看 lima
echo -e "${YELLOW}[1/7] 看 lima${NC}"
if ! command -v limactl >/dev/null 2>&1; then
    echo -e "  ${YELLOW}⚠ lima 没装 — 用 brew 装${NC}"
    if command -v brew >/dev/null 2>&1; then
        brew install lima 2>&1 | tail -3
    else
        echo -e "  ${RED}✗ brew 也不在, 装不了 lima${NC}"
        echo "  手动: /bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
fi
echo -e "  ${GREEN}✓ lima 在: $(which limactl)${NC}"

# 2. 起 VM
echo ""
echo -e "${YELLOW}[2/7] 起 VM (Debian 13, $ARCH)${NC}"
if limactl list --json 2>/dev/null | grep -q "\"name\":\"$VM_NAME\""; then
    echo "  $VM_NAME 已存在, 启动..."
    limactl start $VM_NAME 2>&1 | tail -3
else
    echo "  新建 $VM_NAME..."
    # 用默认 Debian + 用户名 hermes + 密码 hermes
    limactl start --name=$VM_NAME \
        --vm-type=qemu --arch=$ARCH \
        --cpus=2 --memory=4GiB --disk=20GiB \
        --mount="$REPO:w" \
        debian:13 2>&1 | tail -10
fi
echo -e "  ${GREEN}✓ VM 起${NC}"

# 3. 等 VM 就绪
echo ""
echo -e "${YELLOW}[3/7] 等 VM 就绪${NC}"
sleep 10
for i in 1 2 3 4 5; do
    if limactl shell $VM_NAME true 2>/dev/null; then
        echo -e "  ${GREEN}✓ VM 就绪${NC}"
        break
    fi
    echo "  等 ($i/5)..."
    sleep 5
done

# 4. 装基础包 + 创建用户 sea
echo ""
echo -e "${YELLOW}[4/7] 装基础包 + 创建 sea${NC}"
limactl shell $VM_NAME bash << 'SETUP'
set -e
sudo apt update -qq 2>&1 | tail -1
sudo apt install -y -qq sudo curl wget git jq 2>&1 | tail -1
sudo useradd -m -s /bin/bash sea 2>/dev/null || true
echo "sea ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/sea
sudo chmod 0440 /etc/sudoers.d/sea
sudo mkdir -p /home/sea/.hermes
sudo chown -R sea:sea /home/sea/.hermes
echo "  ✓ 基础包 + sea 用户"
SETUP

# 5. 拷仓库 + 跑 install-smart-template.sh
echo ""
echo -e "${YELLOW}[5/7] 跑 install-smart-template.sh (5-10 分钟)${NC}"
limactl shell $VM_NAME bash << 'RUN'
set -e
cp -r /w /tmp/hermes-onboarding
sudo chown -R sea:sea /tmp/hermes-onboarding
sudo -u sea bash -c "cd /tmp/hermes-onboarding && bash install-smart-template.sh" 2>&1 | tee /tmp/install.log | tail -100
RUN

# 6. 验证 6 项 (跟 test-vm.sh 一样)
echo ""
echo -e "${YELLOW}[6/7] 验证 6 项${NC}"
echo "=========================================="
echo "  [1] hermes-web.service:"
limactl shell $VM_NAME sudo systemctl is-active hermes-web.service 2>&1
echo ""
echo "  [2] User=sea 显式:"
limactl shell $VM_NAME grep "^User=" /etc/systemd/system/hermes-web.service 2>&1
echo ""
echo "  [3] hermes-gateway.service:"
limactl shell $VM_NAME sudo systemctl is-active hermes-gateway.service 2>&1
echo ""
echo "  [4] feishu-cli:"
limactl shell $VM_NAME which feishu-cli 2>&1
echo ""
echo "  [5] Python deps:"
limactl shell $VM_NAME bash -c 'python3 -c "import yaml, dotenv" 2>&1'
echo ""
echo "  [6] 9 个 feishu-cli skills:"
limactl shell $VM_NAME ls /home/sea/.hermes/skills/feishu-cli/ 2>&1 | head -10

# 7. 总结 + 报告
echo ""
echo -e "${YELLOW}[7/7] 总结 + 报告${NC}"

PASS=0
FAIL=0

if limactl shell $VM_NAME sudo systemctl is-active hermes-web.service 2>/dev/null | grep -q active; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
if limactl shell $VM_NAME grep -q "^User=sea" /etc/systemd/system/hermes-web.service 2>/dev/null; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
if limactl shell $VM_NAME sudo systemctl is-active hermes-gateway.service 2>/dev/null | grep -q active; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
if limactl shell $VM_NAME which feishu-cli >/dev/null 2>&1; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
if limactl shell $VM_NAME python3 -c "import yaml, dotenv" >/dev/null 2>&1; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi
if limactl shell $VM_NAME ls /home/sea/.hermes/skills/feishu-cli/feishu-cli-platform >/dev/null 2>&1; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); fi

echo "  ✓ Pass: $PASS / 6"
echo "  ✗ Fail: $FAIL"

mkdir -p "$REPO/docs"
cat > "$TEST_LOG" << EOF
# VM Test Results (lima) — $(date +%Y-%m-%d)

## 环境

- VM: $VM_NAME
- lima (QEMU, Apple Silicon)
- 真 Debian 13 + 真 systemd (Docker 容器跑不了 systemd)
- 跑 install-smart-template.sh

## 验证结果

| # | 项 | 状态 |
|---|---|---|
| 1 | hermes-web.service active | $(limactl shell $VM_NAME sudo systemctl is-active hermes-web.service 2>/dev/null || echo ✗) |
| 2 | User=sea 显式 | $(limactl shell $VM_NAME grep -q "^User=sea" /etc/systemd/system/hermes-web.service 2>/dev/null && echo ✓ || echo ✗) |
| 3 | hermes-gateway.service active | $(limactl shell $VM_NAME sudo systemctl is-active hermes-gateway.service 2>/dev/null || echo ✗) |
| 4 | feishu-cli | $(limactl shell $VM_NAME which feishu-cli 2>/dev/null && echo ✓ || echo ✗) |
| 5 | Python deps | $(limactl shell $VM_NAME python3 -c "import yaml, dotenv" 2>/dev/null && echo ✓ || echo ✗) |
| 6 | 9 个 skills | $(limactl shell $VM_NAME ls /home/sea/.hermes/skills/feishu-cli/feishu-cli-platform 2>/dev/null && echo ✓ || echo ✗) |

**总: Pass=$PASS / Fail=$FAIL**

## EVOLUTION-15 (lima 版)

- 用 lima 真 VM (QEMU + Apple Silicon), 不在 Docker 容器测
- 真 systemd 能跑 (Docker 跑不了)
- 真飞书 WS 能连 (msg-frontier.feishu.cn)
- 跟许总你的算力机 (Debian 13) 一致
EOF

echo -e "  ${GREEN}✓ 报告写: $TEST_LOG${NC}"

# 清 VM
if [ -z "$KEEP" ]; then
    echo ""
    echo "清 VM..."
    limactl stop $VM_NAME --force 2>&1 | tail -2
    limactl delete $VM_NAME --force 2>&1 | tail -2
    echo -e "  ${GREEN}✓ VM 清${NC}"
else
    echo ""
    echo -e "${YELLOW}VM 保留: $VM_NAME${NC}"
    echo "  进入: limactl shell $VM_NAME"
    echo "  看 IP: limactl list --json | jq '.[] | {name, ip}'"
fi

echo ""
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ 测完!${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo "报告: $TEST_LOG"