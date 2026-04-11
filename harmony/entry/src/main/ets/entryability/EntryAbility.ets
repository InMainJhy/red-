import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');

      windowStage.getMainWindow().then((mainWindow: window.Window) => {
        try {
          mainWindow.setWindowLayoutFullScreen(true);
          mainWindow.setWindowSystemBarProperties({
            statusBarColor: '#00000000',
            statusBarContentColor: '#FFFFFFFF',
            navigationBarColor: '#00000000',
            navigationBarContentColor: '#FFFFFFFF'
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
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
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
  }
}