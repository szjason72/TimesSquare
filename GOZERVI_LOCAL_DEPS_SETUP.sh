#!/bin/bash

# GoZervi本地依赖设置脚本
# 基于凌鲨项目的成熟方案

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="/Users/szjason72/gozervi/zervigo.demo"

echo "=========================================="
echo "GoZervi 本地依赖设置"
echo "=========================================="
echo ""

# 检查项目目录
if [ ! -d "$PROJECT_ROOT" ]; then
    echo "❌ 错误: 项目目录不存在: $PROJECT_ROOT"
    exit 1
fi

cd "$PROJECT_ROOT"

VENDOR_DIR="vendor_local"
GO_MOD_FILE="shared/core/go.mod"

# 检查go.mod文件
if [ ! -f "$GO_MOD_FILE" ]; then
    echo "⚠️  警告: 未找到go.mod文件: $GO_MOD_FILE"
    echo "请确认项目路径是否正确"
    exit 1
fi

echo "项目路径: $PROJECT_ROOT"
echo "go.mod文件: $GO_MOD_FILE"
echo ""

# 创建vendor_local目录
mkdir -p "$VENDOR_DIR"
echo "✓ 已创建 vendor_local 目录"

# 检查go.mod中的私有仓库
echo ""
echo "检查需要本地化的依赖..."
PRIVATE_REPOS=$(grep -E "^require|^replace" "$GO_MOD_FILE" | grep -E "private|internal|atomgit|gitlab|github.com.*private" || true)

if [ -z "$PRIVATE_REPOS" ]; then
    echo "✓ 未发现明显的私有仓库依赖"
    echo ""
    echo "提示：如果需要添加本地依赖，请："
    echo "1. 将仓库克隆到 $VENDOR_DIR 目录"
    echo "2. 在go.mod中添加replace指令，例如："
    echo "   replace github.com/private/repo => ./vendor_local/repo"
    echo ""
else
    echo "发现以下可能的私有仓库："
    echo "$PRIVATE_REPOS"
    echo ""
fi

# 备份原始go.mod
GO_MOD_BACKUP="${GO_MOD_FILE}.backup"
if [ ! -f "$GO_MOD_BACKUP" ]; then
    cp "$GO_MOD_FILE" "$GO_MOD_BACKUP"
    echo "✓ 已备份原始 go.mod 为 $GO_MOD_BACKUP"
else
    echo "✓ go.mod备份已存在: $GO_MOD_BACKUP"
fi

# 创建go.mod.local模板
GO_MOD_LOCAL="${GO_MOD_FILE}.local"
if [ ! -f "$GO_MOD_LOCAL" ]; then
    cp "$GO_MOD_FILE" "$GO_MOD_LOCAL"
    
    # 在文件开头添加注释说明
    cat > "$GO_MOD_LOCAL.tmp" << 'EOF'
// 本地开发模板 - 使用本地依赖替换私有仓库
// 使用方法：
// 1. 将私有仓库克隆到项目根目录的 vendor_local 目录下
// 2. 使用此文件替换 go.mod: cp shared/core/go.mod.local shared/core/go.mod
// 3. 或者手动添加 replace 指令到 go.mod
//
// 示例replace指令：
// replace github.com/private/repo => ./vendor_local/repo
// replace atomgit.com/private/repo => ./vendor_local/repo

EOF
    cat "$GO_MOD_FILE" >> "$GO_MOD_LOCAL.tmp"
    mv "$GO_MOD_LOCAL.tmp" "$GO_MOD_LOCAL"
    echo "✓ 已创建 go.mod.local 模板: $GO_MOD_LOCAL"
else
    echo "✓ go.mod.local 模板已存在: $GO_MOD_LOCAL"
fi

# 检查是否已有replace指令
if grep -q "^replace" "$GO_MOD_FILE"; then
    echo ""
    echo "✓ go.mod 已包含 replace 指令"
    echo ""
    echo "当前的replace指令："
    grep "^replace" "$GO_MOD_FILE" | head -5
else
    echo ""
    echo "提示：如果需要添加replace指令，可以："
    echo "1. 手动编辑 $GO_MOD_FILE"
    echo "2. 或使用模板: cp $GO_MOD_LOCAL $GO_MOD_FILE"
fi

echo ""
echo "=========================================="
echo "设置完成！"
echo "=========================================="
echo ""
echo "下一步操作："
echo ""
echo "1. 如果需要添加本地依赖："
echo "   cd $VENDOR_DIR"
echo "   git clone <repository-url>"
echo "   然后在go.mod中添加replace指令"
echo ""
echo "2. 下载依赖："
echo "   cd shared/core"
echo "   go mod download"
echo ""
echo "3. 构建项目："
echo "   cd shared/core"
echo "   go build ./..."
echo ""
echo "4. 恢复原始go.mod（如果需要）："
echo "   cp $GO_MOD_BACKUP $GO_MOD_FILE"
echo ""
echo "5. 查看详细文档："
echo "   cat CODE_LOCALIZATION_GUIDE.md"
echo ""

