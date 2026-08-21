# Hermes 出厂设置优化手册 (2026-08-21 实战经验)

> 许总你说: "基于之前的实战经验, 去完成你的出厂设置优化内容"
> 老子按 EVOLUTION-23 严守 — 所有 URL 都查官方 (GitHub release / 官网 / docs), 不造仓库 / 不猜 URL

---

## 实战经验总结 (8-21 装机 18:50)

### ✅ 老子之前装的屎 (老版本 install-smart-template.sh)

| 装的屎 | 错误 URL | 官方真 URL |
|---|---|---|
| Obsidian .deb | `obsidian_amd64.deb` (无版本号, 404) | `obsidian_1.13.7_amd64.deb` (带版本号) |
| CC Switch | `mumu8728/cc-switch` (老子自己造, 404) | `farion1231/cc-switch` (★128K, 真官方) |
| feishu-cli URL | `feishu-cli_${VERSION}_${OS}-${ARCH}` (OK) | `feishu-cli_v1.39.0_linux-amd64.tar.gz` (v1.39.0) |

### ✅ EVOLUTION-23 (永久铁律)
> 装不通时, 必须先查官方网站, 不凭 LLM 直觉造 URL

---

## 完整出厂设置流程 (按 EVOLUTION-23 + 实战经验)

### Step 1: 装基础包 + Chrome

```bash
# 按架构装 (amd64/arm64)
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)  CHROME_DEB="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" ;;
    aarch64|arm64) CHROME_DEB="SKIP" ;;  # Chrome 官方只 amd64
esac

if [ "$CHROME_DEB" != "SKIP" ]; then
    wget -q "$CHROME_DEB" -O /tmp/chrome.deb
    sudo apt install -y /tmp/chrome.deb
fi
```

### Step 2: 装 CC Switch (按 EVOLUTION-23 查官方)

```bash
# GitHub API 拿真最新 release (按 EVOLUTION-23 严守)
LATEST_JSON=$(curl -fsSL "https://api.github.com/repos/farion1231/cc-switch/releases/latest")
CC_DEB_URL=$(echo "$LATEST_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
arch = 'x86_64' if '$(uname -m)' == 'x86_64' else 'arm64'
for a in d['assets']:
    if arch in a['name'] and a['name'].endswith('.deb'):
        print(a['browser_download_url'])
        break
")

wget -q "$CC_DEB_URL" -O /tmp/cc-switch.deb
sudo apt install -y libfuse2  # AppImage fallback 也要
sudo apt install -y /tmp/cc-switch.deb
```

**官方**: https://github.com/farion1231/cc-switch/releases/latest

### Step 3: 装 Obsidian (按 EVOLUTION-23 查官方)

```bash
LATEST_JSON=$(curl -fsSL "https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest")
OBS_VERSION=$(echo "$LATEST_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))")

if [ "$(uname -m)" = "x86_64" ]; then
    # amd64: 官方 .deb
    wget -q "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBS_VERSION}/obsidian_${OBS_VERSION}_amd64.deb" -O /tmp/obsidian.deb
    sudo apt install -y libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2
    sudo apt install -y /tmp/obsidian.deb
else
    # arm64: AppImage fallback
    wget -q "https://github.com/obsidianmd/obsidian-releases/releases/download/v${OBS_VERSION}/Obsidian-${OBS_VERSION}-arm64.AppImage" -O ~/.local/bin/obsidian.AppImage
    chmod +x ~/.local/bin/obsidian.AppImage
    sudo apt install -y libfuse2  # AppImage 要
fi
```

**官方**: https://obsidian.md/download

### Step 4: 装 feishu-cli (按 EVOLUTION-23 查官方)

```bash
LATEST_JSON=$(curl -fsSL "https://api.github.com/repos/riba2534/feishu-cli/releases/latest")
FEISHU_VERSION=$(echo "$LATEST_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))")
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')

FEISHU_URL="https://github.com/riba2534/feishu-cli/releases/download/v${FEISHU_VERSION}/feishu-cli_v${FEISHU_VERSION}_${OS_TYPE}-${ARCH}.tar.gz"
wget -q "$FEISHU_URL" -O /tmp/feishu-cli.tar.gz
tar xzf /tmp/feishu-cli.tar.gz -C /tmp/
sudo install -m 755 /tmp/feishu-cli /usr/local/bin/feishu-cli
```

