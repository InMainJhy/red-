import { common } from '@kit.AbilityKit'
import dataPreferences from '@ohos.data.preferences'
import { ArenaRunHistoryItem, ReasoningEffort } from '../common/Models'
import {
  DEFAULT_PERSISTED_MEETING_HISTORY_LIMIT,
  PersistedMeetingSessionPayload,
  mergeMeetingHistoryRecords,
  normalizePersistedMeetingSessionPayload,
  upsertMeetingHistoryRecord
} from './MeetingSessionPersistence'

const STORAGE_KEY_SESSION = 'meeting_session'

let meetingPrefs: dataPreferences.Preferences | null = null

/**
 * MeetingSessionStore - 页面间传递会议相关数据
 * 支持单场会议关联多个人物（多个 profileId），每人可有多个阶段人格 agent
 */
export class MeetingSessionStore {
  private static _profileId: string = ''
  private static _profileIds: string[] = []
  private static _selectedAgentIds: string[] = []
  private static _topic: string = ''
  /** 会议推理强度，默认 medium */
  private static _reasoningEffort: ReasoningEffort = 'medium'
  /** 从「添加人物」页返回时写入，参会页 onPageShow 消费后清空 */
  private static _pendingAddProfileId: string = ''
  /** 最近一次可续聊会议上下文 */
  private static _continueFromRunId: string = ''
  private static _sessionId: string = ''
  private static _historyRecords: ArenaRunHistoryItem[] = []
  private static _hydrated: boolean = false

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (!meetingPrefs) {
      try {
        meetingPrefs = await dataPreferences.getPreferences(context, 'time_persona_meeting_store')
      } catch (error) {
        console.error('[MeetingSessionStore] init failed:', error)
        return
      }
    }
    if (!MeetingSessionStore._hydrated) {
      await MeetingSessionStore.hydrate()
    }
  }

  private static async hydrate(): Promise<void> {
    if (!meetingPrefs) {
      return
    }

    try {
      const raw = await meetingPrefs.get(STORAGE_KEY_SESSION, '')
      let payload: PersistedMeetingSessionPayload | null = null
      if (typeof raw === 'string' && raw.trim().length > 0) {
        try {
          payload = JSON.parse(raw) as PersistedMeetingSessionPayload
        } catch (_error) {
          payload = null
        }
      }
      MeetingSessionStore.applyPayload(normalizePersistedMeetingSessionPayload(payload))
    } catch (error) {
      console.error('[MeetingSessionStore] hydrate failed:', error)
    } finally {
      MeetingSessionStore._hydrated = true
    }
  }

  private static applyPayload(payload: PersistedMeetingSessionPayload): void {
    MeetingSessionStore._profileId = payload.profileId
    MeetingSessionStore._profileIds = [...payload.profileIds]
    MeetingSessionStore._selectedAgentIds = [...payload.selectedAgentIds]
    MeetingSessionStore._topic = payload.topic
    MeetingSessionStore._reasoningEffort = payload.reasoningEffort
    MeetingSessionStore._continueFromRunId = payload.continueFromRunId
    MeetingSessionStore._sessionId = payload.sessionId
    MeetingSessionStore._historyRecords = [...payload.historyRecords]
  }

  private static snapshot(): PersistedMeetingSessionPayload {
    return normalizePersistedMeetingSessionPayload({
      profileId: MeetingSessionStore._profileId,
      profileIds: [...MeetingSessionStore._profileIds],
      selectedAgentIds: [...MeetingSessionStore._selectedAgentIds],
      topic: MeetingSessionStore._topic,
      reasoningEffort: MeetingSessionStore._reasoningEffort,
      continueFromRunId: MeetingSessionStore._continueFromRunId,
      sessionId: MeetingSessionStore._sessionId,
      historyRecords: [...MeetingSessionStore._historyRecords]
    })
  }

  private static persist(): void {
    if (!meetingPrefs || !MeetingSessionStore._hydrated) {
      return
    }

    const prefs = meetingPrefs
    const payload = JSON.stringify(MeetingSessionStore.snapshot())
    void prefs.put(STORAGE_KEY_SESSION, payload)
      .then(() => prefs.flush())
      .catch((error: Error) => {
        console.error('[MeetingSessionStore] persist failed:', error)
      })
  }

  static setProfileId(profileId: string): void {
    MeetingSessionStore._profileId = profileId.trim()
    MeetingSessionStore.persist()
  }

  static getProfileId(): string {
    return MeetingSessionStore._profileId
  }

  static setProfileIds(ids: string[]): void {
    MeetingSessionStore._profileIds = normalizePersistedMeetingSessionPayload({ profileIds: ids }).profileIds
    if (MeetingSessionStore._profileIds.length > 0) {
      MeetingSessionStore._profileId = MeetingSessionStore._profileIds[0]
    }
    MeetingSessionStore.persist()
  }

  static getProfileIds(): string[] {
    return [...MeetingSessionStore._profileIds]
  }

  static setPendingAddProfileId(profileId: string): void {
    MeetingSessionStore._pendingAddProfileId = profileId
  }

  static takePendingAddProfileId(): string {
    const v = MeetingSessionStore._pendingAddProfileId
    MeetingSessionStore._pendingAddProfileId = ''
    return v
  }

  static setSelectedAgents(ids: string[]): void {
    MeetingSessionStore._selectedAgentIds = normalizePersistedMeetingSessionPayload({ selectedAgentIds: ids }).selectedAgentIds
    MeetingSessionStore.persist()
  }

  static getSelectedAgents(): string[] {
    return [...MeetingSessionStore._selectedAgentIds]
  }

  static setTopic(topic: string): void {
    MeetingSessionStore._topic = topic.trim()
    MeetingSessionStore.persist()
  }

  static getTopic(): string {
    return MeetingSessionStore._topic
  }

  static setReasoningEffort(effort: ReasoningEffort): void {
    MeetingSessionStore._reasoningEffort = normalizePersistedMeetingSessionPayload({ reasoningEffort: effort }).reasoningEffort
    MeetingSessionStore.persist()
  }

  static getReasoningEffort(): ReasoningEffort {
    return MeetingSessionStore._reasoningEffort
  }

  static setContinueContext(runId: string, sessionId?: string): void {
    MeetingSessionStore._continueFromRunId = runId.trim()
    MeetingSessionStore._sessionId = sessionId ? sessionId.trim() : ''
    MeetingSessionStore.persist()
  }

  static clearContinueContext(): void {
    MeetingSessionStore._continueFromRunId = ''
    MeetingSessionStore._sessionId = ''
    MeetingSessionStore.persist()
  }

  static getContinueFromRunId(): string {
    return MeetingSessionStore._continueFromRunId
  }

  static getSessionId(): string {
    return MeetingSessionStore._sessionId
  }

  static setHistoryRecords(records: ArenaRunHistoryItem[]): void {
    MeetingSessionStore._historyRecords = mergeMeetingHistoryRecords(records, [], DEFAULT_PERSISTED_MEETING_HISTORY_LIMIT)
    MeetingSessionStore.persist()
  }

  static mergeHistoryRecords(records: ArenaRunHistoryItem[]): ArenaRunHistoryItem[] {
    MeetingSessionStore._historyRecords = mergeMeetingHistoryRecords(records, MeetingSessionStore._historyRecords)
    MeetingSessionStore.persist()
    return [...MeetingSessionStore._historyRecords]
  }

  static upsertHistoryRecord(record: Partial<ArenaRunHistoryItem>): void {
    MeetingSessionStore._historyRecords = upsertMeetingHistoryRecord(
      MeetingSessionStore._historyRecords,
      record,
      DEFAULT_PERSISTED_MEETING_HISTORY_LIMIT
    )
    MeetingSessionStore.persist()
  }

  static getHistoryRecords(): ArenaRunHistoryItem[] {
    return [...MeetingSessionStore._historyRecords]
  }

  static clear(): void {
    MeetingSessionStore._profileId = ''
    MeetingSessionStore._profileIds = []
    MeetingSessionStore._selectedAgentIds = []
    MeetingSessionStore._topic = ''
    MeetingSessionStore._reasoningEffort = 'medium'
    MeetingSessionStore._pendingAddProfileId = ''
    MeetingSessionStore._continueFromRunId = ''
    MeetingSessionStore._sessionId = ''
    MeetingSessionStore.persist()
  }
}
