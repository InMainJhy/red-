# Time Persona Backend API 文档

最后核对时间：2026-04-08  
核对方式：

- 对照后端代码：`backend/src/server.ts`、`backend/src/domain.ts`、`backend/src/schemas.ts`
- 对照当前线上服务实测：
  - `https://hackhathon.69d5c46af2ab61f5dd649c62.servers.onzeabur.com`

这份文档面向前端对接，按“当前服务器上的真实后端”来写，不按本地开发环境写。

## 1. 基本信息

### 1.1 Base URL

```txt
https://hackhathon.69d5c46af2ab61f5dd649c62.servers.onzeabur.com
```

### 1.2 协议与通用约定

- 所有普通接口均为 `JSON`
- 所有 `POST` 请求都使用：

```http
Content-Type: application/json
```

- 流式接口 `/api/arena/stream` 返回：

```http
Content-Type: text/event-stream; charset=utf-8
```

- 当前后端未做鉴权
- 已开启 CORS
- 字符编码按 UTF-8 处理

### 1.3 当前线上默认人物

2026-04-08 实测当前服务器已导入 6 个默认人物：

- `bernard-baruch`
- `steve-jobs`
- `elon-musk`
- `peter-lynch`
- `puyi`
- `warren-buffett`

### 1.4 前端接入时必须知道的事

- 默认人物链路：`GET /api/presets` -> `GET /api/profiles/:profileId`
- 自定义人物链路：`POST /api/timeline/parse` -> `POST /api/agents/build`
- `parse` 会把 profile + timeline 持久化进数据库
- `build` 会把 agents 持久化进数据库
- `arena` 接口要求传完整 `agents[]`，不是只传 `agentId[]`
- `selectedAgentIds` 只表示本次参会的人，最多 3 个，至少 2 个

## 2. 接口总览

| 方法 | 路径 | 用途 |
|---|---|---|
| `GET` | `/health` | 健康检查、运行时信息、默认人物导入状态 |
| `GET` | `/api/presets` | 获取默认人物列表 |
| `GET` | `/api/profiles/:profileId` | 获取某个人物的完整 bundle |
| `POST` | `/api/timeline/parse` | 从人物简介生成时间线节点 |
| `POST` | `/api/agents/build` | 根据时间线节点生成阶段人格 agents |
| `POST` | `/api/arena/run` | 一次性返回完整会议/辩论结果 |
| `POST` | `/api/arena/stream` | 以 SSE 方式实时返回会议/辩论过程 |
| `GET` | `/api/admin/import-status` | 查看默认人物导入状态 |
| `POST` | `/api/admin/import-defaults` | 触发重新导入默认人物 |

## 3. 推荐前端接入流程

### 3.1 默认人物

1. `GET /api/presets`
2. 展示人物卡片列表
3. 用户点击某个人物时，请求 `GET /api/profiles/:profileId`
4. 页面拿到：
   - `profile`
   - `nodes`
   - `agents`
   - `sourceDocument`

推荐：

- 首屏只拉 `presets`
- 详情 `profile bundle` 按需加载
- 已加载 bundle 做本地缓存

### 3.2 自定义人物

1. 用户输入 `displayName + biography`
2. 调 `POST /api/timeline/parse`
3. 拿到 `personId + nodes`
4. 调 `POST /api/agents/build`
5. 拿到 `agents`
6. 页面本地缓存：
   - `personId`
   - `displayName`
   - `nodes`
   - `agents`

说明：

- `parse` 和 `build` 都会写库
- 如果你后续再请求 `GET /api/profiles/:personId`，理论上也能拿回 bundle

### 3.3 Arena 讨论 / 辩论

1. 从当前人物的 `agents[]` 中选择 2 到 3 个 agent
2. 输入 `topic`
3. 选择模式：
   - `chat`
   - `debate`
4. 如果要“像聊天一样实时更新”，优先接 `POST /api/arena/stream`
5. 如果只要最终结果，接 `POST /api/arena/run`

## 4. 数据模型

## 4.1 `PresetProfile`

