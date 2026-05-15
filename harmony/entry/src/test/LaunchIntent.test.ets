import { describe, it, expect } from '@ohos/hypium'
import {
  buildContinueMeetingShareText,
  buildContinueMeetingUri,
  buildLaunchIntentFromQuickAction,
  buildRecentMeetingSnapshot,
  buildSummaryDetailUri,
  buildWantParamsFromLaunchIntent,
  parseLaunchIntentFromUri,
  type LaunchIntent
} from '../main/ets/common/LaunchIntent'
import type { ArenaRunHistoryItem } from '../main/ets/common/Models'

function buildHistoryRecord(overrides?: Partial<ArenaRunHistoryItem>): ArenaRunHistoryItem {
  return {
    runId: overrides?.runId ?? 'run-1',
    sessionId: overrides?.sessionId ?? 'session-1',
    continuedFromRunId: overrides?.continuedFromRunId,
    status: overrides?.status ?? 'completed',
    mode: overrides?.mode ?? 'chat',
    topic: overrides?.topic ?? 'Should I keep building?',
    title: overrides?.title ?? 'Late-night meeting',
    consensus: overrides?.consensus ?? 'Keep going',
    participantNames: overrides?.participantNames ?? ['乔布斯', '马斯克'],
    participantStages: overrides?.participantStages ?? ['重建期', '创业期'],
    participantAgentIds: overrides?.participantAgentIds ?? ['jobs-rebuild', 'musk-early'],
    profileIds: overrides?.profileIds ?? ['jobs', 'musk'],
    participantCount: overrides?.participantCount ?? 2,
    messageCount: overrides?.messageCount ?? 6,
    summaryTitle: overrides?.summaryTitle ?? 'Late-night meeting',
    consensusPreview: overrides?.consensusPreview ?? 'Keep going',
    latestGuidance: overrides?.latestGuidance ?? '',
    createdAt: overrides?.createdAt ?? '2026-05-15T08:10:00.000Z'
  }
}

export default function launchIntentTest() {
  describe('launchIntent', () => {
    it('parses continue-meeting deep link into normalized launch intent', 0, () => {
      const uri = buildContinueMeetingUri({
        continueFromRunId: 'run-7',
        sessionId: 'session-9',
        topic: '继续讨论创业节奏',
        profileIds: ['jobs', 'musk'],
        selectedAgentIds: ['jobs-late', 'musk-early'],
        reasoningEffort: 'high'
      })

      const intent = parseLaunchIntentFromUri(uri)

      expect(intent.action).assertEqual('continue-meeting')
      expect(intent.continueFromRunId).assertEqual('run-7')
      expect(intent.sessionId).assertEqual('session-9')
      expect(intent.profileIds.length).assertEqual(2)
      expect(intent.selectedAgentIds.length).assertEqual(2)
      expect(intent.reasoningEffort).assertEqual('high')
      expect(intent.topic).assertEqual('继续讨论创业节奏')
    })

    it('builds summary-list launch intent from quick action name', 0, () => {
      const intent = buildLaunchIntentFromQuickAction('open-recent-summaries')

      expect(intent.action).assertEqual('open-recent-summaries')
      expect(intent.targetPage).assertEqual('pages/SummaryListPage')
    })

    it('creates a recent meeting snapshot from latest history record', 0, () => {
      const snapshot = buildRecentMeetingSnapshot([
        buildHistoryRecord({ runId: 'run-older', createdAt: '2026-05-14T01:00:00.000Z' }),
        buildHistoryRecord({
          runId: 'run-latest',
          sessionId: 'session-latest',
          topic: '要不要继续做这个功能',
          createdAt: '2026-05-15T09:20:00.000Z',
          participantNames: ['孔子', '苏格拉底', '乔布斯'],
          participantAgentIds: ['a', 'b', 'c'],
          profileIds: ['confucius', 'socrates', 'jobs']
        })
      ])

      expect(snapshot.hasContinueMeeting).assertTrue()
      expect(snapshot.continueFromRunId).assertEqual('run-latest')
      expect(snapshot.sessionId).assertEqual('session-latest')
      expect(snapshot.topic).assertEqual('要不要继续做这个功能')
      expect(snapshot.participantSummary).assertEqual('孔子、苏格拉底、乔布斯')
      expect(snapshot.participantCount).assertEqual(3)
    })

    it('builds share text for continue-meeting links', 0, () => {
      const shareText = buildContinueMeetingShareText({
        continueFromRunId: 'run-share',
        sessionId: 'session-share',
        topic: '继续讨论产品方向',
        profileIds: ['jobs', 'musk'],
        selectedAgentIds: ['jobs-late', 'musk-early'],
        reasoningEffort: 'medium'
      })

      expect(shareText.includes('继续这场会议：继续讨论产品方向')).assertTrue()
      expect(shareText.includes('timepersona://meeting/continue?')).assertTrue()
      expect(shareText.includes('runId=run-share')).assertTrue()
    })

    it('serializes launch intent into want params for continuation restore', 0, () => {
      const params = buildWantParamsFromLaunchIntent({
        action: 'continue-meeting',
        targetPage: 'pages/MeetingChatPage',
        continueFromRunId: 'run-continue',
        sessionId: 'session-continue',
        topic: '继续讨论接续体验',
        profileIds: ['jobs', 'musk'],
        selectedAgentIds: ['jobs-late', 'musk-early'],
        reasoningEffort: 'high'
      })

      expect(params['launchAction'] as string).assertEqual('continue-meeting')
      expect(params['continueFromRunId'] as string).assertEqual('run-continue')
      expect(params['sessionId'] as string).assertEqual('session-continue')
      expect(params['profileIds'] as string).assertEqual('jobs,musk')
      expect(params['selectedAgentIds'] as string).assertEqual('jobs-late,musk-early')
      expect(params['reasoningEffort'] as string).assertEqual('high')
    })

    it('builds and parses summary-detail deep link', 0, () => {
      const uri = buildSummaryDetailUri('summary-7', 'run-9')
      const intent = parseLaunchIntentFromUri(uri)

      expect(uri).assertEqual('timepersona://summary/detail?summaryId=summary-7&arenaRunId=run-9')
      expect(intent.action).assertEqual('open-summary-detail')
      expect(intent.targetPage).assertEqual('pages/SummaryDetailPage')
      expect(intent.summaryId).assertEqual('summary-7')
      expect(intent.arenaRunId).assertEqual('run-9')
    })

    it('ignores malformed uri and falls back to none action', 0, () => {
      const intent: LaunchIntent = parseLaunchIntentFromUri('https://example.com/not-timepersona')

      expect(intent.action).assertEqual('none')
      expect(intent.targetPage).assertEqual('pages/Index')
    })
  })
}
