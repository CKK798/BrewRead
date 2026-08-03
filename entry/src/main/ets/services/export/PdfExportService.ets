import { BookEntity } from '../../models/BookModel';
import { ExportRecordEntity, PaperSize } from '../../models/ExportRecordModel';
import { getMoodText, ReadingEntryEntity } from '../../models/ReadingEntryModel';
import { DateUtils } from '../../utils/DateUtils';
import { FileNameUtils } from '../../utils/FileNameUtils';
import { IdUtils } from '../../utils/IdUtils';
import { ExportRecordRepository } from '../repository/ExportRecordRepository';
import { ReadingEntryRepository } from '../repository/ReadingEntryRepository';
import { FileStorageService, TextFileSaveResult } from '../storage/FileStorageService';

export interface PdfExportResult {
  success: boolean
  message: string
  record?: ExportRecordEntity
}

/**
 * PDF 导出基础服务
 *
 * 多行说明：
 * 1. 当前阶段先生成可落盘的“书籍日记本文本版 PDF 占位文件”，确保导出文件链路真实可用。
 * 2. 文件扩展名仍保留 .pdf，内容暂为 UTF-8 文本，后续接入真实 PDF 绘制时只替换 buildExportContent 和写入方式。
 * 3. 文件保存成功后再写入 export_records 表，避免导出管理页出现没有对应文件的无效历史记录。
 */
export class PdfExportService {
  static async exportBookJournal(book: BookEntity, paperSize: PaperSize = PaperSize.A4): Promise<PdfExportResult> {
    try {
      const entries: ReadingEntryEntity[] = await ReadingEntryRepository.queryEntriesByBookId(book.id)
      if (entries.length === 0) {
        return { success: false, message: '这本书还没有可导出的阅读记录' }
      }

      const now: number = new Date().getTime()
      const fileName: string = PdfExportService.buildFileName(book, now)
      const relativePath: string = PdfExportService.buildTargetPath(fileName)
      const content: string = PdfExportService.buildExportContent(book, entries, paperSize, now)
      const saveResult: TextFileSaveResult = await FileStorageService.saveText(relativePath, content)
      if (!saveResult.success) {
        return { success: false, message: saveResult.message }
      }

      const record: ExportRecordEntity = {
        id: IdUtils.createId('export'),
        bookId: book.id,
        filePath: saveResult.filePath,
        paperSize: paperSize,
        fileName: fileName,
        createdAt: now,
        updatedAt: now
      }
      await ExportRecordRepository.insertRecord(record)
      return { success: true, message: '导出文件已保存', record: record }
    } catch (err) {
      return { success: false, message: '导出失败，请稍后重试' }
    }
  }

  private static buildExportContent(book: BookEntity, entries: ReadingEntryEntity[], paperSize: PaperSize, timestamp: number): string {
    const lines: string[] = []
    lines.push('啡阅 · 书籍日记本')
    lines.push('')
    lines.push('书名：' + book.name)
    lines.push('作者：' + (book.author === undefined || book.author.length === 0 ? '未填写作者' : book.author))
    lines.push('纸张：' + paperSize)
    lines.push('导出时间：' + DateUtils.formatChineseDate(timestamp))
    lines.push('记录数：' + entries.length)
    lines.push('')
    lines.push('----------------------------------------')
    entries.forEach((entry: ReadingEntryEntity, index: number) => {
      lines.push((index + 1).toString() + '. ' + DateUtils.formatChineseDate(entry.date))
      lines.push('心情：' + getMoodText(entry.mood))
      lines.push('页码：' + PdfExportService.getPageText(entry))
      if (entry.coffee !== undefined && entry.coffee.length > 0) {
        lines.push('咖啡：' + entry.coffee)
      }
      lines.push('感悟：')
      lines.push(entry.content)
      lines.push('----------------------------------------')
    })
    return lines.join('\n')
  }

  private static getPageText(entry: ReadingEntryEntity): string {
    if (entry.pageFrom !== undefined && entry.pageTo !== undefined) {
      return '第 ' + entry.pageFrom + ' — ' + entry.pageTo + ' 页'
    }
    if (entry.pageTo !== undefined) {
      return '第 ' + entry.pageTo + ' 页'
    }
    return '未填写页码'
  }

  private static buildFileName(book: BookEntity, timestamp: number): string {
    const safeBookName: string = FileNameUtils.sanitizeFileName(book.name, '书籍日记本')
    return safeBookName + '_' + DateUtils.formatDate(timestamp) + '.pdf'
  }

  private static buildTargetPath(fileName: string): string {
    return 'exports/pdf/' + fileName
  }
}
