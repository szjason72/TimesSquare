# GoZervi智能化SaaS系统实施方案

## 📊 项目概览

**项目名称**: GoZervi智能化SaaS服务系统  
**当前状态**: 88%完成（缺少多租户支持）  
**目标**: 100%完整的智能化SaaS系统  
**参考项目**: CordysCRM（完整多租户实现）  
**预计工期**: 4-6周

---

## 🎯 实施目标

### 核心目标
1. ✅ **补充多租户支持**（核心缺失功能）
2. ✅ **完善租户管理功能**
3. ✅ **实现数据隔离机制**
4. ✅ **优化权限隔离体系**
5. ✅ **完善监控和文档**

### 成功标准
- ✅ 所有业务表包含 `tenant_id` 字段
- ✅ 所有查询自动过滤租户数据
- ✅ 支持租户创建、切换、管理
- ✅ 租户级别的权限隔离
- ✅ 完整的测试覆盖

---

## 📋 现状分析

### 已具备的功能 ✅

| 功能模块 | 状态 | 完成度 |
|---------|------|--------|
| 微服务架构 | ✅ 完整 | 100% |
| API Gateway | ✅ 完整 | 100% |
| 认证授权 | ✅ 完整 | 100% |
| RBAC权限模型 | ✅ 完整 | 100% |
| 前端管理后台 | ✅ 完整 | 100% |
| 基础设施 | ✅ 完整 | 100% |
| AI服务 | ✅ 完整 | 100% |

### 缺失的功能 ❌

| 功能模块 | 状态 | 优先级 |
|---------|------|--------|
| 多租户支持 | ❌ 缺失 | 🔴 P0 |
| 租户管理 | ❌ 缺失 | 🔴 P0 |
| 数据隔离 | ❌ 缺失 | 🔴 P0 |
| 租户权限隔离 | ⚠️ 部分 | 🟡 P1 |
| 监控系统 | ⚠️ 部分 | 🟢 P2 |
| API文档 | ⚠️ 部分 | 🟢 P2 |

---

## 🏗️ 架构设计

### 多租户架构设计

