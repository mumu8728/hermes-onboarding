# Weixin / WeChat 微信消息

> 官方 Hermes Agent Weixin (微信) 通道
> 按 EVOLUTION-23 实战经验查官方 docs: https://hermes-agent.nousresearch.com/docs/user-guide/messaging/weixin
> 用 Tencent iLink Bot API (个人微信, 不是 WeCom 企业微信)

## 官方支持

- ✅ Hermes 官方支持 Weixin (Chinese platforms)
- ✅ Tencent iLink Bot API (个人微信账号)
- ✅ 长轮询 (不需要公开端点 / webhook)
- ⚠️ QR login 连 iLink bot identity (a5ace6fd482e@im.bot)

## ⚠️ 重要限制 (官方 docs)

1. **个人微信账号专用** — 不是 WeCom 企业微信
2. **iLink bot identity** — 不是完全可脚本化的个人微信
3. **大多数情况只能 DM** — 群消息大部分不到
4. **WEIXIN_GROUP_POLICY / WEIXIN_GROUP_ALLOWED_USERS** — env vars, 但只在 iLink 返回群事件时生效

## 实战经验 — 配置步骤

### Step 1: 配 Weixin (官方 wizard)

```bash
ssh -t new-debian
hermes gateway setup
# 选 "Weixin / WeChat"
# 按官方指引
```

### Step 2: QR login

- 终端显示 QR 码
- 用你的微信扫
- 连 iLink bot identity

### Step 3: 测试

```bash
# 给 iLink bot 发消息
# (微信扫描时绑定的账号给 bot 发 DM)

# 看 hermes gateway status
hermes gateway status --system
```

## 实战经验 — env vars

```bash
# ~/.hermes/.env 加 (按 docs):
WEIXIN_GROUP_POLICY=disabled  # 或 open / allowlist
WEIXIN_GROUP_ALLOWED_USERS=...
WEIXIN_DM_POLICY=open
```

## 限制实战经验

- 群消息大部分不到 (iLink 限制)
- DM 私聊最可靠
- WeCom 企业微信另配 (用 WeCom adapter)
- 微信接口限制 (< 100 条/天)
- iLink bot 是独立身份, 不是你微信

## 实战经验 — 监控

```bash
# 看 Weixin 状态
hermes gateway status

# 日志
sudo journalctl -u hermes-gateway.service -f | grep -i weixin
```

## 实战经验 — 装机后

1. 新机 192.168.100.175 hermes-gateway.service 已跑 ✅
2. Weixin 通道未配 ⚠️
3. 需要许总你 ssh -t new-debian hermes gateway setup, 选 Weixin, QR login

## 实战经验 — 故障

- **QR 码不出**: 看终端支持 UTF-8
- **连不上**: 检查 ~/.hermes/.env (WEIXIN_* vars)
- **群消息不到**: iLink 限制, 不是 Hermes 问题
- **DM 不通**: 检查 iLink bot identity 是否配对

## 官方参考

- https://hermes-agent.nousresearch.com/docs/user-guide/messaging/weixin
- env vars: WEIXIN_GROUP_POLICY / WEIXIN_GROUP_ALLOWED_USERS / WEIXIN_DM_POLICY