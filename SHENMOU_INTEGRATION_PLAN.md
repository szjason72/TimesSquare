# 神目源码集成方案 - GoZervi SaaS系统

## 📋 分析概述

**神目源码位置**: `/Users/szjason72/shenmou`  
**源码类型**: Android APK反编译（smali代码 + 资源文件）  
**分析时间**: 2025-01-XX  
**目标**: 参考神目SDK设计理念，实现GoZervi SaaS系统的智能硬件适配

---

## 🔍 神目源码结构分析

### 1. 源码结构

```
shenmou/
├── AndroidManifest.xml          # Android应用清单
├── assets/                       # 资源文件
│   ├── DeviceSetting.json       # 设备设置配置
│   ├── DeviceMainSetting.json    # 主设备设置
│   ├── config.conf              # 配置文件
│   ├── CN_content_data_transmit_url.json  # 数据传输URL配置
│   └── ...                      # 其他配置文件
├── lib/                         # 原生库（.so文件）
│   ├── arm64-v8a/              # ARM64架构
│   └── armeabi-v7a/            # ARMv7架构
├── smali/                       # Smali反编译代码
└── res/                         # Android资源文件
```

### 2. 关键配置文件分析

#### DeviceSetting.json
- 设备基础设置
- 设备认证配置
- 设备参数配置

#### DeviceMainSetting.json
- 主设备设置
- 设备连接配置
- 设备状态配置

#### config.conf
- 全局配置
- 服务端地址配置
- 认证信息配置

#### CN_content_data_transmit_url.json
- 数据传输URL配置
- 数据同步端点配置

---

## 🎯 基于神目设计理念的集成方案

### 核心设计理念（参考神目SDK）

1. **多租户设备隔离**: 确保数据安全
2. **设备Token认证**: 长期有效的设备认证
3. **心跳机制**: 实时监控设备状态
4. **配置下发**: 支持远程配置更新
5. **数据同步**: 设备数据实时同步到服务端
6. **离线/在线双模式**: 提高可用性

---

## 🏗️ GoZervi SaaS系统集成架构

### Phase 1: 数据库设计（已完成设计）

参考 `SMART_HARDWARE_ADAPTATION.md` 中的数据库设计：

1. **zervigo_smart_devices** - 智能设备表
2. **zervigo_device_tokens** - 设备认证表
3. **zervigo_device_data** - 设备数据同步表

---

### Phase 2: 设备管理服务实现

#### 2.1 设备注册与Token生成

