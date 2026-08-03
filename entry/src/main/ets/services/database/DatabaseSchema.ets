/**
 * 数据库 Schema 常量
 *
 * 多行说明：
 * 1. 本文件集中维护数据库名称、表名、索引名和建表 SQL，避免 Repository 层重复拼接 SQL 字符串。
 * 2. SQL 结构严格对应技术实现方案第 8 节，字段名采用下划线形式，模型层仍保持 ArkTS 驼峰命名。
 * 3. DatabaseManager 初始化数据库时按 createTableSqlList 顺序执行，后续迁移可以在这里扩展版本升级 SQL。
 */
export class DatabaseName {
  static readonly brewRead: string = 'brew_read.db'
}

export class TableName {
  static readonly books: string = 'books'
  static readonly readingEntries: string = 'reading_entries'
  static readonly exportRecords: string = 'export_records'
  static readonly appSettings: string = 'app_settings'
}

export class DatabaseSchema {
  static readonly createBooksTableSql: string = 'CREATE TABLE IF NOT EXISTS books (' +
    'id TEXT PRIMARY KEY, ' +
    'name TEXT NOT NULL, ' +
    'author TEXT, ' +
    'isbn TEXT, ' +
    'total_pages INTEGER, ' +
    'cover_path TEXT, ' +
    'status TEXT NOT NULL, ' +
    'sort_order INTEGER NOT NULL DEFAULT 0, ' +
    'created_at INTEGER NOT NULL, ' +
    'updated_at INTEGER NOT NULL)'

  static readonly createBooksStatusIndexSql: string = 'CREATE INDEX IF NOT EXISTS idx_books_status ON books(status)'
  static readonly createBooksSortIndexSql: string = 'CREATE INDEX IF NOT EXISTS idx_books_sort_order ON books(sort_order ASC)'
  static readonly createBooksCreatedIndexSql: string = 'CREATE INDEX IF NOT EXISTS idx_books_created_at ON books(created_at DESC)'

  static readonly createReadingEntriesTableSql: string = 'CREATE TABLE IF NOT EXISTS reading_entries (' +
    'id TEXT PRIMARY KEY, ' +
    'book_id TEXT NOT NULL, ' +
    'date INTEGER NOT NULL, ' +
    'page_from INTEGER, ' +
    'page_to INTEGER, ' +
    'mood TEXT NOT NULL, ' +
    'coffee TEXT, ' +
    'content TEXT NOT NULL, ' +
    'photo_path TEXT, ' +
    'is_highlight INTEGER NOT NULL DEFAULT 0, ' +
    'created_at INTEGER NOT NULL, ' +
    'updated_at INTEGER NOT NULL, ' +
    'FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE)'

  static readonly createEntriesBookIndexSql: string = 'CREATE INDEX IF NOT EXISTS idx_entries_book_id ON reading_entries(book_id)'
  static readonly createEntriesDateIndexSql: string = 'CREATE INDEX IF NOT EXISTS idx_entries_date ON reading_entries(date DESC)'
  static readonly createEntriesBookDateIndexSql: string = 'CREATE INDEX IF NOT EXISTS idx_entries_book_date ON reading_entries(book_id, date DESC)'
  static readonly createEntriesHighlightIndexSql: string = 'CREATE INDEX IF NOT EXISTS idx_entries_highlight ON reading_entries(is_highlight, date DESC)'
  static readonly alterEntriesHighlightSql: string = 'ALTER TABLE reading_entries ADD COLUMN is_highlight INTEGER NOT NULL DEFAULT 0'

  static readonly createExportRecordsTableSql: string = 'CREATE TABLE IF NOT EXISTS export_records (' +
    'id TEXT PRIMARY KEY, ' +
    'book_id TEXT NOT NULL, ' +
    'file_path TEXT NOT NULL, ' +
    'file_name TEXT NOT NULL, ' +
    'paper_size TEXT NOT NULL, ' +
    'created_at INTEGER NOT NULL, ' +
    'updated_at INTEGER NOT NULL, ' +
    'FOREIGN KEY(book_id) REFERENCES books(id) ON DELETE CASCADE)'

  static readonly createExportRecordsBookIndexSql: string = 'CREATE INDEX IF NOT EXISTS idx_export_records_book_id ON export_records(book_id)'
  static readonly createExportRecordsCreatedIndexSql: string = 'CREATE INDEX IF NOT EXISTS idx_export_records_created_at ON export_records(created_at DESC)'

  static readonly createAppSettingsTableSql: string = 'CREATE TABLE IF NOT EXISTS app_settings (' +
    'key TEXT PRIMARY KEY, ' +
    'value TEXT NOT NULL, ' +
    'updated_at INTEGER NOT NULL)'

  static readonly createTableSqlList: string[] = [
    DatabaseSchema.createBooksTableSql,
    DatabaseSchema.createBooksStatusIndexSql,
    DatabaseSchema.createBooksSortIndexSql,
    DatabaseSchema.createBooksCreatedIndexSql,
    DatabaseSchema.createReadingEntriesTableSql,
    DatabaseSchema.createEntriesBookIndexSql,
    DatabaseSchema.createEntriesDateIndexSql,
    DatabaseSchema.createEntriesBookDateIndexSql,
    DatabaseSchema.createEntriesHighlightIndexSql,
    DatabaseSchema.createExportRecordsTableSql,
    DatabaseSchema.createExportRecordsBookIndexSql,
    DatabaseSchema.createExportRecordsCreatedIndexSql,
    DatabaseSchema.createAppSettingsTableSql
  ]
}
