// 统一动效规范 - HarmonyOS ArkTS 动画工具类
// 时长与曲线对齐华为设计体系：强调动效用 EaseOut / FastOutSlowIn，物理感滚动与回弹可配合 Friction + EdgeEffect.Spring

// 动效时长
export class AnimationDurationClass {
  instant: number = 100
  fast: number = 160
  normal: number = 240
  slow: number = 320
  slower: number = 500
  page: number = 280
}
export const AnimationDuration: AnimationDurationClass = new AnimationDurationClass()

// 动效曲线 - 使用官方推荐的曲线
export class AnimationCurveClass {
  standard: Curve = Curve.Ease
  emphasized: Curve = Curve.EaseOut
  decelerated: Curve = Curve.EaseOut
  accelerated: Curve = Curve.EaseIn
  smooth: Curve = Curve.FastOutSlowIn
  bounce: Curve = Curve.FastOutLinearIn
  linear: Curve = Curve.Linear
  // 新增：更丰富的曲线
  spring: Curve = Curve.FastOutSlowIn
  friction: Curve = Curve.Friction
  sharp: Curve = Curve.Sharp
  rhythmic: Curve = Curve.Rhythm
}
export const AnimationCurve: AnimationCurveClass = new AnimationCurveClass()

// 预设动画配置
export interface AnimationPreset {
  duration: number
  curve: Curve
}

// 预设动画配置类
export class AnimationPresetsClass implements AnimationPreset {
  duration: number = 0
  curve: Curve = Curve.EaseOut

  constructor(duration: number, curve: Curve) {
    this.duration = duration
    this.curve = curve
  }
}

// AnimationPresets 类
export class AnimationPresetsContainerClass {
  quick: AnimationPreset = new AnimationPresetsClass(AnimationDuration.fast, AnimationCurve.emphasized)
  standard: AnimationPreset = new AnimationPresetsClass(AnimationDuration.normal, AnimationCurve.emphasized)
  slow: AnimationPreset = new AnimationPresetsClass(AnimationDuration.slow, AnimationCurve.decelerated)
  bounce: AnimationPreset = new AnimationPresetsClass(AnimationDuration.normal, AnimationCurve.bounce)
}
export const AnimationPresets: AnimationPresetsContainerClass = new AnimationPresetsContainerClass()

// 交错动画延迟计算
export function getStaggerDelay(index: number, baseDelay: number = 50): number {
  return index * baseDelay
}

/** 页面内多段内容错峰出现的基础间隔（ms） */
export const PAGE_SECTION_STAGGER_MS: number = 64

// 组件出现动画配置（从下方滑入 + 淡入）
export function getAppearAnimation(delay: number = 0): TransitionEffect {
  return TransitionEffect.OPACITY
    .animation({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.emphasized,
      delay: delay
    })
    .combine(TransitionEffect.translate({ y: 30 }))
    .animation({
      duration: AnimationDuration.slow,
      curve: AnimationCurve.emphasized,
      delay: delay
    })
}

// 组件消失动画配置（向下滑出 + 淡出）
export function getDisappearAnimation(): TransitionEffect {
  return TransitionEffect.OPACITY
    .animation({
      duration: AnimationDuration.fast,
      curve: AnimationCurve.decelerated
    })
    .combine(TransitionEffect.translate({ y: 20 }))
    .animation({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.decelerated
    })
}

// 缩放入场动画
export function getScaleInAnimation(delay: number = 0): TransitionEffect {
  return TransitionEffect.OPACITY
    .animation({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.emphasized,
      delay: delay
    })
    .combine(TransitionEffect.scale({ x: 0.9, y: 0.9 }))
    .animation({
      duration: AnimationDuration.slow,
      curve: AnimationCurve.emphasized,
      delay: delay
    })
}

// 卡片悬停效果参数
export interface HoverEffect {
  scaleX: number
  scaleY: number
  shadowRadius: number
  shadowOffsetY: number
}

// 悬停效果配置类
export class HoverEffectClass implements HoverEffect {
  scaleX: number = 1
  scaleY: number = 1
  shadowRadius: number = 8
  shadowOffsetY: number = 3

  constructor(scaleX: number, scaleY: number, shadowRadius: number, shadowOffsetY: number) {
    this.scaleX = scaleX
    this.scaleY = scaleY
    this.shadowRadius = shadowRadius
    this.shadowOffsetY = shadowOffsetY
  }
}

// HoverEffects 容器类
export class HoverEffectsContainerClass {
  subtle: HoverEffect = new HoverEffectClass(0.98, 0.98, 6, 2)
  medium: HoverEffect = new HoverEffectClass(0.97, 0.97, 12, 4)
  prominent: HoverEffect = new HoverEffectClass(0.96, 0.96, 20, 8)
}
export const HoverEffects: HoverEffectsContainerClass = new HoverEffectsContainerClass()