```
┌─────────────────────────────────────────────────────────┐
│                     前端层 (Vue 3)                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Web App │  │  Admin   │  │  Mobile  │              │
│  └──────────┘  └──────────┘  └──────────┘              │
│                    │ 租户切换                            │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  API Gateway (Go)                        │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │  路由转发   │  │  限流熔断   │  │  认证鉴权   │       │
│  └────────────┘  └────────────┘  └────────────┘       │
│                    │ TenantMiddleware                   │
│                    │ (从JWT获取tenant_id)               │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  用户服务     │  │  业务服务     │  │  AI服务      │
│  (Go)        │  │  (Python)     │  │  (Python)    │
│              │  │               │  │              │
│ TenantContext│  │ TenantContext │  │ TenantContext│
│ 自动过滤     │  │ 自动过滤     │  │ 自动过滤     │
└──────────────┘  └──────────────┘  └──────────────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────┐
│              服务发现与配置 (Consul)                      │
└─────────────────────────────────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  PostgreSQL   │  │    Redis     │  │   其他存储   │
│              │  │              │  │              │
│ tenant_id    │  │ tenant_cache │  │              │
│ 数据隔离     │  │ 租户缓存     │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## 📅 分阶段实施计划

### 第一阶段：多租户核心功能（Week 1-2）🔴 P0

#### Week 1: 基础设施搭建

**Day 1-2: 租户上下文实现**
- [ ] 实现 `TenantContext`（Go版本）
- [ ] 实现 `TenantMiddleware`（Gin中间件）
- [ ] 实现租户ID从JWT Token提取
- [ ] 单元测试

**Day 3-4: 数据库迁移**
- [ ] 创建租户表（tenants）
- [ ] 为所有业务表添加 `tenant_id` 字段
- [ ] 创建租户相关索引
- [ ] 数据迁移脚本（现有数据分配默认租户）

**Day 5: 基础模型更新**
- [ ] 更新BaseModel包含tenant_id
- [ ] 实现GORM Scope自动过滤
- [ ] 更新所有领域模型

#### Week 2: 租户管理功能

**Day 1-2: 租户管理API**
- [ ] 租户创建API
- [ ] 租户列表API
- [ ] 租户详情API
- [ ] 租户更新API
- [ ] 租户删除API（软删除）

**Day 3-4: 用户-租户关联**
- [ ] 用户-租户关联表
- [ ] 用户加入租户API
- [ ] 用户离开租户API
- [ ] 用户租户列表API

**Day 5: 租户切换功能**
- [ ] 租户切换API
- [ ] JWT Token包含租户ID
- [ ] 前端租户切换组件

---

### 第二阶段：数据隔离完善（Week 3）🟡 P1

**Day 1-2: Service层更新**
- [ ] 更新所有Service方法接收tenantID
- [ ] 实现查询自动过滤
- [ ] 实现创建自动设置tenant_id
- [ ] 实现更新自动校验tenant_id

**Day 3-4: Mapper/DAO层更新**
- [ ] 更新所有查询SQL添加tenant_id过滤
- [ ] 更新所有插入SQL添加tenant_id
- [ ] 更新所有更新SQL添加tenant_id校验

**Day 5: 测试验证**
- [ ] 单元测试
- [ ] 集成测试
- [ ] 数据隔离测试

---

### 第三阶段：权限隔离完善（Week 4）🟡 P1

**Day 1-2: 租户级别权限**
- [ ] 角色表添加tenant_id
- [ ] 权限表添加tenant_id
- [ ] 用户角色关联表添加tenant_id

**Day 3-4: 权限检查更新**
- [ ] 权限检查时过滤tenant_id
- [ ] 角色查询时过滤tenant_id
- [ ] 权限分配时校验tenant_id

**Day 5: 测试验证**
- [ ] 权限隔离测试
- [ ] 跨租户访问测试

---

### 第四阶段：前端集成（Week 5）🟡 P1

**Day 1-2: 租户管理页面**
- [ ] 租户列表页面
- [ ] 租户创建/编辑页面
- [ ] 租户详情页面

**Day 3-4: 租户切换功能**
- [ ] 租户切换下拉菜单
- [ ] 租户切换API调用
- [ ] 租户切换后刷新数据

**Day 5: 测试验证**
- [ ] 前端功能测试
- [ ] 用户体验测试

---

### 第五阶段：优化与完善（Week 6）🟢 P2

**Day 1-2: 监控系统**
- [ ] Prometheus指标收集
- [ ] Grafana可视化面板
- [ ] 租户级别监控

**Day 3-4: API文档**
- [ ] Swagger集成
- [ ] API文档生成
- [ ] Postman Collection

**Day 5: 性能优化**
- [ ] 数据库查询优化
- [ ] 缓存策略优化
- [ ] 索引优化

---

## 💻 详细实施步骤

### Step 1: 租户上下文实现

#### 1.1 创建TenantContext

**文件**: `shared/core/context/tenant_context.go`

```go
package context

import (
    "context"
    "errors"
)

type tenantIDKey struct{}

var (
    ErrNoTenantPermission = errors.New("no tenant permission")
    ErrTenantNotFound     = errors.New("tenant not found")
)

// GetTenantID 从context获取租户ID
func GetTenantID(ctx context.Context) (int64, error) {
    tenantID, ok := ctx.Value(tenantIDKey{}).(int64)
    if !ok || tenantID == 0 {
        return 0, ErrTenantNotFound
    }
    return tenantID, nil
}

// SetTenantID 设置租户ID到context
func SetTenantID(ctx context.Context, tenantID int64) context.Context {
    return context.WithValue(ctx, tenantIDKey{}, tenantID)
}

// MustGetTenantID 获取租户ID（如果不存在则panic）
func MustGetTenantID(ctx context.Context) int64 {
    tenantID, err := GetTenantID(ctx)
    if err != nil {
        panic(err)
    }
    return tenantID
}
```

#### 1.2 创建TenantMiddleware

**文件**: `shared/core/middleware/tenant_middleware.go`

```go
package middleware

