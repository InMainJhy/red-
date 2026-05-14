import { http } from '@kit.NetworkKit'
import { util } from '@kit.ArkTS'
import {
  ArenaHistoryResponse,
  ArenaMode,
  ArenaMessage,
  ArenaOutputLinks,
  ArenaPhase,
  ArenaPosterRequest,
  ArenaPosterResponse,
  ArenaRun,
  ArenaRunHistoryItem,
  ArenaSummary,
  ArenaRunDetailResponse,
  ArenaRunRequest,
  ArenaRunResponse,
  ArenaSessionInterruptResponse,
  ArenaStreamEvent,
  ArenaStreamEventType,
  BuildAgentsRequest,
  BuildAgentsResponse,
  HealthCheckResponse,
  ImportStatusResponse,
  MergeAgentsRequest,
  MergeAgentsResponse,
  ParseTimelineRequest,
  ParseTimelineResponse,
  PersonaSpec,
  PlannedRound,
  PresetProfile,
  PresetsResponse,
  ProfileBundle,
  ProfileImportResponse,
  ProfileImportUploadRequest,
  SelectedAgentsBundle,
  ReasoningEffort,
  SourceEvidence,
  StreamParticipant,
  StreamReplyTarget,
  TimelineNode
} from '../common/Models'
import {
  buildAgents as buildMockAgents,
  buildArenaRun as buildMockArenaRun,
  getPresetProfiles,
  getProfileById,
  getTimelineByProfileId
} from '../data/MockData'

const SERVER_BASE_URL: string = 'https://shixurenge.keenlove.top'
const API_BASE_URLS: string[] = [SERVER_BASE_URL]

const PROFILE_TIMEOUT_MS: number = 20_000
const GENERATION_TIMEOUT_MS: number = 300_000
const MULTIPART_RESPONSE_LIMIT_BYTES: number = 20 * 1024 * 1024
const MOCK_MODE: boolean = false
const MOCK_LABEL: string = 'MOCK DATA'
const MOCK_LATENCY_MS: number = 80

const LIVE_SUPPORTS_STREAM_API: boolean = false
const LIVE_SUPPORTS_ARENA_HISTORY_API: boolean = false
const LIVE_SUPPORTS_ARENA_RUN_DETAIL_API: boolean = true
const LIVE_SUPPORTS_ARENA_INTERRUPT_API: boolean = false
const LIVE_SUPPORTS_ARENA_POSTER_API: boolean = true
const LIVE_SUPPORTS_PROFILE_IMPORT_API: boolean = false
const LIVE_SUPPORTS_MERGE_API: boolean = false

interface ArenaCompactionProfile {
  label: string
  topicChars: number
  guidanceChars: number
  knownFacts: number
  factChars: number
  sourceEvidence: number
  quoteChars: number
  sourceLabelChars: number
  traitCount: number
  valueCount: number
  traitChars: number
  valueChars: number
  eventChars: number
  goalChars: number
  fearChars: number
  styleChars: number
  boundaryChars: number
  displayNameChars: number
  avatarChars: number
  timeLabelChars: number
  stageLabelChars: number
  stanceSeedChars: number
}

interface RequestError extends Error {
  statusCode?: number
  rawPayload?: string
}

const STANDARD_ARENA_COMPACTION: ArenaCompactionProfile = {
  label: 'standard',
  topicChars: 240,
  guidanceChars: 600,
  knownFacts: 4,
  factChars: 120,
  sourceEvidence: 2,
  quoteChars: 120,
  sourceLabelChars: 48,
  traitCount: 4,
  valueCount: 4,
  traitChars: 24,
  valueChars: 24,
  eventChars: 80,
  goalChars: 72,
  fearChars: 72,
  styleChars: 48,
  boundaryChars: 96,
  displayNameChars: 64,
  avatarChars: 64,
  timeLabelChars: 48,
  stageLabelChars: 48,
  stanceSeedChars: 96
}

const TIGHT_ARENA_COMPACTION: ArenaCompactionProfile = {
  label: 'tight',
  topicChars: 180,
  guidanceChars: 320,
  knownFacts: 2,
  factChars: 80,
  sourceEvidence: 1,
  quoteChars: 72,
  sourceLabelChars: 32,
  traitCount: 2,
  valueCount: 2,
  traitChars: 16,
  valueChars: 16,
  eventChars: 56,
  goalChars: 48,
  fearChars: 48,
  styleChars: 28,
  boundaryChars: 60,
  displayNameChars: 40,
  avatarChars: 32,
  timeLabelChars: 28,
  stageLabelChars: 28,
  stanceSeedChars: 60
}

const MINIMAL_ARENA_COMPACTION: ArenaCompactionProfile = {
  label: 'minimal',
  topicChars: 120,
  guidanceChars: 180,
  knownFacts: 1,
  factChars: 48,
  sourceEvidence: 0,
  quoteChars: 0,
  sourceLabelChars: 0,
  traitCount: 1,
  valueCount: 1,
  traitChars: 12,
  valueChars: 12,
  eventChars: 40,
  goalChars: 32,
  fearChars: 32,
  styleChars: 0,
  boundaryChars: 0,
  displayNameChars: 28,
  avatarChars: 20,
  timeLabelChars: 18,
  stageLabelChars: 18,
  stanceSeedChars: 32
}

const ARENA_COMPACTION_PROFILES: ArenaCompactionProfile[] = [
  STANDARD_ARENA_COMPACTION,
  TIGHT_ARENA_COMPACTION,
  MINIMAL_ARENA_COMPACTION
]

let activeBaseUrl: string = API_BASE_URLS[0]
let lastConnectionLabel: string = MOCK_MODE ? MOCK_LABEL : `LIVE ${API_BASE_URLS[0].replace('http://', '').replace('https://', '')}`
let lastArenaRequestSummary: string = MOCK_MODE ? 'Mock mode active.' : 'No arena request sent yet.'
let mockArenaRuns: ArenaRun[] = []

function buildConnectionLabel(baseUrl: string): string {
  if (baseUrl.startsWith('http://192.168.') || baseUrl.startsWith('http://10.') || baseUrl.startsWith('http://172.')) {
    return `LOCAL ${baseUrl.replace('http://', '')}`
  }
  if (baseUrl.startsWith('http://127.0.0.1') || baseUrl.startsWith('http://localhost')) {
    return `LOCAL ${baseUrl.replace('http://', '')}`
  }
  return `LIVE ${baseUrl.replace('http://', '').replace('https://', '')}`
}

function getBaseUrlCandidates(): string[] {
  const unique = new Set<string>()
  const candidates = [activeBaseUrl].concat(API_BASE_URLS)
  return candidates.filter((url: string) => {
    if (!url || unique.has(url)) {
      return false
    }
    unique.add(url)
    return true
  })
}

function waitMockLatency(durationMs: number = MOCK_LATENCY_MS): Promise<void> {
  return new Promise((resolve: () => void) => {
    setTimeout(() => resolve(), durationMs)
  })
}

function shouldUseMockForFeature(liveSupported: boolean): boolean {
  return MOCK_MODE || !liveSupported
}

function markMockFeatureFallback(): void {
  if (MOCK_MODE) {
    lastConnectionLabel = MOCK_LABEL
    return
  }
  if (lastConnectionLabel.startsWith('LOCAL ') || lastConnectionLabel.startsWith('LIVE ')) {
    return
  }
  lastConnectionLabel = MOCK_LABEL
}

function buildSyntheticPlannedRounds(run: ArenaRun): PlannedRound[] {
  if (run.messages.length === 0) {
    return []
  }

  const uniqueRounds = new Map<string, PlannedRound>()
  run.messages.forEach((message: ArenaMessage) => {
    if (message.round === undefined || message.phase === undefined) {
      return
    }
    const key = `${message.round}-${message.phase}`
    if (!uniqueRounds.has(key)) {
      uniqueRounds.set(key, {
        round: message.round,
        phase: message.phase
      })
    }
  })

  return Array.from(uniqueRounds.values())
}

function buildSyntheticStreamRequest(request: ArenaRunRequest): ArenaRunRequest {
  const cloned: ArenaRunRequest = {
    topic: request.topic,
    mode: request.mode,
    selectedAgentIds: [...request.selectedAgentIds],
    agents: [...request.agents]
  }

  if (request.guidance && request.guidance.trim().length > 0) {
    cloned.topic = `${request.topic}\n\n补充要求：${request.guidance.trim()}`
  }
  if (request.roundCount !== undefined) {
    cloned.roundCount = request.roundCount
  }
  if (request.reasoningEffort !== undefined) {
    cloned.reasoningEffort = request.reasoningEffort
  }

  return cloned
}