```go
// services/core/device/device_service.go
package device

import (
    "context"
    "database/sql"
    "encoding/json"
    "fmt"
    "time"
    "github.com/golang-jwt/jwt/v5"
    "github.com/google/uuid"
)

type DeviceService struct {
    db *sql.DB
}

// RegisterDeviceRequest 设备注册请求
type RegisterDeviceRequest struct {
    DeviceCode      string                 `json:"device_code" binding:"required"`
    DeviceName      string                 `json:"device_name" binding:"required"`
    DeviceType      string                 `json:"device_type" binding:"required"` // face_recognition/access_control/iot_sensor
    DeviceModel     string                 `json:"device_model"`
    Manufacturer    string                 `json:"manufacturer"`
    FirmwareVersion string                 `json:"firmware_version"`
    SDKVersion      string                 `json:"sdk_version"`
    IPAddress       string                 `json:"ip_address"`
    MACAddress      string                 `json:"mac_address"`
    Location        string                 `json:"location"`
    Config          map[string]interface{} `json:"config"`
    Metadata        map[string]interface{} `json:"metadata"`
}

// Device 设备信息
type Device struct {
    ID              int64                  `json:"id"`
    TenantID        int64                  `json:"tenant_id"`
    DeviceCode      string                 `json:"device_code"`
    DeviceName      string                 `json:"device_name"`
    DeviceType      string                 `json:"device_type"`
    DeviceModel     string                 `json:"device_model"`
    Manufacturer    string                 `json:"manufacturer"`
    FirmwareVersion string                 `json:"firmware_version"`
    SDKVersion      string                 `json:"sdk_version"`
    IPAddress       string                 `json:"ip_address"`
    MACAddress      string                 `json:"mac_address"`
    Location        string                 `json:"location"`
    Status          string                 `json:"status"` // online/offline/maintenance/error
    LastHeartbeat   *time.Time             `json:"last_heartbeat"`
    Config          map[string]interface{} `json:"config"`
    Metadata        map[string]interface{} `json:"metadata"`
    Token           string                 `json:"token,omitempty"`      // 仅注册时返回
    SecretKey       string                 `json:"secret_key,omitempty"` // 仅注册时返回
    CreatedAt       time.Time              `json:"created_at"`
    UpdatedAt       time.Time              `json:"updated_at"`
}

// RegisterDevice 注册新设备（参考神目SDK的设备初始化）
func (ds *DeviceService) RegisterDevice(ctx context.Context, tenantID int64, req RegisterDeviceRequest) (*Device, error) {
    // 1. 验证设备代码唯一性（租户级别）
    var existingID int64
    checkQuery := `SELECT id FROM zervigo_smart_devices WHERE tenant_id = $1 AND device_code = $2 AND deleted_at IS NULL`
    err := ds.db.QueryRowContext(ctx, checkQuery, tenantID, req.DeviceCode).Scan(&existingID)
    if err == nil {
        return nil, fmt.Errorf("设备代码已存在: %s", req.DeviceCode)
    }
    if err != sql.ErrNoRows {
        return nil, fmt.Errorf("检查设备代码失败: %w", err)
    }
    
    // 2. 准备配置（默认配置）
    defaultConfig := map[string]interface{}{
        "detect_mode":      "video",        // 参考神目SDK的DETECT_MODE_VIDEO
        "liveness_type":    "rgb",          // 参考神目SDK的LIVENESS_TYPE_RGB
        "fast_mode":        false,          // 参考神目SDK的setFastMode
        "detect_fps":       30,             // 检测帧率
        "cache_size":       1000,           // 缓存大小
        "algorithm_version": "1.0.0",       // 算法版本
        "update_required":  false,          // 是否需要更新
    }
    
    // 合并用户提供的配置
    if req.Config != nil {
        for k, v := range req.Config {
            defaultConfig[k] = v
        }
    }
    
    configJSON, _ := json.Marshal(defaultConfig)
    metadataJSON, _ := json.Marshal(req.Metadata)
    
    // 3. 创建设备记录
    insertQuery := `
        INSERT INTO zervigo_smart_devices 
        (tenant_id, device_code, device_name, device_type, device_model, manufacturer,
         firmware_version, sdk_version, ip_address, mac_address, location, status, 
         config, metadata, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'offline', $12, $13, NOW(), NOW())
        RETURNING id
    `
    
    var deviceID int64
    err = ds.db.QueryRowContext(ctx, insertQuery,
        tenantID, req.DeviceCode, req.DeviceName, req.DeviceType, req.DeviceModel,
        req.Manufacturer, req.FirmwareVersion, req.SDKVersion, req.IPAddress,
        req.MACAddress, req.Location, configJSON, metadataJSON).Scan(&deviceID)
    if err != nil {
        return nil, fmt.Errorf("创建设备失败: %w", err)
    }
    
    // 4. 生成设备Token（参考神目SDK的APP_KEY/APP_SECRET机制）
    token, secretKey, err := ds.generateDeviceToken(ctx, deviceID, tenantID)
    if err != nil {
        return nil, fmt.Errorf("生成设备Token失败: %w", err)
    }
    
    // 5. 获取设备信息
    device, err := ds.GetDevice(ctx, deviceID)
    if err != nil {
        return nil, err
    }
    
    device.Token = token
    device.SecretKey = secretKey
    
    return device, nil
}

// generateDeviceToken 生成设备Token（参考神目SDK的认证机制）
func (ds *DeviceService) generateDeviceToken(ctx context.Context, deviceID, tenantID int64) (string, string, error) {
    // 生成设备密钥（类似神目SDK的APP_SECRET）
    secretKey := generateSecretKey()
    
    // 生成JWT Token（长期有效，类似神目SDK的APP_KEY）
    claims := jwt.MapClaims{
        "device_id": deviceID,
        "tenant_id": tenantID,
        "type":      "device",
        "exp":       time.Now().Add(365 * 24 * time.Hour).Unix(), // 1年有效期
        "iat":       time.Now().Unix(),
        "jti":       uuid.New().String(), // 唯一标识
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    tokenString, err := token.SignedString([]byte(secretKey))
    if err != nil {
        return "", "", err
    }
    
    // 存储Token到数据库
    insertQuery := `
        INSERT INTO zervigo_device_tokens (device_id, tenant_id, token, secret_key, expires_at, created_at)
        VALUES ($1, $2, $3, $4, $5, NOW())
    `
    expiresAt := time.Now().Add(365 * 24 * time.Hour)
    _, err = ds.db.ExecContext(ctx, insertQuery, deviceID, tenantID, tokenString, secretKey, expiresAt)
    if err != nil {
        return "", "", err
    }
    
    return tokenString, secretKey, nil
}

func generateSecretKey() string {
    return uuid.New().String() + uuid.New().String() // 64字符密钥
}
```

