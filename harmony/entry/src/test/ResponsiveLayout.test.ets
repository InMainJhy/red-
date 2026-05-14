import { describe, it, expect } from '@ohos/hypium'
import { resolveBreakpointByWidth, responsiveLayoutForBreakpoint } from '../main/ets/common/ResponsiveLayout'

export default function responsiveLayoutTest() {
  describe('responsiveLayout', () => {
    it('maps width to expected breakpoint', 0, () => {
      expect(resolveBreakpointByWidth(319)).assertEqual('xs')
      expect(resolveBreakpointByWidth(320)).assertEqual('sm')
      expect(resolveBreakpointByWidth(600)).assertEqual('md')
      expect(resolveBreakpointByWidth(840)).assertEqual('lg')
      expect(resolveBreakpointByWidth(1440)).assertEqual('xl')
    })

    it('enables split home layout from md breakpoint', 0, () => {
      expect(responsiveLayoutForBreakpoint('sm').useSplitHomeLayout).assertFalse()
      expect(responsiveLayoutForBreakpoint('md').useSplitHomeLayout).assertTrue()
    })

    it('only enables split summary layout on large screens', 0, () => {
      expect(responsiveLayoutForBreakpoint('md').useSplitSummaryLayout).assertFalse()
      expect(responsiveLayoutForBreakpoint('lg').useSplitSummaryLayout).assertTrue()
    })

    it('increases outer gutters on larger breakpoints', 0, () => {
      expect(responsiveLayoutForBreakpoint('sm').pageHorizontalPadding < responsiveLayoutForBreakpoint('lg').pageHorizontalPadding).assertTrue()
    })
  })
}