async function emitArenaRunAsSyntheticStream(
  response: ArenaRunResponse,
  onEvent?: SSEEventHandler,
  onComplete?: SSECompleteHandler
): Promise<void> {
  const run = response.result
  const runTimestamp = run.createdAt ?? new Date().toISOString()
  let sequence = 1

  onEvent?.({
    type: 'run_started',
    runId: run.runId,
    mode: run.mode,
    topic: run.topic,
    sequence: sequence++,
    timestamp: runTimestamp,
    sessionId: run.sessionId,
    continuedFromRunId: run.continuedFromRunId,
    participants: run.participants,
    plannedRounds: buildSyntheticPlannedRounds(run)
  })

  let lastPhase: ArenaPhase | undefined = undefined
  for (const message of run.messages) {
    if (message.phase !== undefined && message.phase !== lastPhase) {
      lastPhase = message.phase
      onEvent?.({
        type: 'phase_started',
        runId: run.runId,
        mode: run.mode,
        topic: run.topic,
        sequence: sequence++,
        timestamp: runTimestamp,
        phase: message.phase,
        round: message.round
      })
    }

    onEvent?.({
      type: 'message',
      runId: run.runId,
      mode: run.mode,
      topic: run.topic,
      sequence: sequence++,
      timestamp: runTimestamp,
      round: message.round,
      phase: message.phase,
      messageId: message.id,
      agentId: message.agentId,
      displayName: message.displayName,
      stageLabel: message.stageLabel,
      participant: {
        agentId: message.agentId,
        displayName: message.displayName,
        stageLabel: message.stageLabel
      },
      replyTarget: message.replyToAgentId ? {
        agentId: message.replyToAgentId,
        displayName: message.replyToDisplayName ?? ''
      } : undefined,
      message
    })
  }

  onEvent?.({
    type: 'summary',
    runId: run.runId,
    mode: run.mode,
    topic: run.topic,
    sequence: sequence++,
    timestamp: runTimestamp,
    summary: run.summary
  })

  onEvent?.({
    type: 'done',
    runId: run.runId,
    mode: run.mode,
    topic: run.topic,
    sequence: sequence++,
    timestamp: runTimestamp,
    result: run,
    links: response.links
  })

  onComplete?.()
}

function buildMockBundle(profileId: string): ProfileBundle | null {
  const profile = getProfileById(profileId)
  if (!profile.id.length) {
    return null
  }
  const nodes = getTimelineByProfileId(profileId)
  return {
    profile,
    nodes,
    agents: buildMockAgents(profile.id, profile.displayName, nodes)
  }
}

function buildMockTimelineNode(
  profileId: string,
  displayName: string,
  stageType: 'early' | 'stable' | 'crisis' | 'rebuild',
  stageLabel: string,
  timeLabel: string,
  keyEvent: string,
  summary: string,
  traits: string[],
  values: string[],
  tensions: string[]
): TimelineNode {
  return {
    nodeId: `${profileId}-${stageType}`,
    timeLabel,
    stageLabel,
    stageType,
    keyEvent,
    summary,
    traits,
    values,
    tensions,
    sourceEvidence: [{ quote: summary, sourceLabel: `${displayName} mock bio` }]
  }
}

function buildMockTimelineFromBiography(profileId: string, displayName: string, biography: string): TimelineNode[] {
  const text = biography.trim().length > 0 ? biography.trim() : `${displayName} 的经历仍在整理中。`
  const short = truncateText(text, 56)
  return [
    buildMockTimelineNode(profileId, displayName, 'early', '初始动机期', '最初阶段', '带着强烈期待开始行动', short, ['理想化', '主动'], ['成长', '可能性'], ['经验有限', '期待过高']),
    buildMockTimelineNode(profileId, displayName, 'stable', '现实磨合期', '进入现实', '开始面对真实约束', `开始正视现实限制：${short}`, ['克制', '适应'], ['稳定', '体面'], ['资源受限', '进度焦虑']),
    buildMockTimelineNode(profileId, displayName, 'crisis', '压力拐点期', '关键受挫', '在压力中重新判断方向', `高压之下更在意损耗与代价：${short}`, ['敏感', '反思'], ['安全感', '边界'], ['害怕继续损耗', '不想轻易放弃']),
    buildMockTimelineNode(profileId, displayName, 'rebuild', '重建选择期', '重新出发', '形成新的边界与节奏', `逐步沉淀出新的选择方式：${short}`, ['清醒', '坚定'], ['长期性', '自尊'], ['仍怕走回旧路', '但更能做取舍'])
  ]
}

function buildMockHealth(): HealthCheckResponse {
  return {
    ok: true,
    runtime: {
      mode: 'mock',
      requestedModel: 'frontend-only',
      requestedEffort: 'low'
    },
    import: {
      running: false,
      lastImportedProfileIds: getPresetProfiles().map((item: PresetProfile) => item.id),
      lastRunAt: new Date().toISOString(),
      documents: 3,
      defaultProfiles: getPresetProfiles().length,
      arenaRuns: mockArenaRuns.length,
      libraryDir: 'mock://persona-library'
    },
    timestamp: new Date().toISOString()
  }
}

function buildMockImportStatus(): ImportStatusResponse {
  return {
    state: {
      running: false,
      lastImportedProfileIds: getPresetProfiles().map((item: PresetProfile) => item.id),
      lastRunAt: new Date().toISOString()
    },
    overview: {
      documents: 3,
      defaultProfiles: getPresetProfiles().length,
      arenaRuns: mockArenaRuns.length,
      libraryDir: 'mock://persona-library',
      lastImportedProfileIds: getPresetProfiles().map((item: PresetProfile) => item.id)
    }
  }
}

function buildMockArenaLinks(runId: string): ArenaOutputLinks {
  return {
    runId,
    shareApiPath: `/mock/arena/${runId}/share`,
    shareApiUrl: `https://mock.local/arena/${runId}/share`,
    suggestedSharePath: `/mock/arena/${runId}/poster`,
    suggestedShareUrl: `https://mock.local/arena/${runId}/poster`
  }
}

function buildMockHistoryItem(run: ArenaRun): ArenaRunHistoryItem {
  return {
    runId: run.runId,
    sessionId: run.sessionId,
    continuedFromRunId: run.continuedFromRunId,
    status: run.status,
    mode: run.mode,
    topic: run.topic,
    title: run.summary.title,
    consensus: run.summary.consensus,
    participantNames: run.participants.map((item: PersonaSpec) => item.displayName),
    participantStages: run.participants.map((item: PersonaSpec) => item.stageLabel),
    participantAgentIds: run.participants.map((item: PersonaSpec) => item.agentId),
    profileIds: Array.from(new Set(run.participants.map((item: PersonaSpec) => item.personId))),
    participantCount: run.participants.length,
    messageCount: run.messages.length,
    summaryTitle: run.summary.title,
    consensusPreview: truncateText(run.summary.consensus, 80),
    createdAt: run.createdAt
  }
}

function mergeStringListsLimited(primary: string[], secondary: string[], limit: number): string[] {
  let merged: string[] = []
  primary.forEach((item: string) => {
    if (merged.length < limit) {
      merged.push(item)
    }
  })
  secondary.forEach((item: string) => {
    if (merged.length < limit) {
      merged.push(item)
    }
  })
  return merged
}

function storeMockRun(run: ArenaRun): void {
  const nextRuns: ArenaRun[] = [run]
  mockArenaRuns.forEach((item: ArenaRun) => {
    if (item.runId !== run.runId) {
      nextRuns.push(item)
    }
  })
  mockArenaRuns = nextRuns
}

function ensureMockRuns(): void {
  if (mockArenaRuns.length < 0) {
    mockArenaRuns = []
  }
}

function buildMockRunDetail(runId: string): ArenaRunDetailResponse {
  ensureMockRuns()
  const found = mockArenaRuns.find((item: ArenaRun) => item.runId === runId)
  const fallbackSummary: ArenaSummary = {
    title: '暂无会议纪要',
    consensus: '当前没有可查看的历史会议内容。',
    disagreements: [],
    actionableAdvice: [],
    narrativeHook: ''
  }
  const fallback: ArenaRun = found ? found : {
    runId: runId.length > 0 ? runId : `mock-run-${Date.now()}`,
    mode: 'chat',
    topic: '暂无历史会议',
    participants: [],
    messages: [],
    summary: fallbackSummary,
    createdAt: new Date().toISOString()
  }
  return {
    result: fallback,
    links: buildMockArenaLinks(fallback.runId)
  }
}

