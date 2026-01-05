# BC4 Pro 系列设备适配方案

## 📋 概述

**目标**: 重点适配 BC4 Pro 系列硬件设备，通过具体设备适配理解本地智能化 SaaS 系统的硬件集成机制

**参考源码**: BC4 Pro 系列相关源码总结  
**适配策略**: 聚焦特定设备系列，而非大而全的适配

---

## 🔍 BC4 Pro 系列设备分析

### 1. 设备类型识别

根据源码分析，BC4 Pro 系列包含以下设备类型：

| 设备类型 | 标识符 | 说明 | 重置引导图 |
|---------|--------|------|-----------|
| BC4 标准版 | `cameraIconBC4` | BC4 设备标准版本 | bc4_guide1, bc4_guide2 |
| BC4L | `cameraIconBC4L` | BC4L 版本（可能是 Lite 版本） | bc4_guide1, bc4_guide2 |
| P1 | `cameraIconP1` | P1 版本（可能与 BC4 Pro 相关） | bc4_guide1, bc4_guide2 |

### 2. 设备特征

- **共享重置引导流程**: 所有 BC4 系列设备使用相同的重置引导图（bc4_guide1.png, bc4_guide2.png）
- **设备图标**: 使用 `camera_bc4.png` 作为设备图标
- **设备系列**: 属于同一硬件系列，具有相似的配置和操作流程

---

## 🏗️ 数据库设计（针对 BC4 Pro 系列）

### 1. 设备类型配置表

```sql
-- BC4 Pro 系列设备类型配置表
CREATE TABLE IF NOT EXISTS zervigo_device_types (
    id BIGSERIAL PRIMARY KEY,
    device_type_code VARCHAR(50) NOT NULL UNIQUE, -- cameraIconBC4, cameraIconBC4L, cameraIconP1
    device_type_name VARCHAR(255) NOT NULL, -- BC4, BC4L, P1
    device_series VARCHAR(50) NOT NULL, -- BC4_PRO_SERIES
    manufacturer VARCHAR(100) DEFAULT 'SuperAcme',
    device_category VARCHAR(50) DEFAULT 'camera', -- camera/access_control/iot_sensor
    icon_resource VARCHAR(255), -- camera_bc4.png
    reset_guide_step1 VARCHAR(255), -- bc4_guide1.png
    reset_guide_step2 VARCHAR(255), -- bc4_guide2.png
    default_config JSONB, -- 默认配置
    capabilities JSONB, -- 设备能力（支持的协议、功能等）
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_device_types_code ON zervigo_device_types(device_type_code);
CREATE INDEX idx_device_types_series ON zervigo_device_types(device_series);

-- 插入 BC4 Pro 系列设备类型
INSERT INTO zervigo_device_types 
(device_type_code, device_type_name, device_series, icon_resource, reset_guide_step1, reset_guide_step2, default_config, capabilities)
VALUES
('cameraIconBC4', 'BC4', 'BC4_PRO_SERIES', 'camera_bc4.png', 'bc4_guide1.png', 'bc4_guide2.png', 
 '{"reset_timeout": 30, "heartbeat_interval": 30, "video_quality": "1080p"}'::jsonb,
 '{"supports_rtsp": true, "supports_onvif": true, "supports_cloud_storage": true}'::jsonb),
('cameraIconBC4L', 'BC4L', 'BC4_PRO_SERIES', 'camera_bc4.png', 'bc4_guide1.png', 'bc4_guide2.png',
 '{"reset_timeout": 30, "heartbeat_interval": 30, "video_quality": "720p"}'::jsonb,
 '{"supports_rtsp": true, "supports_onvif": true, "supports_cloud_storage": false}'::jsonb),
('cameraIconP1', 'P1', 'BC4_PRO_SERIES', 'camera_bc4.png', 'bc4_guide1.png', 'bc4_guide2.png',
 '{"reset_timeout": 30, "heartbeat_interval": 30, "video_quality": "1080p"}'::jsonb,
 '{"supports_rtsp": true, "supports_onvif": true, "supports_cloud_storage": true}'::jsonb);
```

### 2. 设备注册表（扩展）

