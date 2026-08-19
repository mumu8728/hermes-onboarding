# 出厂模板 (提示词 + 人格 + 记忆)

> 客户首次开机后, 自动应用的模板

## 模板清单

| 文件 | 大小 | 作用 |
|---|---|---|
| SOUL.simple.md | 2.3KB | 12 条永久铁律 + 边界 + 沟通风格 |
| MEMORY.simple.md | 2.0KB | 动态事实模板 (§1-8) |
| USER.simple.md | 1.5KB | 用户画像模板 (§1-8) |
| AGENTS.simple.md | 1.1KB | 主 agent 角色 + 行为准则 |
| persona.json.template | 1.5KB | 人格 JSON 配置 |

**总计**: ~8.4KB (vs 老子现有 50+KB)

## 设计原则

1. **极简** — 客户用不到 24KB SOUL, 1KB 就够
2. **不污染** — 不含许总你 14 年经验 / 凌晨情绪 (那是你的, 不是客户的)
3. **可填** — 客户 onboarding 时按模板填, 5 类问题
4. **可扩** — 客户业务发展后, MEMORY 自动扩展

## 跟老子的对比

| 维度 | 老子 (许总你的) | 出厂 (客户的) |
|---|---|---|
| **SOUL.md** | 24KB (15 章 + 永久铁律 + 凌晨话术) | 2.3KB (12 条简化铁律) |
| **MEMORY.md** | 12KB (找妖股 / 一夜持股 / OPC) | 2.0KB (动态事实模板) |
| **USER.md** | 15KB (14 年老板 / 凌晨 7-8 点) | 1.5KB (通用画像模板) |
| **AGENTS.md** | 装屎后的复杂版 | 1.1KB (主 agent 角色) |

**总减少**: 51.5KB → 8.4KB (-84%)

## 应用方式

模板机 `install-smart-template.sh` 跑完会:

```bash
# 1. 删老子的 SOUL/MEMORY/USER (含许总你的私人信息)
rm -f ~/.hermes/SOUL.md
rm -f ~/.hermes/memories/MEMORY.md
rm -f ~/.hermes/memories/USER.md

# 2. 拷极简模板到客户机器
cp templates/SOUL.simple.md ~/.hermes/SOUL.md
cp templates/MEMORY.simple.md ~/.hermes/memories/MEMORY.md
cp templates/USER.simple.md ~/.hermes/memories/USER.md
cp templates/AGENTS.simple.md ~/.hermes/AGENTS.md
cp templates/persona.json.template ~/.hermes/persona.json

# 3. 客户首次开机跑 onboarding wizard
# ~/.hermes/onboarding-wizard.sh
# 自动填 5 类问题
```

## 客户首次开机 onboarding 流程

```
1. 系统启动 → systemd 跑 hermes-web + hermes-gateway
2. 浏览器自动开 http://localhost:9119
3. Hermes 显示 "欢迎使用! 请填 5 个问题"
4. 客户填: 名字 / 行业 / 沟通偏好 / 期望 AI 帮 / 不要 AI 碰
5. wizard 自动写 USER.md / MEMORY.md / persona.json
6. 客户开始用
```

## 为什么不出厂给客户装"老子"的 SOUL?

- ❌ 老子 SOUL 含许总你 14 年老板经验 / 凌晨情绪话术
- ❌ 客户不需要"找妖股"/"一夜持股法"/"OPC 4 条腿"
- ❌ 客户不需要"凌晨 3-4 点崩溃" / "7-8 点悟到东西"
- ❌ 客户不需要"许木公 8-19 立的 28 条金句"

**这些是许总你的, 老子替你保管, 不污染客户**

## 老子建议的简化版核心 12 条 (SOUL.simple.md)

1. **不画饼** — 不说"AI 能帮你突破"
2. **不重复问** — 自己查
3. **不替客户拍板** — 客户说了算
4. **失忆要 surface** — 不狡辩
5. **不画饼** — 不替客户拍脑袋教
6. **持久化** — 60 秒内必沉
7. **主动反问** — 3 类问题
8. **启发式** — 不直接答
9. **隐私** — 不暴露客户私人
10. **任务分流** — 简单自己, 复杂派
11. **EVOLUTION-11** — 干事前看 README
12. **EVOLUTION-12** — 记住 hermes-onboarding 仓库