async function emitMockArenaStream(
  run: ArenaRun,
  onEvent?: SSEEventHandler,
  onComplete?: SSECompleteHandler
): Promise<void> {
  const baseTimestamp = new Date().toISOString()
  onEvent?.({
    type: 'run_started',
    runId: run.runId,
    mode: run.mode,
    topic: run.topic,
    sequence: 1,
    timestamp: baseTimestamp,
    reasoningEffort: 'medium',
    sessionId: run.sessionId,
    participants: run.participants,
    plannedRounds: [{ round: 1, phase: 'opening' }]
  })
  await waitMockLatency()

  onEvent?.({
    type: 'phase_started',
    runId: run.runId,
    mode: run.mode,
    topic: run.topic,
    sequence: 2,
    timestamp: baseTimestamp,
    phase: 'opening'
  })
  await waitMockLatency()

  for (let index = 0; index < run.messages.length; index++) {
    const message = run.messages[index]
    const draft = message.content
    onEvent?.({
      type: 'speaker_started',
      runId: run.runId,
      mode: run.mode,
      topic: run.topic,
      sequence: 3 + index * 3,
      timestamp: baseTimestamp,
      round: 1,
      phase: 'opening',
      agentId: message.agentId,
      displayName: message.displayName,
      stageLabel: message.stageLabel,
      participant: {
        agentId: message.agentId,
        displayName: message.displayName,
        stageLabel: message.stageLabel
      }
    })
    await waitMockLatency(40)
    onEvent?.({
      type: 'speaker_delta',
      runId: run.runId,
      mode: run.mode,
      topic: run.topic,
      sequence: 4 + index * 3,
      timestamp: baseTimestamp,
      round: 1,
      phase: 'opening',
      agentId: message.agentId,
      channel: 'text',
      delta: draft
    })
    await waitMockLatency(50)
    onEvent?.({
      type: 'speaker_completed',
      runId: run.runId,
      mode: run.mode,
      topic: run.topic,
      sequence: 5 + index * 3,
      timestamp: baseTimestamp,
      round: 1,
      phase: 'opening',
      agentId: message.agentId,
      message
    })
  }

  await waitMockLatency()
  onEvent?.({
    type: 'summary',
    runId: run.runId,
    mode: run.mode,
    topic: run.topic,
    sequence: 100,
    timestamp: baseTimestamp,
    summary: run.summary
  })
  await waitMockLatency(40)
  onEvent?.({
    type: 'done',
    runId: run.runId,
    mode: run.mode,
    topic: run.topic,
    sequence: 101,
    timestamp: baseTimestamp,
    result: run,
    links: buildMockArenaLinks(run.runId)
  })
  onComplete?.()
}

function normalizePayload(result: Object | string): string {
  if (typeof result === 'string') {
    return result
  }
  return JSON.stringify(result)
}

function parseJson<T>(result: Object | string): T {
  return JSON.parse(normalizePayload(result)) as T
}

function parseErrorMessage(result: Object | string, statusCode: number): string {
  const rawPayload = normalizePayload(result)

  if (statusCode === 413 || rawPayload.includes('413 Request Entity Too Large')) {
    return 'Meeting request is too large for the upstream model.'
  }

  if (
    statusCode === 504 ||
    rawPayload.includes('504 Gateway Time-out') ||
    rawPayload.includes('504 Gateway Timeout')
  ) {
    return 'Import took too long and the gateway timed out. Please try again later.'
  }

  try {
    const payload = parseJson<Record<string, Object | string>>(result)
    const errorValue = payload.error

    if (typeof errorValue === 'string') {
      return errorValue
    }

    if (errorValue) {
      const flatError = errorValue as Record<string, Object>
      const fieldErrors = flatError.fieldErrors as Record<string, string[]> | undefined
      if (fieldErrors) {
        let messages: string[] = []
        Object.keys(fieldErrors).forEach((key: string) => {
          const values = fieldErrors[key]
          if (values && values.length > 0) {
            messages.push(`${key}: ${values[0]}`)
          }
        })
        if (messages.length > 0) {
          return messages.join(', ')
        }
      }
    }
  } catch (_error) {
    const stripped = rawPayload
      .replace(/<[^>]*>/g, ' ')
      .replace(/\s+/g, ' ')
      .trim()
    if (stripped.length > 0 && stripped.length <= 200) {
      return `${stripped} (${statusCode})`
    }
  }

  return `Request failed ${statusCode}`
}

function formatThrownError(error: Object): string {
  if (typeof error === 'string') {
    return normalizeNetworkErrorMessage(error)
  }

  const maybeMessage = error as Record<string, string>
  if (maybeMessage.message) {
    return normalizeNetworkErrorMessage(maybeMessage.message)
  }

  return normalizeNetworkErrorMessage(JSON.stringify(error))
}

function normalizeNetworkErrorMessage(message: string): string {
  const lower = message.toLowerCase()
  if (lower.includes('invalid ssl peer certificate') || lower.includes('ssh remote key')) {
    return '线上服务证书校验失败，请切换本地后端或更新服务证书。'
  }
  if (lower.includes('could not resolve host') || lower.includes('name or service not known')) {
    return '域名解析失败，请检查网络或后端地址配置。'
  }
  if (lower.includes('failed to connect') || lower.includes('connect to server')) {
    return '后端服务未启动，或当前设备无法访问本地 3030 服务。'
  }
  if (lower.includes('timeout')) {
    return '后端请求超时，请稍后重试。'
  }
  return message
}

function buildRequestError(result: Object | string, statusCode: number): RequestError {
  const error = new Error(parseErrorMessage(result, statusCode)) as RequestError
  error.statusCode = statusCode
  error.rawPayload = normalizePayload(result)
  return error
}

function buildMultipartField(name: string, value: string): http.MultiFormData {
  return {
    name,
    contentType: 'text/plain',
    data: value
  }
}

function buildProfileImportFormData(request: ProfileImportUploadRequest): http.MultiFormData[] {
  let formDataList: http.MultiFormData[] = [
    buildMultipartField('importType', request.importType)
  ]

  if (request.displayNameHint && request.displayNameHint.trim().length > 0) {
    formDataList.push(buildMultipartField('displayNameHint', request.displayNameHint.trim()))
  }
  if (request.title && request.title.trim().length > 0) {
    formDataList.push(buildMultipartField('title', request.title.trim()))
  }
  if (request.profileId && request.profileId.trim().length > 0) {
    formDataList.push(buildMultipartField('profileId', request.profileId.trim()))
  }

  let filePart: http.MultiFormData = {
    name: 'file',
    contentType: request.mimeType && request.mimeType.length > 0 ? request.mimeType : 'application/octet-stream',
    remoteFileName: request.fileName
  }

  if (request.fileData !== undefined) {
    filePart.data = request.fileData
  } else if (request.filePath && request.filePath.length > 0) {
    filePart.filePath = request.filePath
  } else {
    throw new Error('Missing file payload for profile import.')
  }

  formDataList.push(filePart)
  return formDataList
}

function isPayloadTooLargeError(error: Object): boolean {
  const requestError = error as RequestError
  if (requestError.statusCode === 413) {
    return true
  }
  const message = formatThrownError(error).toLowerCase()
  return message.includes('too large') || message.includes('413')
}

function updateArenaRequestSummary(summary: string): void {
  lastArenaRequestSummary = summary
}

function buildArenaRequestSummary(
  profile: ArenaCompactionProfile,
  payloadChars: number,
  attemptIndex: number,
  totalAttempts: number,
  selectedCount: number,
  guidanceLength: number
): string {
  const retryLabel = totalAttempts > 1 ? `try ${attemptIndex}/${totalAttempts}` : 'try 1/1'
  const guidanceLabel = guidanceLength > 0 ? `follow-up ${guidanceLength}c` : 'first run'
  return `${buildConnectionLabel(activeBaseUrl)} 路 ${profile.label} 路 ${payloadChars} chars 路 ${selectedCount} roles 路 ${guidanceLabel} 路 ${retryLabel}`
}

