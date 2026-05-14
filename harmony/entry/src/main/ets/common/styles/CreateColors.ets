type ThemeColor = ResourceColor | string

export interface CreateColorsScheme {
  purple: ThemeColor
  purpleLight: ThemeColor
  purplePale: ThemeColor
  purpleBg: ThemeColor

  green: ThemeColor
  greenLight: ThemeColor
  greenPale: ThemeColor
  greenBg: ThemeColor

  blue: ThemeColor
  blueLight: ThemeColor
  bluePale: ThemeColor
  blueBg: ThemeColor

  gradientPurpleGreen: string[]
  gradientPurpleBlue: string[]
  gradientGreenBlue: string[]

  illustrationBg: ThemeColor
  illustrationAccent1: ThemeColor
  illustrationAccent2: ThemeColor
  illustrationAccent3: ThemeColor

  inputBg: ThemeColor
  inputFocusBorder: ThemeColor
  inputPlaceholder: ThemeColor

  buttonPrimary: ThemeColor
  buttonPrimaryHover: ThemeColor
  buttonSecondary: ThemeColor
  buttonSecondaryHover: ThemeColor
}

@Observed
class CreateColorsClass implements CreateColorsScheme {
  purple: ThemeColor = $r('app.color.accent_lavender_dark')
  purpleLight: ThemeColor = $r('app.color.accent_lavender_light')
  purplePale: ThemeColor = $r('app.color.overlay_soft')
  purpleBg: ThemeColor = $r('app.color.card_primary')

  green: ThemeColor = $r('app.color.accent_mint_dark')
  greenLight: ThemeColor = $r('app.color.accent_mint_light')
  greenPale: ThemeColor = $r('app.color.accent_mint_bg')
  greenBg: ThemeColor = $r('app.color.card_primary')

  blue: ThemeColor = $r('app.color.accent_primary')
  blueLight: ThemeColor = $r('app.color.accent_lavender')
  bluePale: ThemeColor = $r('app.color.overlay_medium')
  blueBg: ThemeColor = $r('app.color.card_primary')

  gradientPurpleGreen: string[] = ['#8FB8FF', '#8EE7F1']
  gradientPurpleBlue: string[] = ['#7BAAFF', '#71C5FF']
  gradientGreenBlue: string[] = ['#8EE7F1', '#71C5FF']

  illustrationBg: ThemeColor = $r('app.color.bg_elevated')
  illustrationAccent1: ThemeColor = $r('app.color.text_primary')
  illustrationAccent2: ThemeColor = $r('app.color.text_secondary')
  illustrationAccent3: ThemeColor = $r('app.color.text_muted')

  inputBg: ThemeColor = $r('app.color.card_secondary')
  inputFocusBorder: ThemeColor = $r('app.color.accent_primary')
  inputPlaceholder: ThemeColor = $r('app.color.text_placeholder')

  buttonPrimary: ThemeColor = $r('app.color.accent_primary')
  buttonPrimaryHover: ThemeColor = $r('app.color.brand_primary_dark')
  buttonSecondary: ThemeColor = $r('app.color.card_primary')
  buttonSecondaryHover: ThemeColor = $r('app.color.overlay_soft')
}

export const CreateColors: CreateColorsScheme = new CreateColorsClass()
