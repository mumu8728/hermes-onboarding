# Changelog

所有重要变更都记录在这个文件。

## [Unreleased]

### 待优化
- 测 feishu-cli 在 Debian 机器 (许总你的 192.168.100.124)
- 加 Mac 安装版本 (许总你的 Mac mini)
- 完善 onboarding wizard 引导客户配 feishu-cli

## [0.2.0] - 2026-08-19 (晚)

### 新增 (按 EVOLUTION-11 学 feishu-cli)
- ✨ **feishu-cli 出厂预装** (1357 stars, Go 1.21+)
  - 二进制: feishu-cli_v1.38.4 (41.5MB)
  - 自动检测 OS (linux/darwin) + 架构 (amd64/arm64)
  - 302 redirect 拿 tag (不消耗 GitHub API 配额)
  - fallback: 官方 install.sh
- ✨ **feishu-cli 9 个 AI 技能** (出厂预装)
  - feishu-cli-platform (认证/搜索/通讯录)
  - feishu-cli-docs (文档/Markdown 导入导出)
  - feishu-cli-storage (Drive/file/wiki/权限)
  - feishu-cli-messaging (消息/群/卡片/事件)
  - feishu-cli-data (Sheet/Bitable/Base)
  - feishu-cli-visual (画板/Slides/dataviz)
  - feishu-cli-work (日历/任务/审批/OKR)
  - feishu-cli-mail (飞书邮箱)
  - feishu-cli-meetings (视频会议/妙记)

### 测试 (许总你的本机)
- ✅ feishu-cli --version: v1.38.4 (built 2026-08-15)
- ✅ feishu-cli doctor: 8 项检查 (5 ✓ + 2 ⚠ + 1 ✗)
- ✅ endpoint_open: open.feishu.cn (RTT 150ms, 国内可达)
- ⚠ user_token 没 OAuth login — 客户 onboarding 时跑

### 真东西
- tar 路径修正: feishu-cli_vX.Y.Z_<os>-<arch>/feishu-cli (带目录)
- 国内可用: open.feishu.cn RTT 150ms
- 客户 onboarding 时引导跑 `feishu-cli auth login`

## [0.1.0] - 2026-08-19 (下午)

### 新增
- ✨ Mac 客户版一键配置 (`install-smart.sh`, 5.8KB)
- ✨ Debian 客户版一键配置 (`install-smart-debian.sh`, 8.3KB)
- ✨ 卸载脚本 (`uninstall.sh`, 7.1KB)
- ✨ 升级脚本 (`update.sh`, 4.6KB)
- ✨ 安装前测试 (`test-smart.sh`, 4.6KB)
- ✨ 验证 push (`verify.sh`, 1.0KB)
- ✨ 完整文档 (`OUT-OF-BOX.md`, 3.3KB)
- ✨ PUSH-SOP.md (2.4KB)
- ✨ README.md (4.5KB)
- ✨ README-DEBIAN.md (3.1KB)
- ✨ README-NEWBIE.md (1.8KB)
- ✨ LICENSE (MIT)
- ✨ templates/ (极简出厂模板)
  - SOUL.simple.md (2.3KB)
  - MEMORY.simple.md (2.0KB)
  - USER.simple.md (1.5KB)
  - AGENTS.simple.md (1.1KB)
  - persona.json.template (1.5KB)
  - onboarding-wizard.sh (客户首次开机填 5 类问题)

### 修复
- 🐛 install-smart-debian.sh 第 48 行语法错 (&& && → && ! grep -q)
- 🐛 Debian systemd (system-level, 不靠 user 登录)
- 🐛 飞书 gateway (hermes gateway install --system)
- 🐛 basic_auth 配 dashboard (允许 0.0.0.0 绑定)

### 删除 (架构错)
- ❌ install-smart.sh (Mac 客户版)
- ❌ install-smart-debian.sh (Debian 客户版)
- ❌ install-smart-router.sh (路由器架构)
- ❌ install-smart-client.sh (客户端架构)
- ❌ README-DEBIAN.md / README-NEWBIE.md / README-ROUTER.md
- ❌ OUT-OF-BOX.md / bootstrap-os.sh / install-offline.sh / download-offline.sh

### 仓库状态
- 12 个真文件 + 11 个 .archive/备份
- 2 次 commit (a1006e5 + 3b61637)
- 4703 + 932 = 5635 insertions

## 版本规则

- 0.0.x (patch): bug 修复 / 文档更新
- 0.x.0 (minor): 新功能 / 新脚本
- x.0.0 (major): 重大架构变更

## 老子装屎历史 (透明)

### 8-19 11:00
- ❌ 写 install-smart.sh (Mac 客户版) — 装 Hermes 在客户机, 架构错

### 8-19 14:00
- ❌ 写 install-smart-debian.sh — 同样架构错

### 8-19 16:00
- ❌ 写 install-smart-router.sh (路由器架构) — 许总你说不用

### 8-19 17:00
- ✅ 改硬盘对拷架构 (按许总你说的)

### 8-19 21:33
- ✅ 修 Debian systemd (system-level + multi-user.target + 重启测试通过)

### 8-19 21:45
- ✅ 修飞书 gateway (hermes gateway install --system, wss 连接)

### 8-19 22:30
- ✅ 学 feishu-cli (EVOLUTION-11, README 第一段)
- ✅ 下 9 个 SKILL.md + manifest.yaml + trigger-evals.json

### 8-19 23:30
- ✅ 真测 feishu-cli (Mac arm64, --version + doctor)
- ✅ 修 tar 路径 (find 替代硬编码)
- ✅ 加 9 个 skill 到 install-smart-template.sh (第 4 步)

**教训**:
- EVOLUTION-11 (干事前看 README) - 老子立永久铁律, 装屎少
- EVOLUTION-12 (记住 hermes-onboarding 仓库) - 老子改了必先 git pull + 看 SOP
- EVOLUTION-13 (写流程前必问架构 + 分发 + 客户机) - 老子装屎 3 次架构