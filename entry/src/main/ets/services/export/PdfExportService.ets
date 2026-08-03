import { pdfService } from '@kit.PDFKit';
import { BookEntity } from '../../models/BookModel';
import { ExportRecordEntity, PaperSize } from '../../models/ExportRecordModel';
import { getMoodText, ReadingEntryEntity } from '../../models/ReadingEntryModel';
import { DateUtils } from '../../utils/DateUtils';
import { FileNameUtils } from '../../utils/FileNameUtils';
import { IdUtils } from '../../utils/IdUtils';
import { ExportRecordRepository } from '../repository/ExportRecordRepository';
import { ReadingEntryRepository } from '../repository/ReadingEntryRepository';
import { FileStorageService } from '../storage/FileStorageService';

export interface PdfExportResult {
  success: boolean
  message: string
  record?: ExportRecordEntity
}

interface PdfLineItem {
  text: string
  size: number
  bold: boolean
}

/**
 * PDF 导出服务
 *
 * 多行说明：
 * 1. 当前服务使用 HarmonyOS PDFKit 创建真实 PDF 文档，不再写入文本占位文件。
 * 2. 导出时先组装书籍日记本内容，再按页面高度自动分页，将文本写入 PDF 页面。
 * 3. PDF 文件保存成功后才写入 export_records 表，确保导出管理页中的历史记录都对应真实文件。
 */
export class PdfExportService {
  private static readonly PAGE_WIDTH: number = 595
  private static readonly PAGE_HEIGHT: number = 842
  private static readonly MARGIN_X: number = 48
  private static readonly MARGIN_TOP: number = 790
  private static readonly MARGIN_BOTTOM: number = 48
  private static readonly LINE_GAP: number = 8
  private static readonly FONT_PATH: string = '/system/fonts/HarmonyOS_Sans.ttf'

  static async exportBookJournal(book: BookEntity, paperSize: PaperSize = PaperSize.A4): Promise<PdfExportResult> {
    try {
      const entries: ReadingEntryEntity[] = await ReadingEntryRepository.queryEntriesByBookId(book.id)
      if (entries.length === 0) {
        return { success: false, message: '这本书还没有可导出的阅读记录' }
      }

      const now: number = new Date().getTime()
      const fileName: string = PdfExportService.buildFileName(book, now)
      const relativePath: string = PdfExportService.buildTargetPath(fileName)
      const fullPath: string = FileStorageService.buildFullPath(relativePath)
      if (fullPath.length === 0) {
        return { success: false, message: '文件目录未初始化，暂不能保存文件' }
      }
      if (!FileStorageService.ensureParentDirForFile(fullPath)) {
        return { success: false, message: '导出目录创建失败，请稍后重试' }
      }
      const saved: boolean = PdfExportService.createPdfFile(book, entries, paperSize, now, fullPath)
      if (!saved) {
        return { success: false, message: 'PDF 文件保存失败，请稍后重试' }
      }
      const fileSize: number = FileStorageService.getFileSize(fullPath)
      if (fileSize <= 0) {
        FileStorageService.deleteFile(fullPath)
        return { success: false, message: 'PDF 文件为空，导出失败，请稍后重试' }
      }

      const record: ExportRecordEntity = {
        id: IdUtils.createId('export'),
        bookId: book.id,
        filePath: fullPath,
        paperSize: paperSize,
        fileName: fileName,
        createdAt: now,
        updatedAt: now
      }
      await ExportRecordRepository.insertRecord(record)
      return { success: true, message: 'PDF 文件已保存', record: record }
    } catch (err) {
      return { success: false, message: '导出失败，请稍后重试' }
    }
  }