---

#### 2.2 设备心跳机制（参考神目SDK的心跳设计）

```go
// UpdateDeviceHeartbeat 更新设备心跳（参考神目SDK的心跳机制）
func (ds *DeviceService) UpdateDeviceHeartbeat(ctx context.Context, deviceID int64, ipAddress string) error {
    // 更新设备状态为online，更新心跳时间
    updateQuery := `
        UPDATE zervigo_smart_devices 
        SET status = 'online', last_heartbeat = NOW(), updated_at = NOW(),
            ip_address = COALESCE($2, ip_address)
        WHERE id = $1
    `
    
    result, err := ds.db.ExecContext(ctx, updateQuery, deviceID, ipAddress)
    if err != nil {
        return fmt.Errorf("更新心跳失败: %w", err)
    }
    
    rowsAffected, _ := result.RowsAffected()
    if rowsAffected == 0 {
        return fmt.Errorf("设备不存在: %d", deviceID)
    }
    
    // 检查设备是否长时间未心跳（超过5分钟视为离线）
    checkQuery := `
        UPDATE zervigo_smart_devices 
        SET status = 'offline'
        WHERE id = $1 AND last_heartbeat < NOW() - INTERVAL '5 minutes'
    `
    ds.db.ExecContext(ctx, checkQuery, deviceID)
    
    return nil
}

// CheckDeviceStatus 检查设备状态（后台任务）
func (ds *DeviceService) CheckDeviceStatus(ctx context.Context) error {
    // 将超过5分钟未心跳的设备标记为离线
    updateQuery := `
        UPDATE zervigo_smart_devices 
        SET status = 'offline', updated_at = NOW()
        WHERE status = 'online' 
        AND last_heartbeat < NOW() - INTERVAL '5 minutes'
    `
    _, err := ds.db.ExecContext(ctx, updateQuery)
    return err
}
```

---

#### 2.3 配置下发机制（参考神目SDK的动态配置更新）