import (
    "github.com/gin-gonic/gin"
    "github.com/szjason72/zervigo/shared/core/context"
    "github.com/szjason72/zervigo/shared/core/auth"
)

// TenantMiddleware 租户ID中间件
func TenantMiddleware() gin.HandlerFunc {
    return func(c *gin.Context) {
        // 1. 尝试从JWT Token获取租户ID
        user := auth.GetUserFromContext(c)
        if user != nil && user.TenantID > 0 {
            ctx := context.SetTenantID(c.Request.Context(), user.TenantID)
            c.Request = c.Request.WithContext(ctx)
            c.Set("tenant_id", user.TenantID)
            c.Next()
            return
        }
        
        // 2. 尝试从请求头获取租户ID（用于切换租户）
        tenantIDHeader := c.GetHeader("X-Tenant-ID")
        if tenantIDHeader != "" {
            // 解析并验证租户ID
            // TODO: 验证用户是否有该租户的权限
            // tenantID := parseTenantID(tenantIDHeader)
            // ctx := context.SetTenantID(c.Request.Context(), tenantID)
            // c.Request = c.Request.WithContext(ctx)
        }
        
        c.Next()
    }
}
```

---

### Step 2: 数据库迁移

#### 2.1 创建租户表

**文件**: `databases/postgres/init/03-tenant-tables.sql`

```sql
-- 租户表
CREATE TABLE IF NOT EXISTS zervigo_tenants (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT '租户名称',
    code VARCHAR(50) UNIQUE NOT NULL COMMENT '租户代码',
    description TEXT COMMENT '租户描述',
    
    -- 状态信息
    status VARCHAR(20) DEFAULT 'active' COMMENT '状态: active, suspended, deleted',
    
    -- 配置信息
    settings JSONB DEFAULT '{}' COMMENT '租户配置',
    
    -- 配额信息
    quota JSONB DEFAULT '{}' COMMENT '资源配额',
    
    -- 时间戳
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    INDEX idx_code (code),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
);

-- 用户-租户关联表
CREATE TABLE IF NOT EXISTS zervigo_user_tenants (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES zervigo_auth_users(id) ON DELETE CASCADE,
    tenant_id BIGINT NOT NULL REFERENCES zervigo_tenants(id) ON DELETE CASCADE,
    
    -- 角色信息
    role VARCHAR(50) DEFAULT 'member' COMMENT '角色: owner, admin, member',
    
    -- 状态信息
    status VARCHAR(20) DEFAULT 'active' COMMENT '状态: active, inactive',
    
    -- 时间戳
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(user_id, tenant_id),
    INDEX idx_user_id (user_id),
    INDEX idx_tenant_id (tenant_id),
    INDEX idx_role (role)
);
```

#### 2.2 为现有表添加tenant_id

**文件**: `databases/postgres/migrations/add_tenant_id.sql`

```sql
-- 为所有业务表添加tenant_id字段
ALTER TABLE zervigo_jobs ADD COLUMN tenant_id BIGINT;
ALTER TABLE zervigo_user_profiles ADD COLUMN tenant_id BIGINT;
ALTER TABLE zervigo_companies ADD COLUMN tenant_id BIGINT;
ALTER TABLE zervigo_resumes ADD COLUMN tenant_id BIGINT;

-- 设置默认值（现有数据分配默认租户ID=1）
UPDATE zervigo_jobs SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE zervigo_user_profiles SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE zervigo_companies SET tenant_id = 1 WHERE tenant_id IS NULL;
UPDATE zervigo_resumes SET tenant_id = 1 WHERE tenant_id IS NULL;

-- 设置为NOT NULL
ALTER TABLE zervigo_jobs ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE zervigo_user_profiles ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE zervigo_companies ALTER COLUMN tenant_id SET NOT NULL;
ALTER TABLE zervigo_resumes ALTER COLUMN tenant_id SET NOT NULL;

