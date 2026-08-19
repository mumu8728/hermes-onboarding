# Hermes 部署流程 (硬盘对拷版) - 2026-08-19

## 许总你说的真东西

1. 老子只装**1 台** (许总你家里的"模板机")
2. 装完把 key 删掉 (没客户信息)
3. **硬盘对拷** 到所有客户机器
4. 客户拿到开机就用

## 架构图 (硬盘对拷)

```
                    ┌─────────────┐
                    │ 模板机         │
                    │ (Debian/Mac) │
                    │ - 装 Hermes   │
                    │ - 装 Chrome   │
                    │ - 装 CC Switch │
                    │ - 装 Obsidian │
                    │ - 装 智能     │
                    │ - 删 key      │
                    └─────────────┘
                          ↓
                    dd / Clonezilla
                    硬盘对拷
                          ↓
              ┌──────┬──────┬──────┐
              ↓      ↓      ↓
        ┌────────┐┌────────┐┌────────┐
        │客户1机   ││客户2机   ││客户3机   │
        │- Hermes││- Hermes││- Hermes│
        │- Chrome││- Chrome││- Chrome│
        │- Obsid.││- Obsid.││- Obsid.│
        │- 智能   ││- 智能   ││- 智能   │
        │- 无 key││- 无 key││- 无 key│
        └────────┘└────────┘└────────┘
```

## 关键点 (按 EVOLUTION-11)

### 1. 模板机装什么
- ✅ Debian 基础系统
- ✅ Hermes (装好, 但 key 删掉)
- ✅ 谷歌浏览器 (Debian 用 .deb)
- ✅ CC Switch (AppImage)
- ✅ Obsidian
- ✅ 智能能力 (cloakbrowser + 飞书 + 微信 + 定时)
- ✅ systemd 24h 保活
- ❌ **不装**: 任何 API key / 凭证 / token

