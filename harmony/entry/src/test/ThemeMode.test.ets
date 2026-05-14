import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant'
import { describe, it, expect } from '@ohos/hypium'
import { isDarkColorMode, isLightColorMode, statusBarContentColor } from '../main/ets/common/styles/ThemeMode'

export default function themeModeTest() {
  describe('themeMode', () => {
    it('detects dark color mode correctly', 0, () => {
      expect(isDarkColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)).assertTrue()
      expect(isDarkColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)).assertFalse()
      expect(isDarkColorMode(undefined)).assertFalse()
    })

    it('detects light color mode correctly', 0, () => {
      expect(isLightColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)).assertTrue()
      expect(isLightColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)).assertFalse()
      expect(isLightColorMode(undefined)).assertFalse()
    })

    it('returns system bar content color for current mode', 0, () => {
      expect(statusBarContentColor(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)).assertEqual('#FFFFFFFF')
      expect(statusBarContentColor(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)).assertEqual('#FF18212F')
      expect(statusBarContentColor(undefined)).assertEqual('#FF18212F')
    })
  })
}
