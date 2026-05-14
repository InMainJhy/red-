type ThemeColor = ResourceColor | string

export interface StageColors {
  early: ThemeColor
  turningPoint: ThemeColor
  crisis: ThemeColor
  rebuild: ThemeColor
  peak: ThemeColor
  default: ThemeColor
}

export interface StanceColors {
  support: ThemeColor
  oppose: ThemeColor
  reflective: ThemeColor
  default: ThemeColor
}

export interface ColorScheme {
  primary: ThemeColor
  primaryDark: ThemeColor
  primaryDarkAlt: ThemeColor

  background: ThemeColor
  backgroundSecondary: ThemeColor
  backgroundTertiary: ThemeColor
  backgroundElevated: ThemeColor

  cardPrimary: ThemeColor
  cardSecondary: ThemeColor
  cardMuted: ThemeColor

  textPrimary: ThemeColor
  textSecondary: ThemeColor
  textTertiary: ThemeColor
  textMuted: ThemeColor
  textPlaceholder: ThemeColor
  textInverse: ThemeColor

  accent: ThemeColor
  accentAlt: ThemeColor
  accentLight: ThemeColor
  accentPurple: ThemeColor

  success: ThemeColor
  warning: ThemeColor
  error: ThemeColor
  errorLight: ThemeColor
  errorBg: ThemeColor

  loading: ThemeColor
  loadingBg: ThemeColor

  border: ThemeColor
  borderLight: ThemeColor
  divider: ThemeColor

  tagBg: ThemeColor
  tagMuted: ThemeColor

  overlaySoft: ThemeColor
  overlayMedium: ThemeColor
  overlayStrong: ThemeColor

  shadowSoft: ThemeColor
  shadowMedium: ThemeColor
  shadowStrong: ThemeColor

  stage: StageColors
  stance: StanceColors
}

export interface LiquidGlassScheme {
  surface: ThemeColor
  surfaceStrong: ThemeColor
  surfaceSoft: ThemeColor
  surfaceMuted: ThemeColor
  border: ThemeColor
  borderStrong: ThemeColor
  highlight: ThemeColor
  highlightSoft: ThemeColor
  glow: ThemeColor
}

@Observed
class ColorsClass implements ColorScheme {
  primary: ThemeColor = $r('app.color.brand_primary')
  primaryDark: ThemeColor = $r('app.color.brand_primary_dark')
  primaryDarkAlt: ThemeColor = $r('app.color.brand_primary_alt')

  background: ThemeColor = $r('app.color.bg_primary')
  backgroundSecondary: ThemeColor = $r('app.color.bg_secondary')
  backgroundTertiary: ThemeColor = $r('app.color.bg_tertiary')
  backgroundElevated: ThemeColor = $r('app.color.bg_elevated')

  cardPrimary: ThemeColor = $r('app.color.card_primary')
  cardSecondary: ThemeColor = $r('app.color.card_secondary')
  cardMuted: ThemeColor = $r('app.color.card_muted')

  textPrimary: ThemeColor = $r('app.color.text_primary')
  textSecondary: ThemeColor = $r('app.color.text_secondary')
  textTertiary: ThemeColor = $r('app.color.text_tertiary')
  textMuted: ThemeColor = $r('app.color.text_muted')
  textPlaceholder: ThemeColor = $r('app.color.text_placeholder')
  textInverse: ThemeColor = $r('app.color.text_inverse')

  accent: ThemeColor = $r('app.color.accent_primary')
  accentAlt: ThemeColor = $r('app.color.accent_primary_alt')
  accentLight: ThemeColor = $r('app.color.accent_light')
  accentPurple: ThemeColor = $r('app.color.accent_purple')

  success: ThemeColor = $r('app.color.success')
  warning: ThemeColor = $r('app.color.warning')
  error: ThemeColor = $r('app.color.error')
  errorLight: ThemeColor = $r('app.color.error_light')
  errorBg: ThemeColor = $r('app.color.error_bg')

  loading: ThemeColor = $r('app.color.accent_primary')
  loadingBg: ThemeColor = $r('app.color.accent_light')

  border: ThemeColor = $r('app.color.border_primary')
  borderLight: ThemeColor = $r('app.color.border_light')
  divider: ThemeColor = $r('app.color.divider')

  tagBg: ThemeColor = $r('app.color.glass_surface_soft')
  tagMuted: ThemeColor = $r('app.color.glass_surface')

  overlaySoft: ThemeColor = $r('app.color.overlay_soft')
  overlayMedium: ThemeColor = $r('app.color.overlay_medium')
  overlayStrong: ThemeColor = $r('app.color.overlay_strong')

  shadowSoft: ThemeColor = $r('app.color.shadow_soft')
  shadowMedium: ThemeColor = $r('app.color.shadow_medium')
  shadowStrong: ThemeColor = $r('app.color.shadow_strong')

  stage: StageColors = {
    early: $r('app.color.accent_primary'),
    turningPoint: $r('app.color.accent_lavender'),
    crisis: $r('app.color.warning'),
    rebuild: $r('app.color.accent_mint'),
    peak: $r('app.color.accent_mint_dark'),
    default: $r('app.color.border_primary')
  }

  stance: StanceColors = {
    support: $r('app.color.accent_primary'),
    oppose: $r('app.color.error'),
    reflective: $r('app.color.accent_lavender'),
    default: $r('app.color.border_primary')
  }
}

@Observed
class LiquidGlassClass implements LiquidGlassScheme {
  surface: ThemeColor = $r('app.color.glass_surface')
  surfaceStrong: ThemeColor = $r('app.color.glass_surface_strong')
  surfaceSoft: ThemeColor = $r('app.color.glass_surface_soft')
  surfaceMuted: ThemeColor = $r('app.color.glass_surface_muted')
  border: ThemeColor = $r('app.color.glass_border')
  borderStrong: ThemeColor = $r('app.color.glass_border_strong')
  highlight: ThemeColor = $r('app.color.glass_highlight')
  highlightSoft: ThemeColor = $r('app.color.glass_highlight_soft')
  glow: ThemeColor = $r('app.color.glass_glow')
}

export const Colors: ColorScheme = new ColorsClass()
export const LiquidGlass: LiquidGlassScheme = new LiquidGlassClass()
export const ColorsLight: ColorScheme = Colors
