# Hermes 主机新用户初始化出厂设置 (Debian 系统)

> 给 Hermes 主机新用户装的初始化出厂设置
> 出厂系统 = Debian (许总 8-19 立)
> 老子按 EVOLUTION-11 + 深度思考做的
> 硬盘对拷部署: 1 次装模板机, N 次对拷客户机

## 项目定位

**Hermes 主机新用户的初始化出厂设置 (Debian 系统)**

这是给所有拿到 Hermes 主机的新用户用的初始化脚本。包含:

- ✅ Debian 系统基础包
- ✅ **feishu-cli** (飞书 CLI, 9 个 AI 技能, 1357 stars)
- ✅ 谷歌浏览器 (Debian 用 .deb)
- ✅ CC Switch (模型切换工具)
- ✅ Obsidian (智能笔记)
- ✅ Hermes AI 助手 (主功能)
- ✅ 智能能力 (反爬 + 飞书 + 微信 + 定时 + 自进化)
- ✅ 24h 保活 (systemd)
- ✅ 国内镜像 (阿里云 + 清华, 国内可用)

## feishu-cli 出厂预装 (新加, 2026-08-19)

`feishu-cli` 是 `riba2534` 写的飞书 CLI (Go 1.21+, 1357 stars)。

**安装的 9 个 AI 技能** (`~/.hermes/skills/feishu-cli/`):

| 技能 | 功能 |
|---|---|
| `feishu-cli-platform` | 认证/配置/Profile/通讯录/API schema |
| `feishu-cli-docs` | 文档读写/Markdown 导入导出 |
| `feishu-cli-storage` | Drive/file/media/wiki/评论/权限 |
| `feishu-cli-messaging` | 消息发送/聊天历史/群管理/卡片/事件订阅 |
| `feishu-cli-data` | Sheet/Bitable/Base 全功能 |
| `feishu-cli-visual` | dataviz/画板/Slides/妙笔BOX |
| `feishu-cli-work` | 日历/任务/审批/考勤/OKR |
| `feishu-cli-mail` | 飞书邮箱 |
| `feishu-cli-meetings` | 视频会议/妙记/录制/逐字稿 |

**核心能力**:
- 飞书 API 全覆盖 (499 个命令)
- Markdown ↔ 飞书文档双向无损 (40+ 块类型)
- Mermaid / PlantUML 自动转飞书画板 (可编辑矢量图)
- Device Flow 一键创建应用 (免手工建)
- P2P 私聊可读 (msg history --user-email)
- sha256 完整性校验

**测试结果** (许总你本机):
```
$ feishu-cli --version
feishu-cli version v1.38.4 (built 2026-08-15_21:33:57)

$ feishu-cli doctor
endpoint_open: open.feishu.cn (RTT 150ms, 国内可达) ✓
endpoint_larksuite: open.larksuite.com (RTT 196ms) ✓
deps: go=1.26.5 larksuite-sdk=v3.5.3 ✓
config_file: ✗ (客户 onboarding 时配)
user_token: ⚠️ (客户 onboarding 时跑 auth login)
```

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
- **装的**: Hermes + Chrome + CC Switch + Obsidian + **feishu-cli** + 智能能力
- **架构**: 模板机装好删 key → 硬盘对拷 → 客户机首次开机跑 reset

## 系统架构 (Debian 13)

```
模板机 (Debian)
├─ 国内镜像 (阿里云 apt + pip)
├─ Hermes (官方 install.sh)
│   ├─ hermes serve (system-level service)
│   └─ hermes gateway (system-level service, 飞书)
├─ feishu-cli (GitHub release, 自动检测 OS/arch)
│   └─ 9 个 AI 技能 (skills/feishu-cli/)
├─ 谷歌浏览器 (.deb)
├─ CC Switch (AppImage)
├─ Obsidian (.deb)
├─ Obsidian vault (~/Documents/ObsidianVault)
└─ 智能能力 (cloakbrowser + 飞书 MCP + 微信 MCP + cron + 自学习)
```

## 系统服务 (systemd, 24h 保活)

```
✅ hermes-web.service       (hermes serve --host 0.0.0.0 --port 9119)
✅ hermes-gateway.service   (hermes gateway run, 飞书/微信通道)
✅ cron (auto-backup + weekly-report + auto-doctor)
```

## 客户 onboarding 流程

1. 客户首次开机 → 跑 `install-smart-reset.sh`
2. 生成新 machine-id + SSH key + hostname
3. 跑 `onboarding-wizard.sh` 填 5 类问题:
   - 名字 / 称呼
   - 行业 / 主营
   - 沟通偏好
   - 期望 AI 帮什么
   - 不要 AI 碰什么
4. 跑 `feishu-cli config create-app --save` (Device Flow, 扫码创建飞书应用)
5. 跑 `feishu-cli auth login` (OAuth 用户身份, 用 search/vc/minutes 等)
6. 浏览器开 http://localhost:9119 → 跟 Hermes 说话

## 文件清单 (15 个 + 9 个 skill + 11 个 backup)

```
脚本:
  install-smart-template.sh    模板机一键配置 (25KB, 8+1 步)
  install-smart-reset.sh       客户机首次开机 (内嵌在 template)
  uninstall.sh                 卸载
  update.sh                    升级 (git pull + 重装)
  test-smart.sh                安装前 8 类测试
  verify.sh                    验证 push 成功

文档:
  README.md                    项目说明 (这个)
  FLOW.md                      部署流程 (3 阶段)
  CHANGELOG.md                 版本历史 (v0.1.0 + v0.2.0)
  TROUBLESHOOTING.md           故障排查
  FAQ.md                       常见问题
  PUSH-SOP.md                  push SOP

许可:
  LICENSE                      MIT

模板 (templates/):
  SOUL.simple.md              (2.3KB)
  MEMORY.simple.md            (2.0KB)
  USER.simple.md              (1.5KB)
  AGENTS.simple.md            (1.1KB)
  persona.json.template       (1.5KB)
  README.md                   (3.2KB)
  skills/feishu-cli/          (9 个 SKILL.md + manifest + evals)
```

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

- 8-19 11:00 写 install-smart.sh ❌ 架构错
- 8-19 14:00 写 install-smart-debian.sh ❌ 同样错
- 8-19 16:00 写 install-smart-router.sh ❌ 许总你说不用
- 8-19 17:00 改硬盘对拷 ✅ 按许总你说的
- 8-19 21:33 修 Debian systemd ✅
- 8-19 21:45 修飞书 gateway ✅
- 8-19 22:30 学 feishu-cli ✅ (按 EVOLUTION-11)
- 8-19 23:30 真测 feishu-cli ✅

**教训 (EVOLUTION-11/12/13)**:
- 干事前看 README
- 改 hermes-onboarding 必先 git pull
- 写流程前必问架构 + 分发 + 客户机

## 版本

- v0.1.0 (2026-08-19 下午) — 客户版一键配置 (硬盘对拷 + Debian + 极简模板)
- v0.2.0 (2026-08-19 晚) — 加 feishu-cli (9 个 AI 技能)

## 作者

许总 @ xumugong (中国赫墨斯之父)