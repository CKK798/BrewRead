import { relationalStore } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { DatabaseName, DatabaseSchema } from './DatabaseSchema';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: DatabaseName.brewRead,
  securityLevel: relationalStore.SecurityLevel.S1
}

/**
 * RelationalStore 数据库管理器
 *
 * 多行说明：
 * 1. DatabaseManager 负责应用启动后的数据库打开、建表和 Store 实例缓存，Repository 层不直接创建数据库连接。
 * 2. init 方法具备幂等能力，重复调用时会复用已初始化的 RdbStore，避免多个页面同时初始化造成资源浪费。
 * 3. executeSchemaSql 会顺序执行 DatabaseSchema 中的建表和索引 SQL，保证后续 CRUD 前表结构已经存在。
 */
export class DatabaseManager {
  private static store?: relationalStore.RdbStore
  private static initializing?: Promise<relationalStore.RdbStore>

  static async init(context: Context): Promise<relationalStore.RdbStore> {
    if (DatabaseManager.store !== undefined) {
      return DatabaseManager.store
    }

    if (DatabaseManager.initializing !== undefined) {
      return DatabaseManager.initializing
    }

    DatabaseManager.initializing = DatabaseManager.openStore(context)
    DatabaseManager.store = await DatabaseManager.initializing
    DatabaseManager.initializing = undefined
    return DatabaseManager.store
  }

  static getStore(): relationalStore.RdbStore {
    if (DatabaseManager.store === undefined) {
      throw new Error('Database has not been initialized')
    }
    return DatabaseManager.store
  }

  private static async openStore(context: Context): Promise<relationalStore.RdbStore> {
    const store: relationalStore.RdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG)
    await DatabaseManager.executeSchemaSql(store)
    return store
  }

  private static async executeSchemaSql(store: relationalStore.RdbStore): Promise<void> {
    for (let index = 0; index < DatabaseSchema.createTableSqlList.length; index++) {
      await store.executeSql(DatabaseSchema.createTableSqlList[index])
    }
  }
}
