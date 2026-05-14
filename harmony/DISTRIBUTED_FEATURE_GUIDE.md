# 分布式特性技术说明

本项目已预留以下分布式特性的接入能力：

## 1. 分布式软总线（Distributed Bus）

### 技术方案
使用 `@kit.DistributedServiceKit` 进行设备发现和连接管理。

### 权限配置
```json5
"requestPermissions": [
  { "name": "ohos.permission.INTERNET" },
  { "name": "ohos.permission.NFC_TAG" },
  { "name": "ohos.permission.GET_BUNDLE_INFO" }
]
```

### 实现步骤
1. 在AGC后台配置设备信任关系
2. 调用 `distributedDeviceManager.createDeviceManager(bundleName)` 创建设备管理器
3. 使用 `startDiscovering()` 发现周围设备
4. 通过 `bindTarget()` 建立可信连接
5. 使用 `@kit.ArkData` 的 `distributedDataCloud` 进行数据同步

### 注意事项
- 设备需要在同一华为账号下
- 需要在设备设置中开启"跨设备协同"
- API调用需要放在异常处理中

---

## 2. 星闪连接（NearLink）

### 技术方案
使用 `@kit.ConnectivityKit` 中的星闪模块。

### 当前状态
星闪API在HarmonyOS NEXT 5.0 SDK中可能尚未完全开放，需要：
1. 确认设备支持星闪
2. 使用 `ohos.permission.ACCESS_NEARLINK` 权限
3. 调用 `nearLink` 模块进行设备扫描和连接

### 星闪优势
- 延迟：20μs（蓝牙为20ms）
- 传输速率：12Mbps
- 抗干扰能力强

---

## 3. App Linking（元服务免安装分发）

### 这是最容易实现的功能

App Linking 允许通过链接直接打开应用的指定页面，支持免安装分发。

### 配置步骤

#### 步骤1：在AGC后台配置
1. 登录 [AGC控制台](https://developer.huawei.com/consumer/cn/service/josp/agc/)
2. 进入"用户与访问" > "App Linking"
3. 添加关联域名（如：`hackathon.huawei.com`）
4. 创建链接前缀（如：`https://hackathon.huawei.com/app`）

#### 步骤2：在module.json5中配置skills
```json5
"abilities": [
  {
    "name": "EntryAbility",
    "skills": [
      {
        "entities": ["entity.system.home"],
        "actions": ["ohos.want.action.home"]
      },
      {
        "entities": [],
        "actions": ["ohos.intent.action.VIEW"]
      }
    ]
  }
]
```

#### 步骤3：生成分享链接
在代码中使用 Want 参数传递深度链接：
```typescript
import { common, Want } from '@kit.AbilityKit';

function openDeepLink(context: common.UIAbilityContext, path: string): void {
  const link = `https://hackathon.huawei.com/app${path}`;
  const want: Want = {
    action: 'ohos.intent.action.VIEW',
    uri: link
  };
  context.startAbility(want);
}

// 分享会议纪要
openDeepLink(context, '/meeting-summary?id=xxx&title=xxx');

// 分享角色资料
openDeepLink(context, '/persona-profile?id=xxx');
```

#### 步骤4：处理深度链接
在 EntryAbility 中接收：
```typescript
onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  const uri = want.uri?.toString() || '';
  if (uri.includes('/meeting-summary')) {
    // 跳转到会议纪要详情
  }
}
```

---

## 4. 应用接续（App Continuation）

设备间应用状态的无缝切换。

### 实现方案
1. 使用 `@kit.ArkData` 保存应用状态到分布式数据库
2. 在目标设备上读取状态并恢复UI

---

## 比赛建议

由于时间和设备限制，建议：

1. **优先实现 App Linking** - 只需配置AGC，无需复杂编码
2. **文档说明分布式能力** - 在PPT/文档中说明架构设计
3. **准备设备演示** - 如果有支持的手机/平板，展示NFC碰一碰分享
