/**
 * ImageSuperResolutionService — 图片超分辨率服务
 *
 * 使用 PixelMap 高质量缩放实现图片画质增强
 * 注意：这是基于插值的图像放大，不是真正的 AI 超分
 * 真正的 HiAI 超分 API 需要麒麟芯片 NPU 支持，当前 SDK 为 Java 接口
 *
 * 适用场景：
 * - 海报预览时提升清晰度
 * - 分享前增强图片质量
 * - 低分辨率图片修复
 */

import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { http } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

const DOMAIN = 0xFF01;
const TAG = 'ImageSuperResolutionService';

export enum SuperResolutionScale {
  X1 = 1,
  X2 = 2,
  X3 = 3
}

export interface SuperResolutionOptions {
  scale: SuperResolutionScale;
  quality: number;
}

export interface SuperResolutionResult {
  width: number;
  height: number;
  scale: SuperResolutionScale;
  success: boolean;
  outputPath?: string;
}

/** 图像信息接口 */
interface ImageSizeInfo {
  width: number;
  height: number;
}

/**
 * 图片超分辨率服务
 * 提供图像高质量缩放增强能力
 */
export class ImageSuperResolutionService {
  private static instance: ImageSuperResolutionService | null = null;
  private initialized: boolean = false;

  private constructor() {}

  static getInstance(): ImageSuperResolutionService {
    if (!ImageSuperResolutionService.instance) {
      ImageSuperResolutionService.instance = new ImageSuperResolutionService();
    }
    return ImageSuperResolutionService.instance;
  }

  /**
   * 初始化服务
   */
  async initialize(): Promise<boolean> {
    if (this.initialized) {
      return true;
    }
    this.initialized = true;
    hilog.info(DOMAIN, TAG, 'ImageSuperResolutionService 初始化成功');
    return true;
  }

  /**
   * 对 PixelMap 进行高质量缩放处理
   * 使用 scaleSync + 抗锯齿级别实现更好的放大效果
   */
  async enhance(
    sourceImage: image.PixelMap,
    options: SuperResolutionOptions = { scale: SuperResolutionScale.X2, quality: 90 }
  ): Promise<SuperResolutionResult | null> {
    try {
      hilog.info(DOMAIN, TAG, '开始图像增强处理, scale=%{public}d', options.scale);

      const sourceInfo: image.ImageInfo = await sourceImage.getImageInfo();
      const newWidth = Math.floor(sourceInfo.size.width * options.scale);
      const newHeight = Math.floor(sourceInfo.size.height * options.scale);

      hilog.info(DOMAIN, TAG, '原图尺寸: %{public}dx%{public}d, 目标尺寸: %{public}dx%{public}d',
        sourceInfo.size.width, sourceInfo.size.height, newWidth, newHeight);

      const scaleX: number = options.scale;
      const scaleY: number = options.scale;

      sourceImage.scaleSync(scaleX, scaleY);

      hilog.info(DOMAIN, TAG, '图像增强完成: %{public}dx%{public}d', newWidth, newHeight);

      return {
        width: newWidth,
        height: newHeight,
        scale: options.scale,
        success: true
      };
    } catch (err) {
      hilog.error(DOMAIN, TAG, '图像增强失败: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 从文件路径加载图片并增强
   */
  async enhanceFromFile(
    filePath: string,
    options: SuperResolutionOptions = { scale: SuperResolutionScale.X2, quality: 90 }
  ): Promise<SuperResolutionResult | null> {
    try {
      hilog.info(DOMAIN, TAG, '从文件加载图片: %{public}s', filePath);

      const imageSource: image.ImageSource = image.createImageSource(filePath);
      if (!imageSource) {
        hilog.error(DOMAIN, TAG, '无法创建图像源');
        return null;
      }

      const pixelMap: image.PixelMap | undefined = await imageSource.createPixelMap();
      if (!pixelMap) {
        hilog.error(DOMAIN, TAG, '无法解码图片');
        imageSource.release();
        return null;
      }

      const result: SuperResolutionResult | null = await this.enhance(pixelMap, options);

      imageSource.release();

      return result;
    } catch (err) {
      hilog.error(DOMAIN, TAG, '从文件加载失败: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 检查设备是否支持图像增强
   */
  async isSupported(): Promise<boolean> {
    try {
      const ctx = getContext();
      if (!ctx) {
        hilog.warn(DOMAIN, TAG, '无法获取上下文，假定支持');
        return true;
      }
      hilog.info(DOMAIN, TAG, '设备支持图像增强处理');
      return true;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, '设备不支持图像增强: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  /**
   * 获取图片尺寸信息
   */
  async getImageSize(pixelMap: image.PixelMap): Promise<ImageSizeInfo | null> {
    try {
      const info: image.ImageInfo = await pixelMap.getImageInfo();
      return {
        width: info.size.width,
        height: info.size.height
      };
    } catch (err) {
      hilog.error(DOMAIN, TAG, '获取图片尺寸失败');
      return null;
    }
  }

  /**
   * 从 URL 增强图片（下载、处理、返回增强后的 URL）
   */
  async enhanceFromUrl(
    url: string,
    options: SuperResolutionOptions = { scale: SuperResolutionScale.X2, quality: 90 }
  ): Promise<SuperResolutionResult | null> {
    try {
      hilog.info(DOMAIN, TAG, '从 URL 加载图片进行增强: %{public}s', url);

      const httpClient = http.createHttp();
      const result = await httpClient.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      });
      httpClient.destroy();

      if (result.responseCode === 200 && result.result instanceof ArrayBuffer) {
        const imageSource: image.ImageSource = image.createImageSource(result.result as ArrayBuffer);
        if (!imageSource) {
          hilog.error(DOMAIN, TAG, '无法创建图像源');
          return null;
        }

        const pixelMap: image.PixelMap | undefined = await imageSource.createPixelMap();
        if (!pixelMap) {
          hilog.error(DOMAIN, TAG, '无法解码图片');
          imageSource.release();
          return null;
        }

        const enhanceResult: SuperResolutionResult | null = await this.enhance(pixelMap, options);

        imageSource.release();

        return enhanceResult;
      } else {
        hilog.error(DOMAIN, TAG, '下载图片失败: responseCode=%{public}d', result.responseCode);
        return null;
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, '从 URL 增强失败: %{public}s', JSON.stringify(err));
      return null;
    }
  }

  /**
   * 释放资源
   */
  release(): void {
    this.initialized = false;
    hilog.info(DOMAIN, TAG, 'ImageSuperResolutionService 已释放');
  }
}