```go
// GetDeviceConfig 获取设备配置（参考神目SDK的FaceConfig）
func (ds *DeviceService) GetDeviceConfig(ctx context.Context, deviceID int64) (map[string]interface{}, error) {
    query := `SELECT config FROM zervigo_smart_devices WHERE id = $1 AND deleted_at IS NULL`
    var configJSON []byte
    
    err := ds.db.QueryRowContext(ctx, query, deviceID).Scan(&configJSON)
    if err != nil {
        return nil, fmt.Errorf("获取设备配置失败: %w", err)
    }
    
    var config map[string]interface{}
    if err := json.Unmarshal(configJSON, &config); err != nil {
        return nil, fmt.Errorf("解析配置失败: %w", err)
    }
    
    return config, nil
}

// UpdateDeviceConfig 更新设备配置（服务端下发，参考神目SDK的动态算法更新）
func (ds *DeviceService) UpdateDeviceConfig(ctx context.Context, deviceID int64, config map[string]interface{}) error {
    configJSON, err := json.Marshal(config)
    if err != nil {
        return fmt.Errorf("序列化配置失败: %w", err)
    }
    
    updateQuery := `
        UPDATE zervigo_smart_devices 
        SET config = $1, updated_at = NOW()
        WHERE id = $2 AND deleted_at IS NULL
    `
    
    result, err := ds.db.ExecContext(ctx, updateQuery, configJSON, deviceID)
    if err != nil {
        return fmt.Errorf("更新配置失败: %w", err)
    }
    
    rowsAffected, _ := result.RowsAffected()
    if rowsAffected == 0 {
        return fmt.Errorf("设备不存在: %d", deviceID)
    }
    
    return nil
}

// PushAlgorithmUpdate 推送算法更新（参考神目SDK的动态算法更新机制）
func (ds *DeviceService) PushAlgorithmUpdate(ctx context.Context, deviceID int64, 
    algorithmVersion string, modelURL string) error {
    
    config, err := ds.GetDeviceConfig(ctx, deviceID)
    if err != nil {
        return err
    }
    
    // 更新配置，标记需要更新算法
    config["algorithm_version"] = algorithmVersion
    config["model_url"] = modelURL
    config["update_required"] = true
    config["update_time"] = time.Now().Unix()
    
    return ds.UpdateDeviceConfig(ctx, deviceID, config)
}
```

---

#### 2.4 数据同步服务（参考神目SDK的数据传输）

```go
// DeviceDataService 设备数据同步服务
type DeviceDataService struct {
    db *sql.DB
}

// SyncDeviceData 同步设备数据（设备上报，参考神目SDK的数据传输）
func (dds *DeviceDataService) SyncDeviceData(ctx context.Context, deviceID, tenantID int64,
    dataType string, dataContent map[string]interface{}) error {
    
    contentJSON, err := json.Marshal(dataContent)
    if err != nil {
        return fmt.Errorf("序列化数据失败: %w", err)
    }
    
    insertQuery := `
        INSERT INTO zervigo_device_data (device_id, tenant_id, data_type, data_content, created_at)
        VALUES ($1, $2, $3, $4, NOW())
    `
    
    _, err = dds.db.ExecContext(ctx, insertQuery, deviceID, tenantID, dataType, contentJSON)
    if err != nil {
        return fmt.Errorf("同步数据失败: %w", err)
    }
    
    return nil
}

// GetDeviceData 查询设备数据（按租户过滤）
func (dds *DeviceDataService) GetDeviceData(ctx context.Context, tenantID int64,
    deviceID *int64, dataType *string, startTime, endTime *time.Time) ([]DeviceData, error) {
    
    query := `
        SELECT id, device_id, tenant_id, data_type, data_content, created_at
        FROM zervigo_device_data
        WHERE tenant_id = $1
    `
    args := []interface{}{tenantID}
    argIndex := 2
    
    if deviceID != nil {
        query += fmt.Sprintf(" AND device_id = $%d", argIndex)
        args = append(args, *deviceID)
        argIndex++
    }
    
    if dataType != nil {
        query += fmt.Sprintf(" AND data_type = $%d", argIndex)
        args = append(args, *dataType)
        argIndex++
    }
    
    if startTime != nil {
        query += fmt.Sprintf(" AND created_at >= $%d", argIndex)
        args = append(args, *startTime)
        argIndex++
    }
    
    if endTime != nil {
        query += fmt.Sprintf(" AND created_at <= $%d", argIndex)
        args = append(args, *endTime)
        argIndex++
    }
    
    query += " ORDER BY created_at DESC LIMIT 1000"
    
    rows, err := dds.db.QueryContext(ctx, query, args...)
    if err != nil {
        return nil, fmt.Errorf("查询数据失败: %w", err)
    }
    defer rows.Close()
    
    var results []DeviceData
    for rows.Next() {
        var data DeviceData
        var contentJSON []byte
        
        err := rows.Scan(&data.ID, &data.DeviceID, &data.TenantID, &data.DataType, &contentJSON, &data.CreatedAt)
        if err != nil {
            return nil, fmt.Errorf("扫描数据失败: %w", err)
        }
        
        if err := json.Unmarshal(contentJSON, &data.DataContent); err != nil {
            return nil, fmt.Errorf("解析数据失败: %w", err)
        }
        
        results = append(results, data)
    }
    
    return results, nil
}
```

