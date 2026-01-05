# 凌鲨(api-server)代码本地化管理参考

## 📋 项目信息

**项目名称**: 凌鲨 API服务端  
**项目路径**: `/Users/szjason72/Saasbolent/szbolent/api-server-develop-40b52c9a140068c0c291c900006bbf05de3da90a`  
**技术栈**: Go + MongoDB + Redis  
**本地化管理**: ⭐⭐⭐⭐⭐ (完整方案)

## 🎯 核心实现

### 1. 目录结构

```
api-server/
├── vendor_local/          # 本地依赖仓库
│   ├── proto-gen-go.git/
│   ├── extension-proto-gen-go.git/
│   └── webhook.git/
├── go.mod                 # 原始go.mod
├── go.mod.local           # 本地开发模板
├── go.mod.backup          # 备份文件
└── setup-local-deps.sh    # 自动化脚本
```

**GoZervi实现**: 相同结构

---

### 2. go.mod.local模板

**参考文件**: `go.mod.local`

**核心机制**:
- 使用replace指令替换私有仓库
- 提供清晰的注释说明
- 便于版本控制

**关键代码**:
```go
// 本地开发替换 - 将私有仓库替换为本地路径
replace atomgit.com/openlinksaas/proto-gen-go.git => ./vendor_local/proto-gen-go.git
replace atomgit.com/openlinksaas/extension-proto-gen-go.git => ./vendor_local/extension-proto-gen-go.git
replace atomgit.com/openlinksaas/webhook.git => ./vendor_local/webhook.git
```

**GoZervi实现**: `shared/core/go.mod.local`

---

### 3. 自动化脚本

**参考文件**: `setup-local-deps.sh`

**核心功能**:
- 检查本地仓库是否存在
- 自动备份go.mod
- 自动添加replace指令
- 友好的错误提示

**关键代码**:
```bash
# 备份原始go.mod
if [ ! -f "go.mod.backup" ]; then
    cp go.mod go.mod.backup
fi

# 添加replace指令
if ! grep -q "^replace" go.mod; then
    # 添加replace指令
fi
```

**GoZervi实现**: `GOZERVI_LOCAL_DEPS_SETUP.sh`

---

### 4. 文档体系

**参考文档**:
- `LOCAL_DEPS_GUIDE.md` - 详细使用指南
- `LOCAL_SETUP.md` - 本地环境设置
- `TROUBLESHOOTING.md` - 故障排除

**GoZervi实现**: `CODE_LOCALIZATION_GUIDE.md`

---

## 📚 相关文档

- [代码本地化指南](../../CODE_LOCALIZATION_GUIDE.md)
- [GoZervi本地化脚本](../../GOZERVI_LOCAL_DEPS_SETUP.sh)

---

**最后更新**: 2025-01-XX

