# 项目现状梳理

最后更新：2026-05-12

## 1. 项目当前定位

当前仓库已经不是纯概念稿，而是一个以 HarmonyOS 端为核心的可演示项目。

主产品主题是：
围绕“同一个人不同人生阶段的人格切片”，进行多角色会议、对话和纪要沉淀。

## 2. 当前主流程

### 2.1 启动流程

- 入口能力：`harmony/entry/src/main/ets/entryability/EntryAbility.ets`
- 首屏页面：`pages/SplashPage`
- 启动视频结束后进入：`pages/Index`

### 2.2 首页工作台

核心页面：
`harmony/entry/src/main/ets/pages/Index.ets`

首页当前承担这些职责：

- 展示最近一次会议
- 进入角色准备
- 配置会议参数
- 进入分类人物 / 资料页
- 进入创建 / 导入
- 查看纪要
- 点击底部 `+` 直接进入会议对话

### 2.3 会议流程

当前会议主链路：

1. 首页工作台选择角色
2. 首页参数卡调整轮数与准度
3. 点击底部 `+`
4. 进入 `MeetingChatPage`
5. 用户在底部输入框输入议题并发送
6. 开始流式人格对话
7. 沉淀会议结果并进入纪要链路

相关页面：

- `harmony/entry/src/main/ets/pages/MeetingParticipantPage.ets`
- `harmony/entry/src/main/ets/pages/MeetingChatPage.ets`

### 2.4 资料与人物

当前人物相关页面：

- `ExplorePersonas.ets`
- `ProfileDetail.ets`
- `CreateRole.ets`
- `AIDialogueCreateRole.ets`
- `ImportProfilePage.ets`

### 2.5 纪要链路

当前纪要相关页面：

- `SummaryListPage.ets`
- `SummaryDetailPage.ets`
- 首页底部纪要 Tab：`RecordsTab.ets`

当前纪要能力包括：

- 浏览历史纪要
- 查看纪要详情
- 收藏 / 删除
- 导出海报入口
- 分享文案生成

## 3. 当前保留的核心前端模块

### 页面

- `Index`
- `SplashPage`
- `MeetingParticipantPage`
- `MeetingProfilePickerPage`
- `MeetingChatPage`
- `ExplorePersonas`
- `ProfileDetail`
- `CreateRole`
- `AIDialogueCreateRole`
- `ImportProfilePage`
- `SummaryListPage`
- `SummaryDetailPage`
- `PosterPreviewPage`
- `UserCenter`

### 服务层

- `PersonaApi.ets`
- `SummaryService.ets`
- `SmartFillService.ets`
- `GestureSenseService.ets`
- `ImageSuperResolutionService.ets`
- `NfcShareService.ets`

### 状态与工具

- `MeetingSessionStore.ets`
- `ProfileImportStore.ets`
- `MeetingSelection.ets`

## 4. 本轮已清理的废弃代码

已经移除以下旧分支 / 实验页：

- `pages/IndexV2`
- `pages/Arena`
- `pages/FusionWorkbench`
- `pages/SmartQuestionPrep`
- `components/ArenaHeader`
- `components/ArenaTab`
- 根目录预览文件 `background_design_preview.html`

同时移除了与这组旧页面绑定的遗留路由字段：

- `workbenchJson`
- `mergedAgentsJson`
- `debateTopic`
- `WorkbenchPickBrief`

## 5. 当前未完全收口的点

### 5.1 后端接口未完全对齐

前端接口层定义比当前 backend 实现更完整。
也就是说，前端“想调用”的能力，后端不一定都已经真有。

最明显的问题是：

- `PersonaApi.ets` 还保留 mock 路径
- `SummaryService.ets` 里依赖的 `/api/summaries` 系列接口，当前 backend 目录下并没有完整实现
- Arena 流式、历史、回放、海报等接口，前端已经接了，但 backend 当前代码并不完整

### 5.2 纪要数据源仍有分裂

当前纪要有两种数据来源：

- `PersonaApi.getArenaHistory()`
- `SummaryService`

如果后端要长期可维护，后续需要统一设计：

- 是全部以 arena history 为主
- 还是以 summaries 作为正式纪要资源

### 5.3 还缺真机收口验收

当前代码已经做了多轮 UI 和逻辑迭代，但还需要在 DevEco Studio / 真机上跑完一次完整链路。

## 6. 当前完成度判断

如果只看 Harmony 主流程，我会判断为：

- 结构与交互链路：已基本成型
- UI 风格：已建立统一方向
- 真实联调：未完全收口
- 可演示性：较高
- 可正式交付性：仍需一轮联调和稳定性验收

一个相对保守的结论是：
Harmony 主功能完成度约在 `80% ~ 85%`。

## 7. 当前建议优先级

### P0

- 完成后端缺失接口
- 关闭主流程 mock
- 跑通一次真机完整链路

### P1

- 统一纪要数据源
- 梳理错误提示与空态
- 进一步补全动效细节

### P2

- 再考虑补高级能力和实验功能
- 不建议在当前阶段重新引入多套会议流或工作台分支
