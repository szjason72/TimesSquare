# GoZervi本地云部署实施计划

## 📋 项目概述

**目标**: 实现GoZervi SaaS系统的真正本地云部署能力  
**参考**: btcloud-main（宝塔面板第三方云端）  
**原则**: 完全离线、一键部署、资源本地化

---

## 🎯 核心目标

### 1. 完全离线部署
- ✅ 不依赖外部服务
- ✅ 所有资源本地存储
- ✅ 支持内网环境部署

### 2. 一键安装
- ✅ 自动化环境检查
- ✅ 自动化服务启动
- ✅ 自动化健康检查

### 3. 资源本地化
- ✅ Docker镜像本地存储
- ✅ 数据库初始化脚本
- ✅ 配置文件模板

---

## 📦 实施方案

### Phase 1: Docker Compose完整编排（Week 1）

#### 1.1 创建完整的docker-compose.yml

**文件位置**: `docker/docker-compose.local-cloud.yml`

**服务列表**:
```yaml
version: '3.8'

services:
  # ==================== 基础设施层 ====================
  
  postgresql:
    image: postgres:14-alpine
    container_name: zervigo-postgresql
    environment:
      POSTGRES_DB: zervigo_mvp
      POSTGRES_USER: zervigo
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-zervigo2025}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./databases/postgres/init:/docker-entrypoint-initdb.d:ro
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U zervigo"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - zervigo-network

  redis:
    image: redis:7-alpine
    container_name: zervigo-redis
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - zervigo-network

  consul:
    image: consul:1.16
    container_name: zervigo-consul
    command: consul agent -dev -client=0.0.0.0
    volumes:
      - consul_data:/consul/data
    ports:
      - "8500:8500"
    healthcheck:
      test: ["CMD", "consul", "members"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - zervigo-network

  # ==================== 核心服务层 ====================
  
  auth-service:
    build:
      context: .
      dockerfile: services/core/auth/Dockerfile
    container_name: zervigo-auth-service
    environment:
      DATABASE_URL: postgres://zervigo:${POSTGRES_PASSWORD:-zervigo2025}@postgresql:5432/zervigo_mvp?sslmode=disable
      JWT_SECRET: ${JWT_SECRET:-zervigo-mvp-secret-key-2025}
      AUTH_SERVICE_PORT: 8207
      ENVIRONMENT: ${ENVIRONMENT:-production}
    ports:
      - "8207:8207"
    depends_on:
      postgresql:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8207/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - zervigo-network

  tenant-service:
    build:
      context: .
      dockerfile: services/core/tenant/Dockerfile
    container_name: zervigo-tenant-service
    environment:
      DATABASE_URL: postgres://zervigo:${POSTGRES_PASSWORD:-zervigo2025}@postgresql:5432/zervigo_mvp?sslmode=disable
      AUTH_SERVICE_URL: http://auth-service:8207
      TENANT_SERVICE_PORT: 8088
      CONSUL_ADDR: consul:8500
    ports:
      - "8088:8088"
    depends_on:
      postgresql:
        condition: service_healthy
      auth-service:
        condition: service_healthy
      consul:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8088/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - zervigo-network

  # ==================== 业务服务层 ====================
  
  job-service:
    build:
      context: .
      dockerfile: services/business/job/Dockerfile
    container_name: zervigo-job-service
    environment:
      DATABASE_URL: postgres://zervigo:${POSTGRES_PASSWORD:-zervigo2025}@postgresql:5432/zervigo_mvp?sslmode=disable
      AUTH_SERVICE_URL: http://auth-service:8207
      CONSUL_ADDR: consul:8500
    ports:
      - "8084:8084"
    depends_on:
      postgresql:
        condition: service_healthy
      auth-service:
        condition: service_healthy
      consul:
        condition: service_healthy
    networks:
      - zervigo-network

  company-service:
    build:
      context: .
      dockerfile: services/business/company/Dockerfile
    container_name: zervigo-company-service
    environment:
      DATABASE_URL: postgres://zervigo:${POSTGRES_PASSWORD:-zervigo2025}@postgresql:5432/zervigo_mvp?sslmode=disable
      AUTH_SERVICE_URL: http://auth-service:8207
      CONSUL_ADDR: consul:8500
    ports:
      - "8085:8085"
    depends_on:
      postgresql:
        condition: service_healthy
      auth-service:
        condition: service_healthy
      consul:
        condition: service_healthy
    networks:
      - zervigo-network

  # ==================== API网关层 ====================
  
  api-gateway:
    build:
      context: .
      dockerfile: services/gateway/Dockerfile
    container_name: zervigo-api-gateway
    environment:
      CONSUL_ADDR: consul:8500
      AUTH_SERVICE_URL: http://auth-service:8207
    ports:
      - "9000:9000"
    depends_on:
      consul:
        condition: service_healthy
      auth-service:
        condition: service_healthy
    networks:
      - zervigo-network

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  consul_data:
    driver: local

networks:
  zervigo-network:
    driver: bridge
```

---

### Phase 2: 一键安装脚本（Week 1-2）

#### 2.1 创建install.sh

**文件位置**: `scripts/install-local-cloud.sh`

**功能**:
1. 环境检查（Docker, Docker Compose）
2. 镜像导入（从本地tar文件）
3. 配置生成（从模板）
4. 数据库初始化
5. 服务启动
6. 健康检查

---

### Phase 3: 配置管理工具（Week 2）

#### 3.1 创建setup-env.sh

