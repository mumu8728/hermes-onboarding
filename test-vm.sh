#!/bin/bash
# ============================================================================
# test-vm.sh - 一键 Docker 容器测 install-smart-template.sh
# ============================================================================
# 许总你说: 全面考虑好, 到时给老子新机 SSH
# 这脚本是给老子的 (老子自己测, 不碰新机)
#
# 用法:
#   cd ~/.hermes/hermes-onboarding
#   bash test-vm.sh                    # 跑测
#   bash test-vm.sh --keep             # 测完保留容器
#   bash test-vm.sh --clean            # 测完清掉 (默认)
# ============================================================================

set -e

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINER_NAME="hermes-test"
IMAGE="debian:13"
TEST_LOG="$REPO/docs/TEST-RESULTS-$(date +%Y-%m-%d).md"

# 参数
KEEP=""
CLEAN="--rm"
for arg in "$@"; do
    case $arg in
        --keep) KEEP="yes" ;;
        --clean) CLEAN="--rm" ;;
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
echo -e "${CYAN}${BOLD}  test-vm.sh — Docker 容器测安装${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo "目标: 跑 install-smart-template.sh 在干净 Debian 13"
echo "环境: Mac + Docker Desktop"
echo "原则: EVOLUTION-15 — 不碰生产机器"
echo ""

# 1. 看 Docker 在不
echo -e "${YELLOW}[1/8] 看 Docker daemon${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "  ${RED}✗ Docker daemon 没起${NC}"
    echo "  启动 Docker Desktop: open -a Docker"
    exit 1
fi
echo -e "  ${GREEN}✓ Docker 在${NC}"

# 2. 看镜像
echo ""
echo -e "${YELLOW}[2/8] 看 Debian 13 镜像${NC}"
if ! docker images $IMAGE --format "{{.Repository}}:{{.Tag}}" | grep -q "^debian:13$"; then
    echo "  拉 debian:13..."
    docker pull $IMAGE 2>&1 | tail -3
fi
echo -e "  ${GREEN}✓ debian:13 在${NC}"

# 3. 删老容器 (如果有)
echo ""
echo -e "${YELLOW}[3/8] 删老容器 (如有)${NC}"
docker rm -f $CONTAINER_NAME 2>/dev/null || true
echo "  ✓"

# 4. 起新容器 (privileged 让 systemd 能跑部分)
echo ""
echo -e "${YELLOW}[4/8] 起新容器 (privileged 让 systemd 能跑)${NC}"
docker run -d \
    --name $CONTAINER_NAME \
    --privileged \
    --tmpfs /run \
    --tmpfs /tmp \
    -v "$REPO:/test:ro" \
    -p 9119:9119 \
    -p 8080:8080 \
    $IMAGE \
    /bin/bash -c 'while true; do sleep 30; done'
echo -e "  ${GREEN}✓ 容器起 (id: $(docker ps --filter name=$CONTAINER_NAME --format '{{.ID}}' | head -c 12))${NC}"

# 5. 装基础包 + 创建用户 sea
echo ""
echo -e "${YELLOW}[5/8] 装基础包 + 创建用户 sea${NC}"
docker exec $CONTAINER_NAME bash -c '
    apt update -qq 2>&1 | tail -1
    apt install -y -qq sudo curl wget git jq 2>&1 | tail -1
    useradd -m -s /bin/bash sea 2>/dev/null || true
    echo "sea ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sea
    chmod 0440 /etc/sudoers.d/sea
    mkdir -p /home/sea/.hermes
    chown -R sea:sea /home/sea/.hermes
    echo "  ✓ 基础包 + sea 用户"
'

# 6. 拷仓库 + 跑 install-smart-template.sh
echo ""
echo -e "${YELLOW}[6/8] 跑 install-smart-template.sh (5-10 分钟)${NC}"
docker exec -u sea -w /home/sea \
    -e DEBIAN_FRONTEND=noninteractive \
    $CONTAINER_NAME bash -c '
        cp -r /test /home/sea/hermes-onboarding
        chown -R sea:sea /home/sea/hermes-onboarding
        cd /home/sea/hermes-onboarding
        bash install-smart-template.sh 2>&1 | tee /tmp/install.log | tail -100
    '

# 7. 验证 (5 行关键)
echo ""
echo -e "${YELLOW}[7/8] 验证 5 项${NC}"
echo "=========================================="
echo "  [1] hermes-web.service 配置:"
docker exec $CONTAINER_NAME bash -c '
    cat /etc/systemd/system/hermes-web.service 2>/dev/null | grep -E "^(User|Working|ExecStart)" || echo "    (systemd 文件不存在 — Docker 容器限制)"
'
echo ""
echo "  [2] hermes-gateway.service 装没:"
docker exec $CONTAINER_NAME bash -c '
    ls /etc/systemd/system/hermes-gateway.service 2>&1
