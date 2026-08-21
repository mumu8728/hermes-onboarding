# Hermes 架构 (通用, 不带个人场景)

> 通用架构说明, 适用于所有装机的客户端
> 不带个人场景, 不带个人资料, 不带个人业务

## 系统架构

```
┌─────────────────────────────────────────┐
│  Hermes Agent (Nous Research)            │
│  ─────────────────────────────────       │
│  安装位置: ~/.hermes/hermes-agent/       │
│  数据: ~/.hermes/                        │
│  二进制: ~/.local/bin/hermes             │
└─────────────────────────────────────────┘
            │
            ├─ 入门: hermes (CLI)
            ├─ 服务: hermes serve (web dashboard)
            ├─ 网关: hermes gateway (messaging)
            └─ 插件: ~/.hermes/hermes-agent/plugins/
```

## 关键组件

| 组件 | 路径 | 作用 |
|---|---|---|
| CLI | `~/.local/bin/hermes` | 主命令 |
| Web | `~/.hermes/hermes-agent/venv/bin/hermes serve` | dashboard (127.0.0.1:9119) |
| Gateway | `~/.hermes/hermes-agent/venv/bin/hermes gateway` | 飞书/微信/Telegram 通道 |
| Skills | `~/.hermes/skills/` | AI 技能库 |
| Config | `~/.hermes/config.yaml` | 主配置 |
| Secrets | `~/.hermes/.env` | API key (chmod 600) |
| Logs | `~/.hermes/logs/` | 服务日志 |
| Plugins | `~/.hermes/hermes-agent/plugins/` | 官方 + 用户插件 |

## 官方安装入口

```bash
# 官方安装 (Nous Research)
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash

# 官方 docs
https://hermes-agent.nousresearch.com/docs
```

## 服务架构 (systemd)

| Service | 监听 | 端口 | User |
|---|---|---|---|
| hermes-web | 127.0.0.1 | 9119 | 系统用户 |
| hermes-gateway | 127.0.0.1 | 0 | 系统用户 |
| disable-suspend | - | - | system |

## 通信流程

```
用户 ←→ Hermes CLI (本地)
        ↓
        hermes-gateway (systemd)
        ↓
        飞书/微信/Telegram platform
        ↓
        消息送回 Hermes
```

## 持久化路径

```
~/.hermes/
├── config.yaml              # 主配置 (避免 dashboard 节)
├── .env                     # API key (chmod 600)
├── logs/                    # 服务日志
├── scripts/                 # cron 脚本
├── skills/                  # AI 技能
├── crons/                   # 定时任务
├── memory/                  # 长期记忆
├── sessions/                # 历史会话
├── hermes-agent/            # 官方代码
│   ├── venv/                # Python venv
│   ├── plugins/             # 插件
│   └── ...
└── hermes-onboarding/       # 装机脚本仓库(经 install-smart-template.sh)
```

## 注入策略 (system prompt)

```
优先级 (按 EVOLUTION-11 严守):
1. SOUL.md (1.5KB, 7 条核心铁律)     <- 通用, 不带个人
2. AGENTS.md (项目级)                 <- 项目相关
3. skills/ 目录列表                  <- 工具
4. HERMES-ARCHITECTURE.md (本文)    <- 通用架构
5. HERMES-RUNTIME.md (运行时)        <- 通用状态
```

## 文档架构

| 文档 | 作用 | 频率 |
|---|---|---|
| SOUL.md | 7 条永久铁律 | 每条回复前注入 |
| AGENTS.md | 项目 context | 当前项目 |
| HERMES-ARCHITECTURE.md | 通用架构 | 装机/调试时 |
| HERMES-RUNTIME.md | 运行时状态 | 监控时 |
| HERMES-CHANGELOG.md | 变更记录 | 装机/升级时 |
| HERMES-CONVENTIONS.md | 编码规范 | 写代码时 |

## 关键铁律 (来自 SOUL.md)

1. 不画饼
2. 不重复问
3. 不替客户拍板
4. 失忆要 surface
5. 生产机器不碰
6. 测试用 Docker
7. 改前必读 README

## 远程访问

- SSH 22 (公开)
- Hermes 9119 (本地)
- 远程访问用 SSH 隧道: `ssh -L 9119:localhost:9119 user@host`

## 官方资源

- [Nous Research](https://nousresearch.com)
- [Hermes Docs](https://hermes-agent.nousresearch.com/docs)
- [Skills Hub](https://agentskills.io)
- [Discord](https://discord.gg/NousResearch)