import { Colors } from './Colors'

export interface FontSizes {
  xs: number
  sm: number
  caption: number
  body: number
  bodyLg: number
  subtitle: number
  lg: number
  xl: number
  xxl: number
  hero: number
  display: number
}

export interface FontWeights {
  regular: FontWeight
  medium: FontWeight
  bold: FontWeight
}

export interface LineHeights {
  tight: number
  normal: number
  relaxed: number
  loose: number
}

export interface LetterSpacings {
  tight: number
  normal: number
  wide: number
  wider: number
}

export interface TextStyle {
  fontSize: number
  fontWeight: FontWeight
  fontColor: ResourceColor | string
  letterSpacing?: number
}

export interface TypographyScheme {
  size: FontSizes
  weight: FontWeights
  lineHeight: LineHeights
  letterSpacing: LetterSpacings
}

@Observed
class TypographyClass implements TypographyScheme {
  size: FontSizes = {
    xs: 10,
    sm: 11,
    caption: 12,
    body: 14,
    bodyLg: 15,
    subtitle: 16,
    lg: 18,
    xl: 24,
    xxl: 28,
    hero: 34,
    display: 38
  }

  weight: FontWeights = {
    regular: FontWeight.Normal,
    medium: FontWeight.Medium,
    bold: FontWeight.Bold
  }

  lineHeight: LineHeights = {
    tight: 20,
    normal: 24,
    relaxed: 26,
    loose: 30
  }

  letterSpacing: LetterSpacings = {
    tight: 0.5,
    normal: 1,
    wide: 2,
    wider: 3
  }
}

export const Typography: TypographyScheme = new TypographyClass()

export interface TextStylesInterface {
  displayLarge: TextStyle
  displayMedium: TextStyle
  titleLarge: TextStyle
  titleMedium: TextStyle
  titleSmall: TextStyle
  bodyLarge: TextStyle
  bodyMedium: TextStyle
  bodySmall: TextStyle
  labelLarge: TextStyle
  labelMedium: TextStyle
  labelSmall: TextStyle
  caption: TextStyle
  overline: TextStyle
}

@Observed
class TextStylesClass implements TextStylesInterface {
  displayLarge: TextStyle = { fontSize: 40, fontWeight: FontWeight.Bold, fontColor: Colors.textPrimary }
  displayMedium: TextStyle = { fontSize: 30, fontWeight: FontWeight.Bold, fontColor: Colors.textPrimary }
  titleLarge: TextStyle = { fontSize: 26, fontWeight: FontWeight.Bold, fontColor: Colors.textPrimary }
  titleMedium: TextStyle = { fontSize: 20, fontWeight: FontWeight.Bold, fontColor: Colors.textPrimary }
  titleSmall: TextStyle = { fontSize: 17, fontWeight: FontWeight.Medium, fontColor: Colors.textSecondary }
  bodyLarge: TextStyle = { fontSize: 16, fontWeight: FontWeight.Normal, fontColor: Colors.textSecondary }
  bodyMedium: TextStyle = { fontSize: 14, fontWeight: FontWeight.Normal, fontColor: Colors.textMuted }
  bodySmall: TextStyle = { fontSize: 11, fontWeight: FontWeight.Normal, fontColor: Colors.textMuted }
  labelLarge: TextStyle = { fontSize: 16, fontWeight: FontWeight.Medium, fontColor: Colors.textMuted }
  labelMedium: TextStyle = { fontSize: 12, fontWeight: FontWeight.Medium, fontColor: Colors.textMuted }
  labelSmall: TextStyle = { fontSize: 11, fontWeight: FontWeight.Medium, fontColor: Colors.textPlaceholder }
  caption: TextStyle = { fontSize: 11, fontWeight: FontWeight.Normal, fontColor: Colors.textPlaceholder }
  overline: TextStyle = {
    fontSize: 12,
    fontWeight: FontWeight.Medium,
    fontColor: Colors.textPrimary,
    letterSpacing: 3
  }
}

export const TextStyles: TextStylesInterface = new TextStylesClass()