```sql
-- 智能设备表（扩展，支持 BC4 Pro 系列）
CREATE TABLE IF NOT EXISTS zervigo_smart_devices (
    id BIGSERIAL PRIMARY KEY,
    tenant_id BIGINT NOT NULL REFERENCES zervigo_tenants(id),
    device_code VARCHAR(100) NOT NULL UNIQUE, -- 设备唯一编码（设备序列号）
    device_name VARCHAR(255) NOT NULL,
    device_type_code VARCHAR(50) NOT NULL REFERENCES zervigo_device_types(device_type_code), -- 关联设备类型
    device_model VARCHAR(100), -- BC4, BC4L, P1
    manufacturer VARCHAR(100) DEFAULT 'SuperAcme',
    firmware_version VARCHAR(50),
    sdk_version VARCHAR(50),
    ip_address VARCHAR(50),
    mac_address VARCHAR(50),
    location VARCHAR(255),
    status VARCHAR(20) DEFAULT 'offline', -- online/offline/maintenance/resetting/error
    reset_status VARCHAR(20), -- idle/resetting/reset_success/reset_failed
    last_heartbeat TIMESTAMP,
    config JSONB, -- 设备配置（JSON格式）
    metadata JSONB, -- 设备元数据
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    UNIQUE(tenant_id, device_code)
);

CREATE INDEX idx_devices_tenant_id ON zervigo_smart_devices(tenant_id);
CREATE INDEX idx_devices_device_type ON zervigo_smart_devices(device_type_code);
CREATE INDEX idx_devices_status ON zervigo_smart_devices(status);
```

### 3. 设备重置引导表

```sql
-- 设备重置引导记录表
CREATE TABLE IF NOT EXISTS zervigo_device_reset_guides (
    id BIGSERIAL PRIMARY KEY,
    device_id BIGINT NOT NULL REFERENCES zervigo_smart_devices(id),
    tenant_id BIGINT NOT NULL REFERENCES zervigo_tenants(id),
    reset_step INTEGER NOT NULL, -- 1 或 2
    guide_image VARCHAR(255) NOT NULL, -- bc4_guide1.png 或 bc4_guide2.png
    step_description TEXT, -- 步骤说明
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_reset_guides_device_id ON zervigo_device_reset_guides(device_id);
```

---

## 🔌 BC4 Pro 系列设备适配实现

### 1. 设备类型管理服务

```go
// services/core/device/bc4_device_type_service.go
package device

import (
    "context"
    "database/sql"
    "encoding/json"
)

type BC4DeviceTypeService struct {
    db *sql.DB
}

// DeviceType 设备类型结构
type DeviceType struct {
    ID              int64                  `json:"id"`
    DeviceTypeCode  string                 `json:"device_type_code"`
    DeviceTypeName  string                 `json:"device_type_name"`
    DeviceSeries    string                 `json:"device_series"`
    Manufacturer    string                 `json:"manufacturer"`
    DeviceCategory  string                 `json:"device_category"`
    IconResource    string                 `json:"icon_resource"`
    ResetGuideStep1 string                 `json:"reset_guide_step1"`
    ResetGuideStep2 string                 `json:"reset_guide_step2"`
    DefaultConfig   map[string]interface{} `json:"default_config"`
    Capabilities    map[string]interface{} `json:"capabilities"`
}

// GetDeviceTypeByCode 根据设备类型代码获取设备类型信息
func (s *BC4DeviceTypeService) GetDeviceTypeByCode(ctx context.Context, deviceTypeCode string) (*DeviceType, error) {
    query := `
        SELECT id, device_type_code, device_type_name, device_series, manufacturer,
               device_category, icon_resource, reset_guide_step1, reset_guide_step2,
               default_config, capabilities
        FROM zervigo_device_types
        WHERE device_type_code = $1
    `
    
    var dt DeviceType
    var defaultConfigJSON, capabilitiesJSON []byte
    
    err := s.db.QueryRowContext(ctx, query, deviceTypeCode).Scan(
        &dt.ID, &dt.DeviceTypeCode, &dt.DeviceTypeName, &dt.DeviceSeries,
        &dt.Manufacturer, &dt.DeviceCategory, &dt.IconResource,
        &dt.ResetGuideStep1, &dt.ResetGuideStep2,
        &defaultConfigJSON, &capabilitiesJSON,
    )
    if err != nil {
        return nil, err
    }
    
    json.Unmarshal(defaultConfigJSON, &dt.DefaultConfig)
    json.Unmarshal(capabilitiesJSON, &dt.Capabilities)
    
    return &dt, nil
}

// GetResetGuideImages 获取设备重置引导图
func (s *BC4DeviceTypeService) GetResetGuideImages(ctx context.Context, deviceTypeCode string) ([]string, error) {
    dt, err := s.GetDeviceTypeByCode(ctx, deviceTypeCode)
    if err != nil {
        return nil, err
    }
    
    return []string{dt.ResetGuideStep1, dt.ResetGuideStep2}, nil
}

// GetDeviceIcon 获取设备图标
func (s *BC4DeviceTypeService) GetDeviceIcon(ctx context.Context, deviceTypeCode string) (string, error) {
    dt, err := s.GetDeviceTypeByCode(ctx, deviceTypeCode)
    if err != nil {
        return "", err
    }
    
    return dt.IconResource, nil
}

// IsBC4ProSeries 判断是否为 BC4 Pro 系列设备
func (s *BC4DeviceTypeService) IsBC4ProSeries(ctx context.Context, deviceTypeCode string) (bool, error) {
    dt, err := s.GetDeviceTypeByCode(ctx, deviceTypeCode)
    if err != nil {
        return false, err
    }
    
    return dt.DeviceSeries == "BC4_PRO_SERIES", nil
}
```