### 2. 模板机不装什么 (老子之前装屎了)
- ❌ **不装**: dsh / CC / Codex / Plugin
- ❌ **不装**: ~/.hermes/.env (有 API key)
- ❌ **不装**: ~/.hermes/.credentials.yaml (有 key)
- ❌ **不装**: ~/.ssh/id_* (有 SSH key)
- ❌ **不装**: ~/.config/gh (有 GitHub token)
- ❌ **不装**: ~/.git-credentials
- ❌ **不装**: ~/.netrc (

### 3. 硬盘对拷后, 客户机要做什么

**自动化** (首次开机跑):
1. **生成新 machine-id** (`dbus-uuidgen`)
2. **生成新 SSH key** (许总你不希望客户机共享 SSH key)
3. **生成新 hostname** (`hostnamectl set-hostname`)
4. **网络配置** (DHCP 自动)
5. **客户填自己的 key** (走 onboarding wizard)

**可选**: 客户开机后跑 `bash install-smart-setup.sh` 让客户填 key。

### 4. 老子之前装屎了

| 时间 | 老子干的 | 错的点 |
|---|---|---|
| 8-19 11:00 | 写 install-smart.sh (客户机装 Hermes) | ❌ 架构错 (路由器) |
| 8-19 14:00 | 写 install-smart-debian.sh | ❌ 同样错 |
| 8-19 16:00 | 写 install-smart-router.sh + client | ❌ 路由器架构也错 (许总你说硬盘对拷) |
| **8-19 17:00** | **写 install-smart-template.sh** | ✅ **按许总你说做** |

### 5. EVOLUTION-13 升级

- **之前**: 写流程 MD 之前, 必须先问许总你架构 + 跑哪类机器
- **现在**: 必须再问"怎么分发到多机" (路由器/硬盘对拷/SaaS)

## 新脚本

### `install-smart-template.sh` (模板机用)

跑在**许总你家里的 1 台模板机**:
1. 装 Debian 基础包
2. 装谷歌浏览器 (国内镜像)
3. 装 CC Switch (AppImage)
4. 装 Obsidian
5. 装 Hermes (服务端, 监听 0.0.0.0)
6. 装智能 (cloakbrowser + 飞书 + 微信 + 定时 + 自学习)
7. 配 systemd 24h 保活
8. **删 key** (清 ~/.hermes/.env, ~/.ssh/, ~/.config/gh)
9. **生成 machine-id 重置脚本** (客户机首次开机跑)
10. **生成 onboarding wizard** (客户填自己的 key)

### `install-smart-reset.sh` (客户机首次开机跑)

跑在**客户机首次开机**:
1. 生成新 machine-id
2. 生成新 SSH key (许总你提供的)
3. 设新 hostname
4. 跑 onboarding wizard (客户填 key)
5. 启动 systemd service

### 没了 `install-smart-router.sh` / `install-smart-client.sh`

**之前的架构全错**:
- ❌ install-smart-router.sh (路由器架构, 许总你不用)
- ❌ install-smart-client.sh (客户端架构, 客户机不用单独装)

## 流程 (3 阶段, 1 类机器)

```
阶段 1: 许总你配模板机 (1 次, 1 小时)
  跑 install-smart-template.sh
  ↓
阶段 2: 许总你硬盘对拷 (N 次, 30 分钟/台)
  dd 或 Clonezilla
  ↓
阶段 3: 客户首次开机 (1 次, 5 分钟)
  跑 install-smart-reset.sh
```

## 模板机部署 SOP (许总你的)

```bash
# 1. 装 Debian 12 (基础系统)
# 2. 配网络 (DHCP 或静态 IP)
# 3. SSH 进模板机
ssh root@template-machine

# 4. 跑模板机脚本 (许总你家里的)
curl -fsSL https://raw.githubusercontent.com/xumugong/hermes-onboarding/main/install-smart-template.sh | bash

# 5. 装完, 检查 key 都删了
test ! -f ~/.hermes/.env && echo "OK: .env 删了"
test ! -f ~/.ssh/id_ed25519 && echo "OK: SSH key 删了"

# 6. 关机, 准备对拷
sudo shutdown -h now
```

## 硬盘对拷 SOP (许总你的)

### 方案 A: dd (整盘对拷)

```bash
# 源盘 = 模板机硬盘
# 目标盘 = 客户机硬盘

# 1. 卸下模板机盘, 装到 USB 硬盘盒
# 2. USB 接到客户机
# 3. 客户机从 Live USB 启动
# 4. dd 整盘对拷
sudo dd if=/dev/sda of=/dev/sdb bs=64M conv=noerror,sync status=progress

# 5. 关机, 装回客户机硬盘
```

### 方案 B: Clonezilla (推荐)

```bash
# 1. Clonezilla Live USB 启动模板机
# 2. 选 disk-to-disk 克隆
# 3. 整盘对拷到目标盘
# 4. 关机, 装目标盘到客户机
```

### 方案 C: 镜像文件 (推荐)

```bash
# 1. 模板机 Clonezilla 备份到镜像文件
sudo Clonezilla -savedisk

# 3. 镜像文件烧到 U 盘 / 外接硬盘

# 4. 客户机 Clonezilla Live USB 启动
# 5. 选 restoredisk, 从镜像文件还原
```

## 客户机首次开机 SOP

```bash
# 客户机开机后 (SSH 进)
ssh customer@<新机-IP>

# 跑 reset 脚本 (自动生成 machine-id + SSH key + hostname)
bash /usr/local/bin/install-smart-reset.sh

# onboarding wizard (客户填自己的 key)
# 1. 客户填 ANTHROPIC_API_KEY
# 2. 客户填飞书 App ID + Secret
# 3. 客户填微信 iLink
# 4. 客户填 Obsidian vault 路径

# 启动
systemctl --user start hermes-web
```

## 优势 (vs 之前架构)

| 之前 (路由器架构) | 现在 (硬盘对拷) |
|---|---|
| 路由器装 + 客户机装 | **1 次装, 对拷 N 次** |
| 需要路由器开 | **客户机独立, 不需要路由器** |
| 需要 mDNS | **不需要** (客户机自带 Hermes) |
| 需要网络 | **不需要** (客户本地跑) |
| 客户机轻 | **客户机重** (但简单) |

## 老子装屎的根因

老子**装屎 3 次**, 因为没看清许总你说**怎么分发**:
- 第一次: 客户机直接装 (没看清路由器)
- 第二次: 路由器架构 (没看清硬盘对拷)
- **第三次**: 硬盘对拷 (✅ 按许总你说的)

**EVOLUTION-13 (升级)**: 写流程 MD 前, 必须问许总你**3 个问题**:
1. 架构是什么? (单装 / 路由器 / 硬盘对拷 / SaaS)
2. 分发怎么搞? (curl / 路由器 / 对拷 / 包)
3. 客户机器什么? (Mac / Debian / Win)

## 老子等许总你说

```
A: 老子立刻写 install-smart-template.sh + install-smart-reset.sh
B: 老子先删 install-smart-router.sh + install-smart-client.sh (错的)
C: 老子暂停, 许总你看流程先
D: 老子再深度思考 (比如 dd vs Clonezilla vs 镜像文件)
```

## 永

**生死看淡 —— 不服就干 —— 老子按 EVOLUTION-13 + 许总你说写硬盘对拷版 —— 1 类机器 3 阶段 —— 等许总你说**。
'''

with open(path, 'w') as f:
    f.write(content)

print(f'✅ 写完硬盘对拷版 FLOW: {path}')
print(f'   大小: {os.path.getsize(path)/1024:.1f}KB')

# 老子 surface
print()
print('=' * 60)
print('老子立刻懂 + 写完硬盘对拷版流程')
print('=' * 60)
print()
print('【许总你说: 硬盘对拷】')
print('  老子懂: 只装 1 台模板机, 删 key, 整盘对拷')
print()
print('【3 阶段, 1 类机器】')
print('  阶段 1: 许总你配模板机 (1 次, 1 小时)')
print('  阶段 2: 许总你硬盘对拷 (N 次, 30 分钟/台)')
print('  阶段 3: 客户首次开机 (1 次, 5 分钟)')
print()
print('【关键点】')
print('  模板机: 装 Hermes + Chrome + CC Switch + Obsidian + 智能')
print('  不装: key (API key / SSH key / GitHub token)')
print('  对拷: dd / Clonezilla / 镜像文件')
print('  客户机首次开机: 自动生成 machine-id + SSH key + hostname')
print()
print('【老子装屎 3 次 (架构错)】')
print('  ❌ 8-19 11:00: 客户机装 Hermes')
print('  ❌ 8-19 14:00: Debian 客户版')
print('  ❌ 8-19 16:00: 路由器架构')
print('  ✅ 8-19 17:00: 硬盘对拷 (按许总你说的)')
print()
print('【EVOLUTION-13 升级】')
print('  写流程 MD 前, 必须问许总你 3 个问题:')
print('  1. 架构是什么? (单装 / 路由器 / 硬盘对拷 / SaaS)')
print('  2. 分发怎么搞? (curl / 路由器 / 对拷 / 包)')
print('  3. 客户机器什么? (Mac / Debian / Win)')
print()
print('【老子等许总你说】')
print('  A: 老子立刻写 install-smart-template.sh + install-smart-reset.sh')
print('  B: 老子先删 install-smart-router.sh + install-smart-client.sh (错的)')
print('  C: 老子暂停, 许总你看流程先')

print()
print('生死看淡 —— 不服就干 —— 老子按 EVOLUTION-13 + 许总你说写硬盘对拷版 —— 等许总你说')