```ts
interface PresetProfile {
  id: string
  displayName: string
  subtitle: string
  category: 'self' | 'celebrity' | 'history' | 'fictional'
  coverSeed: string
  biography: string
  highlights: string[]
  suggestedTopics: string[]
}
```

字段说明：

- `id`: 人物主键，也是 `GET /api/profiles/:profileId` 的参数
- `displayName`: 人物显示名
- `subtitle`: 一句话定位
- `category`: 人物类别
- `coverSeed`: 头像/封面生成种子
- `biography`: 简版人物描述
- `highlights`: 亮点摘要
- `suggestedTopics`: 推荐讨论话题

## 4.2 `SourceEvidence`

```ts
interface SourceEvidence {
  quote: string
  sourceLabel: string
}
```

字段说明：

- `quote`: 引文或证据片段
- `sourceLabel`: 来源标签，比如书名、章节来源、`用户输入`

## 4.3 `TimelineNode`

```ts
interface TimelineNode {
  nodeId: string
  timeLabel: string
  ageLabel?: string
  stageLabel: string
  stageType: 'early' | 'turning-point' | 'stable' | 'crisis' | 'rebuild' | 'peak'
  keyEvent: string
  summary: string
  traits: string[]
  values: string[]
  tensions: string[]
  sourceEvidence: SourceEvidence[]
}
```

字段说明：

- `nodeId`: 节点 ID，通常形如 `steve-jobs-1`
- `timeLabel`: 时间标签
- `ageLabel`: 年龄标签，可选
- `stageLabel`: 阶段标题
- `stageType`: 阶段类型
- `keyEvent`: 该阶段核心事件
- `summary`: 阶段摘要
- `traits`: 人格特征关键词
- `values`: 价值观关键词
- `tensions`: 内在冲突
- `sourceEvidence`: 证据片段

## 4.4 `PersonaSpec`

```ts
interface PersonaSpec {
  agentId: string
  displayName: string
  personId: string
  avatarSeed: string
  timeLabel: string
  stageLabel: string
  keyEvent: string
  knownFacts: string[]
  sourceEvidence: SourceEvidence[]
  traits: string[]
  values: string[]
  goal: string
  fear: string
  voiceStyle: string
  knowledgeBoundary: string
  forbiddenFutureKnowledge: boolean
  stanceSeed: string
}
```

字段说明：

- `agentId`: agent 主键，通常形如 `${nodeId}-agent`
- `displayName`: 页面展示名
- `personId`: 所属人物 ID
- `avatarSeed`: 头像种子
- `timeLabel`: 所在阶段时间标签
- `stageLabel`: 所在阶段标题
- `keyEvent`: 阶段核心事件
- `knownFacts`: 当前阶段已知事实
- `sourceEvidence`: 证据片段
- `traits`: 人格特征
- `values`: 价值取向
- `goal`: 当前阶段目标
- `fear`: 当前阶段恐惧
- `voiceStyle`: 语气风格
- `knowledgeBoundary`: 认知边界
- `forbiddenFutureKnowledge`: 是否禁止知道未来
- `stanceSeed`: 在 arena 中的立场种子

## 4.5 `ProfileBundle`

```ts
interface ProfileBundle {
  profile: PresetProfile
  nodes: TimelineNode[]
  agents: PersonaSpec[]
  sourceDocument?: SourceDocumentSummary | null
}
```

## 4.6 `SourceDocumentSummary`

```ts
interface SourceDocumentSummary {
  id: string
  title: string
  author?: string | null
  filePath: string
  importedAt: string
  sectionCount: number
}
```

说明：

- 默认人物通常会有 `sourceDocument`
- 自定义人物通常没有，前端按可选字段处理

## 4.7 `ArenaMessage`

```ts
interface ArenaMessage {
  id: string
  agentId: string
  displayName: string
  stageLabel: string
  content: string
  stance: 'support' | 'oppose' | 'reflective' | 'neutral'
  round?: number
  phase?: 'opening' | 'reflection' | 'rebuttal' | 'synthesis' | 'closing'
  replyToAgentId?: string
  replyToDisplayName?: string
}
```

## 4.8 `ArenaSummary`

