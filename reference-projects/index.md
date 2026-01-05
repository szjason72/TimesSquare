# 参考项目索引

## 📚 项目列表

### 1. CordysCRM ⭐⭐⭐⭐⭐

**路径**: `/Users/szjason72/Saasbolent/szbolent/CordysCRM-main`  
**类型**: 开源CRM系统  
**技术栈**: Spring Boot + MyBatis + MySQL  
**核心价值**: 完整的多租户实现

**可借鉴点**:
- ✅ OrganizationContext实现
- ✅ Web过滤器实现
- ✅ 数据库设计模式
- ✅ 查询自动过滤机制

**文档**: [CordysCRM多租户分析](../CORDYSCRM_MULTI_TENANT_ANALYSIS.md)

---

### 2. 凌鲨(api-server) ⭐⭐⭐⭐⭐

**路径**: `/Users/szjason72/Saasbolent/szbolent/api-server-develop-*`  
**类型**: SaaS API服务端  
**技术栈**: Go + MongoDB + Redis  
**核心价值**: 完整的代码本地化管理方案

**可借鉴点**:
- ✅ vendor_local目录结构
- ✅ go.mod.local模板
- ✅ 自动化配置脚本
- ✅ 完善的文档体系

**文档**: [代码本地化指南](../CODE_LOCALIZATION_GUIDE.md)

---

### 3. VueCMF ⭐⭐⭐

**路径**: `/Users/szjason72/looma/vuecmf`  
**类型**: 内容管理框架  
**技术栈**: Go + Vue  
**核心价值**: app_id隔离模式

**可借鉴点**:
- ⚠️ app_id字段设计
- ⚠️ 应用级别隔离

**文档**: [VueCMF多租户分析](../GOVUECMF_MULTI_TENANT_ANALYSIS.md)

---

### 4. Zervi.test ⭐⭐

**路径**: `/Users/szjason72/gozervi/zervi.test`  
**类型**: Spring Cloud微服务  
**技术栈**: Java + Spring Boot  
**核心价值**: tenant_type模式

**可借鉴点**:
- ⚠️ tenant_type字段设计
- ⚠️ 客户端类型区分

---

### 5. WooCMS ⭐

**路径**: `/Users/szjason72/looma-crm/woocms`  
**类型**: 内容管理系统  
**技术栈**: PHP + ThinkPHP  
**核心价值**: 模型设计模式

**可借鉴点**:
- ⚠️ 模型基类设计
- ⚠️ 事件机制
- ⚠️ 权限树设计

**文档**: [WooCMS分析](../WOOCMS_MULTI_TENANT_ANALYSIS.md)

---

## 🎯 借鉴优先级

| 项目 | 优先级 | 完成度 | 状态 |
|------|--------|--------|------|
| **CordysCRM** | 🔴 P0 | 100% | ✅ 已分析 |
| **凌鲨** | 🔴 P0 | 100% | ✅ 已借鉴 |
| **VueCMF** | 🟡 P1 | 60% | ⚠️ 部分借鉴 |
| **Zervi.test** | 🟡 P1 | 40% | ⚠️ 待深入 |
| **WooCMS** | 🟢 P2 | 20% | ⚠️ 待分析 |

---

**最后更新**: 2025-01-XX

