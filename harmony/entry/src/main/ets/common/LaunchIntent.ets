import type { ArenaRunHistoryItem, ReasoningEffort, RouteParams } from './Models'

export type LaunchAction =
  | 'none'
  | 'continue-meeting'
  | 'new-meeting'
  | 'open-recent-summaries'
  | 'open-summary-detail'

export interface LaunchIntent {
  action: LaunchAction
  targetPage: string
  continueFromRunId: string
  sessionId: string
  summaryId: string
  arenaRunId: string
  topic: string
  profileIds: string[]
  selectedAgentIds: string[]
  reasoningEffort: ReasoningEffort
}

export interface RecentMeetingSnapshot {
  hasContinueMeeting: boolean
  continueFromRunId: string
  sessionId: string
  topic: string
  participantSummary: string
  participantCount: number
  profileIds: string[]
  selectedAgentIds: string[]
  reasoningEffort: ReasoningEffort
  createdAt: string
}

export interface LaunchWantParams {
  launchAction: string
  continueFromRunId: string
  sessionId: string
  summaryId: string
  arenaRunId: string
  topic: string
  profileIds: string
  selectedAgentIds: string
  reasoningEffort: string
}

export type QuickActionName = 'continue-meeting' | 'new-meeting' | 'open-recent-summaries'

const DEFAULT_TARGET_PAGE: string = 'pages/Index'
const CONTINUE_MEETING_PATH: string = '/meeting/continue'
const NEW_MEETING_PATH: string = '/meeting/new'
const RECENT_SUMMARIES_PATH: string = '/summaries/recent'
const SUMMARY_DETAIL_PATH: string = '/summary/detail'

function normalizeString(value?: string | null): string {
  return value ? value.trim() : ''
}

function normalizeStringArray(values?: string[] | null): string[] {
  const next: string[] = []
  if (!values) {
    return next
  }

  values.forEach((value: string) => {
    const normalized = normalizeString(value)
    if (normalized.length > 0 && next.indexOf(normalized) < 0) {
      next.push(normalized)
    }
  })
  return next
}

function normalizeReasoningEffort(value?: string | null): ReasoningEffort {
  return value === 'low' || value === 'medium' || value === 'high' || value === 'xhigh'
    ? value
    : 'medium'
}

function parseQueryString(query: string): Record<string, string> {
  const result: Record<string, string> = {}
  if (query.length <= 0) {
    return result
  }

  query.split('&').forEach((part: string) => {
    const index = part.indexOf('=')
    if (index < 0) {
      result[decodeURIComponent(part)] = ''
      return
    }

    const key = decodeURIComponent(part.slice(0, index))
    const value = decodeURIComponent(part.slice(index + 1))
    result[key] = value
  })
  return result
}

function parseDelimitedIds(raw: string): string[] {
  return normalizeStringArray(raw.split(','))
}

function encodeDelimitedIds(values: string[]): string {
  return normalizeStringArray(values).join(',')
}

function emptyLaunchIntent(): LaunchIntent {
  return {
    action: 'none',
    targetPage: DEFAULT_TARGET_PAGE,
    continueFromRunId: '',
    sessionId: '',
    summaryId: '',
    arenaRunId: '',
    topic: '',
    profileIds: [],
    selectedAgentIds: [],
    reasoningEffort: 'medium'
  }
}

function buildLaunchIntent(action: LaunchAction, overrides?: Partial<LaunchIntent>): LaunchIntent {
  const base = emptyLaunchIntent()
  const targetPage = action === 'continue-meeting'
    ? 'pages/MeetingChatPage'
    : (action === 'open-recent-summaries'
      ? 'pages/SummaryListPage'
      : (action === 'open-summary-detail' ? 'pages/SummaryDetailPage' : DEFAULT_TARGET_PAGE))

  return {
    action: action,
    targetPage: targetPage,
    continueFromRunId: normalizeString(overrides?.continueFromRunId),
    sessionId: normalizeString(overrides?.sessionId),
    summaryId: normalizeString(overrides?.summaryId),
    arenaRunId: normalizeString(overrides?.arenaRunId),
    topic: normalizeString(overrides?.topic),
    profileIds: normalizeStringArray(overrides?.profileIds),
    selectedAgentIds: normalizeStringArray(overrides?.selectedAgentIds),
    reasoningEffort: normalizeReasoningEffort(overrides?.reasoningEffort ?? base.reasoningEffort)
  }
}

