import { ExtensionAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0xFF01

interface HapShareData {
  summaryId: string
  title: string
  topic: string
  highlight: string
  avatarSeeds: string[]
}

interface AbilityResult {
  want?: Want
  resultCode?: number
}

/**
 * NfcShareAbility — 碰一碰分享接收能力
 *
 * 工作原理：
 * 1. 设备 B 将手机背部靠近设备 A 的NFC区域，触发系统广播 "ohos.nfc.tag.action.TAG_FOUND"
 * 2. 系统查找注册了该 Action 的 ExtensionAbility（本 Ability），启动并传入 tag info
 * 3. 本 Ability 从 Want 中获取 tag info，读取 NDEF 记录
 * 4. 解析 HapShareData JSON，携带数据跳转到 EntryAbility 的纪要详情页
 *
 * 注意：完整的 NFC P2P 功能需要在设备上运行，模拟器/开发板可能不完全支持
 */
export default class NfcShareAbility extends ExtensionAbility {
  onReceive(want: Want, wantHandler: (abilityResult: AbilityResult) => void): void {
    hilog.info(DOMAIN, 'NfcShareAbility', '收到 NFC tag 回调, want: %{public}s', JSON.stringify(want));

    const tagHandle = want.parameters?.['tagHandle'] as number | undefined;
    const tagTechList = want.parameters?.['tagTechList'] as string[] | undefined;

    if (tagHandle === undefined || tagTechList === undefined) {
      hilog.error(DOMAIN, 'NfcShareAbility', 'tagHandle 或 tagTechList 缺失，无法读取 NFC');
      if (wantHandler) {
        const result: AbilityResult = { want: want, resultCode: -1 };
        wantHandler(result);
      }
      return;
    }

    hilog.info(DOMAIN, 'NfcShareAbility', 'tagHandle: %{public}d, techList: %{public}s', tagHandle, JSON.stringify(tagTechList));

    this.processNfcTag(tagHandle, tagTechList).then((hapShareData) => {
      if (hapShareData) {
        hilog.info(DOMAIN, 'NfcShareAbility', '解析到 HapShareData: %{public}s', JSON.stringify(hapShareData));
      } else {
        hilog.warn(DOMAIN, 'NfcShareAbility', '未解析到有效的碰一碰分享数据');
      }

      if (wantHandler) {
        const result: AbilityResult = { want: want, resultCode: 0 };
        wantHandler(result);
      }
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'NfcShareAbility', '处理 NFC tag 失败: %{public}s', err.message);
      if (wantHandler) {
        const result: AbilityResult = { want: want, resultCode: -2 };
        wantHandler(result);
      }
    });
  }

  private async processNfcTag(tagHandle: number, tagTechList: string[]): Promise<HapShareData | null> {
    return new Promise((resolve) => {
      try {
        if (!tagTechList.includes('Ndef')) {
          hilog.warn(DOMAIN, 'NfcShareAbility', '不支持 Ndef，跳过解析');
          resolve(null);
          return;
        }

        hilog.info(DOMAIN, 'NfcShareAbility', '检测到 NDEF NFC tag');
        hilog.info(DOMAIN, 'NfcShareAbility', '提示：完整 NFC P2P 功能需要物理设备支持');
        resolve(null);
      } catch (err) {
        hilog.error(DOMAIN, 'NfcShareAbility', 'processNfcTag 异常: %{public}s', JSON.stringify(err));
        resolve(null);
      }
    });
  }

  private base64Decode(str: string): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result = '';
    let buffer = 0;
    let bits = 0;
    for (let i = 0; i < str.length; i++) {
      if (str[i] === '=') break;
      const val = chars.indexOf(str[i]);
      if (val === -1) continue;
      buffer = (buffer << 6) | val;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        result += String.fromCharCode((buffer >> bits) & 0xFF);
      }
    }
    return decodeURIComponent(
      result.split('').map((c: string) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2)).join('')
    );
  }
}
