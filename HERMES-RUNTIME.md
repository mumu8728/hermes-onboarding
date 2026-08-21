# Hermes 运行时状态 (通用, 不带个人场景)

> 通用运行时状态格式, 适用于所有装机的客户端
> 不带个人场景, 不带个人资料, 不带个人业务

## 服务状态

```bash
# 服务是否 active
systemctl is-active hermes-web hermes-gateway

# 服务是否 enabled (开机自启)
systemctl is-enabled hermes-web hermes-gateway

# 服务 Restart 策略
systemctl show hermes-web.service | grep -E "Restart=|RestartSec="
```

## 端口状态

| 端口 | 服务 | 监听 | 用途 |
|---|---|---|---|
| 22 | sshd | 0.0.0.0 | SSH |
| 9119 | hermes-web | 127.0.0.1 | Hermes dashboard (本地) |
| 631 | CUPS | 127.0.0.1 | 打印 (不重要) |

## 资源使用

```bash
# 磁盘
df -h / | tail -1

# 内存
free -h

# CPU
uptime

# hermes 进程
ps aux | grep hermes | grep -v grep
```

## 配置检查

```bash
# 主配置位置
~/.hermes/config.yaml

# API key 位置
~/.hermes/.env  (chmod 600)

# 是否配 dashboard 节 (不配, CC Switch 管 key)
grep -q "^dashboard:" ~/.hermes/config.yaml && echo "有" || echo "无"

# 是否绑 127.0.0.1 (本地)
grep -q "127.0.0.1" /etc/systemd/system/hermes-web.service && echo "有" || echo "无"
```

## 健康检查脚本

```bash
# 8 项健康检查
bash ~/.local/bin/health-check.sh
```

## 常用监控命令

```bash
# 看服务日志
sudo journalctl -u hermes-web.service -n 50 --no-pager
sudo journalctl -u hermes-gateway.service -n 50 --no-pager

# 实时跟踪
sudo journalctl -u hermes-web.service -f

# 看 hermes 进程
ps aux | grep hermes | grep -v grep

# 看端口
ss -tlnp | grep -E "9119|22"
```

## 故障排查

```
服务起不来 → systemctl status hermes-web
端口没监听 → ss -tlnp | grep 9119
日志报错 → sudo journalctl -u hermes-web -n 100
config 错 → hermes config check
```

## 53 项验证

```bash
# 装机后跑验证
bash ~/.hermes/hermes-onboarding/verify-install.sh
```

## 关键路径速查

```
~/.hermes/
├── config.yaml              # 主配置
├── .env                     # API key (chmod 600)
├── logs/                    # 日志
├── skills/                  # 技能
├── scripts/                 # 脚本
├── crons/                   # 定时
├── hermes-agent/            # 官方代码
└── hermes-onboarding/       # 装机仓库

/etc/systemd/system/
├── hermes-web.service
├── hermes-gateway.service
└── disable-suspend.service
```