function buildCustomProfile(profileId: string, displayName: string, biography: string, nodes: TimelineNode[]): PresetProfile {
  return {
    id: profileId,
    displayName,
    subtitle: 'Custom imported profile',
    category: 'self',
    coverSeed: profileId,
    biography,
    highlights: nodes.slice(0, 4).map((node: TimelineNode) => node.stageLabel),
    suggestedTopics: [
      'What matters most right now?',
      'Should I keep investing or cut my losses?',
      'How should ambition, boundaries and reality be reordered?'
    ]
  }
}

function buildParseTimelineRequest(displayName: string, biography: string): ParseTimelineRequest {
  return {
    displayName,
    biography
  }
}

function buildAgentsRequest(parsed: ParseTimelineResponse, biography: string): BuildAgentsRequest {
  return {
    personId: parsed.personId,
    displayName: parsed.displayName,
    biography,
    nodes: parsed.nodes
  }
}

function buildArenaRunRequest(
  topic: string,
  mode: ArenaMode,
  selectedAgents: PersonaSpec[],
  roundCount?: number
): ArenaRunRequest {
  const request: ArenaRunRequest = {
    topic,
    mode,
    selectedAgentIds: selectedAgents.map((agent: PersonaSpec) => agent.agentId),
    agents: compactPersonaSpecs(selectedAgents, STANDARD_ARENA_COMPACTION),
    roundCount: roundCount !== undefined && roundCount > 0 ? roundCount : 3,
    maxMessageChars: 180
  }
  return request
}

function truncateText(value: string, maxChars: number): string {
  const trimmed = value.trim()
  if (trimmed.length <= maxChars) {
    return trimmed
  }
  return `${trimmed.substring(0, Math.max(0, maxChars - 3)).trim()}...`
}

function compactStringList(values: string[], maxItems: number, maxChars: number): string[] {
  let compacted: string[] = []
  values.forEach((value: string) => {
    const normalized = truncateText(value, maxChars)
    if (normalized.length === 0 || compacted.includes(normalized) || compacted.length >= maxItems) {
      return
    }
    compacted.push(normalized)
  })
  return compacted
}

function compactSourceEvidence(values: SourceEvidence[], profile: ArenaCompactionProfile): SourceEvidence[] {
  let compacted: SourceEvidence[] = []
  values.forEach((item: SourceEvidence) => {
    if (compacted.length >= profile.sourceEvidence) {
      return
    }

    const quote = truncateText(item.quote, profile.quoteChars)
    const sourceLabel = truncateText(item.sourceLabel, profile.sourceLabelChars)
    if (quote.length === 0 && sourceLabel.length === 0) {
      return
    }

    compacted.push({
      quote,
      sourceLabel
    })
  })
  return compacted
}

function compactPersonaSpec(agent: PersonaSpec, profile: ArenaCompactionProfile): PersonaSpec {
  return {
    agentId: agent.agentId,
    displayName: truncateText(agent.displayName, profile.displayNameChars),
    personId: agent.personId,
    avatarSeed: truncateText(agent.avatarSeed, profile.avatarChars),
    timeLabel: truncateText(agent.timeLabel, profile.timeLabelChars),
    stageLabel: truncateText(agent.stageLabel, profile.stageLabelChars),
    keyEvent: truncateText(agent.keyEvent, profile.eventChars),
    knownFacts: compactStringList(agent.knownFacts, profile.knownFacts, profile.factChars),
    sourceEvidence: compactSourceEvidence(agent.sourceEvidence, profile),
    traits: compactStringList(agent.traits, profile.traitCount, profile.traitChars),
    values: compactStringList(agent.values, profile.valueCount, profile.valueChars),
    goal: truncateText(agent.goal, profile.goalChars),
    fear: truncateText(agent.fear, profile.fearChars),
    voiceStyle: truncateText(agent.voiceStyle, profile.styleChars),
    knowledgeBoundary: truncateText(agent.knowledgeBoundary, profile.boundaryChars),
    forbiddenFutureKnowledge: agent.forbiddenFutureKnowledge,
    stanceSeed: truncateText(agent.stanceSeed, profile.stanceSeedChars)
  }
}

function compactPersonaSpecs(agents: PersonaSpec[], profile: ArenaCompactionProfile): PersonaSpec[] {
  return agents.map((agent: PersonaSpec) => compactPersonaSpec(agent, profile))
}

function sanitizeArenaRequest(request: ArenaRunRequest, profile: ArenaCompactionProfile = STANDARD_ARENA_COMPACTION): ArenaRunRequest {
  const compactAgents = compactPersonaSpecs(request.agents, profile)
  const allowedAgentIds = compactAgents.map((agent: PersonaSpec) => agent.agentId)
  const selectedAgentIds = request.selectedAgentIds.filter((agentId: string) => allowedAgentIds.includes(agentId))

  const sanitized: ArenaRunRequest = {
    topic: truncateText(request.topic, profile.topicChars),
    mode: request.mode,
    selectedAgentIds,
    agents: compactAgents
  }

  if (request.reasoningEffort) {
    sanitized.reasoningEffort = request.reasoningEffort
  }
  if (request.roundCount !== undefined) {
    sanitized.roundCount = request.roundCount
  }
  if (request.maxMessageChars !== undefined) {
    sanitized.maxMessageChars = request.maxMessageChars
  }
  if (request.guidance && request.guidance.trim().length > 0) {
    sanitized.guidance = truncateText(request.guidance, profile.guidanceChars)
  }
  if (request.continueFromRunId && request.continueFromRunId.length > 0) {
    sanitized.continueFromRunId = request.continueFromRunId
  }
  if (request.sessionId && request.sessionId.length > 0) {
    sanitized.sessionId = request.sessionId
  }

  return sanitized
}

function buildQueryParam(name: string, value: string | number): string {
  return `${encodeURIComponent(name)}=${encodeURIComponent(`${value}`)}`
}

async function requestJson<T>(path: string, method: http.RequestMethod, body?: Object | string, timeoutMs: number = PROFILE_TIMEOUT_MS): Promise<T> {
  const payload = body ? (typeof body === 'string' ? body : JSON.stringify(body)) : ''
  let attemptErrors: string[] = []
  let lastError: Object | undefined = undefined
  let sawHttpResponse: boolean = false

  for (const baseUrl of getBaseUrlCandidates()) {
    const client = http.createHttp()

    try {
      let response = await client.request(`${baseUrl}${path}`, {
        method,
        header: {
          'Content-Type': 'application/json'
        },
        extraData: payload,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs
      })

      if (response.responseCode >= 200 && response.responseCode < 300) {
        activeBaseUrl = baseUrl
        lastConnectionLabel = buildConnectionLabel(baseUrl)
        return parseJson<T>(response.result)
      }

      activeBaseUrl = baseUrl
      lastConnectionLabel = buildConnectionLabel(baseUrl)
      sawHttpResponse = true
      throw buildRequestError(response.result, response.responseCode)
    } catch (error) {
      lastError = error as Object
      attemptErrors.push(`${baseUrl}: ${path} -> ${formatThrownError(error as Object)}`)
    } finally {
      client.destroy()
    }
  }

  if (!sawHttpResponse) {
    lastConnectionLabel = 'API ERROR'
  }
  if (lastError) {
    throw new Error(formatThrownError(lastError))
  }
  throw new Error(attemptErrors.length > 0 ? attemptErrors[0] : 'Request failed')
}

async function requestMultipart<T>(
  path: string,
  formDataList: http.MultiFormData[],
  timeoutMs: number = GENERATION_TIMEOUT_MS
): Promise<T> {
  let attemptErrors: string[] = []
  let lastError: Object | undefined = undefined
  let sawHttpResponse: boolean = false

  for (const baseUrl of getBaseUrlCandidates()) {
    const client = http.createHttp()

    try {
      let response = await client.request(`${baseUrl}${path}`, {
        method: http.RequestMethod.POST,
        header: {
          'Accept': 'application/json'
        },
        multiFormDataList: formDataList,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs,
        maxLimit: MULTIPART_RESPONSE_LIMIT_BYTES
      })

      if (response.responseCode >= 200 && response.responseCode < 300) {
        activeBaseUrl = baseUrl
        lastConnectionLabel = buildConnectionLabel(baseUrl)
        return parseJson<T>(response.result)
      }

      activeBaseUrl = baseUrl
      lastConnectionLabel = buildConnectionLabel(baseUrl)
      sawHttpResponse = true
      throw buildRequestError(response.result, response.responseCode)
    } catch (error) {
      lastError = error as Object
      attemptErrors.push(`${baseUrl}: ${path} -> ${formatThrownError(error as Object)}`)
    } finally {
      client.destroy()
    }
  }

  if (!sawHttpResponse) {
    lastConnectionLabel = 'API ERROR'
  }
  if (lastError) {
    throw new Error(formatThrownError(lastError))
  }
  throw new Error(attemptErrors.length > 0 ? attemptErrors[0] : 'Request failed')
}

