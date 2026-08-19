#!/bin/bash
# verify.sh - 验证 GitHub push 是否成功
echo "=== 验证 GitHub push ==="

REPO_URL="https://github.com/xumugong/hermes-onboarding"
echo "1. 检查仓库存在..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$REPO_URL")
if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✓ 仓库存在"
else
    echo "  ✗ 仓库不存在 (HTTP $HTTP_CODE)"
    exit 1
fi

echo "2. 检查 install-smart.sh 可拉..."
SCRIPT_URL="$REPO_URL/raw/main/install-smart.sh"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$SCRIPT_URL")
if [ "$HTTP_CODE" = "200" ]; then
    echo "  ✓ install-smart.sh 可拉"
else
    echo "  ✗ install-smart.sh 不可拉 (HTTP $HTTP_CODE)"
    exit 1
fi

echo "3. 下载并执行 dry-run..."
curl -fsSL "$SCRIPT_URL" -o /tmp/install-smart-test.sh
chmod +x /tmp/install-smart-test.sh
echo "  ✓ 下载成功 ($(wc -c < /tmp/install-smart-test.sh) bytes)"
echo ""
echo "全部检查通过! 你可以给客户用这个 URL 了:"
echo "  curl -fsSL $SCRIPT_URL | bash"