### 2. BC4 Pro 设备注册服务

```go
// services/core/device/bc4_device_service.go
package device

import (
    "context"
    "database/sql"
    "encoding/json"
    "fmt"
    "time"
)

type BC4DeviceService struct {
    db                *sql.DB
    deviceTypeService *BC4DeviceTypeService
}

// RegisterBC4Device 注册 BC4 Pro 系列设备
func (s *BC4DeviceService) RegisterBC4Device(ctx context.Context, tenantID int64, req RegisterBC4DeviceRequest) (*BC4Device, error) {
    // 1. 验证设备类型是否为 BC4 Pro 系列
    isBC4Series, err := s.deviceTypeService.IsBC4ProSeries(ctx, req.DeviceTypeCode)
    if err != nil {
        return nil, fmt.Errorf("验证设备类型失败: %w", err)
    }
    if !isBC4Series {
        return nil, fmt.Errorf("设备类型 %s 不属于 BC4 Pro 系列", req.DeviceTypeCode)
    }
    
    // 2. 获取设备类型信息
    deviceType, err := s.deviceTypeService.GetDeviceTypeByCode(ctx, req.DeviceTypeCode)
    if err != nil {
        return nil, fmt.Errorf("获取设备类型信息失败: %w", err)
    }
    
    // 3. 合并默认配置和用户配置
    config := make(map[string]interface{})
    for k, v := range deviceType.DefaultConfig {
        config[k] = v
    }
    for k, v := range req.Config {
        config[k] = v
    }
    configJSON, _ := json.Marshal(config)
    
    // 4. 创建设备记录
    query := `
        INSERT INTO zervigo_smart_devices 
        (tenant_id, device_code, device_name, device_type_code, device_model, manufacturer,
         firmware_version, sdk_version, ip_address, mac_address, location, status, config, metadata, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'offline', $12, $13, NOW(), NOW())
        RETURNING id
    `
    
    metadataJSON, _ := json.Marshal(map[string]interface{}{
        "device_series": deviceType.DeviceSeries,
        "icon_resource": deviceType.IconResource,
        "reset_guides": []string{deviceType.ResetGuideStep1, deviceType.ResetGuideStep2},
    })
    
    var deviceID int64
    err = s.db.QueryRowContext(ctx, query,
        tenantID, req.DeviceCode, req.DeviceName, req.DeviceTypeCode, deviceType.DeviceTypeName,
        deviceType.Manufacturer, req.FirmwareVersion, req.SDKVersion, req.IPAddress,
        req.MACAddress, req.Location, configJSON, metadataJSON).Scan(&deviceID)
    if err != nil {
        return nil, fmt.Errorf("创建设备记录失败: %w", err)
    }
    
    // 5. 生成设备Token
    deviceAuth := NewDeviceAuth(s.db)
    token, secretKey, err := deviceAuth.GenerateDeviceToken(deviceID, tenantID)
    if err != nil {
        return nil, fmt.Errorf("生成设备Token失败: %w", err)
    }
    
    // 6. 获取设备信息
    device, err := s.GetBC4Device(ctx, deviceID)
    if err != nil {
        return nil, err
    }
    
    device.Token = token
    device.SecretKey = secretKey
    
    return device, nil
}

// GetBC4Device 获取 BC4 Pro 设备信息
func (s *BC4DeviceService) GetBC4Device(ctx context.Context, deviceID int64) (*BC4Device, error) {
    query := `
        SELECT d.id, d.tenant_id, d.device_code, d.device_name, d.device_type_code,
               d.device_model, d.manufacturer, d.firmware_version, d.sdk_version,
               d.ip_address, d.mac_address, d.location, d.status, d.reset_status,
               d.last_heartbeat, d.config, d.metadata, d.created_at, d.updated_at,
               dt.icon_resource, dt.reset_guide_step1, dt.reset_guide_step2
        FROM zervigo_smart_devices d
        JOIN zervigo_device_types dt ON d.device_type_code = dt.device_type_code
        WHERE d.id = $1 AND d.deleted_at IS NULL
    `
    
    var device BC4Device
    var configJSON, metadataJSON []byte
    
    err := s.db.QueryRowContext(ctx, query, deviceID).Scan(
        &device.ID, &device.TenantID, &device.DeviceCode, &device.DeviceName,
        &device.DeviceTypeCode, &device.DeviceModel, &device.Manufacturer,
        &device.FirmwareVersion, &device.SDKVersion, &device.IPAddress,
        &device.MACAddress, &device.Location, &device.Status, &device.ResetStatus,
        &device.LastHeartbeat, &configJSON, &metadataJSON,
        &device.CreatedAt, &device.UpdatedAt,
        &device.IconResource, &device.ResetGuideStep1, &device.ResetGuideStep2,
    )
    if err != nil {
        return nil, err
    }
    
    json.Unmarshal(configJSON, &device.Config)
    json.Unmarshal(metadataJSON, &device.Metadata)
    
    return &device, nil
}

// RegisterBC4DeviceRequest BC4 设备注册请求
type RegisterBC4DeviceRequest struct {
    DeviceCode      string                 `json:"device_code" binding:"required"`
    DeviceName      string                 `json:"device_name" binding:"required"`
    DeviceTypeCode  string                 `json:"device_type_code" binding:"required"` // cameraIconBC4, cameraIconBC4L, cameraIconP1
    FirmwareVersion string                 `json:"firmware_version"`
    SDKVersion      string                 `json:"sdk_version"`
    IPAddress       string                 `json:"ip_address"`
    MACAddress      string                 `json:"mac_address"`
    Location        string                 `json:"location"`
    Config          map[string]interface{} `json:"config"`
}

// BC4Device BC4 Pro 设备结构
type BC4Device struct {
    ID               int64                  `json:"id"`
    TenantID         int64                  `json:"tenant_id"`
    DeviceCode       string                 `json:"device_code"`
    DeviceName       string                 `json:"device_name"`
    DeviceTypeCode   string                 `json:"device_type_code"`
    DeviceModel      string                 `json:"device_model"`
    Manufacturer     string                 `json:"manufacturer"`
    FirmwareVersion  string                 `json:"firmware_version"`
    SDKVersion       string                 `json:"sdk_version"`
    IPAddress        string                 `json:"ip_address"`
    MACAddress       string                 `json:"mac_address"`
    Location         string                 `json:"location"`
    Status           string                 `json:"status"`
    ResetStatus      *string                `json:"reset_status"`
    LastHeartbeat    *time.Time             `json:"last_heartbeat"`
    Config           map[string]interface{} `json:"config"`
    Metadata         map[string]interface{} `json:"metadata"`
    IconResource     string                 `json:"icon_resource"`
    ResetGuideStep1  string                 `json:"reset_guide_step1"`
    ResetGuideStep2  string                 `json:"reset_guide_step2"`
    Token            string                 `json:"token,omitempty"`
    SecretKey        string                 `json:"secret_key,omitempty"`
    CreatedAt        time.Time              `json:"created_at"`
    UpdatedAt        time.Time              `json:"updated_at"`
}
```

