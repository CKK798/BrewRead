import { relationalStore } from '@kit.ArkData';
import { AppSettingEntity, SettingKey, ThemeMode } from '../../models/AppSettingModel';
import { DatabaseManager } from '../database/DatabaseManager';
import { TableName } from '../database/DatabaseSchema';

/**
 * 应用设置 Repository
 *
 * 多行说明：
 * 1. AppSettingRepository 负责 app_settings 表的 key-value 读写，设置页不直接操作数据库。
 * 2. saveSetting 使用 insert + update 兜底实现 upsert，兼容当前 RelationalStore API 差异。
 * 3. 主题、默认纸张、最近书籍等配置都可以复用这里的基础读写能力。
 */
export class AppSettingRepository {
  static async saveSetting(key: SettingKey, value: string): Promise<void> {
    const now: number = new Date().getTime()
    const setting: AppSettingEntity = {
      key: key,
      value: value,
      updatedAt: now
    }
    const oldSetting: AppSettingEntity | undefined = await AppSettingRepository.querySetting(key)
    if (oldSetting === undefined) {
      await AppSettingRepository.insertSetting(setting)
      return
    }
    await AppSettingRepository.updateSetting(setting)
  }

  static async querySetting(key: SettingKey): Promise<AppSettingEntity | undefined> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.appSettings)
    predicates.equalTo('key', key)
    const settings: AppSettingEntity[] = await AppSettingRepository.querySettings(predicates)
    if (settings.length === 0) {
      return undefined
    }
    return settings[0]
  }

  static async getThemeMode(): Promise<ThemeMode> {
    const setting: AppSettingEntity | undefined = await AppSettingRepository.querySetting(SettingKey.THEME_MODE)
    if (setting === undefined) {
      return ThemeMode.SYSTEM
    }
    if (setting.value === ThemeMode.LIGHT || setting.value === ThemeMode.DARK || setting.value === ThemeMode.SYSTEM) {
      return setting.value as ThemeMode
    }
    return ThemeMode.SYSTEM
  }

  static async saveThemeMode(mode: ThemeMode): Promise<void> {
    await AppSettingRepository.saveSetting(SettingKey.THEME_MODE, mode)
  }

  private static async insertSetting(setting: AppSettingEntity): Promise<number> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    return await store.insert(TableName.appSettings, AppSettingRepository.toValueBucket(setting))
  }

  private static async updateSetting(setting: AppSettingEntity): Promise<number> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.appSettings)
    predicates.equalTo('key', setting.key)
    return await store.update(AppSettingRepository.toValueBucket(setting), predicates)
  }

  private static async querySettings(predicates: relationalStore.RdbPredicates): Promise<AppSettingEntity[]> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const resultSet: relationalStore.ResultSet = await store.query(predicates)
    const settings: AppSettingEntity[] = []
    try {
      while (resultSet.goToNextRow()) {
        settings.push(AppSettingRepository.fromResultSet(resultSet))
      }
    } finally {
      resultSet.close()
    }
    return settings
  }

  private static toValueBucket(setting: AppSettingEntity): relationalStore.ValuesBucket {
    return {
      'key': setting.key,
      'value': setting.value,
      'updated_at': setting.updatedAt
    }
  }

  private static fromResultSet(resultSet: relationalStore.ResultSet): AppSettingEntity {
    return {
      key: resultSet.getString(resultSet.getColumnIndex('key')),
      value: resultSet.getString(resultSet.getColumnIndex('value')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
    }
  }
}