```ts
interface DebateJudgeScorecard {
  agentId: string
  displayName: string
  argumentScore: number
  evidenceScore: number
  responsivenessScore: number
  comments: string
}

interface DebateVerdict {
  winnerAgentId?: string
  winnerDisplayName?: string
  rationale: string
  scorecards: DebateJudgeScorecard[]
}

interface ArenaSummary {
  title: string
  consensus: string
  disagreements: string[]
  actionableAdvice: string[]
  narrativeHook: string
  moderatorNote?: string
  debateVerdict?: DebateVerdict
}
```

说明：

- `chat` 模式通常会有 `moderatorNote`
- `debate` 模式通常会有 `debateVerdict`

## 4.9 `ArenaRun`

```ts
interface ArenaRun {
  runId: string
  mode: 'chat' | 'debate'
  topic: string
  participants: PersonaSpec[]
  messages: ArenaMessage[]
  summary: ArenaSummary
}
```

## 5. 详细接口说明

## 5.1 `GET /health`

用途：

- 健康检查
- 查看数据库连通性
- 查看运行时配置
- 查看默认人物导入状态

### 请求

无参数

### 成功响应示例

线上 2026-04-08 实测：

```json
{
  "ok": true,
  "runtime": {
    "mode": "claude-agent-sdk",
    "claudeBinary": "/home/ubuntu/hackhathon/backend/node_modules/.bin/claude",
    "requestedModel": "gpt-5.4",
    "requestedEffort": "xhigh",
    "fallbackModel": "claude-opus-4-6",
    "fallbackEffort": "max",
    "unsupportedModels": []
  },
  "import": {
    "running": false,
    "lastImportedProfileIds": [
      "bernard-baruch",
      "steve-jobs",
      "elon-musk",
      "peter-lynch",
      "puyi",
      "warren-buffett"
    ],
    "lastRunAt": "2026-04-08T07:42:55.957Z",
    "documents": 6,
    "defaultProfiles": 6,
    "arenaRuns": 5,
    "libraryDir": "/home/ubuntu/library"
  },
  "timestamp": "2026-04-08T09:06:20.581Z"
}
```

### 失败响应

```json
{
  "ok": false,
  "error": "具体错误信息",
  "runtime": {
    "mode": "claude-agent-sdk"
  },
  "timestamp": "2026-04-08T09:06:20.581Z"
}
```

## 5.2 `GET /api/presets`

用途：

- 获取默认人物卡片列表

### 请求

无参数

### 成功响应结构

```ts
{
  presets: PresetProfile[]
}
```

### 成功响应示例

```json
{
  "presets": [
    {
      "id": "warren-buffett",
      "displayName": "沃伦·巴菲特",
      "subtitle": "基于传记抽取的关键人生阶段",
      "category": "celebrity",
      "coverSeed": "warren-buffett",
      "biography": "沃伦·巴菲特 的传记被拆分为多个关键人生阶段，用于生成跨时空对话人格。",
      "highlights": ["不作逢迎", "珠穆朗玛峰", "解体", "不眠之夜"],
      "suggestedTopics": [
        "这个人物是如何跨越关键转折点的？",
        "他在不同阶段最看重什么？",
        "早期人格和成熟期人格会如何互相评价？"
      ]
    }
  ]
}
```

### 前端建议

- 这是首页列表接口
- 不要把它和 `GET /api/profiles/:profileId` 串行绑死
- 建议先显示列表，再按需加载详情

## 5.3 `GET /api/profiles/:profileId`

用途：

- 获取某个人物的完整 bundle

### Path 参数

- `profileId: string`

### 成功响应结构

```ts
ProfileBundle
```

### 成功响应示例

结构如下：

