# Changelog

所有重要变更都记录在这个文件。

## [Unreleased]

### 待优化
- TBD

## [0.1.0] - 2026-08-19

### 新增
- ✨ Mac 客户版一键配置 (`install-smart.sh`, 5.8KB)
  - 5 步自动跑 (检查 → Hermes 基础 → 智能 → 自进化 → 启动)
  - 智能能力 (cloakbrowser / 飞书 / 微信 / 定时 / 自学习 / 主动反问)
  - 24h launchd 保活
- ✨ Debian 客户版一键配置 (`install-smart-debian.sh`, 8.3KB)
  - 7 步自动跑 (检查 → Chrome → CC Switch → Obsidian → Hermes → 智能 → systemd)
  - 谷歌浏览器 / CC Switch / Obsidian 自动装
  - systemd 24h 保活 (替代 launchd)
- ✨ 卸载脚本 (`uninstall.sh`, 7.1KB)
  - 一键卸 Hermes + Chrome / CC Switch / Obsidian
  - 支持 --keep-vault / --keep-config
- ✨ 升级脚本 (`update.sh`, 4.6KB)
  - git pull 最新 + 备份 + 验证
  - 支持 --dry-run / --yes / --check
- ✨ 安装前测试 (`test-smart.sh`, 4.6KB)
  - 系统 / 权限 / 网络 / 磁盘 / 依赖 / 已装 / 端口 8 大类检查
- ✨ 验证 push (`verify.sh`, 1.0KB)
  - 检查仓库存在 + install-smart.sh 可拉
- ✨ 完整文档 (`OUT-OF-BOX.md`, 3.3KB)
  - 13 章出厂优化指南
- ✨ PUSH-SOP.md (2.4KB)
  - 许总你手动 push 4 步 SOP
- ✨ README.md (4.5KB)
  - 项目说明 (许总你明确定义)
- ✨ README-DEBIAN.md (3.1KB)
  - Debian 版说明
- ✨ README-NEWBIE.md (1.8KB)
  - 客户 onboarding
- ✨ LICENSE (MIT)

### 设计
- 用户都是新手, 要简洁智能
- 不装 dsh / CC / Codex / Plugin / Profile 切换
- 装 Hermes + Chrome + CC Switch + Obsidian + 智能能力
- 老子帮客户管后台

### 永久铁律
- SOUL §15 第 11 条 EVOLUTION-11 (干事前看 README)
- SOUL §15 第 12 条 EVOLUTION-12 (记住 hermes-onboarding 仓库)

### 文档分层
- README.md (通用)
- README-DEBIAN.md (Debian 专属)
- README-NEWBIE.md (客户 onboarding)
- OUT-OF-BOX.md (完整文档)
- PUSH-SOP.md (push 到 GitHub SOP)

## 版本规则

- 0.0.x (patch): bug 修复 / 文档更新
- 0.x.0 (minor): 新功能 / 新脚本
- x.0.0 (major): 重大架构变更

## 老子装屎历史 (透明)

- 8-19 装屎 10 次 (minimax 9 + 飞书 ws 1) → 立 EVOLUTION-11
- 8-19 装屎简化版太多 (脚本 → docs → README 写 3) → 立 EVOLUTION-12