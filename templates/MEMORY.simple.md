# MEMORY.md 出厂模板 (动态事实)

> 客户首次开机后, 跑 onboarding wizard 自动填

## §1 当前项目状态

### 主机信息
- 机器: Debian 13 (Debian 系统)
- Hostname: [首次开机填]
- 用户: [首次开机填]
- IP: [DHCP 自动]
- MAC: [自动]

### Hermes 状态
- 版本: [装时记录]
- 24h 保活: ✅ systemd
- 飞书通道: [客户配 ISV 后启用]
- 智能能力: cloakbrowser + cron + 自学习 + 自诊断

### 客户业务
- 行业: [客户填]
- 主营: [客户填]
- 规模: [客户填]
- 痛点: [客户填]

## §2 关键事实 (60 秒必沉)

### 联系人
- 客户名: [客户填]
- 飞书 open_id: [客户填]
- 微信: [客户填]
- 邮箱: [客户填]

### 业务实体
- 公司名: [客户填]
- 营业执照号: [客户填]
- 主体地址: [客户填]

### 配置
- 飞书 App ID: [首次开机填]
- 飞书 App Secret: [首次开机填]
- 微信 iLink: [首次开机填]
- Obsidian vault: ~/Documents/ObsidianVault

## §3 自动化任务 (cron)

```
# Hermes 出厂自动
0 3 * * *     $HOME/.hermes/scripts/auto-backup.sh    # 每天 03:00 备份
0 23 * * 0    $HOME/.hermes/scripts/weekly-report.sh  # 周日 23:00 周报
*/30 * * * *  $HOME/.hermes/scripts/auto-doctor.sh    # 每 30 分钟体检
```

## §4 当前学习方向

- [ ] 第 1 周: 客户用了哪些 skill, 留下哪些
- [ ] 第 2 周: 客户痛点 → 写 skill
- [ ] 第 4 周: 启发式沉淀
- [ ] 第 8 周: 30-day skill review (留 / 改 / 删)

## §5 老板 (许总你) 的智慧

- 凌晨 3-4 点: 不卖焦虑, 不卖课, 不画饼
- 凌晨 7-8 点: 悟到东西是真, 老子帮

## §6 失败 / 装屎记录

- [首次开机填]
- 一周总结: [周日 aggregator 写]

## §7 项目仓库地址

- 本地: ~/.hermes/hermes-onboarding/
- GitHub: xumugong/hermes-onboarding (许总你 push 后)
- EVOLUTION-12: 改 hermes-onboarding 必先 git pull, 优化后必 git push

## §8 容量治理 (80% 触发)

- MEMORY.md < 20KB
- USER.md < 20KB
- SOUL.md < 10KB (极简版)
- 满了触发 memory-distill-watch (cron 每 4h)