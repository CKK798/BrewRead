/**
 * 啡阅主题 Token
 *
 * 多行说明：
 * 1. 这里集中管理产品的颜色、字号、间距、圆角等设计常量，避免页面重复写死样式值。
 * 2. 当前先提供亮色晨雾主题与暗色夜幕主题的数据结构，页面可以逐步接入 BrightTheme。
 * 3. 后续做外观设置时，只需要根据 AppSetting 选择不同 ThemePalette，不必重写业务页面。
 */
export interface ThemePalette {
  pageBg: string
  cardBg: string
  inputBg: string
  primary: string
  primaryDeep: string
  accentGreen: string
  textPrimary: string
  textSecondary: string
  textTertiary: string
  divider: string
  shadow: string
}

export class BrewTheme {
  static readonly light: ThemePalette = {
    pageBg: '#F6F4F0',
    cardBg: '#FFFFFF',
    inputBg: '#F1EEE8',
    primary: '#C2865E',
    primaryDeep: '#9B5C3E',
    accentGreen: '#8EA590',
    textPrimary: '#2C2825',
    textSecondary: '#7D7872',
    textTertiary: '#A8A39C',
    divider: '#1A000000',
    shadow: '#0A000000'
  }

  static readonly dark: ThemePalette = {
    pageBg: '#1A1C1D',
    cardBg: '#242628',
    inputBg: '#2A2C2E',
    primary: '#D4A882',
    primaryDeep: '#E2BFA0',
    accentGreen: '#A3B5A6',
    textPrimary: '#E8E4DF',
    textSecondary: '#9E9992',
    textTertiary: '#7D7872',
    divider: '#24FFFFFF',
    shadow: '#33000000'
  }
}

export class BrewSpacing {
  static readonly pagePadding: number = 16
  static readonly cardPadding: number = 16
  static readonly sectionGap: number = 16
  static readonly smallGap: number = 8
  static readonly tabContentBottomSpace: number = 76
}

export class BrewRadius {
  static readonly small: number = 10
  static readonly card: number = 16
  static readonly pill: number = 999
}

export class BrewFontSize {
  static readonly title: number = 28
  static readonly sectionTitle: number = 20
  static readonly body: number = 16
  static readonly secondary: number = 14
  static readonly caption: number = 12
}
