# Hermes 主机新用户初始化出厂设置 (Debian 系统)

> 给 Hermes 主机新用户装的初始化出厂设置
> 出厂系统 = Debian (许总 8-19 立)
> 老子按 EVOLUTION-11 + 深度思考做的
> 硬盘对拷部署: 1 次装模板机, N 次对拷客户机

## 项目定位

**Hermes 主机新用户的初始化出厂设置 (Debian 系统)**

这是给所有拿到 Hermes 主机的新用户用的初始化脚本。包含:

- ✅ Debian 系统基础包
- ✅ 谷歌浏览器 (Debian 用 .deb)
- ✅ CC Switch (模型切换工具)
- ✅ Obsidian (智能笔记)
- ✅ Hermes AI 助手 (主功能)
- ✅ 智能能力 (反爬 + 飞书 + 微信 + 定时 + 自进化)
- ✅ 24h 保活 (systemd)
- ✅ 国内镜像 (阿里云 + 清华, 国内可用)

## 一键部署 (模板机)

```bash
curl -fsSL https://raw.githubusercontent.com/xumugong/hermes-onboarding/main/install-smart-template.sh | bash
```

## 部署流程 (3 阶段, 1 类机器)

```
阶段 1: 许总你配模板机 (1 次, 30-60 分钟)
  ↓
阶段 2: 许总你硬盘对拷 (N 次, dd / Clonezilla)
  ↓
阶段 3: 客户首次开机 (1 次, 5 分钟)
  跑 install-smart-reset.sh
```

## 设计原则

- **用户感受**: 打开 Hermes, 跟它说话就行
- **后台复杂**: 老子帮客户管
- **不装的**: dsh / CC / Codex / Plugin / Profile 切换
- **装的**: Hermes + Chrome + CC Switch + Obsidian + 智能能力
- **架构**: 模板机装好删 key → 硬盘对拷 → 客户机首次开机跑 reset

## 系统架构 (Debian 13)

```
模板机 (Debian)
├─ 国内镜像 (阿里云 apt + pip)
├─ Hermes (官方 install.sh)
│   ├─ hermes serve (system-level service)
│   └─ hermes gateway (system-level service, 飞书)
├─ 谷歌浏览器 (.deb)
├─ CC Switch (AppImage)
├─ Obsidian (.deb)
├─ Obsidian vault (~/Documents/ObsidianVault)
└─ 智能能力 (cloakbrowser + 飞书 MCP + 微信 MCP + cron + 自学习)
```

## 系统服务 (systemd, 24h 保活)

```
✅ hermes-web.service   (hermes serve --host 0.0.0.0 --port 9119)
✅ hermes-gateway.service (hermes gateway run, 飞书/微信通道)
✅ cron (auto-backup + weekly-report + auto-doctor)
```

## 文件清单 (15 个, 错文件已删)

```
脚本:
  install-smart-template.sh    模板机一键配置 (17KB, 8+1 步)
  install-smart-reset.sh       客户机首次开机 (内嵌在 template)
  uninstall.sh                 卸载
  update.sh                    升级 (git pull + 重装)
  test-smart.sh                安装前 8 类测试
  verify.sh                    验证 push 成功

文档:
  README.md                    项目说明 (这个)
  FLOW.md                      部署流程 (3 阶段)
  CHANGELOG.md                 版本历史
  TROUBLESHOOTING.md           故障排查
  FAQ.md                       常见问题
  PUSH-SOP.md                  push SOP

许可:
  LICENSE                      MIT
```

**已删除的错文件** (架构错):
- ❌ install-smart.sh (Mac 客户版)
- ❌ install-smart-debian.sh (Debian 客户版)
- ❌ install-smart-router.sh (路由器架构)
- ❌ install-smart-client.sh (客户端架构)
- ❌ README-DEBIAN.md
- ❌ README-NEWBIE.md
- ❌ README-ROUTER.md
- ❌ OUT-OF-BOX.md
- ❌ bootstrap-os.sh
- ❌ install-offline.sh
- ❌ download-offline.sh

## 不装的东西 (新手不需要)

| 不装 | 原因 |
|---|---|
| dsh (DeepSeek Harness) | 用户不需要 CLI 框架 |
| CC (Claude Code) | 用户用 Hermes 桌面就够 |
| Codex CLI | 同上 |
| 复杂多 Agent | 老子帮管 |
| Plugin 架构 | 新手不需要 |
| profile 切换 | 新手不需要 |
| 路由器架构 | 硬盘对拷更简单 |

## 老子装屎记录 (透明)

- 8-19 11:00 写 install-smart.sh (客户机装 Hermes) ❌ 架构错
- 8-19 14:00 写 install-smart-debian.sh ❌ 同样架构错
- 8-19 16:00 写 install-smart-router.sh + client (路由器架构) ❌ 许总你说不用
- 8-19 17:00 改硬盘对拷架构 ✅ 按许总你说的
- 8-19 21:33 修 Debian systemd (system-level + 重启测试通过) ✅
- 8-19 21:45 修飞书 gateway (hermes gateway install) ✅

**教训 (EVOLUTION-11)**: 写流程前必问许总你架构 + 分发 + 客户机系统。

## 老子等许总你说

```
A: 老子立刻 commit + 删错文件 (git rm)
B: 老子加 Mac 版 (许总你自己的 Mac mini 可能要)
C: 老子暂停, 许总你看仓库先
```

## 版本

- v0.1.0 (2026-08-19) — 第一版 (硬盘对拷 + Debian 系统)

## 作者

许总 @ xumugong (中国赫墨斯之父)
```

## 🤝 贡献

欢迎 PR。

## 📜 许可

MIT