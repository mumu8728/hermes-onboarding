# TROUBLESHOOTING — 故障排查

> 老子按 EVOLUTION-12 沉淀的故障排查指南
> 来源: 8-19 实战 + 老子装屎 10 次经验

## 装不上

### 网络连不上
```
❌ curl: (6) Could not resolve host
```
**原因**: DNS 解析失败
**修法**:
```bash
# 1. 看 DNS
nslookup github.com

# 2. 换 DNS
sudo networksetup -setdnsservers Wi-Fi 8.8.8.8 1.1.1.1  # Mac
# Debian: 编辑 /etc/resolv.conf
nameserver 8.8.8.8
nameserver 1.1.1.1
```

### HTTPS 证书错误
```
curl: (60) SSL certificate problem
```
**修法**:
```bash
# 更新 CA 证书
brew install ca-certificates  # Mac
sudo apt install ca-certificates  # Debian

# 或临时用 -k (不安全)
curl -kfsSL https://github.com
```

### 磁盘空间不够
```
❌ No space left on device
```
**修法**:
```bash
# 看大文件
du -sh ~/Downloads ~/Desktop

# 清理
rm -rf ~/Downloads/old-installers
rm -rf ~/.cache/npm
brew cleanup  # Mac
```

## 装到一半失败

### apt install 失败 (Debian)
```
E: Unable to fetch some archives
```
**修法**:
```bash
# 更新源
sudo apt update

# 装缺失依赖
sudo apt install -f -y

# 重试
bash install-smart-debian.sh
```

### Hermes daemon 启动失败
```
launchctl load: Could not find specified service
```
**修法**:
```bash
# 1. 卸载
launchctl unload ~/Library/LaunchAgents/com.deepseek.harness.web.plist

# 2. 重装
bash install-smart.sh

# 3. 看 log
cat ~/.hermes/logs/launchd.err.log
```

### systemd --user 不工作
```
Failed to connect to bus
```
**修法**:
```bash
# 1. 看 systemd 状态
systemctl --user status hermes-web.service

# 2. 看 log
journalctl --user -u hermes-web.service

# 3. 重启 systemd
systemctl --user daemon-reload
systemctl --user restart hermes-web.service
```

## 装完用不了

### Hermes 跑不通
```
curl http://127.0.0.1:8080 → 拒绝连接
```
**修法**:
```bash
# 1. 看 daemon
launchctl list | grep hermes  # Mac
systemctl --user status hermes-web  # Debian

# 2. 看 port
lsof -i :8080

# 3. 重启
bash install-smart.sh  # 自动重启
```

### Claude API key 错
```
Error: 401 missing
```
**修法**:
```bash
# 1. 看 ~/.hermes/.env 权限
ls -la ~/.hermes/.env
# 应是 -rw------- (600)

# 2. 改权限
chmod 600 ~/.hermes/.env

# 3. 看 key
grep ANTHROPIC ~/.hermes/.env | head -3
```

### 飞书消息发不出去
```
ERROR: missing chat_id
```
**修法**:
```bash
# 1. 看飞书 MCP 配置
ls ~/.hermes/config/feishu-*

# 2. 看 chat_id 白名单
grep "chat_id" ~/.hermes/config/feishu-channels.yaml

# 3. 加 chat_id
vim ~/.hermes/config/feishu-channels.yaml
```

### Obsidian 打不开
```
Failed to load vault
```
**修法**:
```bash
# 1. 看 vault 目录
ls ~/Documents/ObsidianVault/

# 2. 重建 vault
mkdir -p ~/Documents/ObsidianVault/{00-Inbox,10-SKILLS,...}

# 3. 在 Obsidian 里 "Open vault" → 选目录
```

## 升级失败

### git pull 冲突
```
CONFLICT (content): Merge conflict
```
**修法**:
```bash
# 1. 备份本地
cp -r ~/.hermes/hermes-onboarding ~/backup-onboarding

# 2. 强 pull
cd ~/.hermes/hermes-onboarding
git fetch origin
git reset --hard origin/main

# 3. 重装
bash install-smart.sh
```

### 升级后跑不通
**修法**:
```bash
# 1. 看 CHANGELOG 看改了什么
cat ~/.hermes/hermes-onboarding/CHANGELOG.md

# 2. 卸载重装
bash ~/.hermes/hermes-onboarding/uninstall.sh
curl -fsSL https://raw.githubusercontent.com/mumu8728/hermes-onboarding/main/install-smart.sh | bash
```

## 卸载不干净

### 还有残留
```
~/.hermes 还有文件
```
**修法**:
```bash
# 1. 手动删
rm -rf ~/.hermes

# 2. 删 cron
crontab -l | grep -v "hermes" | crontab -

# 3. 删 launchd / systemd
launchctl unload ~/Library/LaunchAgents/com.deepseek.harness.web.plist
rm ~/Library/LaunchAgents/com.deepseek.harness.web.plist

systemctl --user stop hermes-web.service
rm ~/.config/systemd/user/hermes-web.service
```

## 性能问题

### 跑得慢
**修法**:
```bash
# 1. 看 CPU / 内存
top -o cpu

# 2. 清缓存
rm -rf ~/.cache/npm
rm -rf ~/.cache/pip

# 3. 看 launchd / systemd daemon 状态
launchctl list | grep hermes
```

### 内存不够
**修法**:
```bash
# 1. 看谁占内存
ps aux | sort -nrk 4 | head -10

# 2. 重启 Hermes daemon
launchctl kickstart -k com.deepseek.harness.web
```

## 联系老子

跑 `bash ~/.hermes/hermes-onboarding/verify.sh` 把日志给许总你看:

- 微信/飞书: 找 @mumu8728
- GitHub Issues: https://github.com/mumu8728/hermes-onboarding/issues

## 真东西 (按 EVOLUTION-12)

1. ✅ git pull 仓库最新代码 (latest troubleshooting)
2. ✅ 看 TROUBLESHOOTING.md (本文档)
3. ✅ 修
4. ✅ verify.sh 测试
5. ✅ git push 回仓库