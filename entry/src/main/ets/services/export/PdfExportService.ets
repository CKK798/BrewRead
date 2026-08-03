import { BookEntity } from '../../models/BookModel';
import { ExportRecordEntity, PaperSize } from '../../models/ExportRecordModel';
import { ReadingEntryEntity } from '../../models/ReadingEntryModel';
import { ExportRecordRepository } from '../repository/ExportRecordRepository';
import { ReadingEntryRepository } from '../repository/ReadingEntryRepository';
import { DateUtils } from '../../utils/DateUtils';
import { FileNameUtils } from '../../utils/FileNameUtils';
import { IdUtils } from '../../utils/IdUtils';

export interface PdfExportResult {
  success: boolean
  message: string
  record?: ExportRecordEntity
}

/**
 * PDF 导出基础服务
 *
 * 多行说明：
 * 1. 当前阶段先打通“收集导出数据 → 生成导出文件名 → 写入导出历史”的基础链路。
 * 2. 真正的 PDF 绘制和文件写入需要后续接入 HarmonyOS 文件与绘制能力，因此这里先生成稳定的沙箱目标路径。
 * 3. 导出成功后写入 export_records 表，导出管理页可以基于这些记录展示历史和排查导出行为。
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
      const record: ExportRecordEntity = {
        id: IdUtils.createId('export'),
        bookId: book.id,
        filePath: PdfExportService.buildTargetPath(fileName),
        paperSize: paperSize,
        fileName: fileName,
        createdAt: now,
        updatedAt: now
      }
      await ExportRecordRepository.insertRecord(record)
      return { success: true, message: '已生成导出记录，PDF 文件绘制将在后续版本接入', record: record }
    } catch (err) {
      return { success: false, message: '导出失败，请稍后重试' }
    }
  }

  private static buildFileName(book: BookEntity, timestamp: number): string {
    const safeBookName: string = FileNameUtils.sanitizeFileName(book.name, '书籍日记本')
    return safeBookName + '_' + DateUtils.formatDate(timestamp) + '.pdf'
  }

  private static buildTargetPath(fileName: string): string {
    return 'exports/pdf/' + fileName
  }
}
