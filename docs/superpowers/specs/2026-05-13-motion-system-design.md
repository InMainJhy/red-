# Harmony UI Motion System Design

## Goal

为当前 Harmony 端已经完成视觉优化的页面补上一套统一、明显但不过度的动效系统。

目标不是“每个元素都动”，而是让页面切换、卡片出现、按钮点击、抽屉弹出这些核心交互拥有一致的节奏、层次和反馈，提升整体产品感。

## Scope

本轮只覆盖高频核心页面与公共交互组件：

- `Index.ets`
- `MeetingParticipantPage.ets`
- `MeetingChatPage.ets`
- `CreateRole.ets`
- `AIDialogueCreateRole.ets`
- `ExplorePersonas.ets`
- `UserCenter.ets`
- `SummaryListPage.ets`
- `SummaryDetailPage.ets`
- `ShareSheet.ets`
- 首页功能卡片、角色卡片、分享卡片、主要按钮等公共组件

不包含复杂 3D、长时间循环动画、粒子特效和重弹簧动画。

## Motion Direction

采用“明显一点”的统一动效风格：

- 页面进入：轻微横向滑入加淡入
- 区块出现：按视觉层级错峰出现
- 卡片进入：小幅上浮或横移进入
- 抽屉/弹层：底部上浮进入
- 点击反馈：卡片轻压，按钮更明显一点

核心原则：

- 动效必须服务信息层级，不抢内容
- 同类元素使用同一节奏
- 主流程页比次级页更明显
- 列表项和消息项只做轻动效，避免吵

## Motion Tokens

基于现有 `common/styles/Animation.ets` 扩展统一 token，不在各页面写散乱 magic number。

新增或统一如下语义：

- `pageEnterOffsetX`: `24 ~ 32`
- `sectionEnterOffsetY`: `14 ~ 20`
- `cardEnterOffsetY`: `12 ~ 16`
- `sheetEnterOffsetY`: `28 ~ 36`
- `staggerStepMs`: `56 ~ 72`
- `pressScaleCard`: `0.97 ~ 0.98`
- `pressScaleButton`: `0.95 ~ 0.97`

时长策略：

- 页面进入：`280 ~ 320ms`
- 分段出现：`220 ~ 280ms`
- 点击压缩：`120 ~ 160ms`
- 抽屉弹出：`260 ~ 320ms`

曲线策略：

- 页面/区块进入：`EaseOut` / `FastOutSlowIn`
- 按下：`EaseIn`
- 回弹：`EaseOut`

## Page Patterns

### 1. Page Enter

所有核心页统一支持：

- 页面根容器初始 `opacity < 1`
- 同时带少量 `translateX`
- `aboutToAppear` 触发后进入最终状态

这样保证从一个页面进入另一个页面时，有稳定的系统级切页感。

### 2. Section Stagger

每个页面按“顶部信息 / 主卡 / 次卡 / 操作区”拆成 2 到 4 段，而不是所有元素一起动。

例如首页：

- 顶部欢迎区
- 上次会议主卡
- 准备区
- 功能区 / 历史区

例如会议准备页：

- 顶部标题
- 说明卡
- 列表区
- 底部保存按钮

### 3. Cards

卡片默认使用：

- 淡入
- 轻微上浮或横向滑入
- 与所在 section 保持同节奏

首页功能卡、分享卡、设备卡、人格卡等都用同类模式。

### 4. Sheets & Overlays

分享抽屉、参数面板、底部弹层统一：

- 遮罩先淡入
- 面板从底部上浮
- 内部内容再做一拍轻错峰

不再让弹层内容和面板本体同时重动。

### 5. Press / Tap Feedback

所有主要可点击元素统一有按下反馈：

- 大卡片：轻微缩放 + 阴影收紧 + 轻下沉
- 主按钮：更明显的缩放与阴影变化
- 胶囊标签、小型入口：只保留轻量反馈

避免只依赖系统默认 `stateEffect(true)`，对关键卡片补充自定义反馈。

## Component Strategy

优先抽公共能力，减少重复实现。

建议新增：

- 页面进场辅助方法
- section stagger 辅助状态
- 通用卡片 press state 模式
- 通用底部抽屉 enter 模式

如果某个页面已有成熟动画（如 `MeetingParticipantPage.ets`），则对齐到统一 token，而不是推倒重写。

## Error Handling

需要避免以下问题：

- 页面返回时二次跳动
- Scroll 容器与 translate 叠加导致闪动
- 列表过长时全量动画影响性能
- 弹层关闭时内容与遮罩时序错乱

处理策略：

- 页面级动画只挂在稳定的根容器上
- 长列表只给首屏项做错峰
- 运行中消息列表只给新消息做轻动画
- 抽屉和遮罩时序统一

## Verification

实现后验证以下内容：

1. 页面进入时是否统一、是否有“轻滑入”感
2. 首页、会议页、创建角色页是否存在明显但不过度的错峰
3. 点击大卡片、主按钮时反馈是否足够清晰
4. 分享抽屉、参数面板是否从底部稳定浮入
5. 返回操作是否引入抖动、闪白或布局跳动
6. `hvigorw assembleApp --no-daemon` 的 `CompileArkTS` 是否通过

## Implementation Order

1. 扩展 `Animation.ets` 为统一 motion token
2. 统一公共点击反馈模式
3. 接入首页与会议主流程页面
4. 接入创建角色与探索人物页面
5. 接入纪要与分享相关弹层
6. 编译验证并做节奏微调