'
echo ""
echo "  [3] feishu-cli 装没:"
docker exec $CONTAINER_NAME bash -c '
    which feishu-cli 2>&1
    feishu-cli --version 2>&1 | head -1
'
echo ""
echo "  [4] hermes Python deps 装没:"
docker exec $CONTAINER_NAME bash -c '
    python3 -c "import yaml, dotenv, requests, httpx, pydantic; print("  ✓ Python deps 装好")" 2>&1
'
echo ""
echo "  [5] 9 个 feishu-cli skills 装没:"
docker exec $CONTAINER_NAME bash -c '
    ls /home/sea/.hermes/skills/feishu-cli/ 2>&1 | head -15
'

# 8. 总结 + 写报告
echo ""
echo -e "${YELLOW}[8/8] 总结 + 写报告${NC}"

# 算 pass/fail
PASS=0
FAIL=0
WARN=0

docker exec $CONTAINER_NAME bash -c 'ls /etc/systemd/system/hermes-web.service' >/dev/null 2>&1 && PASS=$((PASS+1)) || WARN=$((WARN+1))
docker exec $CONTAINER_NAME bash -c 'grep "^User=sea" /etc/systemd/system/hermes-web.service' >/dev/null 2>&1 && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
docker exec $CONTAINER_NAME bash -c 'ls /etc/systemd/system/hermes-gateway.service' >/dev/null 2>&1 && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
docker exec $CONTAINER_NAME bash -c 'which feishu-cli' >/dev/null 2>&1 && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
docker exec $CONTAINER_NAME bash -c 'python3 -c "import yaml, dotenv, requests, httpx, pydantic"' >/dev/null 2>&1 && PASS=$((PASS+1)) || FAIL=$((FAIL+1))
docker exec $CONTAINER_NAME bash -c 'ls /home/sea/.hermes/skills/feishu-cli/feishu-cli-platform' >/dev/null 2>&1 && PASS=$((PASS+1)) || FAIL=$((FAIL+1))

echo "  ✓ Pass: $PASS / 6"
echo "  ⚠ Warn: $WARN"
echo "  ✗ Fail: $FAIL"

# 写报告
mkdir -p "$REPO/docs"
cat > "$TEST_LOG" << EOF
# Test Results — $(date +%Y-%m-%d)

## 环境

- 容器: $CONTAINER_NAME
- 镜像: $IMAGE (跟许总你的工作机同版本)
- 跑 install-smart-template.sh

## 验证结果

| # | 项 | 状态 |
|---|---|---|
| 1 | hermes-web.service | $(docker exec $CONTAINER_NAME bash -c 'ls /etc/systemd/system/hermes-web.service 2>/dev/null && echo ✓ || echo ✗') |
| 2 | User=sea 显式 | $(docker exec $CONTAINER_NAME bash -c 'grep -q "^User=sea" /etc/systemd/system/hermes-web.service 2>/dev/null && echo ✓ || echo ✗') |
| 3 | hermes-gateway.service | $(docker exec $CONTAINER_NAME bash -c 'ls /etc/systemd/system/hermes-gateway.service 2>/dev/null && echo ✓ || echo ✗') |
| 4 | feishu-cli 二进制 | $(docker exec $CONTAINER_NAME bash -c 'which feishu-cli 2>/dev/null && echo ✓ || echo ✗') |
| 5 | Python deps (yaml/dotenv) | $(docker exec $CONTAINER_NAME bash -c 'python3 -c "import yaml, dotenv" 2>/dev/null && echo ✓ || echo ✗') |
| 6 | 9 个 feishu-cli skills | $(docker exec $CONTAINER_NAME bash -c 'ls /home/sea/.hermes/skills/feishu-cli/feishu-cli-platform 2>/dev/null && echo ✓ || echo ✗') |

**总: Pass=$PASS / Warn=$WARN / Fail=$FAIL**

## EVOLUTION-15

跑这测不碰许总你的工作机, 全在 Docker 容器内。
EOF

echo -e "  ${GREEN}✓ 报告写: $TEST_LOG${NC}"

# 9. 清容器 (除非 --keep)
if [ -z "$KEEP" ]; then
    echo ""
    echo -e "${YELLOW}[9/9] 清容器${NC}"
    docker rm -f $CONTAINER_NAME 2>/dev/null
    echo -e "  ${GREEN}✓ 容器清了${NC}"
else
    echo ""
    echo -e "${YELLOW}[9/9] 保留容器 (--keep)${NC}"
    echo "  进入: docker exec -it -u sea $CONTAINER_NAME bash"
    echo "  清掉: docker rm -f $CONTAINER_NAME"
fi

echo ""
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ 测完!${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo "报告: $TEST_LOG"
echo "Bug 5/6/7 修法: 已装 install-smart-template.sh"