export type ArenaMode = 'chat' | 'debate'

// 人物类别 - 与 API 文档保持一致
export type PersonaCategory = 'self' | 'celebrity' | 'history' | 'fictional'

export interface PresetProfile {
  id: string
  displayName: string
  subtitle: string
  category: PersonaCategory
  coverSeed: string
  biography: string
  highlights: string[]
  suggestedTopics: string[]
}

export interface SourceEvidence {
  quote: string
  sourceLabel: string
}

// 时间线阶段类型
export type TimelineStageType = 'early' | 'turning-point' | 'stable' | 'crisis' | 'rebuild' | 'peak'

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

// Arena 消息立场
export type ArenaStance = 'support' | 'oppose' | 'reflective' | 'neutral'

// Arena 阶段类型
export type ArenaPhase = 'opening' | 'reflection' | 'rebuttal' | 'synthesis' | 'closing'

export interface ArenaMessage {
  id: string
  agentId: string
  displayName: string
  stageLabel: string
  content: string
  stance: ArenaStance
  round?: number
  phase?: ArenaPhase
  replyToAgentId?: string
  replyToDisplayName?: string
}

// 辩论评分卡
export interface DebateJudgeScorecard {
  agentId: string
  displayName: string
  argumentScore: number
  evidenceScore: number
  responsivenessScore: number
  comments: string
}

// 辩论裁决
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

export interface SelectedAgentsBundle {
  profile: PresetProfile
  selectedAgents: PersonaSpec[]
}

export interface ParseTimelineResponse {
  personId: string
  displayName: string
  nodes: TimelineNode[]
}

export interface PresetsResponse {
  presets: PresetProfile[]
}

export interface ParseTimelineRequest {
  displayName: string
  biography: string
  profileId?: string
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

export interface ArenaRunRequest {
  topic: string
  mode: ArenaMode
  selectedAgentIds: string[]
  agents: PersonaSpec[]
}

export interface ArenaRunResponse {
  result: ArenaRun
}

// 健康检查响应
export interface RuntimeInfo {
  mode: string
  claudeBinary?: string
  requestedModel?: string
  requestedEffort?: string
  fallbackModel?: string
  fallbackEffort?: string
  unsupportedModels?: string[]
}

export interface ImportState {
  running: boolean
  lastImportedProfileIds: string[]
  lastRunAt?: string
  lastError?: string
  documents?: number
  defaultProfiles?: number
  arenaRuns?: number
  libraryDir?: string
}

export interface HealthCheckResponse {
  ok: boolean
  error?: string
  runtime: RuntimeInfo
  import: ImportState
  timestamp: string
}

// SSE 流式事件类型
export type ArenaStreamEventType =
  | 'run_started'
  | 'phase_started'
  | 'message'
  | 'phase_completed'
  | 'summary_started'
  | 'summary'
  | 'done'
  | 'error'

export interface PlannedRound {
  round: number
  phase: ArenaPhase
}

export interface ArenaStreamEvent {
  type: ArenaStreamEventType
  runId: string
  mode: ArenaMode
  topic: string
  sequence: number
  timestamp: string
  participants?: PersonaSpec[]
  plannedRounds?: PlannedRound[]
  round?: number
  phase?: ArenaPhase
  message?: ArenaMessage
  summary?: ArenaSummary
  error?: string
  message_?: string
}

export interface RouteParams {
  profileId?: string
  selectedAgentIds?: string
}

export const EMPTY_PROFILE: PresetProfile = {
  id: '',
  displayName: '',
  subtitle: '',
  category: 'self',
  coverSeed: '',
  biography: '',
  highlights: [],
  suggestedTopics: []
}

// 搜索分类枚举
export type SearchCategory =
  | 'all'           // 全部
  | 'business'      // 商业
  | 'finance'       // 金融/炒股
  | 'tech'          // 科技
  | 'politics'      // 政治
  | 'culture'       // 文化
  | 'sports'        // 体育
  | 'entertainment' // 娱乐
  | 'education'     // 教育
  | 'philosophy'    // 哲学

// 分类信息接口
export interface CategoryInfo {
  id: SearchCategory
  name: string
  icon: string
  description: string
}

// 搜索结果人物卡片接口
export interface PersonaSearchResult {
  id: string
  displayName: string
  subtitle: string
  category: SearchCategory
  coverSeed: string
  matchReason: string[]
  hotLevel: number
  tags: string[]
}

// 搜索历史记录
export interface SearchHistoryItem {
  id: string
  keyword: string
  timestamp: number
  resultCount: number
}
