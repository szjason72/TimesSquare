# GitHub 推送设置指南

## 🔐 认证问题解决方案

当前系统检测到 Git 凭据关联到了 `xiajason` 账号，但仓库属于 `szjason72`。需要使用 Personal Access Token (PAT) 进行认证。

## 📝 步骤 1: 创建 Personal Access Token

1. 访问 GitHub: https://github.com/settings/tokens
2. 点击 **"Generate new token"** → **"Generate new token (classic)"**
3. 设置 Token 信息：
   - **Note**: `TimesSquare Project` (描述性名称)
   - **Expiration**: 选择过期时间（建议 90 天或自定义）
   - **Scopes**: 勾选 `repo` (完整仓库访问权限)
4. 点击 **"Generate token"**
5. **重要**: 立即复制 Token（只显示一次！）

## 🚀 步骤 2: 使用 Token 推送代码

### 方法 A: 在 URL 中包含 Token（一次性）

```bash
# 替换 YOUR_TOKEN 为你的实际 Token
git remote set-url origin https://YOUR_TOKEN@github.com/szjason72/TimeSquare.git
git push -u origin main
```

### 方法 B: 推送时输入凭据（推荐）

```bash
# 清除旧的凭据
git credential-osxkeychain erase <<EOF
host=github.com
protocol=https
EOF

# 推送代码（会提示输入用户名和密码）
# 用户名: szjason72@gmail.com
# 密码: 粘贴你的 Personal Access Token
git push -u origin main
```

### 方法 C: 使用 Git Credential Manager

```bash
# 推送时会弹出窗口要求输入凭据
git push -u origin main
# 用户名: szjason72@gmail.com
# 密码: 粘贴你的 Personal Access Token
```

## ✅ 验证推送

推送成功后，访问以下地址查看：
https://github.com/szjason72/TimeSquare

## 🔄 后续推送

设置成功后，后续推送可以直接使用：
```bash
git push
```

## 🛠️ 故障排除

### 如果仍然提示权限错误

1. 检查 Token 是否过期
2. 确认 Token 有 `repo` 权限
3. 清除所有缓存的凭据：
   ```bash
   git credential-osxkeychain erase <<EOF
   host=github.com
   protocol=https
   EOF
   ```

### 使用 SSH 方式（可选）

如果你有 `szjason72` 账号的 SSH key：

```bash
git remote set-url origin git@github.com:szjason72/TimeSquare.git
git push -u origin main
```

## 📚 参考链接

- [GitHub Personal Access Tokens 文档](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [Git 凭据存储文档](https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage)