### 3. BC4 Pro 设备重置引导服务

```go
// services/core/device/bc4_reset_service.go
package device

import (
    "context"
    "database/sql"
    "fmt"
    "time"
)

type BC4ResetService struct {
    db                *sql.DB
    deviceService     *BC4DeviceService
    deviceTypeService *BC4DeviceTypeService
}

// StartResetGuide 开始设备重置引导流程
func (s *BC4ResetService) StartResetGuide(ctx context.Context, deviceID int64) error {
    // 1. 获取设备信息
    device, err := s.deviceService.GetBC4Device(ctx, deviceID)
    if err != nil {
        return err
    }
    
    // 2. 获取重置引导图
    guideImages, err := s.deviceTypeService.GetResetGuideImages(ctx, device.DeviceTypeCode)
    if err != nil {
        return err
    }
    
    // 3. 更新设备重置状态
    resetStatus := "resetting"
    query := `
        UPDATE zervigo_smart_devices 
        SET reset_status = $1, updated_at = NOW()
        WHERE id = $2
    `
    _, err = s.db.ExecContext(ctx, query, resetStatus, deviceID)
    if err != nil {
        return err
    }
    
    // 4. 创建重置引导记录
    for i, guideImage := range guideImages {
        step := i + 1
        insertQuery := `
            INSERT INTO zervigo_device_reset_guides 
            (device_id, tenant_id, reset_step, guide_image, step_description, created_at)
            VALUES ($1, $2, $3, $4, $5, NOW())
        `
        description := fmt.Sprintf("BC4 Pro 系列设备重置引导步骤 %d", step)
        _, err = s.db.ExecContext(ctx, insertQuery, deviceID, device.TenantID, step, guideImage, description)
        if err != nil {
            return err
        }
    }
    
    return nil
}

// CompleteResetStep 完成重置步骤
func (s *BC4ResetService) CompleteResetStep(ctx context.Context, deviceID int64, step int) error {
    query := `
        UPDATE zervigo_device_reset_guides 
        SET completed_at = NOW()
        WHERE device_id = $1 AND reset_step = $2
    `
    _, err := s.db.ExecContext(ctx, query, deviceID, step)
    return err
}

// CompleteReset 完成设备重置
func (s *BC4ResetService) CompleteReset(ctx context.Context, deviceID int64, success bool) error {
    resetStatus := "reset_success"
    if !success {
        resetStatus = "reset_failed"
    }
    
    query := `
        UPDATE zervigo_smart_devices 
        SET reset_status = $1, updated_at = NOW()
        WHERE id = $2
    `
    _, err := s.db.ExecContext(ctx, query, resetStatus, deviceID)
    return err
}

// GetResetGuide 获取设备重置引导信息
func (s *BC4ResetService) GetResetGuide(ctx context.Context, deviceID int64) (*ResetGuide, error) {
    device, err := s.deviceService.GetBC4Device(ctx, deviceID)
    if err != nil {
        return nil, err
    }
    
    guideImages, err := s.deviceTypeService.GetResetGuideImages(ctx, device.DeviceTypeCode)
    if err != nil {
        return nil, err
    }
    
    return &ResetGuide{
        DeviceID:      deviceID,
        DeviceTypeCode: device.DeviceTypeCode,
        Steps: []ResetGuideStep{
            {
                Step:        1,
                GuideImage:  guideImages[0],
                Description: "第一步：按住设备重置按钮",
            },
            {
                Step:        2,
                GuideImage:  guideImages[1],
                Description: "第二步：等待指示灯闪烁后松开",
            },
        },
    }, nil
}

// ResetGuide 重置引导信息
type ResetGuide struct {
    DeviceID      int64           `json:"device_id"`
    DeviceTypeCode string         `json:"device_type_code"`
    Steps         []ResetGuideStep `json:"steps"`
}

// ResetGuideStep 重置引导步骤
type ResetGuideStep struct {
    Step        int    `json:"step"`
    GuideImage  string `json:"guide_image"`
    Description string `json:"description"`
    CompletedAt *time.Time `json:"completed_at,omitempty"`
}
```

