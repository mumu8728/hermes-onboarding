#!/bin/bash
# ============================================================================
# Hermes 升级脚本 (2026-08-19)
# ============================================================================
# 升级到最新版 (从 GitHub 拉最新)
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/mumu8728/hermes-onboarding/main/update.sh | bash
#
# 或本地:
#   bash ~/.hermes/hermes-onboarding/update.sh
#
# 或带配置:
#   bash update.sh --dry-run     # 只看不跑
#   bash update.sh --yes         # 不确认直接升级
#   bash update.sh --check        # 只检查有没有新版
# ============================================================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

REPO="mumu8728/hermes-onboarding"
BRANCH="main"
LOCAL_DIR="$HOME/.hermes/hermes-onboarding"
DRY_RUN=false
YES=false
CHECK_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift ;;
        --yes) YES=true; shift ;;
        --check) CHECK_ONLY=true; shift ;;
        -h|--help) echo "用法见顶部"; exit 0 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

echo -e "${CYAN}${BOLD}===========================================${NC}"
echo -e "${CYAN}${BOLD}  Hermes 升级${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"

# 1. 检查本地仓库
echo -e "\n${YELLOW}[1/7] 检查本地仓库${NC}"
if [ ! -d "$LOCAL_DIR" ]; then
    echo -e "${RED}❌ 本地仓库不存在: $LOCAL_DIR${NC}"
    echo -e "${YELLOW}跑 install-smart.sh 装初始版本${NC}"
    exit 1
fi

cd "$LOCAL_DIR"
CURRENT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "无 git")
echo "  ✓ 本地 commit: $CURRENT_COMMIT"

# 2. 拉最新
echo -e "\n${YELLOW}[2/7] 拉最新代码 (GitHub)${NC}"

LATEST_COMMIT=$(curl -sf "https://api.github.com/repos/$REPO/commits/$BRANCH" 2>/dev/null | grep -m1 '"sha"' | head -1 | sed 's/.*"sha": "\([^"]*\)".*/\1/' | head -c 7)

if [ -z "$LATEST_COMMIT" ]; then
    echo -e "${RED}❌ 拉不到最新 (网络或仓库不存在)${NC}"
    exit 1
fi

echo "  ✓ 远端最新: $LATEST_COMMIT"

if [ "$CURRENT_COMMIT" = "$LATEST_COMMIT" ]; then
    echo -e "${GREEN}✓ 已是最新版, 无需升级${NC}"
    exit 0
fi

if [ "$CHECK_ONLY" = true ]; then
    echo -e "${YELLOW}⚠ 有新版可用 ($CURRENT_COMMIT → $LATEST_COMMIT)${NC}"
    exit 0
fi

# 3. 确认
if [ "$YES" = false ]; then
    echo -e "\n${YELLOW}[3/7] 确认升级? (y/N)${NC}"
    read -p ">>> " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}取消升级${NC}"
        exit 0
    fi
else
    echo -e "\n${YELLOW}[3/7] 自动确认 (--yes)${NC}"
fi

# 4. 备份当前
echo -e "\n${YELLOW}[4/7] 备份当前 (回滚用)${NC}"
BACKUP_DIR="$HOME/.hermes/backups/update-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 备份关键文件
[ -f "$HOME/.hermes/SOUL.md" ] && cp "$HOME/.hermes/SOUL.md" "$BACKUP_DIR/"
[ -f "$HOME/.hermes/memories/MEMORY.md" ] && cp "$HOME/.hermes/memories/MEMORY.md" "$BACKUP_DIR/"
[ -f "$HOME/.hermes/memories/USER.md" ] && cp "$HOME/.hermes/memories/USER.md" "$BACKUP_DIR/"
[ -d "$HOME/Documents/ObsidianVault" ] && tar czf "$BACKUP_DIR/vault.tar.gz" "$HOME/Documents/ObsidianVault" 2>/dev/null
echo "  ✓ 备份: $BACKUP_DIR"

# 5. git pull
echo -e "\n${YELLOW}[5/7] git pull${NC}"
if [ "$DRY_RUN" = false ]; then
    git pull origin "$BRANCH" || {
        echo -e "${RED}❌ git pull 失败${NC}"
        echo -e "${YELLOW}手动: cd $LOCAL_DIR && git pull${NC}"
        exit 1
    }
    echo "  ✓ git pull OK"
else
    echo "  [dry-run] git pull $BRANCH"
fi

# 6. 跑新脚本 (install-smart.sh / install-smart-debian.sh)
echo -e "\n${YELLOW}[6/7] 跑最新脚本${NC}"

if [ "$DRY_RUN" = false ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        bash "$LOCAL_DIR/install-smart.sh"
    else
        bash "$LOCAL_DIR/install-smart-debian.sh"
    fi
    echo "  ✓ 升级完成"
else
    echo "  [dry-run] install-smart.sh (or -debian)"
fi

# 7. 验证
echo -e "\n${YELLOW}[7/7] 验证升级${NC}"
if [ "$DRY_RUN" = false ]; then
    bash "$LOCAL_DIR/verify.sh"
else
    echo "  [dry-run] verify.sh"
fi

echo -e "\n${CYAN}${BOLD}===========================================${NC}"
echo -e "${GREEN}${BOLD}  ✅ 升级完成!${NC}"
echo -e "${CYAN}${BOLD}===========================================${NC}"
echo ""
echo -e "${YELLOW}备份在:${NC} $BACKUP_DIR"
echo -e "${YELLOW}回滚:${NC} bash $BACKUP_DIR/restore.sh (自动生成)"
echo -e "${YELLOW}有问题:${NC} 看 CHANGELOG.md + TROUBLESHOOTING.md"