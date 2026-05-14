# Harmony Meeting Persistence And Summary Sync Design

**Background**

Harmony 端当前把会议配置和参会人格主要保存在 `MeetingSessionStore` 的静态内存里，应用重启后状态会全部丢失。与此同时，会议结束后的结果仍然主要停留在 `MeetingChatPage`，而不是稳定沉淀到纪要数据源，导致“历史会议”和“纪要”在产品层面职责混杂。

本次调整目标是收紧主流程，让“会议”“历史会议”“纪要”三者边界明确，并让用户重开应用后仍能延续上一次使用状态。

## Goals

- 会议配置与最近会议上下文在 Harmony 端持久化，重开应用后不再重置为全新状态。
- 首页“历史会议”只展示可续聊的会议记录，点击后直接继续上一次会议。
- 每次会议完成后自动生成并保存纪要，同步进入纪要列表。
- 会议页不再承担纪要结果页职责，会议完成后仅停留当前页并提示“已同步到纪要”。
- 首页参数面板移除“轮数”，仅保留 `agent 准度`。

## Non-Goals

- 不修改 Web 端与 `time-persona-web` 端行为。
- 不新增“会议完成后自动跳转纪要页”。
- 不重构后端历史会议接口协议，只在 Harmony 端调整消费方式。
- 不在本轮引入新的会议分类、筛选或复杂归档逻辑。

## Product Rules

### 1. 首页历史会议

- 首页里的“历史会议”是会议 history 数据源，不是纪要数据源。
- 历史会议条目点击后，进入 `MeetingChatPage` 并携带该场会议的 `runId`、`sessionId`、参会人格、议题等信息，用于继续发问。
- 如果历史记录缺少继续会议所需的参会人格信息，则给出错误提示，但不跳去纪要页兜底。

### 2. 纪要页

- 纪要页只展示自动同步生成的会议纪要。
- 每场会议完成一次，就生成一条纪要记录。
- 纪要数据优先通过 `SummaryService` 读取，不再把 arena history 直接当作纪要列表主数据源。

### 3. 会议页

- 会议页只负责发起会议、展示会议过程、以及基于历史会议继续发问。
- 会议完成后停留在当前会议页，不自动跳首页、不自动跳纪要页。
- 会议完成后给出轻提示，告知用户该次结果已同步到纪要。
- 会议页不再把“查看纪要结果”作为主承接体验，不再依赖会议页内部结果卡充当纪要页。

### 4. 参数面板

- 删除会议轮数设置。
- 全链路只保留 `reasoningEffort` 作为会议参数。
- 所有路由参数、状态读写、文案展示里与 `roundCount` 相关的逻辑一并移除或失效化。

## Technical Design

### A. 会议会话持久化

当前 `MeetingSessionStore` 仅使用静态字段，应用进程销毁后状态丢失。本次将其升级为“内存 + 本地 Preferences 持久化”的轻量会话存储：

- 持久化字段：
  - `profileId`
  - `profileIds`
  - `selectedAgentIds`
  - `topic`
  - `reasoningEffort`
  - 最近一次可续聊会议上下文：`continueFromRunId`、`sessionId`
- 首页、选角页、会议页在读取会话状态时优先读内存，冷启动时自动从本地恢复。
- 当用户重新选人、开始会议、继续会议时，同步刷新本地存储。

这样可以满足“重开软件后，不需要重新选择角色和重新开始”的核心诉求。

### B. 会议完成后自动写入纪要

`SummaryService` 已具备本地存储与 `createSummary(arenaRun, profileId)` 能力，本次将会议完成事件正式接入这条链路：

- 在 `MeetingChatPage` 收到流式 `done` 结果或普通模式 `runArena` 完成后，整理当前 `ArenaRun` 数据。
- 调用 `SummaryService.createSummary(...)` 自动写入纪要。
- 为避免同一 `runId` 因流式完成、回放加载、页面恢复而重复创建纪要，增加去重策略：
  - 优先按 `arenaRunId/runId` 查重；
  - 已存在则更新本地记录而不是重复新增。

### C. 首页与纪要页数据边界

- 首页 `Index.ets` 中的历史会议区域继续消费 `PersonaApi.getArenaHistory(...)`。
- `SummaryListPage.ets` 改为优先消费 `SummaryService.getSummaryList(...)`，只展示纪要记录，不直接把 history 当作纪要。
- `SummaryDetailPage.ets` 保持兼容：
  - 从 `summaryId` 打开时读取正式纪要；
  - 从旧的 `arenaRunId` 打开时仍可回看；
  - 但主入口改为纪要记录。

### D. 会议页结果承接收口

- 保留会议过程消息流和“继续发问”输入框。
- 会议完成时仅展示完成态和“已同步到纪要”的提示。
- 弱化或移除“在会议页直接打开纪要详情”的主按钮，避免会议页继续承担纪要承接。

### E. 删除轮数参数

需要同时收口以下位置：

- `MeetingSessionStore` 删除 `roundCount` 字段及对应读写接口。
- `Index.ets` 删除参数面板里的轮数 UI、默认值、保存逻辑、路由透传。
- `MeetingChatPage.ets` 删除对路由 `roundCount` 和本地 `roundCount` 的依赖。
- 会议调用 API 时使用后端默认轮数，不再由前端传入用户可配置轮数。

## Error Handling

- 持久化初始化失败时，不阻塞页面打开，回退到内存态，并输出日志。
- 自动写纪要失败时，不影响会议完成本身；会议页提示“会议已完成，纪要同步失败”。
- 继续历史会议时，如果记录缺少 `selectedAgentIds` 或 `profileIds`，保留现有错误提示并阻止进入错误状态。

## Testing Focus

- 冷启动后首页是否恢复上一次选择的人物和参会人格。
- 完成一场会议后，纪要页是否出现新增纪要。
- 首页历史会议点击后是否进入续聊，而不是进入纪要页。
- 会议完成后是否仍停留在会议页，并显示“已同步到纪要”提示。
- 参数面板里是否只剩 `agent 准度`。
- 旧的通过 `arenaRunId` 打开的纪要详情是否仍兼容。

## Risks And Mitigations

- `SummaryService` 当前只在 `SummaryDetailPage` 显式初始化。
  - 需要把初始化前置到首页/会议页可用的时机，避免首次自动写纪要失败。
- arena history 与 summary 本地存储短期内会并存两套数据源。
  - 通过“首页只看 history、纪要页只看 summary”明确职责，避免 UI 继续混用。
- 会议结果自动保存若无去重，会出现重复纪要。
  - 必须以 `arenaRunId` 作为幂等键处理。
