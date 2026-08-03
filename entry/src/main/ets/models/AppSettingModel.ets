/**
 * 应用设置模型
 *
 * 多行说明：
 * 1. AppSettingEntity 使用 key-value 结构，便于渐进增加主题、备份、导出偏好等配置。
 * 2. SettingKey 只收敛当前已规划的稳定配置键，减少页面与服务层之间的字符串硬编码。
 * 3. 后续设置页更新选项时，只需要写入对应 key 的 value，并刷新相关 Store 即可。
 */
export enum SettingKey {
  THEME_MODE = 'theme_mode',
  DEFAULT_PAPER_SIZE = 'default_paper_size',
  LAST_USED_BOOK_ID = 'last_used_book_id'
}

export enum ThemeMode {
  LIGHT = 'light',
  DARK = 'dark',
  SYSTEM = 'system'
}

export interface AppSettingEntity {
  key: string
  value: string
  updatedAt: number
}