-- 创建索引
CREATE INDEX idx_jobs_tenant_id ON zervigo_jobs(tenant_id);
CREATE INDEX idx_user_profiles_tenant_id ON zervigo_user_profiles(tenant_id);
CREATE INDEX idx_companies_tenant_id ON zervigo_companies(tenant_id);
CREATE INDEX idx_resumes_tenant_id ON zervigo_resumes(tenant_id);

-- 创建联合索引
CREATE INDEX idx_jobs_tenant_created ON zervigo_jobs(tenant_id, created_at);
CREATE INDEX idx_jobs_tenant_user ON zervigo_jobs(tenant_id, created_by);
```

---

### Step 3: 基础模型更新

#### 3.1 更新BaseModel

**文件**: `shared/core/model/base_model.go`

```go
package model

import (
    "time"
    "gorm.io/gorm"
)

// BaseModel 基础模型（包含租户ID）
type BaseModel struct {
    ID        int64          `gorm:"primaryKey;autoIncrement" json:"id"`
    TenantID  int64          `gorm:"column:tenant_id;index;not null" json:"tenant_id"`
    CreatedAt time.Time      `gorm:"column:created_at" json:"created_at"`
    UpdatedAt time.Time      `gorm:"column:updated_at" json:"updated_at"`
    DeletedAt gorm.DeletedAt `gorm:"column:deleted_at;index" json:"deleted_at"`
}

// BeforeCreate GORM Hook: 创建前自动设置tenant_id
func (m *BaseModel) BeforeCreate(tx *gorm.DB) error {
    if m.TenantID == 0 {
        // 从context获取tenant_id
        if tenantID, ok := tx.Statement.Context.Value("tenant_id").(int64); ok {
            m.TenantID = tenantID
        }
    }
    return nil
}

// ScopeTenant GORM Scope: 自动过滤租户
func ScopeTenant(tenantID int64) func(db *gorm.DB) *gorm.DB {
    return func(db *gorm.DB) *gorm.DB {
        return db.Where("tenant_id = ?", tenantID)
    }
}
```

#### 3.2 更新领域模型

**文件**: `services/business/job/models.go`

```go
package job

import (
    "github.com/szjason72/zervigo/shared/core/model"
)

// Job 职位模型
type Job struct {
    model.BaseModel  // 继承BaseModel（包含tenant_id）
    
    Title       string `gorm:"column:title" json:"title"`
    Description string `gorm:"column:description" json:"description"`
    CompanyID   int64  `gorm:"column:company_id" json:"company_id"`
    // ... 其他字段
}
```

---

### Step 4: Service层更新

#### 4.1 更新JobService

**文件**: `services/business/job/service.go`

```go
package job

import (
    "context"
    "github.com/szjason72/zervigo/shared/core/context"
    "github.com/szjason72/zervigo/shared/core/model"
    "gorm.io/gorm"
)

type JobService struct {
    db *gorm.DB
}

// List 列表查询（自动过滤租户）
func (s *JobService) List(ctx context.Context, req *JobListRequest) ([]*Job, error) {
    // 1. 从context获取租户ID
    tenantID, err := context.GetTenantID(ctx)
    if err != nil {
        return nil, err
    }
    
    // 2. 查询时自动过滤租户
    var jobs []*Job
    query := s.db.Model(&Job{}).
        Where("tenant_id = ?", tenantID)  // 自动过滤租户
    
    if req.Keyword != "" {
        query = query.Where("title LIKE ?", "%"+req.Keyword+"%")
    }
    
    err = query.Find(&jobs).Error
    return jobs, err
}

// Create 创建（自动设置tenant_id）
func (s *JobService) Create(ctx context.Context, req *JobCreateRequest) (*Job, error) {
    // 1. 从context获取租户ID
    tenantID, err := context.GetTenantID(ctx)
    if err != nil {
        return nil, err
    }
    
    // 2. 创建时自动设置tenant_id
    job := &Job{
        BaseModel: model.BaseModel{
            TenantID: tenantID,  // 自动设置
        },
        Title:       req.Title,
        Description: req.Description,
        // ... 其他字段
    }
    
    err = s.db.Create(job).Error
    return job, err
}

