# CordysCRM多租户实现参考

## 📋 项目信息

**项目名称**: CordysCRM  
**项目路径**: `/Users/szjason72/Saasbolent/szbolent/CordysCRM-main`  
**技术栈**: Spring Boot + MyBatis + MySQL  
**多租户实现**: ⭐⭐⭐⭐⭐ (完整实现)

## 🎯 核心实现

### 1. OrganizationContext (组织上下文)

**参考文件**: `backend/framework/src/main/java/cn/cordys/context/OrganizationContext.java`

**核心机制**:
- 使用ThreadLocal存储组织ID
- 自动权限校验
- 请求结束后自动清理

**关键代码**:
```java
private static final ThreadLocal<String> ORGANIZATION_ID = new InheritableThreadLocal<>();

public static String getOrganizationId() {
    String orgId = ORGANIZATION_ID.get();
    // 权限校验逻辑
    if (user.getOrganizationIds().contains(orgId)) {
        return orgId;
    }
    throw new GenericException("No organization permission");
}
```

**GoZervi实现**: `shared/core/context/tenant_context.go`

---

### 2. OrganizationContextWebFilter (Web过滤器)

**参考文件**: `backend/crm/src/main/java/cn/cordys/common/context/OrganizationContextWebFilter.java`

**核心机制**:
- 从HTTP请求头获取组织ID
- 自动注入到ThreadLocal
- 请求结束后自动清理

**关键代码**:
```java
public class OrganizationContextWebFilter extends OncePerRequestFilter {
    public static final String ORGANIZATION_ID_HEADER = "Organization-Id";
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, 
                                   HttpServletResponse response, 
                                   FilterChain chain) {
        String organizationId = request.getHeader(ORGANIZATION_ID_HEADER);
        if (organizationId != null) {
            OrganizationContext.setOrganizationId(organizationId);
        }
        try {
            chain.doFilter(request, response);
        } finally {
            OrganizationContext.clear();
        }
    }
}
```

**GoZervi实现**: `shared/core/middleware/tenant_middleware.go`

---

### 3. 数据库设计

**参考文件**: `backend/crm/src/main/resources/migration/*/ddl/*.sql`

**核心特点**:
- 所有业务表包含`organization_id`字段
- 创建索引优化查询
- 通过organization_id实现数据隔离

**关键SQL**:
```sql
CREATE TABLE clue (
    id VARCHAR(64) PRIMARY KEY,
    organization_id VARCHAR(64) NOT NULL,
    -- ... 其他字段
    INDEX idx_organization_id (organization_id)
);
```

**GoZervi实现**: `databases/postgres/init/03-tenant-tables.sql`

---

### 4. 查询自动过滤

**参考文件**: `backend/crm/src/main/java/cn/cordys/crm/clue/mapper/ExtClueMapper.xml`

**核心机制**:
- MyBatis Mapper XML中所有查询都过滤organization_id
- Service层方法都接收organizationId参数

**关键代码**:
```xml
<select id="list" resultType="Clue">
    SELECT * FROM clue c
    WHERE c.organization_id = #{orgId}  -- 自动过滤
    -- ... 其他条件
</select>
```

**GoZervi实现**: GORM Scope自动过滤

---

## 📚 相关文档

- [完整分析报告](../../CORDYSCRM_MULTI_TENANT_ANALYSIS.md)
- [GoZervi实施方案](../../GOZERVI_SAAS_IMPLEMENTATION_PLAN.md)

---

**最后更新**: 2025-01-XX