// SSE 行解析器
function parseSSELine(line: string): SSELineResult | null {
  if (!line || line.startsWith(':')) {
    return null
  }
  const colonIndex = line.indexOf(':')
  if (colonIndex === -1) {
    return { field: line.trim(), value: '' }
  }
  const field = line.substring(0, colonIndex).trim()
  let value = line.substring(colonIndex + 1).trim()
  if (value.startsWith(' ')) {
    value = value.substring(1)
  }
  return { field, value }
}

/** 续聊 / 插话：与文档 `ArenaRunRequest.guidance、continueFromRunId、sessionId` 一致 */
export interface StreamArenaExtras {
  guidance?: string
  continueFromRunId?: string
  sessionId?: string
}

// SSE 事件处理器类型
export type SSEEventHandler = (event: ArenaStreamEvent) => void
export type SSEErrorHandler = (error: string) => void
export type SSECompleteHandler = () => void

// SSE 解析的行结果
export interface SSELineResult {
  field: string
  value: string
}

// SSE data 里嵌套字段可能是 JSON 字符串或已解析对象，需同时兼容
function coerceJsonValue<T>(raw: Object | string | undefined | null): T | undefined {
  if (raw === undefined || raw === null) {
    return undefined
  }
  if (typeof raw === 'string') {
    const trimmed = raw.trim()
    if (trimmed.length === 0) {
      return undefined
    }
    try {
      return JSON.parse(trimmed) as T
    } catch (_e) {
      return undefined
    }
  }
  return raw as T
}

// 构建流事件对象
function buildStreamEvent(parsedData: SSEParsedData, eventType: string): ArenaStreamEvent {
  const event: ArenaStreamEvent = {
    type: parseStreamEventType(eventType),
    runId: parsedData.runId ?? '',
    mode: parseStreamArenaMode(parsedData.mode),
    topic: parsedData.topic ?? '',
    sequence: parsedData.sequence ?? 0,
    timestamp: parsedData.timestamp ?? ''
  }

  // run_started 事件
  if (eventType === 'run_started') {
    if (parsedData.reasoningEffort) {
      event.reasoningEffort = parsedData.reasoningEffort
    }
    if (parsedData.sessionId) { event.sessionId = parsedData.sessionId }
    if (parsedData.continuedFromRunId) { event.continuedFromRunId = parsedData.continuedFromRunId }
    // 部分网关/后端会以 snake_case 输出，需与 camelCase 等价兼容
    const snake = parsedData as Record<string, string | undefined>
    if (!event.sessionId || event.sessionId.trim().length === 0) {
      const s = snake['session_id']
      if (s !== undefined && s.trim().length > 0) {
        event.sessionId = s.trim()
      }
    }
    if (!event.runId || event.runId.trim().length === 0) {
      const r = snake['run_id']
      if (r !== undefined && r.trim().length > 0) {
        event.runId = r.trim()
      }
    }
    const participants = coerceJsonValue<PersonaSpec[]>(parsedData.participants)
    if (participants) { event.participants = participants }
    const plannedRounds = coerceJsonValue<PlannedRound[]>(parsedData.plannedRounds)
    if (plannedRounds) { event.plannedRounds = plannedRounds }
    if (event.runId.length > 0) {
      event.runId = event.runId.trim()
    }
    if (event.sessionId !== undefined && event.sessionId.length > 0) {
      event.sessionId = event.sessionId.trim()
    }
  }

  // speaker_started / message 事件
  if (parsedData.round !== undefined) { event.round = parsedData.round }
  if (parsedData.phase) {
    event.phase = parsedData.phase as ArenaPhase
  }
  if (parsedData.messageId) { event.messageId = parsedData.messageId }
  if (parsedData.agentId) { event.agentId = parsedData.agentId }
  if (parsedData.displayName) { event.displayName = parsedData.displayName }
  if (parsedData.stageLabel) { event.stageLabel = parsedData.stageLabel }

  if (eventType === 'speaker_started') {
    const participant = coerceJsonValue<StreamParticipant>(parsedData.participant)
    if (participant) {
      event.participant = participant
      event.agentId = participant.agentId
      event.displayName = participant.displayName
      event.stageLabel = participant.stageLabel
    }
    const replyTarget = coerceJsonValue<StreamReplyTarget>(parsedData.replyTarget)
    if (replyTarget) { event.replyTarget = replyTarget }
  }

  // speaker_delta / summary_delta 事件
  if (parsedData.channel) { event.channel = parsedData.channel }
  if (parsedData.delta) { event.delta = parsedData.delta }
  if (parsedData.accumulatedText) { event.accumulatedText = parsedData.accumulatedText }

  // message 事件
  if (eventType === 'message') {
    const msg = coerceJsonValue<ArenaMessage>(parsedData.message)
    if (msg) { event.message = msg }
  }

  if (eventType === 'summary') {
    const summary = coerceJsonValue<ArenaSummary>(parsedData.summary)
    if (summary) { event.summary = summary }
  }

  // done 事件
  if (eventType === 'done') {
    const result = coerceJsonValue<ArenaRun>(parsedData.result)
    if (result) { event.result = result }
    const links = coerceJsonValue<ArenaOutputLinks>(parsedData.links)
    if (links) { event.links = links }
  }

  // error 事件（message 可能是字符串或嵌套对象）
  if (eventType === 'error') {
    let errorMsg: string = 'Stream transport error'
    if (typeof parsedData.message === 'string' && parsedData.message.length > 0) {
      errorMsg = parsedData.message
    } else if (parsedData.message_ && `${parsedData.message_}`.length > 0) {
      errorMsg = `${parsedData.message_}`
    } else if (parsedData.error && `${parsedData.error}`.length > 0) {
      errorMsg = `${parsedData.error}`
    }
    event.error = errorMsg
  }

  return event
}

// SSE 解析的数据结构
interface SSEParsedData {
  type?: string
  runId?: string
  mode?: string
  topic?: string
  sequence?: number
  timestamp?: string
  reasoningEffort?: ReasoningEffort
  sessionId?: string
  continuedFromRunId?: string
  round?: number
  phase?: string
  messageId?: string
  agentId?: string
  displayName?: string
  stageLabel?: string
  channel?: 'text' | 'thinking'
  delta?: string
  accumulatedText?: string
  message?: Object | string
  summary?: Object | string
  message_?: string
  error?: string
  participants?: Object | string
  plannedRounds?: Object | string
  participant?: Object | string
  replyTarget?: Object | string
  result?: Object | string
  links?: Object | string
}

// 有效的流事件类型
const VALID_STREAM_EVENT_TYPES: ArenaStreamEventType[] = [
  'run_started', 'phase_started',
  'speaker_started', 'speaker_delta', 'speaker_completed',
  'message', 'phase_completed',
  'summary_started', 'summary_delta', 'summary',
  'done', 'error'
]

// 解析流事件类型
function parseStreamEventType(type: string): ArenaStreamEventType {
  const validIndex: number = VALID_STREAM_EVENT_TYPES.indexOf(type as ArenaStreamEventType)
  if (validIndex >= 0) {
    return VALID_STREAM_EVENT_TYPES[validIndex]
  }
  return 'message'
}

// 解析 arena 模式
function parseStreamArenaMode(mode?: string): ArenaMode {
  if (mode === 'debate') {
    return 'debate'
  }
  return 'chat'
}