// Update 更新（自动校验tenant_id）
func (s *JobService) Update(ctx context.Context, id int64, req *JobUpdateRequest) error {
    // 1. 从context获取租户ID
    tenantID, err := context.GetTenantID(ctx)
    if err != nil {
        return err
    }
    
    // 2. 更新时校验tenant_id
    var job Job
    err = s.db.Where("id = ? AND tenant_id = ?", id, tenantID).First(&job).Error
    if err != nil {
        return err
    }
    
    // 3. 更新数据
    updates := map[string]interface{}{
        "title":       req.Title,
        "description": req.Description,
        // ... 其他字段
    }
    
    err = s.db.Model(&job).Updates(updates).Error
    return err
}

// Delete 删除（自动校验tenant_id）
func (s *JobService) Delete(ctx context.Context, id int64) error {
    tenantID, err := context.GetTenantID(ctx)
    if err != nil {
        return err
    }
    
    // 软删除，自动校验tenant_id
    err = s.db.Where("id = ? AND tenant_id = ?", id, tenantID).
        Delete(&Job{}).Error
    return err
}
```

---

### Step 5: 租户管理API

#### 5.1 租户Service

**文件**: `services/core/tenant/service.go`

```go
package tenant

import (
    "context"
    "errors"
    "github.com/szjason72/zervigo/shared/core/context"
    "gorm.io/gorm"
)

type TenantService struct {
    db *gorm.DB
}

// Create 创建租户
func (s *TenantService) Create(ctx context.Context, req *TenantCreateRequest) (*Tenant, error) {
    // 1. 检查租户代码是否已存在
    var existing Tenant
    err := s.db.Where("code = ?", req.Code).First(&existing).Error
    if err == nil {
        return nil, errors.New("tenant code already exists")
    }
    
    // 2. 创建租户
    tenant := &Tenant{
        Name:        req.Name,
        Code:        req.Code,
        Description: req.Description,
        Status:      "active",
    }
    
    err = s.db.Create(tenant).Error
    if err != nil {
        return nil, err
    }
    
    // 3. 创建用户-租户关联（创建者为owner）
    userID := getUserIDFromContext(ctx)
    userTenant := &UserTenant{
        UserID:   userID,
        TenantID: tenant.ID,
        Role:     "owner",
        Status:   "active",
    }
    err = s.db.Create(userTenant).Error
    
    return tenant, err
}

// List 租户列表（当前用户的租户）
func (s *TenantService) List(ctx context.Context) ([]*Tenant, error) {
    userID := getUserIDFromContext(ctx)
    
    var tenants []*Tenant
    err := s.db.Table("zervigo_tenants").
        Joins("JOIN zervigo_user_tenants ON zervigo_tenants.id = zervigo_user_tenants.tenant_id").
        Where("zervigo_user_tenants.user_id = ?", userID).
        Where("zervigo_user_tenants.status = ?", "active").
        Find(&tenants).Error
    
    return tenants, err
}

// Switch 切换租户
func (s *TenantService) Switch(ctx context.Context, tenantID int64) error {
    userID := getUserIDFromContext(ctx)
    
    // 1. 验证用户是否有该租户的权限
    var userTenant UserTenant
    err := s.db.Where("user_id = ? AND tenant_id = ? AND status = ?", 
        userID, tenantID, "active").First(&userTenant).Error
    if err != nil {
        return errors.New("no permission for this tenant")
    }
    
    // 2. 更新用户的last_tenant_id（在用户表中）
    err = s.db.Model(&User{}).
        Where("id = ?", userID).
        Update("last_tenant_id", tenantID).Error
    
    return err
}
```

#### 5.2 租户Controller

**文件**: `services/core/tenant/controller.go`

```go
package tenant

