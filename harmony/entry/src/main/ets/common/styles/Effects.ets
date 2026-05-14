// 统一阴影和视觉效果

// 阴影尺寸接口
export interface ShadowSize {
  blurRadius: number
  color: string
  offsetX: number
  offsetY: number
}

// 卡片阴影接口
export interface CardShadows {
  small: ShadowSize
  medium: ShadowSize
  large: ShadowSize
}

// 强调阴影接口
export interface AccentShadows {
  small: ShadowSize
  medium: ShadowSize
}

// 阴影主接口
export interface ShadowScheme {
  card: CardShadows
  elevated: ShadowSize
  accent: AccentShadows
}

// 动效时长接口
export interface DurationScheme {
  instant: number
  fast: number
  normal: number
  slow: number
  slower: number
  page: number
}

// 缓动曲线接口
export interface CurveScheme {
  standard: Curve
  emphasized: Curve
  decelerated: Curve
  accelerated: Curve
  smooth: Curve
  bounce: Curve
}

// 动画配置接口
export interface AnimationConfig {
  duration: number
  curve: Curve
}

// 列表动画配置接口
export interface ListAnimationConfig {
  duration: number
  delayIncrement: number
}

// 动画主接口
export interface AnimationScheme {
  buttonPress: AnimationConfig
  cardEntry: AnimationConfig
  listItemStagger: ListAnimationConfig
  pageTransition: AnimationConfig
  loading: AnimationConfig
  fade: AnimationConfig
}

// 阴影配置
export const Shadows: ShadowScheme = {
  card: {
    small: {
      blurRadius: 18,
      color: 'rgba(112, 160, 198, 0.10)',
      offsetX: 0,
      offsetY: 5
    },
    medium: {
      blurRadius: 28,
      color: 'rgba(112, 160, 198, 0.16)',
      offsetX: 0,
      offsetY: 10
    },
    large: {
      blurRadius: 38,
      color: 'rgba(112, 160, 198, 0.20)',
      offsetX: 0,
      offsetY: 14
    }
  },

  elevated: {
    blurRadius: 34,
    color: 'rgba(90, 148, 255, 0.18)',
    offsetX: 0,
    offsetY: 12
  },

  accent: {
    small: {
      blurRadius: 16,
      color: 'rgba(74, 154, 222, 0.18)',
      offsetX: 0,
      offsetY: 5
    },
    medium: {
      blurRadius: 24,
      color: 'rgba(74, 154, 222, 0.24)',
      offsetX: 0,
      offsetY: 8
    }
  }
}

// 动效时长
export const Durations: DurationScheme = {
  instant: 100,
  fast: 130,
  normal: 220,
  slow: 300,
  slower: 500,
  page: 260
}

// 缓动曲线
export const Curves: CurveScheme = {
  standard: Curve.Ease,
  emphasized: Curve.EaseOut,
  decelerated: Curve.EaseOut,
  accelerated: Curve.EaseIn,
  smooth: Curve.FastOutSlowIn,
  bounce: Curve.FastOutLinearIn
}

// 动画配置
export const Animations: AnimationScheme = {
  buttonPress: {
    duration: Durations.fast,
    curve: Curve.EaseOut
  },

  cardEntry: {
    duration: Durations.slow,
    curve: Curve.EaseOut
  },

  listItemStagger: {
    duration: Durations.normal,
    delayIncrement: 50
  },

  pageTransition: {
    duration: Durations.page,
    curve: Curve.EaseInOut
  },

  loading: {
    duration: Durations.slower,
    curve: Curve.Linear
  },

  fade: {
    duration: Durations.normal,
    curve: Curve.EaseInOut
  }
}
