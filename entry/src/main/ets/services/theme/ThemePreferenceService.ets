import { ThemeMode } from '../../models/AppSettingModel';
import { BrewTheme, ThemePalette } from '../../theme/ThemeTokens';
import { AppSettingRepository } from '../repository/AppSettingRepository';

/**
 * 主题偏好服务
 *
 * 多行说明：
 * 1. ThemePreferenceService 负责把数据库中的 theme_mode 同步到 AppStorage.currentThemeMode。
 * 2. 页面可以先读取 AppStorage.currentThemeMode 判断当前主题偏好，后续再逐步替换硬编码颜色。
 * 3. 这里不直接切换系统颜色模式，避免和 EntryAbility 的窗口配置、跟随系统策略产生冲突。
 */
export class ThemePreferenceService {
  static async loadThemeModeToStorage(): Promise<ThemeMode> {
    const mode: ThemeMode = await AppSettingRepository.getThemeMode()
    ThemePreferenceService.syncThemeModeToStorage(mode)
    return mode
  }

  static syncThemeModeToStorage(mode: ThemeMode) {
    AppStorage.setOrCreate('currentThemeMode', mode)
  }

  static getCurrentThemeMode(): ThemeMode {
    const mode: string = AppStorage.get<string>('currentThemeMode') ?? ThemeMode.SYSTEM
    if (mode === ThemeMode.LIGHT || mode === ThemeMode.DARK || mode === ThemeMode.SYSTEM) {
      return mode as ThemeMode
    }
    return ThemeMode.SYSTEM
  }

  static isDarkMode(): boolean {
    return ThemePreferenceService.getCurrentThemeMode() === ThemeMode.DARK
  }

  static getCurrentPalette(): ThemePalette {
    if (ThemePreferenceService.isDarkMode()) {
      return BrewTheme.dark
    }
    return BrewTheme.light
  }
}