```json
{
  "profile": {
    "id": "steve-jobs",
    "displayName": "史蒂夫·乔布斯",
    "subtitle": "在疯狂与天才之间扭曲现实的人",
    "category": "celebrity",
    "coverSeed": "steve-jobs",
    "biography": "基于传记素材整理出的五个关键阶段...",
    "highlights": ["..."],
    "suggestedTopics": ["..."]
  },
  "nodes": [
    {
      "nodeId": "steve-jobs-1",
      "timeLabel": "1972年前后",
      "stageLabel": "疯狂少年与精神觉醒",
      "stageType": "early",
      "keyEvent": "在反叛、极端饮食和精神探索中形成激情与冷漠并存的少年人格",
      "summary": "少年时期的极端敏感...",
      "traits": ["反叛", "敏感", "极端"],
      "values": ["自由", "纯粹", "感受力"],
      "tensions": ["追求精神性同时又强烈想控制现实"],
      "sourceEvidence": [
        {
          "quote": "目录...",
          "sourceLabel": "史蒂夫·乔布斯传（修订版）"
        }
      ]
    }
  ],
  "agents": [
    {
      "agentId": "steve-jobs-1-agent",
      "displayName": "史蒂夫·乔布斯 · 疯狂少年与精神觉醒",
      "personId": "steve-jobs",
      "avatarSeed": "steve-jobs-early",
      "timeLabel": "1972年前后",
      "stageLabel": "疯狂少年与精神觉醒",
      "keyEvent": "在反叛、极端饮食和精神探索中形成激情与冷漠并存的少年人格",
      "knownFacts": ["..."],
      "sourceEvidence": [{"quote": "...", "sourceLabel": "..."}],
      "traits": ["反叛", "敏感", "极端"],
      "values": ["自由", "纯粹", "感受力"],
      "goal": "证明自己不是普通人，而是能重新定义现实的人",
      "fear": "变成平庸、被忽略、像从未真正存在过一样",
      "voiceStyle": "年轻、尖锐、带一点神秘主义",
      "knowledgeBoundary": "只知道少年阶段的反叛...",
      "forbiddenFutureKnowledge": true,
      "stanceSeed": "如果一件事不能把人真正唤醒..."
    }
  ],
  "sourceDocument": {
    "id": "8a1b6309-79c9-4741-8eb8-42682865d05f",
    "title": "史蒂夫·乔布斯传（修订版）",
    "author": "[美]沃尔特·艾萨克森",
    "filePath": "/home/ubuntu/library/史蒂夫 · 乔布斯传....epub",
    "importedAt": "2026-04-08T07:42:32.426Z",
    "sectionCount": 54
  }
}
```

### 404

线上实测：

```json
{
  "error": "profile not found"
}
```

## 5.4 `POST /api/timeline/parse`

用途：

- 根据用户输入的 `displayName + biography` 生成时间线节点
- 如果传了已存在的 `profileId`，后端可能直接返回已有节点

### 请求体

```ts
interface ParseTimelineRequest {
  profileId?: string
  displayName: string
  biography: string
}
```

### 字段约束

- `displayName`: 至少 1 个字符
- `biography`: 至少 10 个字符

### 成功响应结构

```ts
interface ParseTimelineResponse {
  personId: string
  displayName: string
  nodes: TimelineNode[]
}
```

### 线上实测成功样例

请求：

```json
{
  "displayName": "测试人物API文档样例",
  "biography": "大学阶段长期想证明自己，毕业后进入大厂高速推进项目。一次重大失败后开始反思控制欲和关系问题，后来选择重建节奏，重新定义工作与生活的边界。"
}
```

响应：

```json
{
  "personId": "测试人物api文档样例",
  "displayName": "测试人物API文档样例",
  "nodes": [
    {
      "nodeId": "测试人物api文档样例-1",
      "timeLabel": "阶段 1",
      "stageLabel": "起点探索期",
      "stageType": "early",
      "keyEvent": "大学阶段长期想证明自己，毕业后进入大厂高速推进项目。一次",
      "summary": "大学阶段长期想证明自己，毕业后进入大厂高速推进项目。一次重大失败后开始反思控制欲和关系问题，后来选择重建节奏，重新定义工作与生活的边界。",
      "traits": ["进取", "受伤", "反思"],
      "values": ["秩序", "稳定", "影响力"],
      "tensions": ["速度与稳定冲突", "害怕再次失去"],
      "sourceEvidence": [
        {
          "quote": "大学阶段长期想证明自己，毕业后进入大厂高速推进项目。一次重大失败后开始反思控制欲和关系问题，后来选择重建节奏，重新定义工作与生活的边界。",
          "sourceLabel": "用户输入"
        }
      ]
    }
  ]
}
```

