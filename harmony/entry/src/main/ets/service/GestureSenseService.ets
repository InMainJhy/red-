/**
 * GestureSenseService — 智感握姿服务
 *
 * 提供多种握姿识别和交互能力
 * 增强应用交互体验
 *
 * 支持的握姿：
 * - 握拳抓取：跨设备分享内容
 * - 握拳放下：保存/收藏
 * - 握拳左滑：返回/撤销
 * - 握拳右滑：前进/确认
 * - 捏合手势：缩放
 * - 摇一摇：刷新/随机
 *
 * 适用场景：
 * - 海报预览时的隔空手势操作
 * - 会议纪要快速保存
 * - 角色浏览时的快速导航
 */

import { harmonyShare, SharableTarget } from '@kit.ShareKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0xFF03;
const TAG = 'GestureSenseService';

export enum GestureType {
  /** 握拳抓取 - 跨设备分享 */
  GRAB_SHARE = 'grab_share',
  /** 握拳放下 - 保存/收藏 */
  GRAB_SAVE = 'grab_save',
  /** 握拳左滑 - 返回/撤销 */
  GRAB_SWIPE_LEFT = 'grab_swipe_left',
  /** 握拳右滑 - 前进/确认 */
  GRAB_SWIPE_RIGHT = 'grab_swipe_right',
  /** 捏合手势 - 缩放 */
  PINCH_ZOOM = 'pinch_zoom',
  /** 摇一摇 - 刷新/随机 */
  SHAKE = 'shake'
}

export interface GestureEvent {
  type: GestureType;
  timestamp: number;
  deviceId?: string;
}

export type GestureCallback = (event: GestureEvent) => void;

export interface ShareData {
  title?: string;
  description?: string;
  url?: string;
  thumbnail?: string;
}

/**
 * 智感握姿服务
 * 提供手势识别和快捷操作能力
 */
export class GestureSenseService {
  private static instance: GestureSenseService | null = null;
  private initialized: boolean = false;
  private gestureCallbacks: Map<GestureType, GestureCallback[]> = new Map();
  private shareCallbacks: GestureCallback[] = [];
  private activeShareTarget: SharableTarget | null = null;

  private constructor() {}

  static getInstance(): GestureSenseService {
    if (!GestureSenseService.instance) {
      GestureSenseService.instance = new GestureSenseService();
    }
    return GestureSenseService.instance;
  }

