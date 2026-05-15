import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { statusBarContentColor } from '../common/styles/ThemeMode';
import { buildLaunchIntentFromQuickAction, buildWantParamsFromLaunchIntent, parseLaunchIntentFromWant } from '../common/LaunchIntent';
import { LaunchIntentStore } from '../common/LaunchIntentStore';
import { MeetingSessionStore } from '../utils/MeetingSessionStore';
import abilityConnectionManager from '@ohos.distributedsched.abilityConnectionManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private mainWindow?: window.Window;

  private cacheLaunchIntentFromCollaborationParams(params?: Record<string, string>): void {
    if (!params) {
      return
    }

    const wantParams: Record<string, Object> = {}
    Object.keys(params).forEach((key: string) => {
      wantParams[key] = params[key]
    })

    const intent = parseLaunchIntentFromWant(undefined, wantParams)
    if (intent.action === 'none') {
      return
    }
    LaunchIntentStore.set(intent)
    this.context.eventHub.emit('launchIntentReceived', {
      action: intent.action
    })
    hilog.info(DOMAIN, 'testTag', 'cached collaboration launch intent: %{public}s', intent.action)
  }

  private async markContinuationStateActive(): Promise<void> {
    try {
      await this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE)
    } catch (err) {
      hilog.warn(DOMAIN, 'testTag', 'setMissionContinueState failed: %{public}s', JSON.stringify(err))
    }
  }

  private cacheLaunchIntentFromWant(want: Want): void {
    const intent = parseLaunchIntentFromWant(want.uri?.toString(), want.parameters as Record<string, Object> | undefined)
    if (intent.action === 'none') {
      return
    }
    LaunchIntentStore.set(intent)
    hilog.info(DOMAIN, 'testTag', 'cached launch intent: %{public}s', intent.action)
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    void MeetingSessionStore.init(this.context)
    void this.markContinuationStateActive()
    this.cacheLaunchIntentFromWant(want);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/SplashPage', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      windowStage.getMainWindow().then((mainWindow: window.Window) => {
        try {
          this.mainWindow = mainWindow;
          mainWindow.setWindowLayoutFullScreen(true);
          mainWindow.setWindowSystemBarProperties({
            statusBarColor: '#00000000',
            statusBarContentColor: statusBarContentColor(this.context.config.colorMode),
            navigationBarColor: '#00000000',
            navigationBarContentColor: statusBarContentColor(this.context.config.colorMode)
          });
        } catch (innerErr) {
          hilog.error(DOMAIN, 'testTag', 'immersive window failed: %{public}s', JSON.stringify(innerErr));
        }
      }).catch((e: Error) => {
        hilog.error(DOMAIN, 'testTag', 'getMainWindow failed: %{public}s', JSON.stringify(e));
      });
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    this.mainWindow = undefined;
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onConfigurationUpdate(config: Configuration): void {
    hilog.info(DOMAIN, 'testTag', 'configuration updated');
    if (!this.mainWindow) {
      return;
    }

    try {
      const contentColor = statusBarContentColor(config.colorMode);
      this.mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: contentColor,
        navigationBarColor: '#00000000',
        navigationBarContentColor: contentColor
      });
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'update system bar failed: %{public}s', JSON.stringify(err));
    }
  }

  onForeground(): void {
    // Ability has brought to foreground
    void this.markContinuationStateActive()
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  /**
   * 处理从 NfcShareAbility 传来的碰一碰数据
   * 当另一台设备碰一碰后，NfcShareAbility 解析 tag 数据并通过 startAbility 启动 EntryAbility
   * 此处拦截 want 中的碰一碰参数，跳转到纪要详情页
   */
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', 'onNewWant received');
    this.cacheLaunchIntentFromWant(want);

    const fromNfc = want.parameters?.['fromNfc'] as boolean | undefined;
    if (fromNfc) {
      const nfcShareData = want.parameters?.['nfcShareData'] as string | undefined;
      const summaryId = want.parameters?.['summaryId'] as string | undefined;

      hilog.info(DOMAIN, 'testTag', '收到碰一碰数据: summaryId=%{public}s', summaryId || 'null');

      if (summaryId && summaryId.length > 0) {
        // 通过 eventHub 通知 UI 层有碰一碰数据到达
        // Index 页面或其他页面可以通过订阅 'nfcShareReceived' 事件来响应
        this.context.eventHub.emit('nfcShareReceived', {
          summaryId: summaryId,
          nfcShareData: nfcShareData
        });
        hilog.info(DOMAIN, 'testTag', '已通过 eventHub 发送碰一碰数据');
      }
    }

    const pendingIntent = LaunchIntentStore.peek()
    if (pendingIntent && pendingIntent.action !== 'none') {
      this.context.eventHub.emit('launchIntentReceived', {
        action: pendingIntent.action
      });
    }
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    const fallbackIntent = buildLaunchIntentFromQuickAction('continue-meeting', {
      continueFromRunId: MeetingSessionStore.getContinueFromRunId(),
      sessionId: MeetingSessionStore.getSessionId(),
      topic: MeetingSessionStore.getTopic(),
      profileIds: MeetingSessionStore.getProfileIds(),
      selectedAgentIds: MeetingSessionStore.getSelectedAgents(),
      reasoningEffort: MeetingSessionStore.getReasoningEffort()
    })

    const hasPreparedMeeting = fallbackIntent.profileIds.length > 0 && fallbackIntent.selectedAgentIds.length >= 2
    const hasContinueMeeting = hasPreparedMeeting && fallbackIntent.continueFromRunId.length > 0
    const intent = hasContinueMeeting
      ? fallbackIntent
      : (hasPreparedMeeting ? buildLaunchIntentFromQuickAction('new-meeting', {
        topic: fallbackIntent.topic,
        profileIds: fallbackIntent.profileIds,
        selectedAgentIds: fallbackIntent.selectedAgentIds,
        reasoningEffort: fallbackIntent.reasoningEffort
      }) : null)

    if (!intent) {
      hilog.warn(DOMAIN, 'testTag', 'onContinue rejected: missing meeting context')
      return AbilityConstant.OnContinueResult.REJECT
    }

    const params = buildWantParamsFromLaunchIntent(intent)
    wantParam['launchAction'] = params.launchAction
    wantParam['continueFromRunId'] = params.continueFromRunId
    wantParam['sessionId'] = params.sessionId
    wantParam['topic'] = params.topic
    wantParam['profileIds'] = params.profileIds
    wantParam['selectedAgentIds'] = params.selectedAgentIds
    wantParam['reasoningEffort'] = params.reasoningEffort
    wantParam['continuationSource'] = 'meeting-continuation'
    hilog.info(DOMAIN, 'testTag', 'onContinue accepted with action: %{public}s', intent.action)
    return AbilityConstant.OnContinueResult.AGREE
  }

  onCollaborate(wantParam: Record<string, Object>): AbilityConstant.CollaborateResult {
    const connectOptionsObject = wantParam[abilityConnectionManager.CollaborationKeys.CONNECT_OPTIONS]
    if (typeof connectOptionsObject === 'object' && connectOptionsObject !== null) {
      const connectOptions = connectOptionsObject as Record<string, Object>
      const parametersObject = connectOptions['parameters']
      if (typeof parametersObject === 'object' && parametersObject !== null) {
        this.cacheLaunchIntentFromCollaborationParams(parametersObject as Record<string, string>)
      }
    }

    hilog.info(DOMAIN, 'testTag', 'onCollaborate accepted')
    return AbilityConstant.CollaborateResult.ACCEPT
  }
}
