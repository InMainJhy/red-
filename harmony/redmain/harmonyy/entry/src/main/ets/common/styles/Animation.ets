// 统一动效规范 - HarmonyOS ArkTS 动画工具类

// 动效时长
export class AnimationDurationClass {
  instant: number = 100
  fast: number = 200
  normal: number = 300
  slow: number = 400
  slower: number = 500
  page: number = 350
}
export const AnimationDuration: AnimationDurationClass = new AnimationDurationClass()

// 动效曲线 - 使用官方推荐的曲线
export class AnimationCurveClass {
  standard: Curve = Curve.Ease
  emphasized: Curve = Curve.EaseOut
  decelerated: Curve = Curve.EaseIn
  accelerated: Curve = Curve.EaseOut
  smooth: Curve = Curve.FastOutSlowIn
  bounce: Curve = Curve.FastOutLinearIn
  linear: Curve = Curve.Linear
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
