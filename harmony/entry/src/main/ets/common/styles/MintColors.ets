type ThemeColor = ResourceColor | string

export interface MintStageColors {
  early: ThemeColor
  turningPoint: ThemeColor
  crisis: ThemeColor
  rebuild: ThemeColor
  peak: ThemeColor
  default: ThemeColor
}

export interface MintStanceColors {
  support: ThemeColor
  oppose: ThemeColor
  reflective: ThemeColor
  default: ThemeColor
}

export interface MintColorScheme {
  mint: ThemeColor
  mintDark: ThemeColor
  mintLight: ThemeColor
  mintBg: ThemeColor
  mintPale: ThemeColor

  lavender: ThemeColor
  lavenderDark: ThemeColor
  lavenderLight: ThemeColor
  lavenderBg: ThemeColor
  lavenderPale: ThemeColor

  mintAccent: ThemeColor
  lavenderAccent: ThemeColor

  background: ThemeColor
  backgroundSecondary: ThemeColor
  backgroundTertiary: ThemeColor
  surface: ThemeColor
  surfaceGlass: ThemeColor

  cardPrimary: ThemeColor
  cardSecondary: ThemeColor
  cardElevated: ThemeColor

  textPrimary: ThemeColor
  textSecondary: ThemeColor
  textMuted: ThemeColor
  textPlaceholder: ThemeColor

  success: ThemeColor
  warning: ThemeColor
  error: ThemeColor
  errorLight: ThemeColor

  border: ThemeColor
  borderLight: ThemeColor
  divider: ThemeColor

  tagBg: ThemeColor
  tagText: ThemeColor

  categoryAll: ThemeColor
  categoryBusiness: ThemeColor
  categoryFinance: ThemeColor
  categoryTech: ThemeColor
  categoryPolitics: ThemeColor
  categoryCulture: ThemeColor
  categorySports: ThemeColor
  categoryEntertainment: ThemeColor
  categoryEducation: ThemeColor
  categoryPhilosophy: ThemeColor

  stage: MintStageColors
  stance: MintStanceColors
}

@Observed
class MintColorsClass implements MintColorScheme {
  mint: ThemeColor = $r('app.color.accent_mint')
  mintDark: ThemeColor = $r('app.color.accent_mint_dark')
  mintLight: ThemeColor = $r('app.color.accent_mint_light')
  mintBg: ThemeColor = $r('app.color.accent_mint_bg')
  mintPale: ThemeColor = $r('app.color.overlay_soft')

  lavender: ThemeColor = $r('app.color.accent_lavender')
  lavenderDark: ThemeColor = $r('app.color.accent_lavender_dark')
  lavenderLight: ThemeColor = $r('app.color.accent_lavender_light')
  lavenderBg: ThemeColor = $r('app.color.accent_lavender_bg')
  lavenderPale: ThemeColor = $r('app.color.overlay_medium')

  mintAccent: ThemeColor = $r('app.color.accent_mint')
  lavenderAccent: ThemeColor = $r('app.color.accent_lavender')

  background: ThemeColor = $r('app.color.bg_primary')
  backgroundSecondary: ThemeColor = $r('app.color.bg_secondary')
  backgroundTertiary: ThemeColor = $r('app.color.bg_tertiary')
  surface: ThemeColor = $r('app.color.card_primary')
  surfaceGlass: ThemeColor = $r('app.color.glass_surface')

  cardPrimary: ThemeColor = $r('app.color.card_primary')
  cardSecondary: ThemeColor = $r('app.color.card_secondary')
  cardElevated: ThemeColor = $r('app.color.bg_elevated')

  textPrimary: ThemeColor = $r('app.color.text_primary')
  textSecondary: ThemeColor = $r('app.color.text_secondary')
  textMuted: ThemeColor = $r('app.color.text_muted')
  textPlaceholder: ThemeColor = $r('app.color.text_placeholder')

  success: ThemeColor = $r('app.color.success')
  warning: ThemeColor = $r('app.color.warning')
  error: ThemeColor = $r('app.color.error')
  errorLight: ThemeColor = $r('app.color.error_light')

  border: ThemeColor = $r('app.color.border_primary')
  borderLight: ThemeColor = $r('app.color.border_light')
  divider: ThemeColor = $r('app.color.divider')

  tagBg: ThemeColor = $r('app.color.accent_mint_bg')
  tagText: ThemeColor = $r('app.color.accent_mint_dark')

  categoryAll: ThemeColor = $r('app.color.overlay_soft')
  categoryBusiness: ThemeColor = $r('app.color.accent_mint_bg')
  categoryFinance: ThemeColor = $r('app.color.accent_lavender_bg')
  categoryTech: ThemeColor = $r('app.color.accent_mint_bg')
  categoryPolitics: ThemeColor = $r('app.color.accent_lavender_bg')
  categoryCulture: ThemeColor = $r('app.color.overlay_medium')
  categorySports: ThemeColor = $r('app.color.accent_mint_bg')
  categoryEntertainment: ThemeColor = $r('app.color.accent_lavender_bg')
  categoryEducation: ThemeColor = $r('app.color.overlay_soft')
  categoryPhilosophy: ThemeColor = $r('app.color.overlay_medium')

  stage: MintStageColors = {
    early: $r('app.color.accent_primary'),
    turningPoint: $r('app.color.accent_lavender'),
    crisis: $r('app.color.warning'),
    rebuild: $r('app.color.accent_mint'),
    peak: $r('app.color.accent_mint_dark'),
    default: $r('app.color.border_primary')
  }

  stance: MintStanceColors = {
    support: $r('app.color.accent_primary'),
    oppose: $r('app.color.error'),
    reflective: $r('app.color.accent_lavender'),
    default: $r('app.color.border_primary')
  }
}

export const MintColors: MintColorScheme = new MintColorsClass()
