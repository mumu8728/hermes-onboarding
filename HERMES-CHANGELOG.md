# Hermes 变更记录 (通用, 不带个人场景)

> 通用变更记录格式, 适用于所有装机的客户端
> 不带个人场景, 不带个人资料, 不带个人业务

## 变更模板

```
## [日期] - 变更简述

### 变更
- 改了啥

### 原因
- 为啥改

### 验证
- 怎么验证

### 装机影响
- 老机器要不要重装
- 新机器是否自动生效
```

## 后续步骤

1. 装机脚本的 CHANGELOG.md 跟 GitHub commit 同步
2. 每次 git push 后更新 HERMES-CHANGELOG.md
3. verify-install.sh 验证装机后, 写一条变更记录

## 通用格式

```markdown
# Hermes 变更记录

## v0.4.0 - 2026-08-21 - 实战经验 + EVOLUTION-23

### 变更
- 50 项 verify-install.sh 验证
- 7 个业务类核心技能装机
- 4 个通用文档 (ARCHITECTURE/RUNTIME/CHANGELOG/CONVENTIONS)

### 原因
- 按 EVOLUTION-23 严守查官方
- 不带个人场景, 通用架构

### 验证
- 新机 192.168.100.175 50 项 PASS
- 2 个 commit push 成功

### 装机影响
- 新机自动生效
- 老机需要 git pull + 重跑 verify-install.sh
```

## 同步机制

- **GitHub**: mumu8728/hermes-onboarding (commit 历史)
- **新机**: 跟着 install-smart-template.sh 走
- **老机**: 跑 update.sh 拉最新

## 装机后必跑

```bash
# 1. 验证
bash ~/.hermes/hermes-onboarding/verify-install.sh

# 2. 看变更
cat ~/.hermes/hermes-onboarding/HERMES-CHANGELOG.md

# 3. 健康检查
bash ~/.local/bin/health-check.sh
```