import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant'

export function isDarkColorMode(colorMode?: ConfigurationConstant.ColorMode): boolean {
  return colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
}

export function isLightColorMode(colorMode?: ConfigurationConstant.ColorMode): boolean {
  return colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT
}

export function statusBarContentColor(colorMode?: ConfigurationConstant.ColorMode): string {
  return isDarkColorMode(colorMode) ? '#FFFFFFFF' : '#FF18212F'
}
