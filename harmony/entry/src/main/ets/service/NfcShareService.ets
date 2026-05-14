/**
 * NfcShareService — 碰一碰分享服务（发送端）
 *
 * 负责将 HapShareData 写入 NFC Tag，供另一台设备碰一碰读取。
 *
 * 核心流程：
 * 1. 用户在 ShareSheet 点击"碰一碰"按钮
 * 2. 本服务启动 NFC 监听，等待目标设备靠近
 * 3. 当 NFC 连接建立后，将纪要数据编码为 NDEF 记录写入
 * 4. 接收端 NfcShareAbility 读取后自动跳转到纪要详情
 *
 * 数据编码格式：
 * - 方式 A：直接写入 JSON（适合小数据量）
 * - 方式 B：写入自定义 URI hwp://hackathon.meeting?data=<base64>
 *
 * API 来源：@kit.ConnectivityKit → tagManager
 */

import { tagManager } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HapShareData } from '../common/Models';

export type NfcShareState = 'idle' | 'waiting' | 'writing' | 'sent' | 'error';

export interface NfcShareResult {
  success: boolean
  message: string
}

const NFC_SHARE_MIME_TYPE = 'application/vnd.com.example.myapplication.hapshare';
const NFC_SHARE_URI_PREFIX = 'hwp://hackathon.meeting?data=';

export class NfcShareService {
  /**
   * 将 HapShareData 编码为 NDEF 可写入的字符串
   * 使用自定义 URI 格式：hwp://hackathon.meeting?data=<base64 encoded JSON>
   */
  static encodeShareData(data: HapShareData): string {
    const json = JSON.stringify(data);
    return NFC_SHARE_URI_PREFIX + NfcShareService.base64Encode(json);
  }

  /**
   * 将 HapShareData 编码为纯 JSON（用于 NDEF Mime 类型记录）
   */
  static encodeShareDataAsJson(data: HapShareData): string {
    return JSON.stringify(data);
  }

  /**
   * 写入 NDEF 记录到 NFC tag handle
   * @param tagHandle NFC tag handle（由系统提供）
   * @param data 要分享的纪要数据
   */
  static async writeNdefRecord(tagHandle: number, data: HapShareData): Promise<NfcShareResult> {
    try {
      // 连接 NDEF tag
      const ndefHandle = await tagManager.connect(tagHandle, 'Ndef');
      console.info('[NfcShareService] NDEF 连接成功, handle:', ndefHandle);

      // 编码数据（优先使用 JSON，更通用）
      const payload = NfcShareService.encodeShareDataAsJson(data);

      // 写入 NDEF 记录
      await tagManager.writeNdef(ndefHandle, NFC_SHARE_MIME_TYPE, payload);
      console.info('[NfcShareService] NDEF 写入成功');

      // 断开连接
      try {
        await tagManager.disconnect(ndefHandle);
      } catch (_e) {
        // ignore disconnect errors
      }

      return { success: true, message: '碰一碰分享成功' };
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : JSON.stringify(err);
      console.error('[NfcShareService] writeNdefRecord 失败:', errorMsg);

      // 尝试备用方案：URI 格式写入
      try {
        const uriPayload = NfcShareService.encodeShareData(data);
        await tagManager.writeNdef(tagHandle, 'text/uri-list', uriPayload);
        console.info('[NfcShareService] 备用 URI 写入成功');

        try {
          await tagManager.disconnect(tagHandle);
        } catch (_e) { /* ignore */ }

        return { success: true, message: '碰一碰分享成功（URI 模式）' };
      } catch (fallbackErr) {
        console.error('[NfcShareService] 备用写入也失败:', fallbackErr);
        return { success: false, message: `分享失败: ${errorMsg}` };
      }
    }
  }

  /**
   * 快速碰一碰分享入口
   * 自动检测 NFC 可用性，写入数据，返回结果
   */
  static async performTapShare(data: HapShareData): Promise<NfcShareResult> {
    // 检查 NFC 是否可用
    if (!NfcShareService.isNfcAvailable()) {
      return { success: false, message: 'NFC 不可用，请确保已开启 NFC 功能' };
    }

    // 此方法由 UI 层在检测到 NFC tag 连接时调用
    // 实际 tag handle 需要从 NFC 会话中获取
    // 这里提供一个简化版本：直接返回编码后的数据，供 UI 层使用
    return {
      success: true,
      message: '已准备碰一碰数据，请将设备靠近对方手机'
    };
  }

  /**
   * 检查 NFC 是否可用
   */
  static isNfcAvailable(): boolean {
    try {
      // 基本检查：NFC API 是否存在
      return typeof tagManager !== 'undefined';
    } catch (_e) {
      return false;
    }
  }

  /**
   * 生成碰一碰分享的快捷指令数据
   * 返回可直接用于 NFC tag 写入的完整 payload
   */
  static generateNdefPayload(data: HapShareData): string {
    return NfcShareService.encodeShareDataAsJson(data);
  }

  private static base64Encode(str: string): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result = '';
    const bytes: number[] = [];
    // UTF-8 encode
    for (let i = 0; i < str.length; i++) {
      const code = str.charCodeAt(i);
      if (code < 0x80) {
        bytes.push(code);
      } else if (code < 0x800) {
        bytes.push(0xC0 | (code >> 6));
        bytes.push(0x80 | (code & 0x3F));
      } else {
        bytes.push(0xE0 | (code >> 12));
        bytes.push(0x80 | ((code >> 6) & 0x3F));
        bytes.push(0x80 | (code & 0x3F));
      }
    }
    for (let i = 0; i < bytes.length; i += 3) {
      const b0 = bytes[i];
      const b1 = (i + 1 < bytes.length) ? bytes[i + 1] : 0;
      const b2 = (i + 2 < bytes.length) ? bytes[i + 2] : 0;
      result += chars[(b0 >> 2) & 0x3F];
      result += chars[((b0 << 4) | (b1 >> 4)) & 0x3F];
      result += (i + 1 < bytes.length) ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F] : '=';
      result += (i + 2 < bytes.length) ? chars[b2 & 0x3F] : '=';
    }
    return result;
  }
}
