import { relationalStore } from '@kit.ArkData';
import { BookEntity, BookStatus } from '../../models/BookModel';
import { DatabaseManager } from '../database/DatabaseManager';
import { TableName } from '../database/DatabaseSchema';
import { DataRefreshService } from '../refresh/DataRefreshService';

/**
 * 书籍 Repository
 *
 * 多行说明：
 * 1. Repository 层负责 BookEntity 与 books 表之间的数据读写映射，页面层不直接拼 SQL 或操作 RdbStore。
 * 2. 新增、更新、删除方法保持单一职责，后续页面只需要传入领域模型或 id 即可完成持久化。
 * 3. 查询方法统一按 sort_order 和 created_at 排序，保证书架列表展示顺序稳定，后续可扩展拖拽排序。
 */
export class BookRepository {
  static async insertBook(book: BookEntity): Promise<number> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const result: number = await store.insert(TableName.books, BookRepository.toValueBucket(book))
    DataRefreshService.notifyBooksChanged()
    return result
  }

  static async updateBook(book: BookEntity): Promise<number> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.books)
    predicates.equalTo('id', book.id)
    const result: number = await store.update(BookRepository.toValueBucket(book), predicates)
    DataRefreshService.notifyBooksChanged()
    return result
  }

  static async deleteBook(bookId: string): Promise<number> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.books)
    predicates.equalTo('id', bookId)
    const result: number = await store.delete(predicates)
    DataRefreshService.notifyAllChanged()
    return result
  }

  static async queryAllBooks(): Promise<BookEntity[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.books)
    predicates.orderByAsc('sort_order')
    predicates.orderByDesc('created_at')
    return await BookRepository.queryBooks(predicates)
  }

  static async queryBooksByStatus(status: BookStatus): Promise<BookEntity[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.books)
    predicates.equalTo('status', status)
    predicates.orderByAsc('sort_order')
    predicates.orderByDesc('created_at')
    return await BookRepository.queryBooks(predicates)
  }

  static async queryBookById(bookId: string): Promise<BookEntity | undefined> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.books)
    predicates.equalTo('id', bookId)
    const books: BookEntity[] = await BookRepository.queryBooks(predicates)
    if (books.length === 0) {
      return undefined
    }
    return books[0]
  }

  private static async queryBooks(predicates: relationalStore.RdbPredicates): Promise<BookEntity[]> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const resultSet: relationalStore.ResultSet = await store.query(predicates)
    const books: BookEntity[] = []
    try {
      while (resultSet.goToNextRow()) {
        books.push(BookRepository.fromResultSet(resultSet))
      }
    } finally {
      resultSet.close()
    }
    return books
  }

  private static toValueBucket(book: BookEntity): relationalStore.ValuesBucket {
    return {
      'id': book.id,
      'name': book.name,
      'author': book.author === undefined ? null : book.author,
      'isbn': book.isbn === undefined ? null : book.isbn,
      'total_pages': book.totalPages === undefined ? null : book.totalPages,
      'cover_path': book.coverPath === undefined ? null : book.coverPath,
      'status': book.status,
      'sort_order': book.sortOrder,
      'created_at': book.createdAt,
      'updated_at': book.updatedAt
    }
  }

  private static fromResultSet(resultSet: relationalStore.ResultSet): BookEntity {
    const totalPages: number = resultSet.getLong(resultSet.getColumnIndex('total_pages'))
    return {
      id: resultSet.getString(resultSet.getColumnIndex('id')),
      name: resultSet.getString(resultSet.getColumnIndex('name')),
      author: resultSet.getString(resultSet.getColumnIndex('author')),
      isbn: resultSet.getString(resultSet.getColumnIndex('isbn')),
      totalPages: totalPages > 0 ? totalPages : undefined,
      coverPath: resultSet.getString(resultSet.getColumnIndex('cover_path')),
      status: resultSet.getString(resultSet.getColumnIndex('status')) as BookStatus,
      sortOrder: resultSet.getLong(resultSet.getColumnIndex('sort_order')),
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
    }
  }
}