### 4. BC4 Pro 设备 API

```go
// services/core/device/bc4_device_api.go
package device

import (
    "github.com/gin-gonic/gin"
    "net/http"
)

type BC4DeviceAPI struct {
    deviceService     *BC4DeviceService
    resetService      *BC4ResetService
    deviceTypeService *BC4DeviceTypeService
}

// RegisterRoutes 注册 BC4 Pro 设备路由
func (api *BC4DeviceAPI) RegisterRoutes(r *gin.RouterGroup) {
    bc4Group := r.Group("/bc4-devices")
    bc4Group.Use(middleware.TenantMiddleware())
    bc4Group.Use(middleware.AuthMiddleware())
    
    // 设备管理
    bc4Group.POST("", api.registerBC4Device)        // 注册 BC4 Pro 设备
    bc4Group.GET("", api.listBC4Devices)            // BC4 Pro 设备列表
    bc4Group.GET("/:id", api.getBC4Device)         // BC4 Pro 设备详情
    bc4Group.PUT("/:id", api.updateBC4Device)       // 更新 BC4 Pro 设备
    
    // 设备重置引导
    bc4Group.POST("/:id/reset/start", api.startResetGuide)      // 开始重置引导
    bc4Group.GET("/:id/reset/guide", api.getResetGuide)        // 获取重置引导
    bc4Group.POST("/:id/reset/step/:step", api.completeResetStep) // 完成重置步骤
    bc4Group.POST("/:id/reset/complete", api.completeReset)    // 完成重置
    
    // 设备类型
    bc4Group.GET("/types", api.listBC4DeviceTypes)  // 获取 BC4 Pro 系列设备类型
}

// registerBC4Device 注册 BC4 Pro 设备
func (api *BC4DeviceAPI) registerBC4Device(c *gin.Context) {
    tenantID := context.GetTenantID(c.Request.Context())
    
    var req RegisterBC4DeviceRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        response.ErrorResponse(c, http.StatusBadRequest, "参数错误", err.Error())
        return
    }
    
    device, err := api.deviceService.RegisterBC4Device(c.Request.Context(), tenantID, req)
    if err != nil {
        response.ErrorResponse(c, http.StatusInternalServerError, "注册设备失败", err.Error())
        return
    }
    
    response.SuccessResponse(c, "BC4 Pro 设备注册成功", device)
}

// getBC4Device 获取 BC4 Pro 设备详情
func (api *BC4DeviceAPI) getBC4Device(c *gin.Context) {
    deviceID := c.Param("id")
    
    device, err := api.deviceService.GetBC4Device(c.Request.Context(), deviceID)
    if err != nil {
        response.ErrorResponse(c, http.StatusNotFound, "设备不存在", err.Error())
        return
    }
    
    response.SuccessResponse(c, "获取成功", device)
}

// startResetGuide 开始重置引导
func (api *BC4DeviceAPI) startResetGuide(c *gin.Context) {
    deviceID := c.Param("id")
    
    err := api.resetService.StartResetGuide(c.Request.Context(), deviceID)
    if err != nil {
        response.ErrorResponse(c, http.StatusInternalServerError, "开始重置引导失败", err.Error())
        return
    }
    
    guide, err := api.resetService.GetResetGuide(c.Request.Context(), deviceID)
    if err != nil {
        response.ErrorResponse(c, http.StatusInternalServerError, "获取重置引导失败", err.Error())
        return
    }
    
    response.SuccessResponse(c, "重置引导已开始", guide)
}

// getResetGuide 获取重置引导
func (api *BC4DeviceAPI) getResetGuide(c *gin.Context) {
    deviceID := c.Param("id")
    
    guide, err := api.resetService.GetResetGuide(c.Request.Context(), deviceID)
    if err != nil {
        response.ErrorResponse(c, http.StatusNotFound, "重置引导不存在", err.Error())
        return
    }
    
    response.SuccessResponse(c, "获取成功", guide)
}

// listBC4DeviceTypes 获取 BC4 Pro 系列设备类型列表
func (api *BC4DeviceAPI) listBC4DeviceTypes(c *gin.Context) {
    query := `
        SELECT id, device_type_code, device_type_name, device_series, icon_resource
        FROM zervigo_device_types
        WHERE device_series = 'BC4_PRO_SERIES'
        ORDER BY device_type_code
    `
    
    rows, err := api.deviceTypeService.db.Query(query)
    if err != nil {
        response.ErrorResponse(c, http.StatusInternalServerError, "查询失败", err.Error())
        return
    }
    defer rows.Close()
    
    var types []map[string]interface{}
    for rows.Next() {
        var id int64
        var code, name, series, icon string
        rows.Scan(&id, &code, &name, &series, &icon)
        types = append(types, map[string]interface{}{
            "id":              id,
            "device_type_code": code,
            "device_type_name": name,
            "device_series":    series,
            "icon_resource":    icon,
        })
    }
    
    response.SuccessResponse(c, "获取成功", types)
}
```

