#!/bin/bash

# GoZervi知识库管理脚本
# 用于管理和组织项目知识库

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KB_ROOT="$PROJECT_ROOT/knowledge-base"

echo "=========================================="
echo "GoZervi 知识库管理系统"
echo "=========================================="
echo ""

# 功能菜单
show_menu() {
    echo "请选择操作："
    echo ""
    echo "1. 查看知识库状态"
    echo "2. 添加新的参考项目"
    echo "3. 更新知识库索引"
    echo "4. 生成知识库报告"
    echo "5. 备份知识库"
    echo "6. 退出"
    echo ""
}

# 查看知识库状态
show_status() {
    echo "=========================================="
    echo "知识库状态"
    echo "=========================================="
    echo ""
    
    echo "📁 目录结构:"
    find "$KB_ROOT" -type d -maxdepth 2 | sort | sed 's|^|  |'
    echo ""
    
    echo "📄 文档文件:"
    find "$KB_ROOT" -name "*.md" -type f | wc -l | xargs echo "  总计:"
    find "$KB_ROOT" -name "*.md" -type f | sed 's|^|  |'
    echo ""
    
    echo "💻 代码文件:"
    find "$KB_ROOT" -name "*.go" -o -name "*.java" -o -name "*.sql" | wc -l | xargs echo "  总计:"
    echo ""
}

# 更新知识库索引
update_index() {
    echo "=========================================="
    echo "更新知识库索引"
    echo "=========================================="
    echo ""
    
    # 更新PROJECT_KNOWLEDGE_BASE.md
    echo "✓ 更新主索引文件..."
    
    # 统计文档数量
    DOC_COUNT=$(find "$KB_ROOT" -name "*.md" -type f | wc -l | tr -d ' ')
    CODE_COUNT=$(find "$KB_ROOT" -name "*.go" -o -name "*.java" -o -name "*.sql" | wc -l | tr -d ' ')
    
    echo "  文档数量: $DOC_COUNT"
    echo "  代码文件: $CODE_COUNT"
    echo ""
    echo "✓ 索引更新完成"
    echo ""
}

# 生成知识库报告
generate_report() {
    echo "=========================================="
    echo "生成知识库报告"
    echo "=========================================="
    echo ""
    
    REPORT_FILE="$PROJECT_ROOT/knowledge-base-report-$(date +%Y%m%d).md"
    
    cat > "$REPORT_FILE" << EOF
# GoZervi知识库报告

**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')

## 📊 统计信息

### 文档统计
- 总文档数: $(find "$KB_ROOT" -name "*.md" -type f | wc -l | tr -d ' ')
- 分析文档: $(find "$KB_ROOT" -name "*ANALYSIS.md" -type f | wc -l | tr -d ' ')
- 实现文档: $(find "$KB_ROOT" -name "*IMPLEMENTATION.md" -type f | wc -l | tr -d ' ')

### 代码统计
- Go代码: $(find "$KB_ROOT" -name "*.go" -type f | wc -l | tr -d ' ')
- Java代码: $(find "$KB_ROOT" -name "*.java" -type f | wc -l | tr -d ' ')
- SQL脚本: $(find "$KB_ROOT" -name "*.sql" -type f | wc -l | tr -d ' ')

## 📁 目录结构

\`\`\`
$(tree -L 3 "$KB_ROOT" 2>/dev/null || find "$KB_ROOT" -type d | head -20)
\`\`\`

## 📄 文档列表

$(find "$KB_ROOT" -name "*.md" -type f | sed 's|^|  - |')

EOF
    
    echo "✓ 报告已生成: $REPORT_FILE"
    echo ""
}

# 备份知识库
backup_kb() {
    echo "=========================================="
    echo "备份知识库"
    echo "=========================================="
    echo ""
    
    BACKUP_DIR="$PROJECT_ROOT/knowledge-base-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    echo "备份到: $BACKUP_DIR"
    cp -r "$KB_ROOT" "$BACKUP_DIR/"
    cp "$PROJECT_ROOT/PROJECT_KNOWLEDGE_BASE.md" "$BACKUP_DIR/" 2>/dev/null || true
    
    echo "✓ 备份完成"
    echo ""
}

# 主循环
main() {
    while true; do
        show_menu
        read -p "请输入选项 (1-6): " choice
        echo ""
        
        case $choice in
            1)
                show_status
                ;;
            2)
                echo "功能开发中..."
                ;;
            3)
                update_index
                ;;
            4)
                generate_report
                ;;
            5)
                backup_kb
                ;;
            6)
                echo "退出"
                exit 0
                ;;
            *)
                echo "无效选项，请重新选择"
                ;;
        esac
        
        echo ""
        read -p "按Enter继续..."
        clear
    done
}

# 如果直接运行脚本，显示菜单
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main
fi