---

#### 2.5 设备认证中间件（参考神目SDK的认证机制）

```go
// services/core/device/device_auth.go
package device

import (
    "context"
    "database/sql"
    "fmt"
    "net/http"
    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v5"
)

type DeviceAuth struct {
    db *sql.DB
}

type DeviceClaims struct {
    DeviceID int64 `json:"device_id"`
    TenantID int64 `json:"tenant_id"`
    jwt.RegisteredClaims
}

// ValidateDeviceToken 验证设备Token（参考神目SDK的认证验证）
func (da *DeviceAuth) ValidateDeviceToken(tokenString string) (*DeviceClaims, error) {
    // 1. 从数据库查询Token信息
    query := `
        SELECT dt.device_id, dt.tenant_id, dt.secret_key, dt.expires_at, d.status, d.deleted_at
        FROM zervigo_device_tokens dt
        JOIN zervigo_smart_devices d ON dt.device_id = d.id
        WHERE dt.token = $1 AND dt.expires_at > NOW()
    `
    
    var deviceID, tenantID int64
    var secretKey string
    var expiresAt time.Time
    var status string
    var deletedAt sql.NullTime
    
    err := da.db.QueryRow(query, tokenString).Scan(&deviceID, &tenantID, &secretKey, &expiresAt, &status, &deletedAt)
    if err != nil {
        return nil, fmt.Errorf("设备Token不存在或已过期")
    }
    
    // 2. 检查设备状态
    if deletedAt.Valid {
        return nil, fmt.Errorf("设备已删除")
    }
    
    if status == "error" || status == "maintenance" {
        return nil, fmt.Errorf("设备状态异常: %s", status)
    }
    
    // 3. 验证JWT Token
    token, err := jwt.ParseWithClaims(tokenString, &DeviceClaims{}, func(token *jwt.Token) (interface{}, error) {
        if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
            return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
        }
        return []byte(secretKey), nil
    })
    
    if err != nil || !token.Valid {
        return nil, fmt.Errorf("Token验证失败")
    }
    
    claims, ok := token.Claims.(*DeviceClaims)
    if !ok {
        return nil, fmt.Errorf("Token Claims类型错误")
    }
    
    // 4. 验证设备ID和租户ID匹配
    if claims.DeviceID != deviceID || claims.TenantID != tenantID {
        return nil, fmt.Errorf("Token信息不匹配")
    }
    
    return claims, nil
}

// DeviceAuthMiddleware 设备认证中间件（参考神目SDK的认证中间件）
func DeviceAuthMiddleware(deviceAuth *DeviceAuth) gin.HandlerFunc {
    return func(c *gin.Context) {
        // 从请求头获取设备Token
        deviceToken := c.GetHeader("X-Device-Token")
        if deviceToken == "" {
            response.ErrorResponse(c, http.StatusUnauthorized, "设备Token缺失", "")
            c.Abort()
            return
        }
        
        // 验证Token
        claims, err := deviceAuth.ValidateDeviceToken(deviceToken)
        if err != nil {
            response.ErrorResponse(c, http.StatusUnauthorized, "设备Token无效", err.Error())
            c.Abort()
            return
        }
        
        // 设置到context
        ctx := context.WithValue(c.Request.Context(), "device_id", claims.DeviceID)
        ctx = context.WithValue(ctx, "tenant_id", claims.TenantID)
        c.Request = c.Request.WithContext(ctx)
        
        c.Next()
    }
}
```

