import type { BreakpointType } from './BreakpointSystem'

export interface ResponsiveLayoutMetrics {
  breakpoint: BreakpointType
  pageHorizontalPadding: number
  sectionGap: number
  cardPadding: number
  contentMaxWidth: number
  contentWideMaxWidth: number
  splitPanelGap: number
  useSplitHomeLayout: boolean
  useSplitSummaryLayout: boolean
  useSplitMeetingPrepLayout: boolean
}

export function resolveBreakpointByWidth(widthVp: number): BreakpointType {
  if (widthVp < 320) {
    return 'xs'
  }
  if (widthVp < 600) {
    return 'sm'
  }
  if (widthVp < 840) {
    return 'md'
  }
  if (widthVp < 1440) {
    return 'lg'
  }
  return 'xl'
}

export function responsiveLayoutForBreakpoint(breakpoint: BreakpointType): ResponsiveLayoutMetrics {
  if (breakpoint === 'xs' || breakpoint === 'sm') {
    return {
      breakpoint,
      pageHorizontalPadding: 16,
      sectionGap: 14,
      cardPadding: 16,
      contentMaxWidth: 680,
      contentWideMaxWidth: 760,
      splitPanelGap: 16,
      useSplitHomeLayout: false,
      useSplitSummaryLayout: false,
      useSplitMeetingPrepLayout: false
    }
  }

  if (breakpoint === 'md') {
    return {
      breakpoint,
      pageHorizontalPadding: 24,
      sectionGap: 18,
      cardPadding: 20,
      contentMaxWidth: 920,
      contentWideMaxWidth: 1040,
      splitPanelGap: 18,
      useSplitHomeLayout: true,
      useSplitSummaryLayout: false,
      useSplitMeetingPrepLayout: true
    }
  }

  if (breakpoint === 'lg') {
    return {
      breakpoint,
      pageHorizontalPadding: 32,
      sectionGap: 20,
      cardPadding: 22,
      contentMaxWidth: 1120,
      contentWideMaxWidth: 1240,
      splitPanelGap: 20,
      useSplitHomeLayout: true,
      useSplitSummaryLayout: true,
      useSplitMeetingPrepLayout: true
    }
  }

  return {
    breakpoint,
    pageHorizontalPadding: 40,
    sectionGap: 22,
    cardPadding: 24,
    contentMaxWidth: 1280,
    contentWideMaxWidth: 1360,
    splitPanelGap: 24,
    useSplitHomeLayout: true,
    useSplitSummaryLayout: true,
    useSplitMeetingPrepLayout: true
  }
}