import (
    "github.com/gin-gonic/gin"
    "github.com/szjason72/zervigo/shared/core/response"
    "strconv"
)

type TenantController struct {
    service *TenantService
}

// Create 创建租户
// POST /api/v1/tenants
func (c *TenantController) Create(ctx *gin.Context) {
    var req TenantCreateRequest
    if err := ctx.ShouldBindJSON(&req); err != nil {
        response.Error(ctx, 400, "Invalid request", nil)
        return
    }
    
    tenant, err := c.service.Create(ctx.Request.Context(), &req)
    if err != nil {
        response.Error(ctx, 500, err.Error(), nil)
        return
    }
    
    response.Success(ctx, tenant)
}

// List 租户列表
// GET /api/v1/tenants
func (c *TenantController) List(ctx *gin.Context) {
    tenants, err := c.service.List(ctx.Request.Context())
    if err != nil {
        response.Error(ctx, 500, err.Error(), nil)
        return
    }
    
    response.Success(ctx, tenants)
}

// Switch 切换租户
// POST /api/v1/tenants/:id/switch
func (c *TenantController) Switch(ctx *gin.Context) {
    tenantID, err := strconv.ParseInt(ctx.Param("id"), 10, 64)
    if err != nil {
        response.Error(ctx, 400, "Invalid tenant ID", nil)
        return
    }
    
    err = c.service.Switch(ctx.Request.Context(), tenantID)
    if err != nil {
        response.Error(ctx, 500, err.Error(), nil)
        return
    }
    
    response.Success(ctx, gin.H{"message": "Tenant switched successfully"})
}
```

---

### Step 6: JWT Token更新

#### 6.1 更新JWT Claims

**文件**: `shared/core/auth/types.go`

```go
package auth

// Claims JWT Claims（包含tenant_id）
type Claims struct {
    UserID   int64  `json:"user_id"`
    Username string `json:"username"`
    TenantID int64  `json:"tenant_id"`  // 新增租户ID
    Role     string `json:"role"`
    jwt.StandardClaims
}
```

#### 6.2 更新Token生成

**文件**: `shared/core/auth/auth.go`

```go
func (a *AuthSystem) GenerateToken(userID int64, username string, tenantID int64) (string, error) {
    claims := Claims{
        UserID:   userID,
        Username: username,
        TenantID: tenantID,  // 包含租户ID
        Role:     "user",
        StandardClaims: jwt.StandardClaims{
            ExpiresAt: time.Now().Add(15 * time.Minute).Unix(),
        },
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString([]byte(a.jwtSecret))
}
```

---

### Step 7: 前端集成

#### 7.1 租户切换组件

**文件**: `frontend/src/components/TenantSwitcher.vue`

```vue
<template>
  <el-dropdown @command="handleSwitch">
    <span class="tenant-switcher">
      {{ currentTenant?.name }}
      <el-icon><ArrowDown /></el-icon>
    </span>
    <template #dropdown>
      <el-dropdown-menu>
        <el-dropdown-item 
          v-for="tenant in tenantList" 
          :key="tenant.id"
          :command="tenant.id"
          :disabled="tenant.id === currentTenant?.id"
        >
          {{ tenant.name }}
        </el-dropdown-item>
      </el-dropdown-menu>
    </template>
  </el-dropdown>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getTenantList, switchTenant } from '@/api/tenant'
import { useUserStore } from '@/stores/user'

const userStore = useUserStore()
const tenantList = ref([])
const currentTenant = ref(null)

onMounted(async () => {
  await loadTenants()
  currentTenant.value = userStore.currentTenant
})

const loadTenants = async () => {
  const res = await getTenantList()
  tenantList.value = res.data
}

const handleSwitch = async (tenantId: number) => {
  await switchTenant(tenantId)
  // 刷新页面或重新加载数据
  window.location.reload()
}
</script>
```

#### 7.2 租户API

**文件**: `frontend/src/api/tenant.ts`

```typescript
import request from './request'

