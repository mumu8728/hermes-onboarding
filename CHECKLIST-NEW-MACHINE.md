# 新机装机准备 Checklist (许总你拿到新机怎么干)

> 许总你说"继续推进" — 老子写这个 checklist 给许总你 + 客户

## 适用场景

- 许总你拿到一台新 Debian 13 机器 (网络通)
- 客户首启 onboarding wizard
- 售后 / 客服远程装机

## 装机步骤 (10 步)

### Step 1: 确认机器状态 (5 分钟)

```bash
# 许总你 SSH 进机器
ssh user@new-machine

# 确认系统版本 (许总你只装 Debian 13)
cat /etc/debian_version    # 应该 13.x
lsb_release -a            # 应该 Description: Debian GNU/Linux trixie
```

### Step 2: 装基础包 (10 分钟)

```bash
# 许总你的安装命令 (一键)
curl -fsSL https://raw.githubusercontent.com/xumugong/hermes-onboarding/main/install-smart-template.sh | bash
```

### Step 3: 验证 6 项 (5 分钟)

```bash
# 老子新加的监控脚本
bash ~/.hermes/hermes-onboarding/verify.sh
```

应该看到:
- ✅ hermes-web.service active
- ✅ hermes-gateway.service active
- ✅ feishu-cli binary exists
- ✅ Python deps (yaml/dotenv/requests/httpx/pydantic)
- ✅ 9 个 feishu-cli skills
- ✅ Port 9119 LISTEN

### Step 4: 配飞书 (10 分钟)

```bash
# 1. 飞书后台创建 App
#    https://open.feishu.cn/app
# 2. 配长连接模式 (连接 hermes-gateway)
# 3. 把 App ID + Secret 加到 ~/.hermes/.env:
echo "FEISHU_APP_ID=cli_xxx" >> ~/.hermes/.env
echo "FEISHU_APP_SECRET=xxx" >> ~/.hermes/.env

# 4. 重启 gateway
sudo systemctl restart hermes-gateway.service
sudo journalctl -u hermes-gateway.service -f
```

应该看到 `connected to wss://msg-frontier.feishu.cn/ws/v2`

### Step 5: 配 provider (5 分钟)

```bash
# 编辑 ~/.hermes/config.yaml
# 选你的 provider (DeepSeek / 智谱 / Ollama / OpenAI 兼容)
# 推荐 4 路 fallback: M3 主 + DeepSeek 备 + 智谱备 + Ollama 本地

# 加 key 到 ~/.hermes/.env
echo "DEEPSEEK_API_KEY=sk-xxx" >> ~/.hermes/.env
echo "MINIMAX_API_KEY=sk-xxx" >> ~/.hermes/.env
echo "ZHIPU_API_KEY=xxx" >> ~/.hermes/.env

# 验证
hermes model
```

### Step 6: 装 cron (5 分钟)

```bash
# 老子新加的 3 个 cron (logrotate + monitor)
crontab ~/.hermes/crons/hermes-log-rotate.cron
crontab ~/.hermes/crons/hermes-monitor.cron
crontab ~/.hermes/crons/dsh-monitor.cron  # 如果用 DSH
```

### Step 7: 客户首启 onboarding wizard (10 分钟)

```bash
# 自动跑 (在用户主目录)
bash ~/.hermes/hermes-onboarding/install-smart-reset.sh
```

会问 5 类问题:
1. 客户名字?
2. 城市?
3. 飞书 App ID? (没飞书跳过)
4. 飞书 App Secret? (没飞书跳过)
5. 首选 provider?

### Step 8: 硬盘对拷 (许总你家模板机 → 客户机) (30 分钟)

```bash
# 模板机 (许总你家 Debian 13)
# 1. 删 key
bash ~/.hermes/hermes-onboarding/install-smart-template.sh  # 跑完会删 key

# 2. 硬盘对拷到客户机 (dd 或 Clonezilla)
# (老子不碰 sudo, 许总你或客户跑)
```

### Step 9: 客户机首启 (5 分钟)

客户机开机:
- 自动生成新 machine-id
- 自动生成新 SSH key
- 自动改 hostname (hermes-{短hash})
- 自动跑 onboarding wizard (Step 7)
- 自动启动 hermes-web + hermes-gateway

### Step 10: 验证 (5 分钟)

```bash
# 从许总你 Mac 测
curl http://新机IP:9119
# 应该看到 Hermes Web UI

# 飞书发消息 → 应该自动回复
```

## 总耗时

- 首次装机: **30-60 分钟** (Step 1-5)
- 客户机首启: **5-10 分钟** (Step 7 + Step 9)
- 硬盘对拷: **30-60 分钟** (Step 8, 用 Clonezilla)

## 故障排查

| 现象 | 排查 |
|---|---|
| 飞书不回复 | 看 journal + M3 API 余额 (HTTP 402 = Token Plan 用完) |
| Hermes Web 打不开 | 看 hermes-web journal + 端口 9119 |
| systemd 没启动 | `systemctl status hermes-web` 看错 |
| install 失败 | 看 `~/.hermes/logs/install.log` |

## EVOLUTION 严守

- ❌ 不许 reboot 客户机 (Step 9 之前 / 之后都别)
- ❌ 不许碰生产数据 / 视频 / 模型
- ✅ 新机先在 Docker 容器测 (test-vm.sh)
- ✅ 算力机等同于工作机 (不许碰)

## 变更记录

- v1.0 (8-21 14:08) — 装机准备 checklist (10 步)