---

### Phase 3: 设备端SDK封装（参考神目SDK设计）

```go
// 设备端Go SDK（参考神目SDK的FaceEngine设计）
package device_sdk

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
    "time"
)

type DeviceSDK struct {
    serverURL   string
    deviceToken string
    deviceID    int64
    tenantID    int64
    httpClient  *http.Client
    heartbeatInterval time.Duration
    stopHeartbeat chan bool
}

// NewDeviceSDK 初始化设备SDK（参考神目SDK的FaceEngine.init）
func NewDeviceSDK(serverURL, deviceToken string) (*DeviceSDK, error) {
    sdk := &DeviceSDK{
        serverURL:   serverURL,
        deviceToken: deviceToken,
        httpClient: &http.Client{
            Timeout: 10 * time.Second,
        },
        heartbeatInterval: 30 * time.Second, // 默认30秒心跳
        stopHeartbeat: make(chan bool),
    }
    
    // 验证Token并获取设备信息
    if err := sdk.validateAndInit(); err != nil {
        return nil, err
    }
    
    return sdk, nil
}

// validateAndInit 验证Token并初始化设备信息
func (sdk *DeviceSDK) validateAndInit() error {
    // 调用验证接口获取设备信息
    // ...
    return nil
}

// SendHeartbeat 发送心跳（参考神目SDK的心跳机制）
func (sdk *DeviceSDK) SendHeartbeat() error {
    url := fmt.Sprintf("%s/api/v1/devices/heartbeat", sdk.serverURL)
    req, _ := http.NewRequest("POST", url, nil)
    req.Header.Set("X-Device-Token", sdk.deviceToken)
    
    resp, err := sdk.httpClient.Do(req)
    if err != nil {
        return fmt.Errorf("心跳发送失败: %w", err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return fmt.Errorf("心跳失败: %d", resp.StatusCode)
    }
    
    return nil
}

// StartHeartbeatLoop 启动心跳循环（参考神目SDK的后台任务）
func (sdk *DeviceSDK) StartHeartbeatLoop() {
    go func() {
        ticker := time.NewTicker(sdk.heartbeatInterval)
        defer ticker.Stop()
        
        for {
            select {
            case <-ticker.C:
                sdk.SendHeartbeat()
            case <-sdk.stopHeartbeat:
                return
            }
        }
    }()
}

// StopHeartbeatLoop 停止心跳循环
func (sdk *DeviceSDK) StopHeartbeatLoop() {
    close(sdk.stopHeartbeat)
}

// GetConfig 获取设备配置（参考神目SDK的FaceConfig）
func (sdk *DeviceSDK) GetConfig() (map[string]interface{}, error) {
    url := fmt.Sprintf("%s/api/v1/devices/config", sdk.serverURL)
    req, _ := http.NewRequest("GET", url, nil)
    req.Header.Set("X-Device-Token", sdk.deviceToken)
    
    resp, err := sdk.httpClient.Do(req)
    if err != nil {
        return nil, fmt.Errorf("获取配置失败: %w", err)
    }
    defer resp.Body.Close()
    
    var result struct {
        Code int                    `json:"code"`
        Data map[string]interface{} `json:"data"`
    }
    
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, fmt.Errorf("解析配置失败: %w", err)
    }
    
    if result.Code != 0 {
        return nil, fmt.Errorf("获取配置失败: code=%d", result.Code)
    }
    
    return result.Data, nil
}

// SyncData 同步数据到服务端（参考神目SDK的数据传输）
func (sdk *DeviceSDK) SyncData(dataType string, dataContent map[string]interface{}) error {
    url := fmt.Sprintf("%s/api/v1/devices/data", sdk.serverURL)
    
    payload := map[string]interface{}{
        "data_type":    dataType,
        "data_content": dataContent,
    }
    
    jsonData, _ := json.Marshal(payload)
    req, _ := http.NewRequest("POST", url, bytes.NewBuffer(jsonData))
    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("X-Device-Token", sdk.deviceToken)
    
    resp, err := sdk.httpClient.Do(req)
    if err != nil {
        return fmt.Errorf("同步数据失败: %w", err)
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != http.StatusOK {
        return fmt.Errorf("同步数据失败: %d", resp.StatusCode)
    }
    
    return nil
}

// CheckAlgorithmUpdate 检查算法更新（参考神目SDK的动态算法更新）
func (sdk *DeviceSDK) CheckAlgorithmUpdate() (bool, string, string, error) {
    config, err := sdk.GetConfig()
    if err != nil {
        return false, "", "", err
    }
    
    if updateRequired, ok := config["update_required"].(bool); ok && updateRequired {
        algorithmVersion := ""
        modelURL := ""
        
        if v, ok := config["algorithm_version"].(string); ok {
            algorithmVersion = v
        }
        if v, ok := config["model_url"].(string); ok {
            modelURL = v
        }
        
        return true, algorithmVersion, modelURL, nil
    }
    
    return false, "", "", nil
}
```