export interface Tenant {
  id: number
  name: string
  code: string
  description?: string
  status: string
}

export const getTenantList = () => {
  return request.get<Tenant[]>('/api/v1/tenants')
}

export const createTenant = (data: Partial<Tenant>) => {
  return request.post<Tenant>('/api/v1/tenants', data)
}

export const switchTenant = (tenantId: number) => {
  return request.post(`/api/v1/tenants/${tenantId}/switch`)
}
```

---

## 🧪 测试计划

### 单元测试

**文件**: `services/core/tenant/service_test.go`

```go
func TestTenantService_Create(t *testing.T) {
    // 测试租户创建
}

func TestTenantService_List(t *testing.T) {
    // 测试租户列表
}

func TestTenantService_Switch(t *testing.T) {
    // 测试租户切换
}
```

### 集成测试

**文件**: `tests/integration/tenant_test.go`

```go
func TestTenantDataIsolation(t *testing.T) {
    // 测试租户数据隔离
    // 1. 创建两个租户
    // 2. 租户A创建数据
    // 3. 租户B查询数据（应该查不到租户A的数据）
}
```

---

## 📊 实施检查清单

### Phase 1: 多租户核心功能 ✅/❌

**基础设施**
- [ ] TenantContext实现
- [ ] TenantMiddleware实现
- [ ] JWT Token包含tenant_id
- [ ] 单元测试

**数据库**
- [ ] 租户表创建
- [ ] 用户-租户关联表创建
- [ ] 所有业务表添加tenant_id
- [ ] 索引创建
- [ ] 数据迁移脚本

**基础模型**
- [ ] BaseModel更新
- [ ] 所有领域模型更新
- [ ] GORM Scope实现

### Phase 2: 租户管理功能 ✅/❌

**API**
- [ ] 租户创建API
- [ ] 租户列表API
- [ ] 租户详情API
- [ ] 租户更新API
- [ ] 租户删除API
- [ ] 租户切换API

**用户关联**
- [ ] 用户加入租户API
- [ ] 用户离开租户API
- [ ] 用户租户列表API

### Phase 3: 数据隔离完善 ✅/❌

**Service层**
- [ ] 所有Service方法更新
- [ ] 查询自动过滤
- [ ] 创建自动设置tenant_id
- [ ] 更新自动校验tenant_id

**Mapper/DAO层**
- [ ] 所有查询SQL更新
- [ ] 所有插入SQL更新
- [ ] 所有更新SQL更新

### Phase 4: 权限隔离完善 ✅/❌

**权限模型**
- [ ] 角色表添加tenant_id
- [ ] 权限表添加tenant_id
- [ ] 用户角色关联表添加tenant_id

**权限检查**
- [ ] 权限检查更新
- [ ] 角色查询更新
- [ ] 权限分配更新

### Phase 5: 前端集成 ✅/❌

**页面**
- [ ] 租户列表页面
- [ ] 租户创建/编辑页面
- [ ] 租户详情页面

**组件**
- [ ] 租户切换组件
- [ ] 租户选择组件

### Phase 6: 测试验证 ✅/❌

**测试**
- [ ] 单元测试
- [ ] 集成测试
- [ ] 数据隔离测试
- [ ] 权限隔离测试
- [ ] 端到端测试

---

## 🚀 快速开始

### 第一步：环境准备

```bash
# 1. 确认Go版本
go version  # 需要 1.21+

# 2. 确认PostgreSQL版本
psql --version  # 需要 15+

# 3. 确认Redis版本
redis-cli --version  # 需要 7+
```

### 第二步：数据库迁移

```bash
cd /Users/szjason72/gozervi/zervigo.demo

# 1. 执行租户表创建
psql -U postgres -d zervigo_mvp -f databases/postgres/init/03-tenant-tables.sql

# 2. 执行为现有表添加tenant_id
psql -U postgres -d zervigo_mvp -f databases/postgres/migrations/add_tenant_id.sql
```

### 第三步：代码实现

```bash
# 1. 创建TenantContext
# 文件: shared/core/context/tenant_context.go

