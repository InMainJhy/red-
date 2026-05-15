import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { MeetingSessionStore } from '../utils/MeetingSessionStore'
import { buildRecentMeetingSnapshot } from '../common/LaunchIntent'
import { Want } from '@kit.AbilityKit'

interface MeetingQuickActionsFormPayload {
  title: string
  subtitle: string
  meta: string
}

function buildFormPayload(): MeetingQuickActionsFormPayload {
  const snapshot = buildRecentMeetingSnapshot(MeetingSessionStore.getHistoryRecords(), MeetingSessionStore.getReasoningEffort())
  const subtitle = snapshot.hasContinueMeeting
    ? (snapshot.topic.length > 0 ? snapshot.topic : '回到上次讨论')
    : '打开应用开始新的对话'

  const payload: MeetingQuickActionsFormPayload = {
    title: '继续上次会议',
    subtitle: subtitle,
    meta: snapshot.hasContinueMeeting
      ? `${snapshot.participantCount} 位人格 · ${snapshot.participantSummary}`
      : '暂无可继续会议'
  }
  return payload
}

export default class MeetingQuickActionsFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(buildFormPayload())
  }

  onCastToNormalForm(formId: string): void {}

  onUpdateForm(formId: string): void {
    const payload = formBindingData.createFormBindingData(buildFormPayload())
    formProvider.updateForm(formId, payload).catch((error: BusinessError) => {
      console.error(`[MeetingQuickActionsFormAbility] updateForm failed: ${error.code} ${error.message}`)
    })
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {}

  onFormEvent(formId: string, message: string): void {}

  onRemoveForm(formId: string): void {}

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY
  }
}
