# Debian 容器测试报告 (2026-08-19)

## 测试环境

- 容器: `hermes-test` (id: 3ee85c668d5d)
- 镜像: `debian:13` (跟许总你的工作机同版本)
- Docker: Docker Desktop 24.0.6 (Mac arm64)
- 跑: `bash install-smart-template.sh` (1 分钟跑完)
- 不碰许总你的 Debian 工作机 (192.168.100.124)

## 测试结果

| 步骤 | 状态 | 备注 |
|---|---|---|
| 1/8 配国内 apt | ✅ | 阿里云 trixie 通 |
| 2/8 装基础包 + 浏览器 | ✅ | chromium 装好 (arm64 替代) |
| 3/8 CC Switch + Obsidian | ⚠ | .deb 是 amd64, arm64 缺依赖 |
| 4/8 装 Hermes + feishu-cli | ⚠ | Hermes 装好, feishu-cli 没装上 |
| 5/8 装智能能力 | ✅ | cloakbrowser + 飞书 + 微信 + cron |
| 6/8 配 systemd 24h 保活 | ❌ | Docker 容器 systemd 不跑, User= 空 |
| 7/8 onboarding-wizard.sh | ⏸ | 没测 (脚本生成 OK) |
| 8/8 install-smart-reset.sh | ⏸ | 没测 (脚本生成 OK) |

## 发现 6 个 Bug

### P0 阻塞 (3 个)

**Bug 5**: feishu-cli 二进制没装上
- 根因: `tar xzf` 后 `find` 找不到 (路径不对)
- 修法: 用 `tar xzf --strip-components=1` 或固定路径
- 阻塞: 9 个 AI 技能都没装

**Bug 6**: systemd service User= 空
- 根因: 脚本里 `$USER` 在 docker 容器执行时没展开
- 修法: 显式写 `User=sea` 而不是 `$USER`
- 阻塞: systemd 不能起 service

**Bug 7**: hermes-gateway 没装
- 根因: install-smart-template.sh 只装了 hermes-web
- 修法: 加 `sudo hermes gateway install --system --start-now`
- 阻塞: 飞书消息通道根本不存在

### P1 重要 (3 个)

**Bug 8**: CC Switch + Obsidian arm64 缺依赖
- 根因: .deb 包只 amd64
- 修法: amd64 用 .deb, arm64 用 AppImage / 源 build

**Bug 9**: 测试结果没自动沉淀
- 根因: 老子手动加 commit msg
- 修法: 写 test-results-YYYY-MM-DD.md, 跑脚本自动加

**Bug 10**: Docker 容器不能跑 systemd
- 根因: PID 1 是 bash, 不是 systemd
- 修法: 用 `docker run --privileged --pid=host` 或 lima/macOS VM

## EVOLUTION-15 立 (2026-08-19 许总确认)

**测试用 Docker 容器, 不碰生产机器**
- ❌ 不在许总你的工作机 (Mac mini / 局域网 Docker 192.168.100.124 / 其他生产机器) 跑试验
- ❌ 不 `sudo reboot` / `shutdown` 生产机器
- ✅ 新东西先在 Docker 容器测
- ✅ 涉及生产机器, 必先问许总你 "这台是测试机吗?"
- ✅ EVOLUTION-14 (许总的工作机不能拿来试验, 数据丢失要命)
- ✅ EVOLUTION-15 (测试用 Docker 容器, 装屎 4-10 个真东西)
