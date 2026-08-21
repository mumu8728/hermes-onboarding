# fcitx5 拼音输入法 (实战经验)

> fcitx5 实战经验 + 官方教程 (按 EVOLUTION-23 实战经验)
> 官方源码: https://github.com/fcitx/fcitx5
> 官方 Wiki: https://wiki.archlinux.org/title/Fcitx5

## 实战经验 — 现状 (新机 192.168.100.175)

| 包 | 版本 | 状态 |
|---|---|---|
| fcitx5 | 5.1.12-2 | ✅ |
| fcitx5-chinese-addons | 5.1.8-1 | ✅ |
| fcitx5-rime | 5.1.10-2 | ✅ |
| fcitx5-pinyin | 内置 | ✅ |

## 实战经验 — 官方教程步骤 (按 Arch Wiki)

### Step 1: 装包 (apt)

```bash
sudo apt install -y fcitx5 fcitx5-chinese-addons fcitx5-rime
```

### Step 2: env vars

按官方教程 (Arch Wiki), 4 个 env vars:

```bash
# /etc/profile.d/fcitx5.sh (全局)
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
export SDL_IM_MODULE=fcitx
```

### Step 3: Wayland 自动

`/etc/profile.d/im-config_wayland.sh` 已存在 (Debian 自动装的), 自动配 wayland env vars。

### Step 4: 配置文件

`~/.config/fcitx5/` (实战经验已建):
- `profile` - default IM = pinyin
- `conf/pinyin.conf` - 拼音配置
- `conf/notification.conf` - 通知
- `conf/cached_layouts` - 缓存布局
- `conf/punctuation.conf` - 标点

### Step 5: XDG Autostart

`~/.config/autostart/fcitx5.desktop` (实战经验装):

```ini
[Desktop Entry]
Type=Application
Name=fcitx5
Exec=fcitx5 -d
Terminal=false
X-GNOME-Autostart-enabled=true
```

### Step 6: 验证

```bash
# 启动
fcitx5 -d

# 看跑没
pgrep -a fcitx5

# 试试 Ctrl+空格 切换输入法
```

## 实战经验 — 切换

- `Ctrl+Space` - 切换中英文
- `Ctrl+Shift` - 切换输入法
- `Shift+Space` - 全角半角

## 实战经验 — 拼音输入法

- 默认: 智能 ABC 词频
- 双拼: 配 fcitx5-rime + librime
- 云拼音: fcitx5-module-cloudpinyin

## 实战经验 — 故障

| 故障 | 实战经验 |
|---|---|
| 拼音不出 | env vars 没设 (装 /etc/profile.d/fcitx5.sh) |
| 启动不自动 | 装 XDG Autostart (~/.config/autostart/fcitx5.desktop) |
| GTK 应用无反应 | `GTK_IM_MODULE=fcitx` |
| RIME 不出 | `apt install fcitx5-rime`, 选 RIME 输入法 |
| 默认英文 | `~/.config/fcitx5/profile` default IM=pinyin |

## 实战经验 — 链接

- 官方: https://github.com/fcitx/fcitx5
- Wiki: https://wiki.archlinux.org/title/Fcitx5
- 中文: https://fcitx-im.org/wiki/Fcitx5_Chinese
- Debian: im-config_wayland.sh (自动配)

## 实战经验 — 装机实战经验

新机 192.168.100.175:
- ✅ fcitx5 + addons + rime 装好
- ✅ ~/.config/fcitx5/profile + conf 配好
- ✅ im-config_wayland.sh 配好
- ✅ ~/.config/autostart/fcitx5.desktop 装好
- ⚠️ /etc/profile.d/fcitx5.sh env vars (被 sudo 阻断, 老子等许总你)