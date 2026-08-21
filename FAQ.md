# FAQ — 常见问题

> 老子按 EVOLUTION-12 沉淀的常见问题
> 客户 / 贡献者 提的问题 + 解答

## 给客户

### Q1: 这个脚本会装什么?
A: 4 个核心软件 + 智能 + 自动化:
- Hermes (AI 助手)
- Google Chrome (浏览器)
- CC Switch (模型切换工具)
- Obsidian (智能笔记)
- 智能 (反爬 + 定时 + 自学习 + 主动反问)
- 24h 保活

### Q2: 装完会不会删我之前的文件?
A: 不会。install-smart.sh 只装 / 跑, 不删用户文件。
但**会创建**:
- `~/.hermes/` (Hermes 主目录)
- `~/Documents/ObsidianVault/` (Obsidian 笔记)
- `~/Library/LaunchAgents/com.deepseek.harness.web.plist` (Mac daemon)
- `~/.config/systemd/user/hermes-web.service` (Debian daemon)
- crontab 任务 (每天/每周自动跑)

### Q3: 我不想要 Obsidian 怎么办?
A: 加 `--no-obsidian`:
```bash
curl -fsSL https://raw.githubusercontent.com/mumu8728/hermes-onboarding/main/install-smart.sh | bash -s -- --no-obsidian
```

### Q4: 我不想要微信/飞书 MCP 怎么办?
A: 现在默认装, 不需要单独参数。
未来会加 `--no-feishu` / `--no-wechat` (还没实现)。

### Q5: 装错了能卸载吗?
A: 可以:
```bash
bash ~/.hermes/hermes-onboarding/uninstall.sh
```

加 `--keep-vault` 保留 Obsidian 笔记。

### Q6: 装完怎么用?
A: 打开 Hermes 桌面, 跟它说话就行。

### Q7: 多久升级一次?
A: 每周日 23:00 自动检查 (auto-update cron)。
手动: `bash ~/.hermes/hermes-onboarding/update.sh`

### Q8: 出问题找谁?
A: 
- 看 `~/.hermes/hermes-onboarding/TROUBLESHOOTING.md`
- 跑 `bash ~/.hermes/hermes-onboarding/test-smart.sh`
- 找 @mumu8728 (许总) @ mumu8728.com

## 给贡献者

### Q9: 怎么贡献?
A: 详见 `CONTRIBUTING.md` (待写)。
流程:
1. Fork repo
2. 改
3. 跑 `test-smart.sh` 验证
4. 提 PR

### Q10: 项目用什么语言?
A: Shell (`bash`) + Markdown + YAML。
不依赖 Python / Node.js 运行时 (脚本自带检测)。

### Q11: 怎么加新功能?
A: 看 `EXTENDING.md` (待写)。
流程:
1. 在 `install-smart.sh` 加新步骤
2. 跑 `test-smart.sh` 验证
3. 改 CHANGELOG.md
4. 提 PR

### Q12: 有 CI 吗?
A: 待加。计划用 GitHub Actions:
- 自动跑 `test-smart.sh`
- 自动跑 `verify.sh`
- 自动生成 changelog

### Q13: 怎么 release?
A: 看 `RELEASE.md` (待写)。
流程:
1. 改版本号 (CHANGELOG.md + scripts/version)
2. git tag
3. git push --tags
4. GitHub Actions 自动 release

## 给许总你 (老子自己的问题)

### Q14: 老子写脚本时老是装屎, 怎么改?
A: 看 SOUL §15 第 11 条 (EVOLUTION-11 干事前看 README)。
老子 8-19 装屎 10 次 (minimax 9 + 飞书 1) → 立永久铁律 → 后续优化前必读 README 第一段。

### Q15: 这个项目能扩 Windows 吗?
A: 能,加 `install-smart-windows.ps1`:
```powershell
iex (irm https://raw.githubusercontent.com/mumu8728/hermes-onboarding/main/install-smart-windows.ps1)
```
但要 WSL2 (官方推荐)。
原生命 Windows: 待老子研究。

### Q16: 老子可以自动 push 吗?
A: 不能。必须许总你手动 push (老子没凭证)。
但老子可以写 `auto-push.sh` (cron 跑, 自动 commit + push), 前提是许总你配置 SSH key 或 token。

## 老子装屎 FAQ

### Q17: 老子装屎最多的 3 件事?
A: 8-19 老子装屎 10 次:
1. dsh minimax 9 次 (没看 README)
2. 飞书 ws 配置错 (没读 xmanrui-dsh-im README)
3. agent-default-model 不生效 (没读 dsh-llm-pi-ai README)

教训: EVOLUTION-11 (干事前看 README) — 写进 SOUL §15 第 11 条。

### Q18: 老子怎么知道没装屎?
A: 跑 `test-smart.sh` 看 8 大类检查:
- 系统 / 权限 / 网络 / 磁盘 / 依赖 / 已装 / 端口
还有 `verify.sh` 看 push 是否成功。

### Q19: 老子能告诉许总你我装屎吗?
A: 必须。每次装屎后, 老子:
1. 写 CHANGELOG.md (装屎记录)
2. 写 learning-log/<date>-<topic>.md (老子反思)
3. 跑 verify.sh (验证)
4. 等许总你 review 后 push

## 老子等许总你说

有问题 / 建议 → 飞书 @mumu8728 (许总)
紧急问题 → 看 TROUBLESHOOTING.md → 不行找许总你