---

## 📱 前端集成示例

### 1. BC4 Pro 设备注册组件

```typescript
// frontend/src/components/device/BC4DeviceRegister.vue
<template>
  <div class="bc4-device-register">
    <h2>注册 BC4 Pro 系列设备</h2>
    
    <el-form :model="form" :rules="rules" ref="formRef" label-width="120px">
      <el-form-item label="设备类型" prop="deviceTypeCode">
        <el-select v-model="form.deviceTypeCode" placeholder="请选择设备类型">
          <el-option
            v-for="type in deviceTypes"
            :key="type.device_type_code"
            :label="type.device_type_name"
            :value="type.device_type_code"
          >
            <span>{{ type.device_type_name }}</span>
            <img :src="getIconUrl(type.icon_resource)" class="device-icon" />
          </el-option>
        </el-select>
      </el-form-item>
      
      <el-form-item label="设备编码" prop="deviceCode">
        <el-input v-model="form.deviceCode" placeholder="请输入设备唯一编码" />
      </el-form-item>
      
      <el-form-item label="设备名称" prop="deviceName">
        <el-input v-model="form.deviceName" placeholder="请输入设备名称" />
      </el-form-item>
      
      <el-form-item label="IP地址" prop="ipAddress">
        <el-input v-model="form.ipAddress" placeholder="请输入设备IP地址" />
      </el-form-item>
      
      <el-form-item>
        <el-button type="primary" @click="handleRegister">注册设备</el-button>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { registerBC4Device, getBC4DeviceTypes } from '@/api/device'

const form = ref({
  deviceTypeCode: '',
  deviceCode: '',
  deviceName: '',
  ipAddress: '',
  macAddress: '',
  location: '',
})

const deviceTypes = ref([])
const formRef = ref()

const rules = {
  deviceTypeCode: [{ required: true, message: '请选择设备类型', trigger: 'change' }],
  deviceCode: [{ required: true, message: '请输入设备编码', trigger: 'blur' }],
  deviceName: [{ required: true, message: '请输入设备名称', trigger: 'blur' }],
}

onMounted(async () => {
  await loadDeviceTypes()
})

const loadDeviceTypes = async () => {
  try {
    const res = await getBC4DeviceTypes()
    deviceTypes.value = res.data
  } catch (error) {
    ElMessage.error('加载设备类型失败')
  }
}

const handleRegister = async () => {
  await formRef.value.validate()
  
  try {
    const res = await registerBC4Device(form.value)
    ElMessage.success('设备注册成功')
    // 显示设备Token等信息
    console.log('Device Token:', res.data.token)
  } catch (error) {
    ElMessage.error('设备注册失败')
  }
}

const getIconUrl = (iconResource: string) => {
  return `/static/images/devices/${iconResource}`
}
</script>
```

