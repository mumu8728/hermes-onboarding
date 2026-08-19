# 许总你 4 步推到 GitHub (新手友好)

## Step 1: 配 git (首次, 30 秒)
```bash
git config --global user.email "你的邮箱@example.com"
git config --global user.name "许木公"
```

## Step 2: 进仓库 + commit (30 秒)
```bash
cd ~/.hermes/hermes-onboarding
git init
git add .
git commit -m "feat: 客户版一键配置 v0.1.0"
```

## Step 3: 创建 GitHub 仓库 (1 分钟)
1. 浏览器打开 https://github.com/new
2. 仓库名: `hermes-onboarding`
3. 描述: `Hermes 客户版一键配置 (新手友好)`
4. Public (公开)
5. **不勾** README / .gitignore / license (我们已经有了)
6. 点 "Create repository"

## Step 4: push (30 秒)
```bash
git remote add origin git@github.com:xumugong/hermes-onboarding.git
git branch -M main
git push -u origin main
```

## Step 5: 验证
```bash
bash ~/.hermes/hermes-onboarding/verify.sh
```

---

## 给客户的一键命令 (push 后)

```bash
# 主命令 (新机一键装 Hermes)
curl -fsSL https://raw.githubusercontent.com/xumugong/hermes-onboarding/main/install-smart.sh | bash

# 带客户配置
bash <(curl -fsSL https://raw.githubusercontent.com/xumugong/hermes-onboarding/main/install-smart.sh) \
  --client "客户A" \
  --feishu-app "cli_xxx"

# 跳过 Obsidian
bash <(curl -fsSL https://raw.githubusercontent.com/xumugong/hermes-onboarding/main/install-smart.sh) --no-obsidian
```

---

## 出错怎么办

### SSH key 没配
```bash
# 1. 生成 SSH key
ssh-keygen -t ed25519 -C "你的邮箱@example.com"

# 2. 复制 public key
cat ~/.ssh/id_ed25519.pub

# 3. 去 GitHub → Settings → SSH and GPG keys → New SSH key → 粘贴
```

### 推不上去 (权限拒绝)
- 确认 SSH key 加到 GitHub 了
- 确认仓库 URL 对: `git@github.com:xumugong/hermes-onboarding.git`
- 确认许总你的 GitHub 用户名是 `xumugong`

### push 后还是 404
- 确认 GitHub 仓库是 Public
- 确认 default branch 是 `main`
- 跑 `bash verify.sh` 看具体哪步失败

---

## 老子坦白

老子没自动推 GitHub 因为:
- ❌ 老子没 git config (user.email/name)
- ❌ 老子没 gh CLI
- ❌ 老子没许总你的 GitHub 凭证

必须许总你手动 push。

---

## 未来自动同步方案

许总你 push 后, 老子可以加:
- 每周日 23:00 自动 git pull 同步
- 老子改 install-smart.sh → 自动 commit → 自动 push
- 老子的 SOUL 加规则: 改 install-smart.sh 必 push GitHub

但首次 push, 必须许总你手动。
