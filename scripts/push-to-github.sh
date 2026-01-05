#!/bin/bash

# TimesSquare GitHub 推送脚本
# 使用方法: ./scripts/push-to-github.sh <github-repo-url>
# 例如: ./scripts/push-to-github.sh https://github.com/username/TimesSquare.git

set -e

if [ -z "$1" ]; then
    echo "❌ 错误: 请提供 GitHub 仓库 URL"
    echo ""
    echo "使用方法:"
    echo "  ./scripts/push-to-github.sh <github-repo-url>"
    echo ""
    echo "示例:"
    echo "  ./scripts/push-to-github.sh https://github.com/username/TimesSquare.git"
    echo "  ./scripts/push-to-github.sh git@github.com:username/TimesSquare.git"
    exit 1
fi

REPO_URL=$1

echo "🚀 开始推送到 GitHub..."
echo "📦 仓库地址: $REPO_URL"
echo ""

# 检查是否已经设置了远程仓库
if git remote | grep -q "^origin$"; then
    echo "⚠️  检测到已存在的 origin 远程仓库"
    CURRENT_URL=$(git remote get-url origin)
    echo "   当前地址: $CURRENT_URL"
    read -p "是否要更新为新的地址? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git remote set-url origin "$REPO_URL"
        echo "✅ 已更新远程仓库地址"
    else
        echo "❌ 操作已取消"
        exit 1
    fi
else
    echo "➕ 添加远程仓库..."
    git remote add origin "$REPO_URL"
    echo "✅ 远程仓库已添加"
fi

# 检查当前分支
CURRENT_BRANCH=$(git branch --show-current)
echo "📌 当前分支: $CURRENT_BRANCH"

# 推送代码
echo ""
echo "📤 推送代码到 GitHub..."
git push -u origin "$CURRENT_BRANCH"

echo ""
echo "✅ 推送完成！"
echo "🌐 你可以在 GitHub 上查看: $REPO_URL"