// 按钮点击效果参数
export interface PressEffect {
  scaleX: number
  scaleY: number
  duration: number
}

// 点击效果配置类
export class PressEffectClass implements PressEffect {
  scaleX: number = 1
  scaleY: number = 1
  duration: number = 200

  constructor(scaleX: number, scaleY: number, duration: number) {
    this.scaleX = scaleX
    this.scaleY = scaleY
    this.duration = duration
  }
}

// PressEffects 容器类
export class PressEffectsContainerClass {
  light: PressEffect = new PressEffectClass(0.98, 0.98, AnimationDuration.fast)
  medium: PressEffect = new PressEffectClass(0.96, 0.96, AnimationDuration.fast)
  strong: PressEffect = new PressEffectClass(0.94, 0.94, AnimationDuration.instant)
}
export const PressEffects: PressEffectsContainerClass = new PressEffectsContainerClass()

// 旋转动画配置
export function getRotateAnimation(from: number, to: number, duration: number = 300): TransitionEffect {
  return TransitionEffect.asymmetric(
    TransitionEffect.OPACITY.animation({
      duration: duration / 2,
      curve: AnimationCurve.standard
    }).combine(
      TransitionEffect.rotate({ angle: from })
    ),
    TransitionEffect.OPACITY.animation({
      duration: duration / 2,
      curve: AnimationCurve.standard
    }).combine(
      TransitionEffect.rotate({ angle: to })
    )
  )
}

// 骨架屏闪烁动画配置
export class ShimmerAnimationClass {
  duration: number = 1500
  iterations: number = -1
  curve: Curve = Curve.Linear
}
export const ShimmerAnimation: ShimmerAnimationClass = new ShimmerAnimationClass()

// 弹簧动画配置
export interface SpringConfig {
  velocity: number
  mass: number
  stiffness: number
  damping: number
}

export class SpringConfigClass implements SpringConfig {
  velocity: number = 0
  mass: number = 1
  stiffness: number = 100
  damping: number = 10

  constructor(velocity: number, mass: number, stiffness: number, damping: number) {
    this.velocity = velocity
    this.mass = mass
    this.stiffness = stiffness
    this.damping = damping
  }
}

// 弹簧动画预设
export class SpringPresetsClass {
  gentle: SpringConfig = new SpringConfigClass(0, 1, 120, 14)
  bouncy: SpringConfig = new SpringConfigClass(0, 1, 180, 12)
  stiff: SpringConfig = new SpringConfigClass(0, 1, 210, 20)
  slow: SpringConfig = new SpringConfigClass(0, 1, 280, 60)
}
export const SpringPresets: SpringPresetsClass = new SpringPresetsClass()

// 微交互动画 - 用于按钮、图标等小元素
export function getMicroInteraction(delay: number = 0): TransitionEffect {
  return TransitionEffect.scale({ x: 0.95, y: 0.95 })
    .animation({
      duration: AnimationDuration.instant,
      curve: AnimationCurve.sharp,
      delay: delay
    })
    .combine(TransitionEffect.OPACITY)
    .animation({
      duration: AnimationDuration.fast,
      curve: AnimationCurve.emphasized,
      delay: delay
    })
}

// 卡片翻转动画
export function getFlipAnimation(duration: number = 400): TransitionEffect {
  return TransitionEffect.rotate({ x: 0, y: 1, z: 0, angle: 180 })
    .animation({
      duration: duration,
      curve: AnimationCurve.smooth
    })
    .combine(TransitionEffect.OPACITY)
    .animation({
      duration: duration / 2,
      curve: AnimationCurve.emphasized
    })
}

// 弹性缩放入场
export function getElasticScaleIn(delay: number = 0): TransitionEffect {
  return TransitionEffect.scale({ x: 0.3, y: 0.3 })
    .animation({
      duration: AnimationDuration.slower,
      curve: AnimationCurve.smooth,
      delay: delay
    })
    .combine(TransitionEffect.OPACITY)
    .animation({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.emphasized,
      delay: delay
    })
}

// 滑动淡入（从指定方向）
export interface SlideInConfig {
  x?: number
  y?: number
  duration?: number
  delay?: number
}

export function getSlideInAnimation(config: SlideInConfig): TransitionEffect {
  const x = config.x ?? 0
  const y = config.y ?? 0
  const duration = config.duration ?? AnimationDuration.normal
  const delay = config.delay ?? 0

  return TransitionEffect.translate({ x: x, y: y })
    .animation({
      duration: duration,
      curve: AnimationCurve.emphasized,
      delay: delay
    })
    .combine(TransitionEffect.OPACITY)
    .animation({
      duration: duration,
      curve: AnimationCurve.emphasized,
      delay: delay
    })
}