---

## 🎯 实施计划

### Week 1: 数据库和基础服务

**Day 1-2**: 数据库迁移
- [ ] 创建设备表
- [ ] 创建设备Token表
- [ ] 创建设备数据表
- [ ] 创建索引

**Day 3-4**: 设备管理服务
- [ ] 实现设备注册
- [ ] 实现设备Token生成
- [ ] 实现设备查询和更新

**Day 5**: 设备认证中间件
- [ ] 实现Token验证
- [ ] 实现认证中间件

---

### Week 2: 核心功能实现

**Day 1-2**: 心跳和配置管理
- [ ] 实现心跳机制
- [ ] 实现配置获取和更新
- [ ] 实现算法更新推送

**Day 3-4**: 数据同步服务
- [ ] 实现数据上报
- [ ] 实现数据查询（按租户过滤）
- [ ] 实现数据统计

**Day 5**: API端点
- [ ] 实现设备管理API
- [ ] 实现数据同步API
- [ ] 实现配置管理API

---

### Week 3: 设备端SDK和测试

**Day 1-3**: 设备端SDK
- [ ] 实现设备SDK封装
- [ ] 实现心跳循环
- [ ] 实现配置获取
- [ ] 实现数据同步

**Day 4-5**: 测试和文档
- [ ] 单元测试
- [ ] 集成测试
- [ ] API文档
- [ ] SDK使用文档

---

## 📝 总结

### ✅ 核心功能实现

1. **多租户设备隔离**: ✅ 数据库设计支持租户隔离
2. **设备Token认证**: ✅ JWT Token + 密钥机制
3. **心跳机制**: ✅ 30秒心跳，5分钟超时检测
4. **配置下发**: ✅ 支持远程配置更新和算法更新
5. **数据同步**: ✅ 设备数据实时同步到服务端
6. **离线/在线双模式**: ✅ 支持设备状态管理

### 🎯 与神目SDK的对应关系

| 神目SDK功能 | GoZervi实现 | 状态 |
|------------|------------|------|
| FaceEngine.init | DeviceService.RegisterDevice | ✅ 已设计 |
| APP_KEY/APP_SECRET | DeviceToken + SecretKey | ✅ 已设计 |
| FaceConfig | DeviceConfig (JSONB) | ✅ 已设计 |
| 心跳机制 | UpdateDeviceHeartbeat | ✅ 已设计 |
| 动态算法更新 | PushAlgorithmUpdate | ✅ 已设计 |
| 数据传输 | SyncDeviceData | ✅ 已设计 |

---

**分析完成时间**: 2025-01-XX  
**神目源码位置**: `/Users/szjason72/shenmou`  
**预计实施时间**: 3周（分阶段实施）