**文件位置**: `scripts/setup-env.sh`

**功能**:
- 交互式配置生成
- 环境变量设置
- 配置文件模板化

---

### Phase 4: 镜像本地化（Week 2-3）

#### 4.1 创建镜像导出/导入脚本

**文件位置**: `scripts/export-images.sh`, `scripts/import-images.sh`

**功能**:
- 导出所有Docker镜像为tar文件
- 导入本地镜像到Docker
- 镜像版本管理

---

## 🚀 实施步骤

### Step 1: 创建Docker Compose文件

**优先级**: 🔴 **最高**

**任务**:
- [ ] 创建`docker/docker-compose.local-cloud.yml`
- [ ] 配置所有服务
- [ ] 设置健康检查
- [ ] 配置数据卷

---

### Step 2: 开发安装脚本

**优先级**: 🔴 **最高**

**任务**:
- [ ] 创建`scripts/install-local-cloud.sh`
- [ ] 实现环境检查
- [ ] 实现服务启动
- [ ] 实现健康检查

---

### Step 3: 配置管理工具

**优先级**: 🟡 **高**

**任务**:
- [ ] 创建`scripts/setup-env.sh`
- [ ] 创建`.env.template`
- [ ] 实现配置生成逻辑

---

### Step 4: 镜像本地化

**优先级**: 🟡 **高**

**任务**:
- [ ] 创建镜像导出脚本
- [ ] 创建镜像导入脚本
- [ ] 创建镜像版本管理

---

## 📝 使用指南

### 快速开始

```bash
# 1. 克隆项目
git clone <repository>
cd zervigo.demo

# 2. 运行安装脚本
chmod +x scripts/install-local-cloud.sh
./scripts/install-local-cloud.sh

# 3. 配置环境（可选）
./scripts/setup-env.sh

# 4. 启动服务
docker-compose -f docker/docker-compose.local-cloud.yml up -d

# 5. 检查服务状态
docker-compose -f docker/docker-compose.local-cloud.yml ps
```

---

## 🔧 技术细节

### 1. 完全离线部署

#### 镜像本地化
```bash
# 导出镜像
docker save -o zervigo-images.tar \
  postgres:14-alpine \
  redis:7-alpine \
  consul:1.16 \
  zervigo-auth-service:latest \
  zervigo-tenant-service:latest

# 导入镜像
docker load -i zervigo-images.tar
```

#### 数据库初始化
- 所有SQL脚本存储在`databases/postgres/init/`
- Docker自动执行初始化脚本
- 支持增量迁移

---

### 2. 配置管理

#### 环境变量模板
```bash
# .env.template
POSTGRES_PASSWORD=zervigo2025
JWT_SECRET=zervigo-mvp-secret-key-2025
ENVIRONMENT=production
DOMAIN=localhost
```

#### 配置生成
```bash
# 从模板生成.env
cp .env.template .env
# 或使用交互式工具
./scripts/setup-env.sh
```

---

### 3. 健康检查

#### 服务健康检查
```bash
# 检查所有服务
docker-compose -f docker/docker-compose.local-cloud.yml ps

# 检查特定服务
docker-compose -f docker/docker-compose.local-cloud.yml exec auth-service curl http://localhost:8207/health
```

---

## 📊 对比分析

### btcloud vs GoZervi本地云

| 特性 | btcloud | GoZervi本地云 |
|------|---------|---------------|
| **部署方式** | PHP Web应用 | Docker容器化 |
| **资源管理** | 文件系统 | Docker镜像 + 数据卷 |
| **安装脚本** | Shell脚本 | Shell + Docker Compose |
| **配置管理** | 数据库配置 | 环境变量 + 配置文件 |
| **服务编排** | 单机部署 | Docker Compose编排 |
| **扩展性** | 有限 | 支持水平扩展 |
| **监控** | 基础日志 | 健康检查 + 日志 |

---

## 🎯 实施优先级

### 🔴 立即实施（Week 1）
1. **Docker Compose编排**: 完整服务编排
2. **安装脚本**: 一键安装工具

### 🟡 短期实施（Week 2-3）
3. **配置管理**: 环境配置工具
4. **镜像本地化**: 镜像导出/导入

### 🟢 长期优化（Week 4+）
5. **监控面板**: Prometheus + Grafana
6. **日志聚合**: ELK/Loki集成
7. **备份恢复**: 自动化备份工具

---

## 💡 关键设计点

### 1. 完全离线
- ✅ 所有Docker镜像本地存储
- ✅ 数据库初始化脚本本地化
- ✅ 配置文件模板化
- ✅ 不依赖外部服务

### 2. 一键安装
- ✅ 自动化环境检查
- ✅ 自动化镜像导入
- ✅ 自动化配置生成
- ✅ 自动化服务启动

### 3. 可扩展性
- ✅ 支持单机部署
- ✅ 支持集群部署（未来）
- ✅ 支持多环境配置
- ✅ 支持版本升级

---

## 📋 下一步行动

### 立即开始
1. **创建Docker Compose文件**: `docker/docker-compose.local-cloud.yml`
2. **开发安装脚本**: `scripts/install-local-cloud.sh`
3. **配置管理工具**: `scripts/setup-env.sh`

### 测试验证
4. **本地测试**: 完整部署流程测试
5. **文档编写**: 部署文档和使用指南
6. **优化改进**: 根据测试结果优化

---

**计划完成时间**: 2025-01-XX  
**参考项目**: btcloud-main  
**目标**: 实现GoZervi真正的本地云部署能力

