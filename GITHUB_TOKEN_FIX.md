# GitHub Token 问题解决方案

## 🔍 问题诊断

检测到当前使用的 Personal Access Token 属于 `xiajason` 账号，但仓库属于 `szjason72` 账号。

## ✅ 解决方案

### 方案 1: 使用 szjason72 账号创建新 Token（推荐）

1. **登录 szjason72 账号**
   - 访问：https://github.com/login
   - 使用 `szjason72@gmail.com` 登录

2. **创建新的 Personal Access Token**
   - 访问：https://github.com/settings/tokens
   - 点击 **"Generate new token"** → **"Generate new token (classic)"**
   - 设置：
     - **Note**: `TimesSquare Project`
     - **Expiration**: 选择过期时间
     - **Scopes**: 勾选 `repo` (完整仓库访问权限)
   - 点击 **"Generate token"**
   - **复制新生成的 Token**

3. **使用新 Token 推送**
   ```bash
   cd /Users/szjason72/TimesSquare
   git remote set-url origin https://szjason72:你的新Token@github.com/szjason72/TimeSquare.git
   git push -u origin main
   ```

### 方案 2: 将 xiajason 添加为协作者（如果两个账号都是你的）

1. 访问仓库设置：https://github.com/szjason72/TimeSquare/settings/access
2. 点击 "Add people"
3. 添加 `xiajason` 为协作者
4. 使用现有的 Token 推送

### 方案 3: 使用 SSH 方式（如果 szjason72 账号有 SSH key）

```bash
# 切换到 SSH 方式
git remote set-url origin git@github.com:szjason72/TimeSquare.git
git push -u origin main
```

## 🔐 安全建议

推送成功后，建议从 Git 配置中移除 Token：

```bash
# 移除 URL 中的 Token，改用 credential helper
git remote set-url origin https://github.com/szjason72/TimeSquare.git

# 后续推送时会提示输入凭据
git push
```

