import { common } from '@kit.AbilityKit'
import reminderAgentManager from '@ohos.reminderAgentManager'
import type { SummaryRecord } from '../common/Models'
import { buildSummaryDetailUri } from '../common/LaunchIntent'

function buildReminderContent(record: SummaryRecord): string {
  if (record.actionableAdvice.length > 0) {
    return `行动建议：${record.actionableAdvice[0]}`
  }
  if (record.narrativeHook && record.narrativeHook.length > 0) {
    return record.narrativeHook
  }
  if (record.consensus.length > 0) {
    return record.consensus.length > 56 ? `${record.consensus.slice(0, 56)}...` : record.consensus
  }
  return '回看这份纪要，继续推进下一步行动。'
}

function normalizeReminderDate(baseIso?: string): Date {
  const now = new Date()
  const baseDate = baseIso && baseIso.length > 0 ? new Date(baseIso) : now
  const effectiveBase = Number.isNaN(baseDate.getTime()) ? now : baseDate
  const reminderDate = new Date(effectiveBase.getTime())
  reminderDate.setDate(reminderDate.getDate() + 1)
  reminderDate.setHours(9, 0, 0, 0)

  if (reminderDate.getTime() <= now.getTime()) {
    reminderDate.setDate(now.getDate() + 1)
    reminderDate.setHours(9, 0, 0, 0)
  }
  return reminderDate
}

function toLocalDateTime(date: Date): reminderAgentManager.LocalDateTime {
  return {
    year: date.getFullYear(),
    month: date.getMonth() + 1,
    day: date.getDate(),
    hour: date.getHours(),
    minute: date.getMinutes(),
    second: date.getSeconds()
  }
}

export class CalendarReminderService {
  static nextReviewDate(baseIso?: string): Date {
    return normalizeReminderDate(baseIso)
  }

  static formatReviewDate(date: Date): string {
    const month = `${date.getMonth() + 1}`.padStart(2, '0')
    const day = `${date.getDate()}`.padStart(2, '0')
    const hour = `${date.getHours()}`.padStart(2, '0')
    const minute = `${date.getMinutes()}`.padStart(2, '0')
    return `${month}-${day} ${hour}:${minute}`
  }

  static async publishSummaryReviewReminder(record: SummaryRecord, context: common.UIAbilityContext): Promise<number> {
    const reviewDate = normalizeReminderDate(record.updatedAt && record.updatedAt.length > 0 ? record.updatedAt : record.createdAt)
    const request: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: toLocalDateTime(reviewDate),
      title: `复盘提醒：${record.title}`,
      content: buildReminderContent(record),
      tapDismissed: true,
      wantAgent: {
        pkgName: context.abilityInfo.bundleName,
        abilityName: context.abilityInfo.name,
        uri: buildSummaryDetailUri(record.id, record.arenaRunId ?? '')
      }
    }

    return reminderAgentManager.publishReminder(request)
  }
}