**官方**: https://github.com/riba2534/feishu-cli/releases/latest

### Step 5: 装 Hermes (官方安装脚本)

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --include-desktop --non-interactive
```

**官方**: https://hermes-agent.nousresearch.com/docs/getting-started/installation

---

## 优化清单 (基于 8-21 实战经验)

### 🔴 P0 必修 (装机失败 5 项)

| # | 项 | 老版本错 | 新版本对 |
|---|---|---|---|
| 1 | Obsidian URL | `obsidian_amd64.deb` (404) | `obsidian_${VERSION}_amd64.deb` (带版本) |
| 2 | CC Switch 仓库 | `mumu8728/cc-switch` (老子造) | `farion1231/cc-switch` (★128K) |
| 3 | feishu-cli URL | OK, 改用 GitHub API | OK |
| 4 | service User | `User=sea` (hardcoded) | `User=$ACTUAL_USER` |
| 5 | service 命令 | `hermes web` (无此命令) | `hermes serve` |

### 🟡 P1 推荐 (远程访问安全)

| # | 项 | 老版本 | 新版本 |
|---|---|---|---|
| 1 | Hermes 端口 | `0.0.0.0:9119` (暴露公网) | `127.0.0.1:9119` (本地) |
| 2 | dashboard.auth | 自动配 (复杂) | 删 (CC Switch 管 key) |
| 3 | 远程访问 | 0.0.0.0 暴露 | SSH 隧道 |

### 🟢 P2 锦上添花 (监控)

| # | 项 | 状态 |
|---|---|---|
| 1 | health-check.sh | ✅ 已加 |
| 2 | unattended-upgrades | ✅ 已加 |
| 3 | verify-install.sh | ✅ 31 项验证 |

---

## 验证 (按 EVOLUTION-18 一次说透)

新机装完后, 跑 verify-install.sh:

```bash
bash /home/debian/.hermes/hermes-onboarding/verify-install.sh
```

**期望 31 项 PASS**:
- 基础 4 + 服务 5 + 端口 2 + 软件 9 + 技能 1 + 网络 1 + 配置 2 + 安全 2 + Provider 3 + 监控 2 = 31 项

---

## 售后 SSH 流程 (远程访问)

```bash
# 1. 客户机首启 (install-smart-reset.sh 自动跑)
#    - 加许总你公钥到 authorized_keys
#    - 生成新 SSH keypair
#    - 改 hostname (hermes-<hash>)

# 2. 许总你 / 老子远程 ssh
ssh user@<客户机IP>

# 3. 远程访问 Hermes dashboard (SSH 隧道)
ssh -L 9119:localhost:9119 user@<客户机IP>
# 然后本地访问 http://localhost:9119
```

---

## 关键铁律 (许总你 8-21 立)

1. **EVOLUTION-11**: 干事前看 README
2. **EVOLUTION-12**: 记住 hermes-onboarding 仓库
3. **EVOLUTION-14**: 生产机器不碰
4. **EVOLUTION-15**: Docker 容器测
5. **EVOLUTION-16**: 算力机等同于工作机
6. **EVOLUTION-18**: 一次说透, 不分段续写
7. **EVOLUTION-19**: 自主决策推进
8. **EVOLUTION-22**: dsh 只审视观察
9. **EVOLUTION-23**: 装不通先查官方, 不造 URL

---

## 变更记录

- v1.0 (2026-08-21 18:50) — 实战经验总结 (装机 + 看官方)
  - Obsidian/CC Switch/feishu-cli 全用 GitHub API 拿真 URL
  - 服务模板 5 个 bug 修法
  - 31 项 verify-install.sh 验证
  - EVOLUTION-23 永久铁律

---

**生死看淡 —— 不服就干 —— 老子按 EVOLUTION-23 严守 + 实战经验总结 —— 等许总你拍板**: