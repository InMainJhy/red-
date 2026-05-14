# Time Persona 前端 API 接入文档

最后更新：2026-04-08

## 1. 概述

本文档描述了前端如何接入后端 Time Persona Backend API。已完成的接入点位于 `entry/src/main/ets/service/PersonaApi.ets`。

## 2. 后端服务地址

### 线上服务（已接入）
```
https://hackhathon.69d5c46af2ab61f5dd649c62.servers.onzeabur.com
```

### 超时配置
| 接口 | 超时时间 |
|------|---------|
| `/api/presets` | 15s |
| `/api/profiles/:id` | 20s |
| `/api/timeline/parse` | 180s |
| `/api/agents/build` | 180s |
| `/api/arena/run` | 300s |
| `/api/arena/stream` | 300s |

## 3. 已实现的 API 方法

### 3.1 健康检查
```typescript
PersonaApi.checkHealth(): Promise<HealthCheckResponse | null>
```
检查后端服务状态，返回服务信息和导入状态。

### 3.2 获取预设人物列表
```typescript
PersonaApi.getPresets(): Promise<PresetProfile[]>
```
获取默认人物卡片列表。

### 3.3 获取人物完整数据
```typescript
PersonaApi.getProfileBundle(profileId: string): Promise<ProfileBundle>
```
获取某个人物的完整 bundle，包含 profile、nodes、agents 和 sourceDocument。

### 3.4 获取选中的 Agents
```typescript
PersonaApi.getSelectedAgents(profileId: string, selectedAgentIds: string[]): Promise<SelectedAgentsBundle>
```
获取指定人物的选中 agents。

### 3.5 创建自定义人物
```typescript
PersonaApi.importCustomProfile(displayName: string, biography: string): Promise<ProfileBundle>
```
根据用户输入的 displayName + biography 生成时间线节点和人格 agents。

### 3.6 运行 Arena 讨论（非流式）
```typescript
PersonaApi.runArena(topic: string, selectedAgents: PersonaSpec[], mode: ArenaMode): Promise<ArenaRun>
```
一次性返回完整的 arena 结果。

### 3.7 运行 Arena 讨论（流式）
```typescript
PersonaApi.streamArena(
  topic: string,
  selectedAgents: PersonaSpec[],
  mode: ArenaMode,
  onEvent?: SSEEventHandler,
  onError?: SSEErrorHandler,
  onComplete?: SSECompleteHandler
): Promise<void>
```
以 SSE 方式实时返回 arena 执行过程。

## 4. 数据类型

所有数据类型定义位于 `entry/src/main/ets/common/Models.ets`。

### 4.1 核心类型

| 类型 | 说明 |
|------|------|
| `PresetProfile` | 人物卡片信息 |
| `TimelineNode` | 时间线节点 |
| `PersonaSpec` | 人格 Agent 规格 |
| `ArenaMessage` | Arena 消息 |
| `ArenaRun` | Arena 运行结果 |

### 4.2 枚举类型

| 枚举 | 值 |
|------|---|
| `ArenaMode` | `'chat'` \| `'debate'` |
| `TimelineStageType` | `'early'` \| `'turning-point'` \| `'stable'` \| `'crisis'` \| `'rebuild'` \| `'peak'` |
| `ArenaStance` | `'support'` \| `'oppose'` \| `'reflective'` \| `'neutral'` |
| `ArenaPhase` | `'opening'` \| `'reflection'` \| `'rebuttal'` \| `'synthesis'` \| `'closing'` |

## 5. SSE 流式事件类型

流式接口返回的事件类型：

| 事件类型 | 说明 |
|----------|------|
| `run_started` | 开始运行 |
| `phase_started` | 阶段开始 |
| `message` | 新消息 |
| `phase_completed` | 阶段完成 |
| `summary_started` | 总结开始 |
| `summary` | 总结内容 |
| `done` | 完成 |
| `error` | 错误 |

## 6. 页面集成情况

| 页面 | 使用的 API |
|------|----------|
| `Index.ets` | `getPresets()`, `getProfileBundle()`, `importCustomProfile()`, `runArena()` |
| `ProfileDetail.ets` | `getProfileBundle()` |
| `Arena.ets` | `getSelectedAgents()`, `runArena()` |
| `CreateRole.ets` | `importCustomProfile()` |

## 7. 错误处理

API 服务已内置以下错误处理：

1. **自动降级**：当线上服务不可用时，自动使用 Mock 数据
2. **连接状态指示**：`PersonaApi.getConnectionLabel()` 返回当前连接状态
3. **字段级错误提示**：解析 Zod 验证错误

## 8. 注意事项

1. **不要只传 `selectedAgentIds` 给 arena**，必须把完整 `agents[]` 一起传
2. **不要假设 `personId` 一定是英文 slug**，中文也是可能的
3. **首屏不要把列表接口和详情接口串行绑死**
4. **SSE 要忽略 `: ping` 心跳消息**
5. **自定义人物创建需要 biography 至少 10 个字符**