### 2. BC4 Pro 设备重置引导组件

```typescript
// frontend/src/components/device/BC4ResetGuide.vue
<template>
  <div class="bc4-reset-guide">
    <h2>BC4 Pro 设备重置引导</h2>
    
    <div v-for="(step, index) in resetGuide.steps" :key="step.step" class="reset-step">
      <h3>步骤 {{ step.step }}</h3>
      <img :src="getGuideImageUrl(step.guide_image)" class="guide-image" />
      <p>{{ step.description }}</p>
      
      <el-button 
        v-if="!step.completed_at"
        type="primary" 
        @click="completeStep(step.step)"
      >
        完成此步骤
      </el-button>
      <el-tag v-else type="success">已完成</el-tag>
    </div>
    
    <div class="reset-actions">
      <el-button type="success" @click="completeReset(true)">重置成功</el-button>
      <el-button type="danger" @click="completeReset(false)">重置失败</el-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { 
  startResetGuide, 
  getResetGuide, 
  completeResetStep, 
  completeReset as apiCompleteReset 
} from '@/api/device'

const props = defineProps<{
  deviceId: number
}>()

const resetGuide = ref({
  device_id: 0,
  device_type_code: '',
  steps: [],
})

onMounted(async () => {
  await loadResetGuide()
})

const loadResetGuide = async () => {
  try {
    const res = await getResetGuide(props.deviceId)
    resetGuide.value = res.data
  } catch (error) {
    ElMessage.error('加载重置引导失败')
  }
}

const startGuide = async () => {
  try {
    await startResetGuide(props.deviceId)
    await loadResetGuide()
    ElMessage.success('重置引导已开始')
  } catch (error) {
    ElMessage.error('开始重置引导失败')
  }
}

const completeStep = async (step: number) => {
  try {
    await completeResetStep(props.deviceId, step)
    await loadResetGuide()
    ElMessage.success(`步骤 ${step} 已完成`)
  } catch (error) {
    ElMessage.error('完成步骤失败')
  }
}

const completeReset = async (success: boolean) => {
  try {
    await apiCompleteReset(props.deviceId, success)
    ElMessage.success(success ? '重置成功' : '重置失败')
  } catch (error) {
    ElMessage.error('操作失败')
  }
}

const getGuideImageUrl = (guideImage: string) => {
  return `/static/images/reset-guides/${guideImage}`
}
</script>
```