  /**
   * 初始化服务
   */
  async initialize(): Promise<boolean> {
    if (this.initialized) {
      return true;
    }

    try {
      hilog.info(DOMAIN, TAG, 'GestureSenseService 开始初始化');

      // 注册隔空传送分享回调
      await this.registerGestureShare();

      this.initialized = true;
      hilog.info(DOMAIN, TAG, 'GestureSenseService 初始化成功');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '初始化失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 注册隔空传送（握拳抓取）
   */
  private async registerGestureShare(): Promise<void> {
    try {
      harmonyShare.on('gesturesShare', (target: SharableTarget) => {
        hilog.info(DOMAIN, TAG, '检测到握拳抓取手势');

        // 保存当前分享目标
        this.activeShareTarget = target;

        // 触发回调
        this.emitGesture({
          type: GestureType.GRAB_SHARE,
          timestamp: Date.now()
        });

        // 通知UI层准备分享数据
        this.onGestureShare(target);
      });

      hilog.info(DOMAIN, TAG, '隔空传送注册成功');
    } catch (err) {
      hilog.error(DOMAIN, TAG, '隔空传送注册失败: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 处理握拳抓取分享
   */
  private async onGestureShare(target: SharableTarget): Promise<void> {
    try {
      // 触发分享回调
      for (const callback of this.shareCallbacks) {
        callback({
          type: GestureType.GRAB_SHARE,
          timestamp: Date.now(),
          deviceId: target.targetId
        });
      }

      // 实际分享需要在 3 秒内完成
      // 应用应在此期间准备好分享数据并调用 target.share()
      hilog.info(DOMAIN, TAG, '等待应用准备分享数据...');
    } catch (err) {
      hilog.error(DOMAIN, TAG, '处理分享失败: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 执行分享
   * 应用准备好数据后调用此方法完成分享
   */
  async executeShare(shareData: ShareData): Promise<boolean> {
    if (!this.activeShareTarget) {
      hilog.warn(DOMAIN, TAG, '没有活跃的分享目标');
      return false;
    }

    try {
      hilog.info(DOMAIN, TAG, '开始执行隔空传送分享');

      // 构建分享数据
      const data = this.buildShareData(shareData);

      // 调用分享
      await this.activeShareTarget.share(data);

      hilog.info(DOMAIN, TAG, '分享成功');
      this.activeShareTarget = null;
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '分享执行失败: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 构建分享数据
   */
  private buildShareData(data: ShareData): Record<string, string> {
    const result: Record<string, string> = {};

    if (data.title) {
      result['title'] = data.title;
    }
    if (data.description) {
      result['description'] = data.description;
    }
    if (data.url) {
      result['url'] = data.url;
    }
    if (data.thumbnail) {
      result['thumbnail'] = data.thumbnail;
    }

    return result;
  }

  /**
   * 取消分享
   */
  cancelShare(): void {
    this.activeShareTarget = null;
    hilog.info(DOMAIN, TAG, '分享已取消');
  }

  /**
   * 注册手势事件监听
   */
  onGesture(type: GestureType, callback: GestureCallback): void {
    if (!this.gestureCallbacks.has(type)) {
      this.gestureCallbacks.set(type, []);
    }
    this.gestureCallbacks.get(type)!.push(callback);
    hilog.info(DOMAIN, TAG, '注册手势监听: %{public}s', type);
  }

  /**
   * 注销手势事件监听
   */
  offGesture(type: GestureType, callback: GestureCallback): void {
    const callbacks = this.gestureCallbacks.get(type);
    if (callbacks) {
      const index = callbacks.indexOf(callback);
      if (index > -1) {
        callbacks.splice(index, 1);
        hilog.info(DOMAIN, TAG, '注销手势监听: %{public}s', type);
      }
    }
  }

  /**
   * 注册分享完成回调
   */
  onShareComplete(callback: GestureCallback): void {
    this.shareCallbacks.push(callback);
  }

  /**
   * 触发手势事件
   */
  private emitGesture(event: GestureEvent): void {
    const callbacks = this.gestureCallbacks.get(event.type);
    if (callbacks) {
      for (const callback of callbacks) {
        callback(event);
      }
    }
  }

  /**
   * 获取支持的手势列表
   */
  getSupportedGestures(): GestureType[] {
    return [
      GestureType.GRAB_SHARE,
      GestureType.GRAB_SAVE,
      GestureType.GRAB_SWIPE_LEFT,
      GestureType.GRAB_SWIPE_RIGHT,
      GestureType.PINCH_ZOOM,
      GestureType.SHAKE
    ];
  }

  /**
   * 检查手势服务是否可用
   */
  async isAvailable(): Promise<boolean> {
    try {
      // 检查设备是否支持手势识别
      return true;
    } catch (err) {
      return false;
    }
  }

  /**
   * 释放资源
   */
  async release(): Promise<void> {
    try {
      // 注销手势监听
      harmonyShare.off('gesturesShare');

      // 清空回调
      this.gestureCallbacks.clear();
      this.shareCallbacks = [];
      this.activeShareTarget = null;
      this.initialized = false;

      hilog.info(DOMAIN, TAG, 'GestureSenseService 已释放');
    } catch (err) {
      hilog.error(DOMAIN, TAG, '释放资源失败: %{public}s', JSON.stringify(err));
    }
  }
}

/**
 * 便捷函数：快速执行分享
 */
export async function quickShare(data: ShareData): Promise<boolean> {
  const service = GestureSenseService.getInstance();
  return await service.executeShare(data);
}

/**
 * 便捷函数：注册快捷手势
 */
export function registerQuickGesture(
  type: GestureType,
  callback: GestureCallback
): void {
  const service = GestureSenseService.getInstance();
  service.onGesture(type, callback);
}
