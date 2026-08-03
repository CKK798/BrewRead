import { relationalStore } from '@kit.ArkData';
import { ReadingEntryEntity, ReadingMood } from '../../models/ReadingEntryModel';
import { DatabaseManager } from '../database/DatabaseManager';
import { TableName } from '../database/DatabaseSchema';

/**
 * 阅读记录 Repository
 *
 * 多行说明：
 * 1. ReadingEntryRepository 负责 reading_entries 表的数据读写，是记录时间线、日历热力图和书籍进度的基础数据来源。
 * 2. 查询方法默认按 date 倒序排列，符合“最近记录优先回顾”的产品体验。
 * 3. 统计方法先提供当前页和记录数，后续书架页可用它们计算每本书的阅读进度与卡片信息。
 */
export class ReadingEntryRepository {
  static async insertEntry(entry: ReadingEntryEntity): Promise<number> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    return await store.insert(TableName.readingEntries, ReadingEntryRepository.toValueBucket(entry))
  }

  static async updateEntry(entry: ReadingEntryEntity): Promise<number> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.readingEntries)
    predicates.equalTo('id', entry.id)
    return await store.update(ReadingEntryRepository.toValueBucket(entry), predicates)
  }

  static async deleteEntry(entryId: string): Promise<number> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.readingEntries)
    predicates.equalTo('id', entryId)
    return await store.delete(predicates)
  }

  static async queryAllEntries(): Promise<ReadingEntryEntity[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.readingEntries)
    predicates.orderByDesc('date')
    predicates.orderByDesc('created_at')
    return await ReadingEntryRepository.queryEntries(predicates)
  }

  static async queryEntriesByBookId(bookId: string): Promise<ReadingEntryEntity[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.readingEntries)
    predicates.equalTo('book_id', bookId)
    predicates.orderByDesc('date')
    predicates.orderByDesc('created_at')
    return await ReadingEntryRepository.queryEntries(predicates)
  }

  static async queryEntriesByDateRange(startTime: number, endTime: number): Promise<ReadingEntryEntity[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.readingEntries)
    predicates.between('date', startTime, endTime)
    predicates.orderByDesc('date')
    return await ReadingEntryRepository.queryEntries(predicates)
  }

  static async getMaxPageToByBookId(bookId: string): Promise<number> {
    const entries: ReadingEntryEntity[] = await ReadingEntryRepository.queryEntriesByBookId(bookId)
    let maxPage: number = 0
    entries.forEach((entry: ReadingEntryEntity) => {
      if (entry.pageTo !== undefined && entry.pageTo > maxPage) {
        maxPage = entry.pageTo
      }
    })
    return maxPage
  }

  static async countEntriesByBookId(bookId: string): Promise<number> {
    const entries: ReadingEntryEntity[] = await ReadingEntryRepository.queryEntriesByBookId(bookId)
    return entries.length
  }

  private static async queryEntries(predicates: relationalStore.RdbPredicates): Promise<ReadingEntryEntity[]> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const resultSet: relationalStore.ResultSet = await store.query(predicates)
    const entries: ReadingEntryEntity[] = []
    try {
      while (resultSet.goToNextRow()) {
        entries.push(ReadingEntryRepository.fromResultSet(resultSet))
      }
    } finally {
      resultSet.close()
    }
    return entries
  }

  private static toValueBucket(entry: ReadingEntryEntity): relationalStore.ValuesBucket {
    return {
      'id': entry.id,
      'book_id': entry.bookId,
      'date': entry.date,
      'page_from': entry.pageFrom === undefined ? null : entry.pageFrom,
      'page_to': entry.pageTo === undefined ? null : entry.pageTo,
      'mood': entry.mood,
      'coffee': entry.coffee === undefined ? null : entry.coffee,
      'content': entry.content,
      'photo_path': entry.photoPath === undefined ? null : entry.photoPath,
      'created_at': entry.createdAt,
      'updated_at': entry.updatedAt
    }
  }

  private static fromResultSet(resultSet: relationalStore.ResultSet): ReadingEntryEntity {
    const pageFrom: number = resultSet.getLong(resultSet.getColumnIndex('page_from'))
    const pageTo: number = resultSet.getLong(resultSet.getColumnIndex('page_to'))
    return {
      id: resultSet.getString(resultSet.getColumnIndex('id')),
      bookId: resultSet.getString(resultSet.getColumnIndex('book_id')),
      date: resultSet.getLong(resultSet.getColumnIndex('date')),
      pageFrom: pageFrom > 0 ? pageFrom : undefined,
      pageTo: pageTo > 0 ? pageTo : undefined,
      mood: resultSet.getString(resultSet.getColumnIndex('mood')) as ReadingMood,
      coffee: resultSet.getString(resultSet.getColumnIndex('coffee')),
      content: resultSet.getString(resultSet.getColumnIndex('content')),
      photoPath: resultSet.getString(resultSet.getColumnIndex('photo_path')),
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
    }
  }
}