---

## 🎯 实施重点

### 1. 聚焦 BC4 Pro 系列

- ✅ **设备类型明确**: 只适配 `cameraIconBC4`, `cameraIconBC4L`, `cameraIconP1` 三种设备类型
- ✅ **共享引导流程**: 所有 BC4 Pro 系列设备使用相同的重置引导图
- ✅ **统一图标资源**: 使用 `camera_bc4.png` 作为设备图标

### 2. 理解硬件集成机制

通过 BC4 Pro 系列适配，可以理解：

1. **设备类型管理**: 如何定义和管理设备类型配置
2. **设备注册流程**: 如何注册和绑定硬件设备
3. **重置引导机制**: 如何提供设备重置引导流程
4. **设备配置管理**: 如何管理设备默认配置和自定义配置
5. **多租户隔离**: 如何确保设备数据按租户隔离

### 3. 扩展性设计

虽然聚焦 BC4 Pro 系列，但设计保持扩展性：

- 设备类型表可以轻松添加新的设备系列
- 重置引导机制可以适配不同设备的不同引导流程
- 配置管理可以支持不同设备的个性化配置

---

## 📊 实施步骤

### 阶段 1: 数据库和基础服务（1-2天）

1. 创建设备类型配置表
2. 扩展设备注册表
3. 创建重置引导表
4. 实现设备类型管理服务

### 阶段 2: BC4 Pro 设备服务（2-3天）

1. 实现 BC4 Pro 设备注册服务
2. 实现设备重置引导服务
3. 实现设备查询和管理服务

### 阶段 3: API 接口（1-2天）

1. 实现 BC4 Pro 设备 API
2. 实现重置引导 API
3. 实现设备类型查询 API

### 阶段 4: 前端集成（2-3天）

1. 实现设备注册组件
2. 实现重置引导组件
3. 实现设备列表和详情页面

### 阶段 5: 测试和优化（1-2天）

1. 单元测试
2. 集成测试
3. 性能优化

---

## 📝 总结

通过聚焦 BC4 Pro 系列设备的适配，我们可以：

1. **深入理解硬件集成**: 通过具体设备类型理解硬件集成的各个环节
2. **验证架构设计**: 验证多租户设备管理架构的可行性
3. **积累经验**: 为后续扩展其他设备系列积累经验
4. **快速迭代**: 聚焦特定设备可以更快地完成适配和验证

**预计总时间**: 7-12天（分阶段实施）