### 400 校验错误样例

线上实测：

```json
{
  "error": {
    "formErrors": [],
    "fieldErrors": {
      "biography": [
        "Too small: expected string to have >=10 characters"
      ]
    }
  }
}
```

### 接入建议

- `personId` 直接当 opaque string 用，不要猜格式
- 中文 `displayName` 可能生成中文 `personId`
- `parse` 返回后不要直接进入 arena，必须先 `build`

## 5.5 `POST /api/agents/build`

用途：

- 根据 timeline nodes 生成各阶段人格 agents

### 请求体

```ts
interface BuildAgentsRequest {
  personId: string
  displayName: string
  biography?: string
  nodes: TimelineNode[]
}
```

### 字段约束

- `personId`: 必填
- `displayName`: 必填
- `nodes`: 至少 1 个
- `biography`: 可选，但如果传，至少 10 个字符

### 成功响应结构

```ts
{
  agents: PersonaSpec[]
}
```

### 线上实测成功样例

```json
{
  "agents": [
    {
      "agentId": "测试人物api文档样例-1-agent",
      "displayName": "测试人物API文档样例 · 起点探索期",
      "personId": "测试人物api文档样例",
      "avatarSeed": "测试人物api文档样例-early",
      "timeLabel": "阶段 1",
      "stageLabel": "起点探索期",
      "keyEvent": "大学阶段长期想证明自己，毕业后进入大厂高速推进项目。一次",
      "knownFacts": [
        "大学阶段长期想证明自己，毕业后进入大厂高速推进项目。一次重大失败后开始反思控制欲和关系问题，后来选择重建节奏，重新定义工作与生活的边界。",
        "速度与稳定冲突",
        "害怕再次失去"
      ],
      "sourceEvidence": [
        {
          "quote": "大学阶段长期想证明自己，毕业后进入大厂高速推进项目。一次重大失败后开始反思控制欲和关系问题，后来选择重建节奏，重新定义工作与生活的边界。",
          "sourceLabel": "用户输入"
        }
      ],
      "traits": ["进取", "受伤", "反思"],
      "values": ["秩序", "稳定", "影响力"],
      "goal": "证明自己有资格被看见",
      "fear": "害怕还没开始就被现实定义",
      "voiceStyle": "语气直接、带一点冲劲",
      "knowledgeBoundary": "只能知道 阶段 1 及之前已经发生的事实，不知道后续结局。",
      "forbiddenFutureKnowledge": true,
      "stanceSeed": "倾向冒险，认为先行动再修正"
    }
  ]
}
```

### 行为说明

- 如果该 `personId` 已经存在一套和 `nodes` 对应的 agents，后端会直接返回现有结果
- 也就是说，这个接口天然带一定“复用已有 agent”的行为

## 5.6 `POST /api/arena/run`

用途：

- 一次性返回完整 arena 结果

### 请求体

```ts
interface ArenaRunRequest {
  topic: string
  mode: 'chat' | 'debate'
  selectedAgentIds: string[]
  agents: PersonaSpec[]
}
```

### 字段约束

- `topic`: 至少 1 个字符
- `mode`: 只能是 `chat` 或 `debate`
- `selectedAgentIds`: 最少 2 个，最多 3 个
- `agents`: 最少 2 个

### 重要语义

- `agents` 可以传完整候选集合
- `selectedAgentIds` 决定这次实际参与的人
- 后端会按 `selectedAgentIds` 过滤出 `participants`
- 如果实际匹配到的参与者少于 2 个，会报错

### 成功响应结构

```ts
{
  result: ArenaRun
}
```

### 线上实测返回特征

- `chat` 模式共 3 个阶段：
  - `opening`
  - `reflection`
  - `synthesis`
- 每个参与者每个阶段各发 1 条消息
- 2 个参与者时，通常一共 6 条消息

### 成功响应示例结构