// 脉冲动画配置（用于提示、通知等）
export class PulseAnimationClass {
  duration: number = 1000
  iterations: number = -1
  scaleFrom: number = 1.0
  scaleTo: number = 1.05
  curve: Curve = Curve.EaseInOut
}
export const PulseAnimation: PulseAnimationClass = new PulseAnimationClass()

// 呼吸灯动画配置
export class BreathAnimationClass {
  duration: number = 2000
  iterations: number = -1
  opacityFrom: number = 0.4
  opacityTo: number = 1.0
  curve: Curve = Curve.EaseInOut
}
export const BreathAnimation: BreathAnimationClass = new BreathAnimationClass()

// 列表项交错显示配置
export interface StaggerConfig {
  baseDelay: number
  itemDelay: number
  maxDelay?: number
}

export class StaggerConfigClass implements StaggerConfig {
  baseDelay: number = 100
  itemDelay: number = 50
  maxDelay?: number = 1000

  constructor(baseDelay: number = 100, itemDelay: number = 50, maxDelay?: number) {
    this.baseDelay = baseDelay
    this.itemDelay = itemDelay
    this.maxDelay = maxDelay
  }
}

export class StaggerPresetsClass {
  fast: StaggerConfig = new StaggerConfigClass(50, 30, 800)
  normal: StaggerConfig = new StaggerConfigClass(100, 50, 1200)
  slow: StaggerConfig = new StaggerConfigClass(150, 80, 1800)
}
export const StaggerPresets: StaggerPresetsClass = new StaggerPresetsClass()

// 获取交错动画延迟
export function getListStaggerDelay(index: number, config: StaggerConfig = StaggerPresets.normal): number {
  const delay = config.baseDelay + index * config.itemDelay
  if (config.maxDelay !== undefined) {
    return Math.min(delay, config.maxDelay)
  }
  return delay
}

// 3D 卡片效果配置
export interface Card3DEffect {
  perspective: number
  rotateX: number
  rotateY: number
  shadowRadius: number
  shadowOffsetY: number
}

export class Card3DEffectClass implements Card3DEffect {
  perspective: number = 1000
  rotateX: number = 4
  rotateY: number = 4
  shadowRadius: number = 20
  shadowOffsetY: number = 8

  constructor(perspective: number = 1000, rotateX: number = 4, rotateY: number = 4, shadowRadius: number = 20, shadowOffsetY: number = 8) {
    this.perspective = perspective
    this.rotateX = rotateX
    this.rotateY = rotateY
    this.shadowRadius = shadowRadius
    this.shadowOffsetY = shadowOffsetY
  }
}

export class Card3DPresetsClass {
  subtle: Card3DEffect = new Card3DEffectClass(1200, 2, 2, 12, 4)
  normal: Card3DEffect = new Card3DEffectClass(1000, 4, 4, 20, 8)
  prominent: Card3DEffect = new Card3DEffectClass(800, 6, 6, 30, 12)
}
export const Card3DPresets: Card3DPresetsClass = new Card3DPresetsClass()

// 页面入场动画序列
export interface PageEntranceSequence {
  heroDelay: number
  heroDuration: number
  contentDelay: number
  contentDuration: number
  footerDelay: number
  footerDuration: number
}

export class PageEntranceSequenceClass implements PageEntranceSequence {
  heroDelay: number = 80
  heroDuration: number = 480
  contentDelay: number = 200
  contentDuration: number = 560
  footerDelay: number = 320
  footerDuration: number = 380

  constructor(config?: Partial<PageEntranceSequence>) {
    if (config?.heroDelay !== undefined) this.heroDelay = config.heroDelay
    if (config?.heroDuration !== undefined) this.heroDuration = config.heroDuration
    if (config?.contentDelay !== undefined) this.contentDelay = config.contentDelay
    if (config?.contentDuration !== undefined) this.contentDuration = config.contentDuration
    if (config?.footerDelay !== undefined) this.footerDelay = config.footerDelay
    if (config?.footerDuration !== undefined) this.footerDuration = config.footerDuration
  }
}

export class PageEntrancePresetsClass {
  fast: PageEntranceSequence = new PageEntranceSequenceClass({ heroDelay: 40, heroDuration: 320, contentDelay: 120, contentDuration: 400, footerDelay: 200, footerDuration: 280 })
  normal: PageEntranceSequence = new PageEntranceSequenceClass()
  slow: PageEntranceSequence = new PageEntranceSequenceClass({ heroDelay: 120, heroDuration: 640, contentDelay: 280, contentDuration: 720, footerDelay: 420, footerDuration: 480 })
}
export const PageEntrancePresets: PageEntrancePresetsClass = new PageEntrancePresetsClass()

