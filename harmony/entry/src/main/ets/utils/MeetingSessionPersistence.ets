import { ArenaRun, ArenaRunHistoryItem, ReasoningEffort } from '../common/Models'

export interface PersistedMeetingSessionPayload {
  profileId: string
  profileIds: string[]
  selectedAgentIds: string[]
  topic: string
  reasoningEffort: ReasoningEffort
  continueFromRunId: string
  sessionId: string
  historyRecords: ArenaRunHistoryItem[]
}

const DEFAULT_REASONING_EFFORT: ReasoningEffort = 'medium'
export const DEFAULT_PERSISTED_MEETING_HISTORY_LIMIT: number = 50

function normalizeString(value: string | undefined | null): string {
  return value ? value.trim() : ''
}

function normalizeStringArray(value: string[] | undefined | null): string[] {
  const next: string[] = []
  if (!value) {
    return next
  }

  value.forEach((item: string) => {
    const normalized = normalizeString(item)
    if (normalized.length > 0 && next.indexOf(normalized) < 0) {
      next.push(normalized)
    }
  })
  return next
}

function normalizeReasoningEffort(value: string | ReasoningEffort | undefined | null): ReasoningEffort {
  return value === 'low' || value === 'medium' || value === 'high' || value === 'xhigh'
    ? value
    : DEFAULT_REASONING_EFFORT
}

function normalizeHistoryRecord(record: Partial<ArenaRunHistoryItem>): ArenaRunHistoryItem | null {
  const runId = normalizeString(record.runId)
  if (runId.length <= 0) {
    return null
  }

  const participantNames = normalizeStringArray(record.participantNames)
  const participantAgentIds = normalizeStringArray(record.participantAgentIds)
  const profileIds = normalizeStringArray(record.profileIds)
  const mode = record.mode === 'debate' ? 'debate' : 'chat'
  const messageCount = typeof record.messageCount === 'number' ? record.messageCount : 0
  const participantCount = typeof record.participantCount === 'number'
    ? record.participantCount
    : participantNames.length

  return {
    runId: runId,
    sessionId: normalizeString(record.sessionId),
    continuedFromRunId: normalizeString(record.continuedFromRunId),
    status: record.status === 'interrupted' ? 'interrupted' : 'completed',
    mode: mode,
    topic: normalizeString(record.topic),
    title: normalizeString(record.title),
    consensus: normalizeString(record.consensus),
    participantNames: participantNames,
    participantStages: normalizeStringArray(record.participantStages),
    participantAgentIds: participantAgentIds,
    profileIds: profileIds,
    participantCount: participantCount,
    messageCount: messageCount,
    summaryTitle: normalizeString(record.summaryTitle),
    consensusPreview: normalizeString(record.consensusPreview),
    latestGuidance: normalizeString(record.latestGuidance),
    createdAt: normalizeString(record.createdAt)
  }
}

function normalizeHistoryRecords(records: ArenaRunHistoryItem[] | undefined | null): ArenaRunHistoryItem[] {
  const next: ArenaRunHistoryItem[] = []
  if (!records) {
    return next
  }

  records.forEach((record: ArenaRunHistoryItem) => {
    const normalized = normalizeHistoryRecord(record)
    if (normalized) {
      next.push(normalized)
    }
  })
  return next
}

export function normalizePersistedMeetingSessionPayload(
  payload?: Partial<PersistedMeetingSessionPayload> | null
): PersistedMeetingSessionPayload {
  const profileId = normalizeString(payload?.profileId)
  const profileIds = normalizeStringArray(payload?.profileIds)
  const selectedAgentIds = normalizeStringArray(payload?.selectedAgentIds)
  const topic = normalizeString(payload?.topic)
  const reasoningEffort = normalizeReasoningEffort(payload?.reasoningEffort)
  const continueFromRunId = normalizeString(payload?.continueFromRunId)
  const sessionId = normalizeString(payload?.sessionId)
  const historyRecords = normalizeHistoryRecords(payload?.historyRecords)

  return {
    profileId: profileId.length > 0 ? profileId : (profileIds.length > 0 ? profileIds[0] : ''),
    profileIds: profileIds,
    selectedAgentIds: selectedAgentIds,
    topic: topic,
    reasoningEffort: reasoningEffort,
    continueFromRunId: continueFromRunId,
    sessionId: sessionId,
    historyRecords: historyRecords
  }
}

function toTimestamp(record: ArenaRunHistoryItem): number {
  const createdAt = normalizeString(record.createdAt)
  if (createdAt.length <= 0) {
    return 0
  }
  const parsed = new Date(createdAt).getTime()
  return Number.isNaN(parsed) ? 0 : parsed
}

export function upsertMeetingHistoryRecord(
  records: ArenaRunHistoryItem[],
  record: Partial<ArenaRunHistoryItem>,
  limit: number = DEFAULT_PERSISTED_MEETING_HISTORY_LIMIT
): ArenaRunHistoryItem[] {
  const normalized = normalizeHistoryRecord(record)
  if (!normalized) {
    return [...records]
  }

  const next = [normalized, ...records.filter((item: ArenaRunHistoryItem) => item.runId !== normalized.runId)]
  next.sort((left: ArenaRunHistoryItem, right: ArenaRunHistoryItem) => {
    return toTimestamp(right) - toTimestamp(left)
  })

  return next.slice(0, Math.max(1, limit))
}

export function mergeMeetingHistoryRecords(
  primary: ArenaRunHistoryItem[],
  secondary: ArenaRunHistoryItem[],
  limit: number = DEFAULT_PERSISTED_MEETING_HISTORY_LIMIT
): ArenaRunHistoryItem[] {
  let merged: ArenaRunHistoryItem[] = normalizeHistoryRecords(primary)
  normalizeHistoryRecords(secondary).forEach((record: ArenaRunHistoryItem) => {
    merged = upsertMeetingHistoryRecord(merged, record, limit)
  })
  return merged
}

export function buildHistoryRecordFromArenaRun(
  run: ArenaRun,
  profileIds: string[],
  latestGuidance?: string
): ArenaRunHistoryItem {
  return {
    runId: run.runId,
    sessionId: run.sessionId,
    continuedFromRunId: run.continuedFromRunId,
    status: run.status ?? 'completed',
    mode: run.mode,
    topic: run.topic,
    title: run.summary.title,
    consensus: run.summary.consensus,
    participantNames: run.participants.map((participant) => participant.displayName),
    participantStages: run.participants.map((participant) => participant.stageLabel),
    participantAgentIds: run.participants.map((participant) => participant.agentId),
    profileIds: normalizeStringArray(profileIds),
    participantCount: run.participants.length,
    messageCount: run.messages.length,
    summaryTitle: run.summary.title,
    consensusPreview: run.summary.consensus.length > 80
      ? `${run.summary.consensus.slice(0, 80)}...`
      : run.summary.consensus,
    latestGuidance: latestGuidance ? latestGuidance.trim() : '',
    createdAt: run.createdAt && run.createdAt.length > 0 ? run.createdAt : new Date().toISOString()
  }
}