// SSE 解析主函数（多行 data: 拼接、\\r 剥离、末尾块 flush，与后端文档 8.5 一致）
function parseSSELines(content: string, onEvent: SSEEventHandler, onError: SSEErrorHandler, onComplete: SSECompleteHandler | undefined): void {
  const lines = content.split('\n')

  let eventData: Record<string, string> = {}
  let eventType: string = ''

  const flushBlock = (): void => {
    if (eventType && Object.keys(eventData).length > 0) {
      const dataStr = eventData['data']
      if (dataStr) {
        try {
          const parsedData: SSEParsedData = JSON.parse(dataStr) as SSEParsedData
          const event = buildStreamEvent(parsedData, eventType)
          onEvent(event)

          if (eventType === 'done') {
            onComplete?.()
          }
          if (eventType === 'error') {
            const errorMsg: string = typeof parsedData.message === 'string'
              ? parsedData.message
              : (parsedData.message_ ?? parsedData.error ?? 'Stream transport error')
            onError(errorMsg)
          }
        } catch (_parseError) {
          // 单块解析失败则跳过，避免整流中断
        }
      }
    }
    eventData = {}
    eventType = ''
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].replace(/\r$/, '')

    if (!line.trim()) {
      flushBlock()
      continue
    }

    const parsed = parseSSELine(line)
    if (!parsed) {
      continue
    }

    if (parsed.field === 'event') {
      eventType = parsed.value
    } else if (parsed.field === 'data') {
      const prev = eventData['data']
      eventData['data'] = prev !== undefined && prev.length > 0 ? `${prev}\n${parsed.value}` : parsed.value
    } else {
      eventData[parsed.field] = parsed.value
    }
  }

  flushBlock()
}

/**
 * 将网络分片拼入缓冲区，按 SSE 空行分隔出完整事件块并立即 dispatch（实现真流式 UI 刷新）
 */
function feedSSEStreamChunk(
  carry: string,
  chunk: string,
  onEvent: SSEEventHandler,
  onError: SSEErrorHandler,
  onComplete: SSECompleteHandler | undefined
): string {
  const merged = carry + chunk
  const sep = '\n\n'
  const parts = merged.split(sep)
  if (parts.length === 1) {
    return merged
  }
  const tailIndex = parts.length - 1
  for (let i = 0; i < tailIndex; i++) {
    const raw = parts[i].replace(/\r$/, '').trimEnd()
    if (raw.length > 0) {
      parseSSELines(raw + '\n', onEvent, onError, onComplete)
    }
  }
  return parts[tailIndex]
}

function runArenaStreamInStreamMode(
  client: http.HttpRequest,
  baseUrl: string,
  payload: string,
  onEvent: SSEEventHandler | undefined,
  onError: SSEErrorHandler | undefined,
  onComplete: SSECompleteHandler | undefined
): Promise<void> {
  return new Promise<void>((resolve, reject) => {
    let carry = ''
    let responseCode = -1
    let errorTextCarry = ''
    const decoder = util.TextDecoder.create('utf-8', { ignoreBOM: true })
    const fireEvent = onEvent ?? ((_e: ArenaStreamEvent) => {})
    const fireError = onError ?? ((_s: string) => {})
    const fireComplete = onComplete

    const onHeadersReceive = (header: Object) => {
      const h = header as Record<string, number | string>
      const rc = h['responseCode']
      if (typeof rc === 'number') {
        responseCode = rc
      } else if (typeof rc === 'string') {
        const n = parseInt(rc, 10)
        if (!isNaN(n)) {
          responseCode = n
        }
      }
    }

    const onDataReceive = (data: ArrayBuffer) => {
      const slice = new Uint8Array(data)
      const text = decoder.decodeToString(slice, { stream: true })
      if (responseCode >= 0 && responseCode !== 200) {
        errorTextCarry += text
        return
      }
      carry = feedSSEStreamChunk(carry, text, fireEvent, fireError, fireComplete)
    }

    const onDataEnd = () => {
      try {
        const tail = decoder.decodeToString(new Uint8Array(0), { stream: false })
        if (tail.length > 0) {
          if (responseCode >= 0 && responseCode !== 200) {
            errorTextCarry += tail
          } else {
            carry = feedSSEStreamChunk(carry, tail, fireEvent, fireError, fireComplete)
          }
        }
        if (responseCode >= 0 && responseCode !== 200) {
          const msg = errorTextCarry.trim().length > 0 ? errorTextCarry.trim() : `HTTP ${responseCode}`
          fireError(msg)
        } else if (carry.trim().length > 0) {
          parseSSELines(carry + '\n\n', fireEvent, fireError, fireComplete)
        }
      } finally {
        client.off('headersReceive', onHeadersReceive)
        client.off('dataReceive', onDataReceive)
        client.off('dataEnd', onDataEnd)
        resolve()
      }
    }

    client.on('headersReceive', onHeadersReceive)
    client.on('dataReceive', onDataReceive)
    client.on('dataEnd', onDataEnd)

    client.requestInStream(`${baseUrl}/api/arena/stream`, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream'
      },
      extraData: payload,
      expectDataType: http.HttpDataType.ARRAY_BUFFER,
      connectTimeout: GENERATION_TIMEOUT_MS,
      readTimeout: GENERATION_TIMEOUT_MS
    }).catch((err: Error) => {
      client.off('headersReceive', onHeadersReceive)
      client.off('dataReceive', onDataReceive)
      client.off('dataEnd', onDataEnd)
      reject(err)
    })
  })
}

export class PersonaApi {
  static getConnectionLabel(): string {
    return lastConnectionLabel
  }

  static getLastArenaRequestSummary(): string {
    return lastArenaRequestSummary
  }

  static async checkHealth(): Promise<HealthCheckResponse | null> {
    if (MOCK_MODE) {
      lastConnectionLabel = MOCK_LABEL
      ensureMockRuns()
      await waitMockLatency()
      return buildMockHealth()
    }
    try {
      return await requestJson<HealthCheckResponse>('/health', http.RequestMethod.GET, undefined, 10_000)
    } catch (_error) {
      lastConnectionLabel = 'API ERROR'
      return null
    }
  }

