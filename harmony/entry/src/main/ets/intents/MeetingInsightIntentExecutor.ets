import { InsightIntentExecutor, Want, insightIntent } from '@kit.AbilityKit'

const APP_BUNDLE_NAME: string = 'com.example.myapplication'
const ENTRY_ABILITY_NAME: string = 'EntryAbility'

type SupportedIntentName = 'ContinueMeeting' | 'StartMeeting' | 'OpenRecentSummaries'

function mapIntentNameToLaunchAction(name: string): string {
  if (name === 'ContinueMeeting') {
    return 'continue-meeting'
  }
  if (name === 'OpenRecentSummaries') {
    return 'open-recent-summaries'
  }
  return 'new-meeting'
}

function normalizeIntentName(name: string): SupportedIntentName {
  if (name === 'ContinueMeeting' || name === 'OpenRecentSummaries') {
    return name
  }
  return 'StartMeeting'
}

function buildLaunchWant(launchAction: string): Want {
  const want: Want = {
    bundleName: APP_BUNDLE_NAME,
    abilityName: ENTRY_ABILITY_NAME,
    parameters: {
      launchAction: launchAction,
      launchSource: 'insight-intent'
    }
  }
  return want
}

export default class MeetingInsightIntentExecutor extends InsightIntentExecutor {
  async onExecuteInUIAbilityForegroundMode(
    name: string,
    _param: Record<string, Object>
  ): Promise<insightIntent.ExecuteResult> {
    const normalizedName = normalizeIntentName(name)
    const launchAction = mapIntentNameToLaunchAction(normalizedName)
    const want = buildLaunchWant(launchAction)
    await this.context.startAbility(want)

    return {
      code: 0,
      result: {
        intentName: normalizedName,
        launchAction: launchAction
      }
    }
  }
}