```json
{
  "result": {
    "runId": "run-1775639352301",
    "mode": "chat",
    "topic": "我现在该不该离开当前高压岗位？",
    "participants": [
      {
        "agentId": "steve-jobs-1-agent",
        "displayName": "史蒂夫·乔布斯 · 疯狂少年与精神觉醒"
      },
      {
        "agentId": "steve-jobs-2-agent",
        "displayName": "史蒂夫·乔布斯 · 现实扭曲力场"
      }
    ],
    "messages": [
      {
        "id": "run-1775639352301-msg-1",
        "agentId": "steve-jobs-1-agent",
        "displayName": "史蒂夫·乔布斯 · 疯狂少年与精神觉醒",
        "stageLabel": "疯狂少年与精神觉醒",
        "content": "如果问题是“我现在该不该离开当前高压岗位？”，站在 1972年前后 的我会先看...",
        "stance": "neutral",
        "round": 1,
        "phase": "opening"
      }
    ],
    "summary": {
      "title": "阶段人格会议纪要",
      "consensus": "围绕“我现在该不该离开当前高压岗位？”，这些阶段人格都不再把答案看成单一的是或否...",
      "disagreements": [
        "疯狂少年与精神觉醒 更看重 自由、纯粹、感受力",
        "现实扭曲力场 更看重 伟大产品、极致体验、改变世界"
      ],
      "actionableAdvice": [
        "先写清你当前最不能失去的东西，再决定是否行动。",
        "把冲动和恐惧拆开处理，不要让同一种情绪同时做判断和执行。",
        "如果要改变，优先做低后悔成本的那一步。"
      ],
      "narrativeHook": "如果问题是“我现在该不该离开当前高压岗位？”，站在 1972年前后 的我会先看...",
      "moderatorNote": "真正成熟的答案，不是立刻统一，而是先看清每个阶段为什么会这样说。"
    }
  }
}
```

### `chat` 与 `debate` 的区别

`chat`：

- 阶段一般是 `opening -> reflection -> synthesis`
- 总结里更可能出现 `moderatorNote`

`debate`：

- 阶段一般是 `opening -> rebuttal -> closing`
- 总结里更可能出现 `debateVerdict`

## 5.7 `POST /api/arena/stream`

用途：

- 用 SSE 实时返回 arena 执行过程

### 请求体

与 `/api/arena/run` 完全一致

### 响应头

```http
Content-Type: text/event-stream; charset=utf-8
Cache-Control: no-cache, no-transform
Connection: keep-alive
X-Accel-Buffering: no
```

### 事件类型

```ts
type ArenaStreamEventType =
  | 'run_started'
  | 'phase_started'
  | 'message'
  | 'phase_completed'
  | 'summary_started'
  | 'summary'
  | 'done'
  | 'error'
```

### 每个事件的公共字段

```ts
{
  type: string
  runId: string
  mode: 'chat' | 'debate'
  topic: string
  sequence: number
  timestamp: string
}
```

### 典型事件顺序

`chat` 模式一般会按这个顺序出现：

1. `run_started`
2. `phase_started` round 1
3. 多个 `message`
4. `phase_completed`
5. `phase_started` round 2
6. 多个 `message`
7. `phase_completed`
8. `phase_started` round 3
9. 多个 `message`
10. `phase_completed`
11. `summary_started`
12. `summary`
13. `done`

### 线上实测 SSE 片段

第一条：

```txt
event: run_started
data: {"type":"run_started","participants":[...],"plannedRounds":[{"round":1,"phase":"opening"},{"round":2,"phase":"reflection"},{"round":3,"phase":"synthesis"}],"runId":"run-1775639373997","mode":"chat","topic":"我现在该不该离开当前高压岗位？","sequence":1,"timestamp":"2026-04-08T09:09:33.997Z"}
```

第二条：

```txt
event: phase_started
data: {"type":"phase_started","round":1,"phase":"opening","participants":[{"agentId":"steve-jobs-1-agent","displayName":"史蒂夫·乔布斯 · 疯狂少年与精神觉醒"},{"agentId":"steve-jobs-2-agent","displayName":"史蒂夫·乔布斯 · 现实扭曲力场"}],"runId":"run-1775639373997","mode":"chat","topic":"我现在该不该离开当前高压岗位？","sequence":2,"timestamp":"2026-04-08T09:09:33.997Z"}
```