  static async getImportStatus(): Promise<ImportStatusResponse> {
    if (MOCK_MODE) {
      lastConnectionLabel = MOCK_LABEL
      ensureMockRuns()
      await waitMockLatency()
      return buildMockImportStatus()
    }
    try {
      return await requestJson<ImportStatusResponse>('/api/admin/import-status', http.RequestMethod.GET)
    } catch (error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(error as Object))
    }
  }

  static async importDefaultProfiles(): Promise<ImportStatusResponse> {
    if (MOCK_MODE) {
      lastConnectionLabel = MOCK_LABEL
      ensureMockRuns()
      await waitMockLatency()
      return buildMockImportStatus()
    }
    try {
      return await requestJson<ImportStatusResponse>(
        '/api/admin/import-defaults',
        http.RequestMethod.POST,
        undefined,
        GENERATION_TIMEOUT_MS
      )
    } catch (error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(error as Object))
    }
  }

  static async getPresets(): Promise<PresetProfile[]> {
    if (MOCK_MODE) {
      lastConnectionLabel = MOCK_LABEL
      await waitMockLatency()
      return Promise.resolve(getPresetProfiles())
    }
    try {
      const result = await requestJson<PresetsResponse>('/api/presets', http.RequestMethod.GET)
      return result.presets
    } catch (_error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(_error as Object))
    }
  }

  static async getProfileBundle(profileId: string): Promise<ProfileBundle> {
    if (MOCK_MODE) {
      lastConnectionLabel = MOCK_LABEL
      await waitMockLatency()
      const mockBundle = buildMockBundle(profileId)
      if (mockBundle) {
        return Promise.resolve(mockBundle)
      }
      throw new Error(`Mock profile not found: ${profileId}`)
    }
    try {
      return await requestJson<ProfileBundle>(`/api/profiles/${encodeURIComponent(profileId)}`, http.RequestMethod.GET)
    } catch (error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(error as Object))
    }
  }

  static async getSelectedAgents(profileId: string, selectedAgentIds: string[]): Promise<SelectedAgentsBundle> {
    const bundle = await PersonaApi.getProfileBundle(profileId)
    const selectedAgents = bundle.agents.filter((agent: PersonaSpec) => selectedAgentIds.includes(agent.agentId))
    let selectedBundle: SelectedAgentsBundle = { profile: bundle.profile, selectedAgents }
    return Promise.resolve(selectedBundle)
  }

  /** 多人物：合并各 profile 的 agents[]，再按 selectedAgentIds 筛选（与后端 Arena 请求一致） */
  static async getSelectedAgentsForMeeting(profileIds: string[], selectedAgentIds: string[]): Promise<SelectedAgentsBundle> {
    const uniqueIds: string[] = []
    profileIds.forEach((id: string) => {
      const t = id.trim()
      if (t.length > 0 && uniqueIds.indexOf(t) < 0) {
        uniqueIds.push(t)
      }
    })
    if (uniqueIds.length === 0) {
      throw new Error('No profile ids for meeting.')
    }

    const bundles: ProfileBundle[] = await Promise.all(
      uniqueIds.map((pid: string) => PersonaApi.getProfileBundle(pid))
    )

    const seenAgent = new Set<string>()
    let merged: PersonaSpec[] = []
    bundles.forEach((b: ProfileBundle) => {
      b.agents.forEach((agent: PersonaSpec) => {
        if (!seenAgent.has(agent.agentId)) {
          seenAgent.add(agent.agentId)
          merged.push(agent)
        }
      })
    })

    const selectedAgents = merged.filter((agent: PersonaSpec) => selectedAgentIds.includes(agent.agentId))
    const primary = bundles[0].profile
    const selectedBundle: SelectedAgentsBundle = { profile: primary, selectedAgents }
    return Promise.resolve(selectedBundle)
  }

  static async importProfile(request: ProfileImportUploadRequest): Promise<ProfileImportResponse> {
    if (shouldUseMockForFeature(LIVE_SUPPORTS_PROFILE_IMPORT_API)) {
      markMockFeatureFallback()
      await waitMockLatency()
      const displayName = request.displayNameHint && request.displayNameHint.trim().length > 0
        ? request.displayNameHint.trim()
        : (request.title && request.title.trim().length > 0 ? request.title.trim() : request.fileName.replace(/\.[^.]+$/, ''))
      const profileId = `import-${Date.now()}`
      const biography = `${displayName} 的资料来自 ${request.fileName}，当前为前端 mock 导入数据。`
      const nodes = buildMockTimelineFromBiography(profileId, displayName, biography)
      const bundle: ProfileBundle = {
        profile: buildCustomProfile(profileId, displayName, biography, nodes),
        nodes,
        agents: buildMockAgents(profileId, displayName, nodes)
      }
      return {
        bundle,
        import: {
          importType: request.importType,
          sourceLabel: MOCK_LABEL,
          title: request.title && request.title.trim().length > 0 ? request.title.trim() : displayName,
          originalFileName: request.fileName,
          mimeType: request.mimeType ? request.mimeType : 'text/plain',
          extension: request.fileName.includes('.') ? request.fileName.substring(request.fileName.lastIndexOf('.') + 1) : 'txt',
          charCount: biography.length,
          messageCount: nodes.length
        }
      }
    }
    try {
      return await requestMultipart<ProfileImportResponse>(
        '/api/profile-imports',
        buildProfileImportFormData(request),
        GENERATION_TIMEOUT_MS
      )
    } catch (error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(error as Object))
    }
  }

  static async importCustomProfile(displayName: string, biography: string): Promise<ProfileBundle> {
    if (MOCK_MODE) {
      lastConnectionLabel = MOCK_LABEL
      await waitMockLatency()
      const profileId = `custom-${Date.now()}`
      const nodes = buildMockTimelineFromBiography(profileId, displayName.trim(), biography.trim())
      return {
        profile: buildCustomProfile(profileId, displayName.trim(), biography.trim(), nodes),
        nodes,
        agents: buildMockAgents(profileId, displayName.trim(), nodes)
      }
    }
    const parseRequest: ParseTimelineRequest = buildParseTimelineRequest(displayName, biography)
    const parsed = await requestJson<ParseTimelineResponse>('/api/timeline/parse', http.RequestMethod.POST, parseRequest, GENERATION_TIMEOUT_MS)

    const agentsRequest: BuildAgentsRequest = buildAgentsRequest(parsed, biography)
    const built = await requestJson<BuildAgentsResponse>('/api/agents/build', http.RequestMethod.POST, agentsRequest, GENERATION_TIMEOUT_MS)

    try {
      const storedBundle = await requestJson<ProfileBundle>(`/api/profiles/${encodeURIComponent(parsed.personId)}`, http.RequestMethod.GET)
      if (storedBundle.agents.length === 0) {
        storedBundle.agents = built.agents
      }
      return storedBundle
    } catch (_error) {
      const fallbackBundle: ProfileBundle = {
        profile: buildCustomProfile(parsed.personId, parsed.displayName, biography, parsed.nodes),
        nodes: parsed.nodes,
        agents: built.agents
      }
      return Promise.resolve(fallbackBundle)
    }
  }

  static async mergeAgents(request: MergeAgentsRequest): Promise<MergeAgentsResponse> {
    if (shouldUseMockForFeature(LIVE_SUPPORTS_MERGE_API)) {
      markMockFeatureFallback()
      await waitMockLatency()
      const mergedDisplayName = request.displayName && request.displayName.trim().length > 0
        ? request.displayName.trim()
        : `${request.primary.displayName} × ${request.secondary.displayName}`
      return {
        agent: {
          agentId: `merged-${Date.now()}`,
          displayName: mergedDisplayName,
          personId: request.primary.personId,
          avatarSeed: request.primary.avatarSeed,
          timeLabel: request.primary.timeLabel,
          stageLabel: request.primary.stageLabel,
          keyEvent: request.primary.keyEvent,
          knownFacts: mergeStringListsLimited(request.primary.knownFacts, request.secondary.knownFacts, 6),
          sourceEvidence: request.primary.sourceEvidence,
          traits: mergeStringListsLimited(request.primary.traits, request.secondary.traits, 5),
          values: mergeStringListsLimited(request.primary.values, request.secondary.values, 5),
          goal: `${request.primary.goal}；同时兼顾 ${request.secondary.goal}`,
          fear: `${request.primary.fear}；也担心 ${request.secondary.fear}`,
          voiceStyle: request.primary.voiceStyle,
          knowledgeBoundary: request.primary.knowledgeBoundary,
          forbiddenFutureKnowledge: request.primary.forbiddenFutureKnowledge,
          stanceSeed: `${request.primary.stanceSeed} / ${request.secondary.stanceSeed}`
        },
        execution: {
          requestedModel: 'mock',
          requestedEffort: 'medium',
          effectiveModel: 'mock',
          effectiveEffort: 'medium',
          fallbackUsed: false,
          durationMs: MOCK_LATENCY_MS
        }
      }
    }
    try {
      return await requestJson<MergeAgentsResponse>(
        '/api/agents/merge',
        http.RequestMethod.POST,
        request,
        GENERATION_TIMEOUT_MS
      )
    } catch (error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(error as Object))
    }
  }

  static async runArena(
    topic: string,
    selectedAgents: PersonaSpec[],
    mode: ArenaMode = 'chat',
    roundCount?: number
  ): Promise<ArenaRun> {
    if (MOCK_MODE) {
      lastConnectionLabel = MOCK_LABEL
      await waitMockLatency()
      const run = buildMockArenaRun(topic, selectedAgents, mode)
      if (roundCount !== undefined && run.config) {
        run.config.roundCount = roundCount
      }
      storeMockRun(run)
      return Promise.resolve(run)
    }
    try {
      const arenaRequest: ArenaRunRequest = buildArenaRunRequest(topic, mode, selectedAgents, roundCount)
      const result = await requestJson<ArenaRunResponse>('/api/arena/run', http.RequestMethod.POST, arenaRequest, GENERATION_TIMEOUT_MS)
      return result.result
    } catch (error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(error as Object))
    }
  }

  static async runArenaDetailed(request: ArenaRunRequest): Promise<ArenaRunResponse> {
    if (MOCK_MODE) {
      lastConnectionLabel = MOCK_LABEL
      await waitMockLatency()
      const run = buildMockArenaRun(request.topic, request.agents, request.mode)
      run.continuedFromRunId = request.continueFromRunId
      run.sessionId = request.sessionId && request.sessionId.length > 0 ? request.sessionId : run.sessionId
      if (request.roundCount !== undefined && run.config) {
        run.config.roundCount = request.roundCount
      }
      storeMockRun(run)
      updateArenaRequestSummary(`${MOCK_LABEL} 路 ${request.agents.length} roles 路 ${request.topic.length} chars`)
      return {
        result: run,
        links: buildMockArenaLinks(run.runId)
      }
    }
    let lastError: Object = new Error('Arena request failed')
    for (let index = 0; index < ARENA_COMPACTION_PROFILES.length; index++) {
      const profile = ARENA_COMPACTION_PROFILES[index]
      const sanitized = sanitizeArenaRequest(request, profile)
      const payload = JSON.stringify(sanitized)
      updateArenaRequestSummary(
        buildArenaRequestSummary(
          profile,
          payload.length,
          index + 1,
          ARENA_COMPACTION_PROFILES.length,
          sanitized.selectedAgentIds.length,
          sanitized.guidance ? sanitized.guidance.length : 0
        )
      )

      try {
        const response = await requestJson<ArenaRunResponse>(
          '/api/arena/run',
          http.RequestMethod.POST,
          payload,
          GENERATION_TIMEOUT_MS
        )
        updateArenaRequestSummary(`${lastArenaRequestSummary} 路 ok`)
        return response
      } catch (error) {
        lastError = error as Object
        if (isPayloadTooLargeError(lastError) && index < ARENA_COMPACTION_PROFILES.length - 1) {
          updateArenaRequestSummary(`${lastArenaRequestSummary} 路 413 retry`)
          continue
        }
        if (isPayloadTooLargeError(lastError)) {
          updateArenaRequestSummary(`${lastArenaRequestSummary} 路 413 final`)
          throw new Error(
            'Meeting request is still too large after automatic front-end compression. The app is already sending the smallest agent payload, so the backend prompt/history or upstream body limit now needs to be reduced.'
          )
        }
        updateArenaRequestSummary(`${lastArenaRequestSummary} 路 failed`)
        throw new Error(formatThrownError(lastError))
      }
    }
    throw new Error(formatThrownError(lastError))
  }

  static async streamArena(
    topic: string,
    selectedAgents: PersonaSpec[],
    mode: ArenaMode = 'chat',
    onEvent?: SSEEventHandler,
    onError?: SSEErrorHandler,
    onComplete?: SSECompleteHandler,
    roundCount?: number,
    extras?: StreamArenaExtras
  ): Promise<void> {
    const arenaRequest: ArenaRunRequest = buildArenaRunRequest(topic, mode, selectedAgents, roundCount)
    if (extras !== undefined) {
      if (extras.guidance !== undefined && extras.guidance.trim().length > 0) {
        arenaRequest.guidance = extras.guidance.trim()
      }
      if (extras.continueFromRunId !== undefined && extras.continueFromRunId.length > 0) {
        arenaRequest.continueFromRunId = extras.continueFromRunId
      }
      if (extras.sessionId !== undefined && extras.sessionId.length > 0) {
        arenaRequest.sessionId = extras.sessionId
      }
    }
    return PersonaApi.streamArenaRequest(arenaRequest, onEvent, onError, onComplete)
  }

  static async streamArenaRequest(
    request: ArenaRunRequest,
    onEvent?: SSEEventHandler,
    onError?: SSEErrorHandler,
    onComplete?: SSECompleteHandler
  ): Promise<void> {
    if (MOCK_MODE) {
      lastConnectionLabel = MOCK_LABEL
      const run = buildMockArenaRun(request.topic, request.agents, request.mode)
      run.continuedFromRunId = request.continueFromRunId
      run.sessionId = request.sessionId && request.sessionId.length > 0 ? request.sessionId : run.sessionId
      if (request.roundCount !== undefined && run.config) {
        run.config.roundCount = request.roundCount
      }
      storeMockRun(run)
      updateArenaRequestSummary(`${MOCK_LABEL} 路 stream ${request.agents.length} roles`)
      await emitMockArenaStream(run, onEvent, onComplete)
      return
    }
    if (!LIVE_SUPPORTS_STREAM_API) {
      try {
        const fallbackRequest = buildSyntheticStreamRequest(request)
        const response = await PersonaApi.runArenaDetailed(fallbackRequest)
        await emitArenaRunAsSyntheticStream(response, onEvent, onComplete)
        return
      } catch (error) {
        lastConnectionLabel = 'API ERROR'
        onError?.(formatThrownError(error as Object))
        return
      }
    }
    const payload = JSON.stringify(sanitizeArenaRequest(request))
    let attemptErrors: string[] = []

    for (const baseUrl of getBaseUrlCandidates()) {
      const client = http.createHttp()

      try {
        activeBaseUrl = baseUrl
        lastConnectionLabel = buildConnectionLabel(baseUrl)
        await runArenaStreamInStreamMode(client, baseUrl, payload, onEvent, onError, onComplete)
        return
      } catch (error) {
        attemptErrors.push(`${baseUrl}: /api/arena/stream -> ${formatThrownError(error as Object)}`)
      } finally {
        client.destroy()
      }
    }

    lastConnectionLabel = 'API ERROR'
    onError?.(attemptErrors.length > 0 ? attemptErrors[0] : 'Stream request failed')
  }

  static async getArenaHistory(limit: number = 20): Promise<ArenaHistoryResponse> {
    if (shouldUseMockForFeature(LIVE_SUPPORTS_ARENA_HISTORY_API)) {
      markMockFeatureFallback()
      ensureMockRuns()
      await waitMockLatency()
      const normalizedLimit = Math.min(Math.max(Math.floor(limit), 1), 100)
      return {
        runs: mockArenaRuns.slice(0, normalizedLimit).map((item: ArenaRun) => buildMockHistoryItem(item))
      }
    }
    const normalizedLimit = Math.min(Math.max(Math.floor(limit), 1), 100)
    const query = buildQueryParam('limit', normalizedLimit)
    try {
      return await requestJson<ArenaHistoryResponse>(`/api/arena/history?${query}`, http.RequestMethod.GET)
    } catch (error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(error as Object))
    }
  }

  static async getArenaRunDetail(runId: string): Promise<ArenaRunDetailResponse> {
    if (shouldUseMockForFeature(LIVE_SUPPORTS_ARENA_RUN_DETAIL_API)) {
      markMockFeatureFallback()
      await waitMockLatency()
      return buildMockRunDetail(runId)
    }
    try {
      return await requestJson<ArenaRunDetailResponse>(
        `/api/arena/runs/${encodeURIComponent(runId)}`,
        http.RequestMethod.GET
      )
    } catch (error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(error as Object))
    }
  }

  static async getArenaRun(runId: string): Promise<ArenaRunDetailResponse> {
    return PersonaApi.getArenaRunDetail(runId)
  }

  static async interruptArenaSession(sessionId: string): Promise<ArenaSessionInterruptResponse> {
    const id = sessionId.trim()
    if (id.length === 0) {
      throw new Error('缺少 sessionId')
    }
    if (shouldUseMockForFeature(LIVE_SUPPORTS_ARENA_INTERRUPT_API)) {
      markMockFeatureFallback()
      await waitMockLatency(30)
      const matched = mockArenaRuns.find((item: ArenaRun) => item.sessionId === id)
      if (matched) {
        matched.status = 'interrupted'
      }
      return {
        ok: true,
        sessionId: id
      }
    }
    try {
      return await requestJson<ArenaSessionInterruptResponse>(
        `/api/arena/sessions/${encodeURIComponent(id)}/interrupt`,
        http.RequestMethod.POST
      )
    } catch (error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(error as Object))
    }
  }

  static async generateArenaPoster(request: ArenaPosterRequest): Promise<ArenaPosterResponse> {
    if (shouldUseMockForFeature(LIVE_SUPPORTS_ARENA_POSTER_API)) {
      markMockFeatureFallback()
      const runId = request.runId && request.runId.length > 0
        ? request.runId
        : (request.run ? request.run.runId : `mock-run-${Date.now()}`)
      const detail = request.run ? request.run : buildMockRunDetail(runId).result
      const title = detail.summary.title && detail.summary.title.length > 0 ? detail.summary.title : 'Mock 海报'
      const encodedTitle = encodeURIComponent(title)
      await waitMockLatency()
      return {
        runId,
        links: buildMockArenaLinks(runId),
        poster: {
          runId,
          title,
          summary: detail.summary.consensus,
          stylePreset: request.stylePreset ? request.stylePreset : 'editorial',
          aspectRatio: request.aspectRatio ? request.aspectRatio : '3:4',
          outputDir: 'mock://poster',
          imagePath: `mock://poster/${runId}.png`,
          imageUrl: `https://placehold.co/900x1200/png?text=${encodedTitle}`,
          sourcePath: `mock://poster/source/${runId}`,
          sourceUrl: `https://placehold.co/900x1200/png?text=${encodedTitle}`,
          promptPath: `mock://poster/prompt/${runId}.txt`,
          promptUrl: `https://mock.local/poster/${runId}/prompt`,
          generatedAt: new Date().toISOString()
        }
      }
    }
    try {
      return await requestJson<ArenaPosterResponse>(
        '/api/arena/poster',
        http.RequestMethod.POST,
        request,
        GENERATION_TIMEOUT_MS
      )
    } catch (error) {
      lastConnectionLabel = 'API ERROR'
      throw new Error(formatThrownError(error as Object))
    }
  }
}