export function parseLaunchIntentFromUri(uri?: string | null): LaunchIntent {
  const normalizedUri = normalizeString(uri)
  if (!normalizedUri.startsWith('timepersona://')) {
    return emptyLaunchIntent()
  }

  const afterScheme = normalizedUri.slice('timepersona://'.length)
  const queryIndex = afterScheme.indexOf('?')
  const rawPath = queryIndex >= 0 ? afterScheme.slice(0, queryIndex) : afterScheme
  const query = queryIndex >= 0 ? afterScheme.slice(queryIndex + 1) : ''
  const path = rawPath.startsWith('/') ? rawPath : `/${rawPath}`
  const params = parseQueryString(query)

  if (path === CONTINUE_MEETING_PATH) {
    return buildLaunchIntent('continue-meeting', {
      continueFromRunId: params['runId'],
      sessionId: params['sessionId'],
      topic: params['topic'],
      profileIds: parseDelimitedIds(params['profileIds'] ?? ''),
      selectedAgentIds: parseDelimitedIds(params['selectedAgentIds'] ?? ''),
      reasoningEffort: normalizeReasoningEffort(params['reasoningEffort'])
    })
  }

  if (path === NEW_MEETING_PATH) {
    return buildLaunchIntent('new-meeting')
  }

  if (path === RECENT_SUMMARIES_PATH) {
    return buildLaunchIntent('open-recent-summaries')
  }

  if (path === SUMMARY_DETAIL_PATH) {
    return buildLaunchIntent('open-summary-detail', {
      summaryId: params['summaryId'],
      arenaRunId: params['arenaRunId']
    })
  }

  return emptyLaunchIntent()
}

export function buildContinueMeetingUri(intent: Partial<LaunchIntent>): string {
  const params: string[] = []

  if (normalizeString(intent.continueFromRunId).length > 0) {
    params.push(`runId=${encodeURIComponent(normalizeString(intent.continueFromRunId))}`)
  }
  if (normalizeString(intent.sessionId).length > 0) {
    params.push(`sessionId=${encodeURIComponent(normalizeString(intent.sessionId))}`)
  }
  if (normalizeString(intent.topic).length > 0) {
    params.push(`topic=${encodeURIComponent(normalizeString(intent.topic))}`)
  }
  if (normalizeStringArray(intent.profileIds).length > 0) {
    params.push(`profileIds=${encodeURIComponent(encodeDelimitedIds(intent.profileIds ?? []))}`)
  }
  if (normalizeStringArray(intent.selectedAgentIds).length > 0) {
    params.push(`selectedAgentIds=${encodeURIComponent(encodeDelimitedIds(intent.selectedAgentIds ?? []))}`)
  }
  params.push(`reasoningEffort=${encodeURIComponent(normalizeReasoningEffort(intent.reasoningEffort))}`)

  return `timepersona://${CONTINUE_MEETING_PATH.slice(1)}?${params.join('&')}`
}

export function buildContinueMeetingShareText(intent: Partial<LaunchIntent>): string {
  const uri = buildContinueMeetingUri(intent)
  const topic = normalizeString(intent.topic)

  if (topic.length > 0) {
    return `继续这场会议：${topic}\n${uri}`
  }

  return `继续这场会议\n${uri}`
}

export function buildSummaryDetailUri(summaryId?: string | null, arenaRunId?: string | null): string {
  const params: string[] = []
  const normalizedSummaryId = normalizeString(summaryId)
  const normalizedArenaRunId = normalizeString(arenaRunId)

  if (normalizedSummaryId.length > 0) {
    params.push(`summaryId=${encodeURIComponent(normalizedSummaryId)}`)
  }
  if (normalizedArenaRunId.length > 0) {
    params.push(`arenaRunId=${encodeURIComponent(normalizedArenaRunId)}`)
  }

  return `timepersona://${SUMMARY_DETAIL_PATH.slice(1)}${params.length > 0 ? `?${params.join('&')}` : ''}`
}

