import { relationalStore } from '@kit.ArkData';
import { ExportRecordEntity, PaperSize, PdfTemplate } from '../../models/ExportRecordModel';
import { DatabaseManager } from '../database/DatabaseManager';
import { TableName } from '../database/DatabaseSchema';

/**
 * 导出记录 Repository
 *
 * 多行说明：
 * 1. ExportRecordRepository 负责 export_records 表的增删查，记录每次 PDF 导出的文件路径和纸张规格。
 * 2. 导出服务只需要在导出成功后写入 ExportRecordEntity，导出管理页后续通过这里查询历史记录。
 * 3. 查询默认按 created_at 倒序返回，保证最近生成的 PDF 优先展示和分享。
 */
export class ExportRecordRepository {
  static async insertRecord(record: ExportRecordEntity): Promise<number> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    return await store.insert(TableName.exportRecords, ExportRecordRepository.toValueBucket(record))
  }

  static async deleteRecord(recordId: string): Promise<number> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.exportRecords)
    predicates.equalTo('id', recordId)
    return await store.delete(predicates)
  }

  static async queryAllRecords(): Promise<ExportRecordEntity[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.exportRecords)
    predicates.orderByDesc('created_at')
    return await ExportRecordRepository.queryRecords(predicates)
  }

  static async queryRecordsByBookId(bookId: string): Promise<ExportRecordEntity[]> {
    const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(TableName.exportRecords)
    predicates.equalTo('book_id', bookId)
    predicates.orderByDesc('created_at')
    return await ExportRecordRepository.queryRecords(predicates)
  }

  private static async queryRecords(predicates: relationalStore.RdbPredicates): Promise<ExportRecordEntity[]> {
    const store: relationalStore.RdbStore = DatabaseManager.getStore()
    const resultSet: relationalStore.ResultSet = await store.query(predicates)
    const records: ExportRecordEntity[] = []
    try {
      while (resultSet.goToNextRow()) {
        records.push(ExportRecordRepository.fromResultSet(resultSet))
      }
    } finally {
      resultSet.close()
    }
    return records
  }

  private static toValueBucket(record: ExportRecordEntity): relationalStore.ValuesBucket {
    return {
      'id': record.id,
      'book_id': record.bookId,
      'file_path': record.filePath,
      'file_name': record.fileName,
      'paper_size': record.paperSize,
      'template': record.template,
      'file_size': record.fileSize,
      'page_count': record.pageCount,
      'created_at': record.createdAt,
      'updated_at': record.updatedAt
    }
  }

  private static fromResultSet(resultSet: relationalStore.ResultSet): ExportRecordEntity {
    return {
      id: resultSet.getString(resultSet.getColumnIndex('id')),
      bookId: resultSet.getString(resultSet.getColumnIndex('book_id')),
      filePath: resultSet.getString(resultSet.getColumnIndex('file_path')),
      fileName: resultSet.getString(resultSet.getColumnIndex('file_name')),
      paperSize: resultSet.getString(resultSet.getColumnIndex('paper_size')) as PaperSize,
      template: ExportRecordRepository.getStringValue(resultSet, 'template', PdfTemplate.MINIMALIST) as PdfTemplate,
      fileSize: ExportRecordRepository.getLongValue(resultSet, 'file_size', 0),
      pageCount: ExportRecordRepository.getLongValue(resultSet, 'page_count', 0),
      createdAt: resultSet.getLong(resultSet.getColumnIndex('created_at')),
      updatedAt: resultSet.getLong(resultSet.getColumnIndex('updated_at'))
    }
  }

  private static getStringValue(resultSet: relationalStore.ResultSet, columnName: string, fallback: string): string {
    const columnIndex: number = resultSet.getColumnIndex(columnName)
    if (columnIndex < 0) {
      return fallback
    }
    const value: string = resultSet.getString(columnIndex)
    if (value.length === 0) {
      return fallback
    }
    return value
  }

  private static getLongValue(resultSet: relationalStore.ResultSet, columnName: string, fallback: number): number {
    const columnIndex: number = resultSet.getColumnIndex(columnName)
    if (columnIndex < 0) {
      return fallback
    }
    return resultSet.getLong(columnIndex)
  }
}