# 2. 创建TenantMiddleware
# 文件: shared/core/middleware/tenant_middleware.go

# 3. 更新BaseModel
# 文件: shared/core/model/base_model.go
```

### 第四步：测试验证

```bash
# 1. 运行单元测试
go test ./services/core/tenant/...

# 2. 运行集成测试
go test ./tests/integration/...

# 3. 启动服务测试
./scripts/start-local-services.sh
```

---

## 📈 里程碑

### Milestone 1: 多租户核心功能（Week 2结束）
- ✅ TenantContext实现
- ✅ 数据库迁移完成
- ✅ 基础模型更新完成

### Milestone 2: 租户管理功能（Week 2结束）
- ✅ 租户CRUD API完成
- ✅ 用户-租户关联完成
- ✅ 租户切换功能完成

### Milestone 3: 数据隔离完善（Week 3结束）
- ✅ 所有Service层更新完成
- ✅ 所有查询自动过滤
- ✅ 数据隔离测试通过

### Milestone 4: 权限隔离完善（Week 4结束）
- ✅ 租户级别权限实现
- ✅ 权限隔离测试通过

### Milestone 5: 前端集成（Week 5结束）
- ✅ 租户管理页面完成
- ✅ 租户切换功能完成

### Milestone 6: 系统完善（Week 6结束）
- ✅ 监控系统集成
- ✅ API文档完成
- ✅ 性能优化完成

---

## 🎯 成功标准

### 功能完整性
- ✅ 所有业务表包含tenant_id字段
- ✅ 所有查询自动过滤tenant_id
- ✅ 支持租户创建、切换、管理
- ✅ 租户级别的权限隔离

### 代码质量
- ✅ 单元测试覆盖率 > 80%
- ✅ 集成测试通过率 100%
- ✅ 代码审查通过

### 性能指标
- ✅ 查询性能不下降（索引优化）
- ✅ 响应时间 < 200ms（P95）
- ✅ 并发支持 > 1000 QPS

### 文档完整性
- ✅ API文档完整
- ✅ 部署文档完整
- ✅ 用户手册完整

---

## 📝 风险与应对

### 风险1: 数据迁移风险

**风险**: 现有数据迁移可能丢失或错误

**应对**:
- ✅ 数据迁移前完整备份
- ✅ 分批次迁移
- ✅ 迁移后数据校验
- ✅ 回滚方案准备

### 风险2: 性能下降风险

**风险**: 添加tenant_id过滤可能影响查询性能

**应对**:
- ✅ 创建合适的索引
- ✅ 查询优化
- ✅ 性能测试
- ✅ 缓存策略

### 风险3: 兼容性风险

**风险**: 现有API可能不兼容

**应对**:
- ✅ API版本控制
- ✅ 向后兼容
- ✅ 渐进式迁移
- ✅ 充分测试

---

## 📚 参考资源

### 代码参考
- **CordysCRM**: `/Users/szjason72/Saasbolent/szbolent/CordysCRM-main`
  - OrganizationContext实现
  - Web过滤器实现
  - 数据库设计

### 文档参考
- **SaaS规划文档**: `SAAS_SYSTEM_PLANNING.md`
- **GoZervi评估**: `GOZERVI_SAAS_EVALUATION.md`
- **CordysCRM分析**: `CORDYSCRM_MULTI_TENANT_ANALYSIS.md`

---

## 🎉 总结

本实施方案基于以下分析：
1. ✅ **GoZervi现状**: 88%完成，缺少多租户支持
2. ✅ **CordysCRM经验**: 完整的多租户实现，可直接借鉴
3. ✅ **分阶段实施**: 6周完成，分5个阶段
4. ✅ **可执行性**: 详细的代码示例和实施步骤

**下一步**: 按照本方案开始实施，优先完成Phase 1（多租户核心功能）。

---

**方案版本**: v1.0  
**创建时间**: 2025-01-XX  
**预计完成时间**: 6周  
**负责人**: 开发团队