  private static createPdfFile(book: BookEntity, entries: ReadingEntryEntity[], paperSize: PaperSize, timestamp: number,
    fullPath: string): boolean {
    const pdfDocument = new pdfService.PdfDocument()
    pdfDocument.createDocument(PdfExportService.PAGE_WIDTH, PdfExportService.PAGE_HEIGHT)
    let pageIndex: number = 0
    let cursorY: number = PdfExportService.MARGIN_TOP
    let pdfPage: pdfService.PdfPage = pdfDocument.getPage(pageIndex)
    const lines: PdfLineItem[] = PdfExportService.buildPdfLines(book, entries, paperSize, timestamp)
    for (let index = 0; index < lines.length; index++) {
      const line: PdfLineItem = lines[index]
      const lineHeight: number = line.size + PdfExportService.LINE_GAP
      if (cursorY - lineHeight < PdfExportService.MARGIN_BOTTOM) {
        pageIndex++
        pdfDocument.insertBlankPage(pageIndex, PdfExportService.PAGE_WIDTH, PdfExportService.PAGE_HEIGHT)
        pdfPage = pdfDocument.getPage(pageIndex)
        cursorY = PdfExportService.MARGIN_TOP
      }
      PdfExportService.addText(pdfPage, line.text, PdfExportService.MARGIN_X, cursorY, line.size, line.bold)
      cursorY -= lineHeight
    }
    return pdfDocument.saveDocument(fullPath)
  }

  private static buildPdfLines(book: BookEntity, entries: ReadingEntryEntity[], paperSize: PaperSize, timestamp: number): PdfLineItem[] {
    const lines: PdfLineItem[] = []
    PdfExportService.pushLine(lines, '啡阅 · 书籍日记本', 22, true)
    PdfExportService.pushLine(lines, '', 10, false)
    PdfExportService.pushLine(lines, '书名：' + book.name, 14, true)
    PdfExportService.pushLine(lines, '作者：' + (book.author === undefined || book.author.length === 0 ? '未填写作者' : book.author), 12, false)
    PdfExportService.pushLine(lines, '纸张：' + paperSize, 12, false)
    PdfExportService.pushLine(lines, '导出时间：' + DateUtils.formatChineseDate(timestamp), 12, false)
    PdfExportService.pushLine(lines, '记录数：' + entries.length, 12, false)
    PdfExportService.pushLine(lines, '----------------------------------------', 12, false)
    entries.forEach((entry: ReadingEntryEntity, index: number) => {
      PdfExportService.pushLine(lines, (index + 1).toString() + '. ' + DateUtils.formatChineseDate(entry.date), 15, true)
      PdfExportService.pushLine(lines, '心情：' + getMoodText(entry.mood), 12, false)
      PdfExportService.pushLine(lines, '页码：' + PdfExportService.getPageText(entry), 12, false)
      if (entry.coffee !== undefined && entry.coffee.length > 0) {
        PdfExportService.pushLine(lines, '咖啡：' + entry.coffee, 12, false)
      }
      PdfExportService.pushWrappedLines(lines, '感悟：' + entry.content, 12, false)
      PdfExportService.pushLine(lines, '----------------------------------------', 12, false)
    })
    return lines
  }

  private static pushWrappedLines(lines: PdfLineItem[], text: string, size: number, bold: boolean) {
    const maxLength: number = 30
    if (text.length <= maxLength) {
      PdfExportService.pushLine(lines, text, size, bold)
      return
    }
    let start: number = 0
    while (start < text.length) {
      const end: number = Math.min(start + maxLength, text.length)
      PdfExportService.pushLine(lines, text.substring(start, end), size, bold)
      start = end
    }
  }

  private static pushLine(lines: PdfLineItem[], text: string, size: number, bold: boolean) {
    const item: PdfLineItem = {
      text: text,
      size: size,
      bold: bold
    }
    lines.push(item)
  }

  private static addText(page: pdfService.PdfPage, text: string, x: number, y: number, size: number, bold: boolean) {
    const textStyle: pdfService.TextStyle = new pdfService.TextStyle()
    const fontInfo: pdfService.FontInfo = new pdfService.FontInfo()
    fontInfo.fontPath = PdfExportService.FONT_PATH
    textStyle.fontInfo = fontInfo
    textStyle.textSize = size
    textStyle.textColor = 0x2C2825
    textStyle.isBold = bold
    textStyle.isItalic = false
    page.addTextObject(text.length === 0 ? ' ' : text, x, y, textStyle)
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
    return safeBookName + '_' + DateUtils.formatDateTimeForFileName(timestamp) + '.pdf'
  }

  private static buildTargetPath(fileName: string): string {
    return 'exports/pdf/' + fileName
  }
}