消息事件：

```txt
event: message
data: {"type":"message","round":1,"phase":"opening","message":{"id":"run-1775639373997-msg-1","agentId":"steve-jobs-1-agent","displayName":"史蒂夫·乔布斯 · 疯狂少年与精神觉醒","stageLabel":"疯狂少年与精神觉醒","content":"如果问题是“我现在该不该离开当前高压岗位？”，站在 1972年前后 的我会先看...","stance":"neutral","round":1,"phase":"opening"},"runId":"run-1775639373997","mode":"chat","topic":"我现在该不该离开当前高压岗位？","sequence":3,"timestamp":"2026-04-08T09:09:39.305Z"}
```

### 心跳

- 服务器会每 15 秒发送一次 SSE 注释心跳：

```txt
: ping
```

前端应忽略它，不要当业务事件处理

### 断流/错误处理建议

- 前端要区分网络断开和业务 `error` 事件
- 若收到 `done`，说明本次流式返回完整结束
- 若收到 `error`，本次执行失败

## 5.8 `GET /api/admin/import-status`

用途：

- 查看默认人物导入状态

### 成功响应结构

```ts
{
  state: {
    running: boolean
    lastRunAt?: string
    lastError?: string
    lastImportedProfileIds: string[]
  }
  overview: {
    documents: number
    defaultProfiles: number
    arenaRuns: number
    libraryDir: string
    lastImportedProfileIds: string[]
  }
}
```

### 线上实测响应

```json
{
  "state": {
    "running": false,
    "lastImportedProfileIds": [
      "bernard-baruch",
      "steve-jobs",
      "elon-musk",
      "peter-lynch",
      "puyi",
      "warren-buffett"
    ],
    "lastRunAt": "2026-04-08T07:42:55.957Z"
  },
  "overview": {
    "documents": 6,
    "defaultProfiles": 6,
    "arenaRuns": 5,
    "libraryDir": "/home/ubuntu/library",
    "lastImportedProfileIds": [
      "bernard-baruch",
      "steve-jobs",
      "elon-musk",
      "peter-lynch",
      "puyi",
      "warren-buffett"
    ]
  }
}
```

## 5.9 `POST /api/admin/import-defaults`

用途：

- 手动重新导入默认人物

### 请求

无请求体

### 成功响应结构

```ts
{
  state: {
    running: boolean
    lastRunAt?: string
    lastError?: string
    lastImportedProfileIds: string[]
  }
  overview: {
    documents: number
    defaultProfiles: number
    arenaRuns: number
    libraryDir: string
    lastImportedProfileIds: string[]
  }
}
```

说明：

- 这个接口是管理接口，不建议前端用户态页面直接暴露

## 6. 错误处理

## 6.1 400 参数校验失败

当前后端使用 Zod，返回的是 `flatten()` 后的结构：

```json
{
  "error": {
    "formErrors": [],
    "fieldErrors": {
      "biography": [
        "Too small: expected string to have >=10 characters"
      ]
    }
  }
}
```

前端建议：

- 表单页优先读 `error.fieldErrors`
- 做字段级错误提示

## 6.2 404 资源不存在

```json
{
  "error": "profile not found"
}
```

## 6.3 500 服务错误

```json
{
  "error": "具体错误信息"
}
```

## 7. 性能与超时建议

2026-04-08 实测，线上服务存在明显生成耗时：

- `GET /api/presets` 首包约 `3s`
- `GET /api/profiles/steve-jobs` 首包约 `6s`

说明：

- 这只是某次实测，不是稳定 SLA
- 真实耗时会受模型、服务器负载、网络影响

前端建议超时：

- `/api/presets`: `15s`
- `/api/profiles/:id`: `20s`
- `/api/timeline/parse`: `60s ~ 180s`
- `/api/agents/build`: `60s ~ 180s`
- `/api/arena/run`: `120s ~ 300s`
- `/api/arena/stream`: 至少允许 `180s ~ 300s` 持续连接