// 滑动解锁效果动画
export function getSwipeUnlockAnimation(): TransitionEffect {
  return TransitionEffect.OPACITY
    .animation({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.emphasized
    })
    .combine(TransitionEffect.translate({ x: 100 }))
    .animation({
      duration: AnimationDuration.slow,
      curve: AnimationCurve.decelerated
    })
}

// 展开收起动画
export function getExpandCollapseAnimation(expanding: boolean): TransitionEffect {
  if (expanding) {
    return TransitionEffect.OPACITY
      .animation({
        duration: AnimationDuration.normal,
        curve: AnimationCurve.emphasized
      })
      .combine(TransitionEffect.scale({ x: 0.9, y: 0.9 }))
      .animation({
        duration: AnimationDuration.slow,
        curve: AnimationCurve.emphasized
      })
  } else {
    return TransitionEffect.OPACITY
      .animation({
        duration: AnimationDuration.fast,
        curve: AnimationCurve.accelerated
      })
      .combine(TransitionEffect.scale({ x: 0.95, y: 0.95 }))
      .animation({
        duration: AnimationDuration.normal,
        curve: AnimationCurve.accelerated
      })
  }
}

// 拖拽反馈动画配置
export interface DragFeedbackConfig {
  scaleWhenDragging: number
  shadowRadiusWhenDragging: number
  shadowOffsetYWhenDragging: number
  duration: number
}

export class DragFeedbackConfigClass implements DragFeedbackConfig {
  scaleWhenDragging: number = 1.05
  shadowRadiusWhenDragging: number = 24
  shadowOffsetYWhenDragging: number = 12
  duration: number = 200

  constructor(config?: Partial<DragFeedbackConfig>) {
    if (config?.scaleWhenDragging !== undefined) this.scaleWhenDragging = config.scaleWhenDragging
    if (config?.shadowRadiusWhenDragging !== undefined) this.shadowRadiusWhenDragging = config.shadowRadiusWhenDragging
    if (config?.shadowOffsetYWhenDragging !== undefined) this.shadowOffsetYWhenDragging = config.shadowOffsetYWhenDragging
    if (config?.duration !== undefined) this.duration = config.duration
  }
}

export class DragFeedbackPresetsClass {
  subtle: DragFeedbackConfig = new DragFeedbackConfigClass({ scaleWhenDragging: 1.02, shadowRadiusWhenDragging: 16, shadowOffsetYWhenDragging: 6 })
  normal: DragFeedbackConfig = new DragFeedbackConfigClass()
  prominent: DragFeedbackConfig = new DragFeedbackConfigClass({ scaleWhenDragging: 1.08, shadowRadiusWhenDragging: 32, shadowOffsetYWhenDragging: 16 })
}
export const DragFeedbackPresets: DragFeedbackPresetsClass = new DragFeedbackPresetsClass()

// 加载状态动画配置
export interface LoadingAnimationConfig {
  rotationSpeed: number
  pulseScale: number
  opacityRange: [number, number]
}

export class LoadingAnimationConfigClass implements LoadingAnimationConfig {
  rotationSpeed: number = 1000
  pulseScale: number = 1.2
  opacityRange: [number, number] = [0.4, 1.0]

  constructor(config?: Partial<LoadingAnimationConfig>) {
    if (config?.rotationSpeed !== undefined) this.rotationSpeed = config.rotationSpeed
    if (config?.pulseScale !== undefined) this.pulseScale = config.pulseScale
    if (config?.opacityRange !== undefined) this.opacityRange = config.opacityRange
  }
}

export class LoadingAnimationPresetsClass {
  fast: LoadingAnimationConfig = new LoadingAnimationConfigClass({ rotationSpeed: 600 })
  normal: LoadingAnimationConfig = new LoadingAnimationConfigClass()
  slow: LoadingAnimationConfig = new LoadingAnimationConfigClass({ rotationSpeed: 1500, pulseScale: 1.15 })
}
export const LoadingAnimationPresets: LoadingAnimationPresetsClass = new LoadingAnimationPresetsClass()

// 成功反馈动画
export function getSuccessFeedbackAnimation(): TransitionEffect {
  return TransitionEffect.scale({ x: 1.1, y: 1.1 })
    .animation({
      duration: AnimationDuration.fast,
      curve: AnimationCurve.emphasized
    })
    .combine(TransitionEffect.OPACITY)
    .animation({
      duration: AnimationDuration.normal,
      curve: AnimationCurve.emphasized
    })
}

// 错误反馈动画（抖动效果）
export function getErrorShakeAnimation(): TransitionEffect {
  return TransitionEffect.translate({ x: -10 })
    .animation({
      duration: 100,
      curve: AnimationCurve.sharp,
      iterations: 3,
      playMode: PlayMode.Alternate
    })
    .combine(TransitionEffect.OPACITY)
    .animation({
      duration: AnimationDuration.fast,
      curve: AnimationCurve.standard
    })
}
