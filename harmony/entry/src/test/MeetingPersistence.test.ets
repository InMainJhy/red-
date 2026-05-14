import { describe, it, expect } from '@ohos/hypium'
import { buildMeetingRouteParams } from '../main/ets/common/MeetingSelection'
import {
  normalizePersistedMeetingSessionPayload,
  upsertMeetingHistoryRecord
} from '../main/ets/utils/MeetingSessionPersistence'
import { upsertSummaryRecordByArenaRunId } from '../main/ets/service/SummarySyncUtils'
import type { SummaryRecord } from '../main/ets/common/Models'

function buildSummaryRecord(
  id: string,
  arenaRunId: string,
  title: string,
  isFavorite: boolean = false
): SummaryRecord {
  return {
    id: id,
    title: title,
    topic: 'topic',
    createdAt: '2026-05-14T00:00:00.000Z',
    updatedAt: '2026-05-14T00:00:00.000Z',
    duration: 0,
    messageCount: 3,
    consensus: 'consensus',
    disagreements: [],
    actionableAdvice: [],
    narrativeHook: '',
    participants: [],
    highlights: [],
    tags: [],
    isFavorite: isFavorite,
    viewCount: 0,
    exportedAssets: [],
    messageIds: [],
    arenaRunId: arenaRunId
  }
}

export default function meetingPersistenceTest() {
  describe('meetingPersistence', () => {
    it('drops legacy roundCount when building meeting route params', 0, () => {
      const params = buildMeetingRouteParams(
        {
          profileIds: ['confucius'],
          selectedAgentIds: ['confucius-early', 'confucius-late']
        },
        {
          topic: '继续聊',
          roundCount: 12,
          reasoningEffort: 'high'
        }
      )

      expect(params.roundCount === undefined).assertTrue()
      expect(params.reasoningEffort).assertEqual('high')
      expect(typeof params.profileIds).assertEqual('string')
      expect(typeof params.selectedAgentIds).assertEqual('string')
    })

    it('normalizes persisted meeting payload and falls back to safe defaults', 0, () => {
      const normalized = normalizePersistedMeetingSessionPayload({
        profileId: '  confucius  ',
        profileIds: ['confucius', 'confucius', '  musk '],
        selectedAgentIds: ['a', 'a', ' b '],
        topic: '  要不要继续创业  ',
        reasoningEffort: 'invalid',
        continueFromRunId: ' run-1 ',
        sessionId: ' session-1 '
      })

      expect(normalized.profileId).assertEqual('confucius')
      expect(normalized.profileIds.length).assertEqual(2)
      expect(normalized.profileIds[1]).assertEqual('musk')
      expect(normalized.selectedAgentIds.length).assertEqual(2)
      expect(normalized.topic).assertEqual('要不要继续创业')
      expect(normalized.reasoningEffort).assertEqual('medium')
      expect(normalized.continueFromRunId).assertEqual('run-1')
      expect(normalized.sessionId).assertEqual('session-1')
    })

    it('upserts meeting history by runId without duplicating entries', 0, () => {
      const history = upsertMeetingHistoryRecord([
        {
          runId: 'run-1',
          topic: 'old topic',
          title: 'old title',
          participantNames: ['孔子'],
          participantAgentIds: ['a1', 'a2'],
          profileIds: ['confucius'],
          createdAt: '2026-05-14T09:00:00.000Z'
        }
      ], {
        runId: 'run-1',
        topic: 'new topic',
        title: 'new title',
        participantNames: ['孔子', '马斯克'],
        participantAgentIds: ['a1', 'b2'],
        profileIds: ['confucius', 'musk'],
        createdAt: '2026-05-14T10:00:00.000Z'
      })

      expect(history.length).assertEqual(1)
      expect(history[0].topic).assertEqual('new topic')
      expect(history[0].participantNames.length).assertEqual(2)
    })

    it('reuses existing summary id when syncing the same arena run again', 0, () => {
      const existing = buildSummaryRecord('summary-1', 'run-1', '第一次纪要', true)
      const incoming = buildSummaryRecord('summary-2', 'run-1', '更新后的纪要', false)

      const next = upsertSummaryRecordByArenaRunId([existing], incoming)

      expect(next.length).assertEqual(1)
      expect(next[0].id).assertEqual('summary-1')
      expect(next[0].title).assertEqual('更新后的纪要')
      expect(next[0].isFavorite).assertTrue()
    })
  })
}