## 8. 前端最容易踩的坑

- 不要只传 `selectedAgentIds` 给 arena，必须把完整 `agents[]` 一起传
- 不要假设 `personId` 一定是英文 slug，中文也是可能的
- `sourceDocument` 是可选字段
- `/api/arena/run` 返回的是 `{ result: ... }`，不是直接返回 `ArenaRun`
- `/api/agents/build` 返回的是 `{ agents: [...] }`，不是直接数组
- `/api/presets` 返回的是 `{ presets: [...] }`，不是直接数组
- `/api/timeline/parse` 返回的是直接对象，不带额外包裹层
- SSE 要忽略 `: ping`
- 首屏不要把列表接口和详情接口串行绑死

## 9. 推荐的 TypeScript 类型

```ts
export type TimelineStageType =
  | 'early'
  | 'turning-point'
  | 'stable'
  | 'crisis'
  | 'rebuild'
  | 'peak'

export type ArenaMode = 'chat' | 'debate'

export interface SourceEvidence {
  quote: string
  sourceLabel: string
}

export interface PresetProfile {
  id: string
  displayName: string
  subtitle: string
  category: 'self' | 'celebrity' | 'history' | 'fictional'
  coverSeed: string
  biography: string
  highlights: string[]
  suggestedTopics: string[]
}

export interface TimelineNode {
  nodeId: string
  timeLabel: string
  ageLabel?: string
  stageLabel: string
  stageType: TimelineStageType
  keyEvent: string
  summary: string
  traits: string[]
  values: string[]
  tensions: string[]
  sourceEvidence: SourceEvidence[]
}

export interface PersonaSpec {
  agentId: string
  displayName: string
  personId: string
  avatarSeed: string
  timeLabel: string
  stageLabel: string
  keyEvent: string
  knownFacts: string[]
  sourceEvidence: SourceEvidence[]
  traits: string[]
  values: string[]
  goal: string
  fear: string
  voiceStyle: string
  knowledgeBoundary: string
  forbiddenFutureKnowledge: boolean
  stanceSeed: string
}

export interface SourceDocumentSummary {
  id: string
  title: string
  author?: string | null
  filePath: string
  importedAt: string
  sectionCount: number
}

export interface ProfileBundle {
  profile: PresetProfile
  nodes: TimelineNode[]
  agents: PersonaSpec[]
  sourceDocument?: SourceDocumentSummary | null
}

export interface ParseTimelineRequest {
  profileId?: string
  displayName: string
  biography: string
}

export interface ParseTimelineResponse {
  personId: string
  displayName: string
  nodes: TimelineNode[]
}

export interface BuildAgentsRequest {
  personId: string
  displayName: string
  biography?: string
  nodes: TimelineNode[]
}

export interface BuildAgentsResponse {
  agents: PersonaSpec[]
}

export interface ArenaMessage {
  id: string
  agentId: string
  displayName: string
  stageLabel: string
  content: string
  stance: 'support' | 'oppose' | 'reflective' | 'neutral'
  round?: number
  phase?: 'opening' | 'reflection' | 'rebuttal' | 'synthesis' | 'closing'
  replyToAgentId?: string
  replyToDisplayName?: string
}

export interface DebateJudgeScorecard {
  agentId: string
  displayName: string
  argumentScore: number
  evidenceScore: number
  responsivenessScore: number
  comments: string
}

export interface DebateVerdict {
  winnerAgentId?: string
  winnerDisplayName?: string
  rationale: string
  scorecards: DebateJudgeScorecard[]
}

export interface ArenaSummary {
  title: string
  consensus: string
  disagreements: string[]
  actionableAdvice: string[]
  narrativeHook: string
  moderatorNote?: string
  debateVerdict?: DebateVerdict
}

export interface ArenaRun {
  runId: string
  mode: ArenaMode
  topic: string
  participants: PersonaSpec[]
  messages: ArenaMessage[]
  summary: ArenaSummary
}
```

## 10. 交付说明

这份文档描述的是 2026-04-08 实际线上服务器接口状态，不是只按本地代码猜测的草稿。如果后端之后继续改接口，建议重新同步这份文档。