export function buildLaunchIntentFromQuickAction(action: QuickActionName, snapshot?: Partial<RecentMeetingSnapshot>): LaunchIntent {
  if (action === 'continue-meeting') {
    return buildLaunchIntent('continue-meeting', {
      continueFromRunId: snapshot?.continueFromRunId,
      sessionId: snapshot?.sessionId,
      topic: snapshot?.topic,
      profileIds: snapshot?.profileIds,
      selectedAgentIds: snapshot?.selectedAgentIds,
      reasoningEffort: snapshot?.reasoningEffort
    })
  }
  if (action === 'open-recent-summaries') {
    return buildLaunchIntent('open-recent-summaries')
  }
  return buildLaunchIntent('new-meeting')
}

function readWantParamString(params: Record<string, Object> | undefined, key: string): string {
  if (!params) {
    return ''
  }
  const value = params[key]
  if (typeof value === 'string') {
    return normalizeString(value)
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    return `${value}`
  }
  return ''
}

export function parseLaunchIntentFromWant(
  uri?: string | null,
  params?: Record<string, Object>
): LaunchIntent {
  const fromUri = parseLaunchIntentFromUri(uri)
  if (fromUri.action !== 'none') {
    return fromUri
  }

  const action = readWantParamString(params, 'launchAction') as LaunchAction
  if (action !== 'continue-meeting' &&
    action !== 'new-meeting' &&
    action !== 'open-recent-summaries' &&
    action !== 'open-summary-detail') {
    return emptyLaunchIntent()
  }

  return buildLaunchIntent(action, {
    continueFromRunId: readWantParamString(params, 'continueFromRunId'),
    sessionId: readWantParamString(params, 'sessionId'),
    summaryId: readWantParamString(params, 'summaryId'),
    arenaRunId: readWantParamString(params, 'arenaRunId'),
    topic: readWantParamString(params, 'topic'),
    profileIds: parseDelimitedIds(readWantParamString(params, 'profileIds')),
    selectedAgentIds: parseDelimitedIds(readWantParamString(params, 'selectedAgentIds')),
    reasoningEffort: normalizeReasoningEffort(readWantParamString(params, 'reasoningEffort'))
  })
}

export function buildRouteParamsFromLaunchIntent(intent: LaunchIntent): RouteParams {
  return {
    profileIds: encodeDelimitedIds(intent.profileIds),
    selectedAgentIds: encodeDelimitedIds(intent.selectedAgentIds),
    topic: intent.topic,
    continueFromRunId: intent.continueFromRunId,
    sessionId: intent.sessionId,
    summaryId: intent.summaryId,
    arenaRunId: intent.arenaRunId,
    reasoningEffort: intent.reasoningEffort
  }
}

export function buildWantParamsFromLaunchIntent(intent: LaunchIntent): LaunchWantParams {
  return {
    launchAction: intent.action,
    continueFromRunId: intent.continueFromRunId,
    sessionId: intent.sessionId,
    summaryId: intent.summaryId,
    arenaRunId: intent.arenaRunId,
    topic: intent.topic,
    profileIds: encodeDelimitedIds(intent.profileIds),
    selectedAgentIds: encodeDelimitedIds(intent.selectedAgentIds),
    reasoningEffort: intent.reasoningEffort
  }
}

export function buildRecentMeetingSnapshot(
  records: ArenaRunHistoryItem[],
  reasoningEffort: ReasoningEffort = 'medium'
): RecentMeetingSnapshot {
  const latest = records.length > 0 ? records[0] : null
  if (!latest) {
    return {
      hasContinueMeeting: false,
      continueFromRunId: '',
      sessionId: '',
      topic: '',
      participantSummary: '暂无可继续会议',
      participantCount: 0,
      profileIds: [],
      selectedAgentIds: [],
      reasoningEffort: reasoningEffort,
      createdAt: ''
    }
  }

  return {
    hasContinueMeeting: normalizeString(latest.runId).length > 0 && normalizeStringArray(latest.participantAgentIds).length >= 2,
    continueFromRunId: normalizeString(latest.runId),
    sessionId: normalizeString(latest.sessionId),
    topic: normalizeString(latest.topic),
    participantSummary: normalizeStringArray(latest.participantNames).join('、'),
    participantCount: latest.participantCount ?? normalizeStringArray(latest.participantNames).length,
    profileIds: normalizeStringArray(latest.profileIds),
    selectedAgentIds: normalizeStringArray(latest.participantAgentIds),
    reasoningEffort: reasoningEffort,
    createdAt: normalizeString(latest.createdAt)
  }
}
