import { pdfService } from '@kit.PDFKit';
import { BookEntity } from '../../models/BookModel';
import { ExportRecordEntity, PaperSize, PdfTemplate } from '../../models/ExportRecordModel';
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

interface PdfPaperConfig {
  width: number
  height: number
  marginX: number
  marginTop: number
  marginBottom: number
  contentWidth: number
  coverTitleSize: number
  coverAuthorSize: number
  dateTitleSize: number
  metaSize: number
  bodySize: number
  footerSize: number
  bodyLineHeight: number
  wrapLength: number
}

interface PdfTextStyleConfig {
  size: number
  bold: boolean
  color: number
}

interface PdfStatsSummary {
  coffeeCount: number
  pageCount: number
  startDateText: string
  endDateText: string
  moodSummary: string
}

/**
 * PDF 导出服务
 *
 * 多行说明：
 * 1. 当前服务按 pdfUI 排版规范生成真实 PDF：封面页、每条记录独立页、封底页。
 * 2. A4/A5 使用独立页面尺寸、边距和换行长度，避免切换纸张后出现正文溢出或页脚重叠。
 * 3. PDF 文件保存成功后才写入 export_records 表，确保导出管理页中的历史记录都对应真实文件。
 */
export class PdfExportService {
  private static readonly A4_CONFIG: PdfPaperConfig = {
    width: 595,
    height: 842,
    marginX: 36,
    marginTop: 802,
    marginBottom: 40,
    contentWidth: 523,
    coverTitleSize: 36,
    coverAuthorSize: 18,
    dateTitleSize: 22,
    metaSize: 13,
    bodySize: 15,
    footerSize: 11,
    bodyLineHeight: 27,
    wrapLength: 28
  }
  private static readonly A5_CONFIG: PdfPaperConfig = {
    width: 420,
    height: 595,
    marginX: 36,
    marginTop: 555,
    marginBottom: 40,
    contentWidth: 348,
    coverTitleSize: 30,
    coverAuthorSize: 16,
    dateTitleSize: 20,
    metaSize: 12,
    bodySize: 14,
    footerSize: 10,
    bodyLineHeight: 25,
    wrapLength: 18
  }
  private static readonly FONT_PATH: string = '/system/fonts/HarmonyOS_Sans.ttf'
  private static readonly COLOR_DEEP_TERRACOTTA: number = 0x9B5C3E
  private static readonly COLOR_TERRACOTTA: number = 0xC2865E
  private static readonly COLOR_TEXT: number = 0x2C2825
  private static readonly COLOR_SECONDARY: number = 0x7D7872
  private static readonly COLOR_TERTIARY: number = 0xA8A39C

  static async exportBookJournal(book: BookEntity, paperSize: PaperSize = PaperSize.A4,
    template: PdfTemplate = PdfTemplate.MINIMALIST): Promise<PdfExportResult> {
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
      const saved: boolean = PdfExportService.createPdfFile(book, entries, paperSize, template, now, fullPath)
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

  private static createPdfFile(book: BookEntity, entries: ReadingEntryEntity[], paperSize: PaperSize,
    template: PdfTemplate, timestamp: number, fullPath: string): boolean {
    const paperConfig: PdfPaperConfig = PdfExportService.getTemplatePaperConfig(paperSize, template)
    const pdfDocument = new pdfService.PdfDocument()
    pdfDocument.createDocument(paperConfig.width, paperConfig.height)
    const stats: PdfStatsSummary = PdfExportService.buildStatsSummary(entries)
    PdfExportService.renderCoverPage(pdfDocument.getPage(0), paperConfig, template, book, entries.length, stats)
    if (template === PdfTemplate.ARTBOOK) {
      PdfExportService.renderSimpleEntries(pdfDocument, 1, paperConfig, entries)
    } else {
      for (let index = 0; index < entries.length; index++) {
        pdfDocument.insertBlankPage(pdfDocument.getPageCount(), paperConfig.width, paperConfig.height)
        PdfExportService.renderEntryPages(pdfDocument, pdfDocument.getPageCount() - 1, paperConfig, template, entries[index])
      }
    }
    const backPageIndex: number = pdfDocument.getPageCount()
    pdfDocument.insertBlankPage(backPageIndex, paperConfig.width, paperConfig.height)
    PdfExportService.renderBackCoverPage(pdfDocument.getPage(backPageIndex), paperConfig, template, book, stats)
    return pdfDocument.saveDocument(fullPath)
  }

  private static renderCoverPage(page: pdfService.PdfPage, config: PdfPaperConfig, template: PdfTemplate, book: BookEntity, entryCount: number,
    stats: PdfStatsSummary) {
    const centerX: number = config.width / 2
    let y: number = config.height - Math.round(config.height * 0.24)
    PdfExportService.addCenteredText(page, book.name, centerX, y, config.coverTitleSize, true,
      PdfExportService.getTemplatePrimaryColor(template))
    y -= 58
    PdfExportService.addCenteredText(page, PdfExportService.getAuthorText(book), centerX, y, config.coverAuthorSize, false,
      PdfExportService.getTemplateAccentColor(template))
    y -= 50
    PdfExportService.addCenteredText(page, PdfExportService.getTemplateDivider(template), centerX, y, 14, false,
      PdfExportService.getTemplateAccentColor(template))
    y -= 46
    PdfExportService.addCenteredText(page, PdfExportService.getExportYearText(stats), centerX, y, 14, false,
      PdfExportService.COLOR_SECONDARY)
    y -= 34
    PdfExportService.addCenteredText(page, '☕ 共记录 ' + entryCount + ' 次 · 配咖啡 ' + stats.coffeeCount + ' 杯', centerX, y, 12, false,
      PdfExportService.COLOR_TERTIARY)
    y -= 24
    PdfExportService.addCenteredText(page, stats.moodSummary, centerX, y, 12, false, PdfExportService.COLOR_TERTIARY)
  }

  private static renderEntryPages(pdfDocument: pdfService.PdfDocument, startPageIndex: number, config: PdfPaperConfig,
    template: PdfTemplate, entry: ReadingEntryEntity) {
    let pageIndex: number = startPageIndex
    let page: pdfService.PdfPage = pdfDocument.getPage(pageIndex)
    let y: number = config.marginTop
    y = PdfExportService.renderEntryHeader(page, config, template, entry, y)
    const contentLines: string[] = PdfExportService.wrapParagraphs(entry.content, config.wrapLength)
    for (let index = 0; index < contentLines.length; index++) {
      if (y - config.bodyLineHeight < config.marginBottom + 42) {
        PdfExportService.renderEntryFooter(page, config, entry)
        pageIndex++
        pdfDocument.insertBlankPage(pageIndex, config.width, config.height)
        page = pdfDocument.getPage(pageIndex)
        y = config.marginTop
      }
      PdfExportService.addText(page, contentLines[index], config.marginX, y, config.bodySize, false, PdfExportService.COLOR_TEXT)
      y -= config.bodyLineHeight
    }
    if (entry.photoPath !== undefined && entry.photoPath.length > 0 && y - 76 > config.marginBottom + 42) {
      y -= 16
      PdfExportService.addText(page, '┄┄┄┄┄┄┄┄  照片  ┄┄┄┄┄┄┄┄', config.marginX, y, 12, false, PdfExportService.COLOR_TERTIARY)
      y -= 28
      PdfExportService.addText(page, '场景照片已保存在本地：' + entry.photoPath, config.marginX, y, 10, false,
        PdfExportService.COLOR_TERTIARY)
    }
    PdfExportService.renderEntryFooter(page, config, entry)
  }

  private static renderEntryHeader(page: pdfService.PdfPage, config: PdfPaperConfig, template: PdfTemplate, entry: ReadingEntryEntity,
    y: number): number {
    const dateText: string = DateUtils.formatChineseDate(entry.date)
    PdfExportService.addText(page, dateText, config.marginX, y, config.dateTitleSize, true,
      PdfExportService.getTemplatePrimaryColor(template))
    y -= 28
    PdfExportService.addText(page, PdfExportService.getTemplateUnderline(template), config.marginX, y, 12, false,
      PdfExportService.getTemplateAccentColor(template))
    y -= 34
    PdfExportService.addText(page, PdfExportService.getMoodMetaText(entry), config.marginX, y, config.metaSize, false,
      PdfExportService.getTemplateAccentColor(template))
    y -= 22
    PdfExportService.addText(page, '☕ 咖啡：' + PdfExportService.getCoffeeText(entry), config.marginX, y, config.metaSize, false,
      PdfExportService.COLOR_SECONDARY)
    y -= 22
    PdfExportService.addText(page, '📄 ' + PdfExportService.getPageText(entry), config.marginX, y, config.metaSize, false,
      PdfExportService.COLOR_SECONDARY)
    return y - 36
  }

  private static renderEntryFooter(page: pdfService.PdfPage, config: PdfPaperConfig, entry: ReadingEntryEntity) {
    const footerText: string = '— ' + DateUtils.formatChineseDate(entry.date) + ' · ' + PdfExportService.getDayPartText(entry.date)
    PdfExportService.addText(page, footerText, config.width - config.marginX - 112, config.marginBottom, config.footerSize, false,
      PdfExportService.COLOR_TERTIARY)
  }

  private static renderSimpleEntries(pdfDocument: pdfService.PdfDocument, startPageIndex: number, config: PdfPaperConfig,
    entries: ReadingEntryEntity[]) {
    pdfDocument.insertBlankPage(startPageIndex, config.width, config.height)
    let pageIndex: number = startPageIndex
    let page: pdfService.PdfPage = pdfDocument.getPage(pageIndex)
    let y: number = config.marginTop
    for (let entryIndex = 0; entryIndex < entries.length; entryIndex++) {
      const entry: ReadingEntryEntity = entries[entryIndex]
      if (y - 92 < config.marginBottom + 42) {
        pageIndex++
        pdfDocument.insertBlankPage(pageIndex, config.width, config.height)
        page = pdfDocument.getPage(pageIndex)
        y = config.marginTop
      }
      PdfExportService.addText(page, DateUtils.formatChineseDate(entry.date) + ' · ' + getMoodText(entry.mood), config.marginX, y,
        config.dateTitleSize, true, PdfExportService.COLOR_TEXT)
      y -= 24
      PdfExportService.addText(page, PdfExportService.getPageText(entry) + ' · 咖啡：' + PdfExportService.getCoffeeText(entry),
        config.marginX, y, config.metaSize, false, PdfExportService.COLOR_SECONDARY)
      y -= 24
      const lines: string[] = PdfExportService.wrapParagraphs(entry.content, config.wrapLength)
      for (let lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        if (y - config.bodyLineHeight < config.marginBottom + 42) {
          pageIndex++
          pdfDocument.insertBlankPage(pageIndex, config.width, config.height)
          page = pdfDocument.getPage(pageIndex)
          y = config.marginTop
        }
        PdfExportService.addText(page, lines[lineIndex], config.marginX, y, config.bodySize, false, PdfExportService.COLOR_TEXT)
        y -= config.bodyLineHeight
      }
      y -= 18
    }
  }

  private static renderBackCoverPage(page: pdfService.PdfPage, config: PdfPaperConfig, template: PdfTemplate, book: BookEntity, stats: PdfStatsSummary) {
    const centerX: number = config.width / 2
    let y: number = config.height - Math.round(config.height * 0.25)
    PdfExportService.addCenteredText(page, book.name, centerX, y, config.coverAuthorSize + 2, true,
      PdfExportService.getTemplatePrimaryColor(template))
    y -= 34
    PdfExportService.addCenteredText(page, PdfExportService.getAuthorText(book), centerX, y, 14, false,
      PdfExportService.getTemplateAccentColor(template))
    y -= 44
    PdfExportService.addCenteredText(page, '──── ✦ ────', centerX, y, 14, false, PdfExportService.COLOR_TERRACOTTA)
    y -= 48
    PdfExportService.addCenteredText(page, stats.startDateText + ' — ' + stats.endDateText, centerX, y, 13, false,
      PdfExportService.COLOR_SECONDARY)
    y -= 50
    PdfExportService.addCenteredText(page, '感谢这本书的陪伴。', centerX, y, 13, false, PdfExportService.COLOR_TEXT)
    y -= 28
    PdfExportService.addCenteredText(page, '感谢每一杯咖啡。', centerX, y, 13, false, PdfExportService.COLOR_TEXT)
    y -= 28
    PdfExportService.addCenteredText(page, '感谢每一个写下感想的夜晚。', centerX, y, 13, false, PdfExportService.COLOR_TEXT)
  }

  private static wrapParagraphs(text: string, maxLength: number): string[] {
    const result: string[] = []
    const paragraphs: string[] = text.split('\n')
    paragraphs.forEach((paragraph: string, paragraphIndex: number) => {
      const trimmed: string = paragraph.trim()
      if (trimmed.length === 0) {
        result.push('')
      } else {
        let start: number = 0
        while (start < trimmed.length) {
          const end: number = Math.min(start + maxLength, trimmed.length)
          result.push(trimmed.substring(start, end))
          start = end
        }
      }
      if (paragraphIndex < paragraphs.length - 1) {
        result.push('')
      }
    })
    return result
  }

  private static buildStatsSummary(entries: ReadingEntryEntity[]): PdfStatsSummary {
    const sortedEntries: ReadingEntryEntity[] = entries.sort((left: ReadingEntryEntity, right: ReadingEntryEntity) => left.date - right.date)
    const coffeeCount: number = sortedEntries.filter((entry: ReadingEntryEntity) => {
      return entry.coffee !== undefined && entry.coffee.trim().length > 0
    }).length
    let pageCount: number = 0
    sortedEntries.forEach((entry: ReadingEntryEntity) => {
      if (entry.pageFrom !== undefined && entry.pageTo !== undefined && entry.pageTo >= entry.pageFrom) {
        pageCount += entry.pageTo - entry.pageFrom + 1
      }
    })
    return {
      coffeeCount: coffeeCount,
      pageCount: pageCount,
      startDateText: DateUtils.formatChineseDate(sortedEntries[0].date),
      endDateText: DateUtils.formatChineseDate(sortedEntries[sortedEntries.length - 1].date),
      moodSummary: PdfExportService.buildMoodSummary(sortedEntries)
    }
  }

  private static buildMoodSummary(entries: ReadingEntryEntity[]): string {
    const moodTexts: string[] = []
    entries.forEach((entry: ReadingEntryEntity) => {
      const moodText: string = getMoodText(entry.mood)
      if (moodTexts.indexOf(moodText) < 0) {
        moodTexts.push(moodText)
      }
    })
    const parts: string[] = []
    moodTexts.forEach((moodText: string) => {
      const count: number = entries.filter((entry: ReadingEntryEntity) => getMoodText(entry.mood) === moodText).length
      parts.push(moodText + ' ' + count)
    })
    return parts.join(' · ')
  }

  private static getMoodMetaText(entry: ReadingEntryEntity): string {
    return '心情：' + getMoodText(entry.mood)
  }

  private static getCoffeeText(entry: ReadingEntryEntity): string {
    if (entry.coffee !== undefined && entry.coffee.trim().length > 0) {
      return entry.coffee.trim()
    }
    return '—'
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

  private static getAuthorText(book: BookEntity): string {
    if (book.author === undefined || book.author.length === 0) {
      return '未填写作者'
    }
    return book.author
  }

  private static getExportYearText(stats: PdfStatsSummary): string {
    return stats.startDateText.substring(0, 4) + '年 阅读日记'
  }

  private static getDayPartText(timestamp: number): string {
    const hour: number = new Date(timestamp).getHours()
    if (hour < 6) {
      return '深夜'
    }
    if (hour < 12) {
      return '上午'
    }
    if (hour < 18) {
      return '午后'
    }
    return '夜晚'
  }

  private static addCenteredText(page: pdfService.PdfPage, text: string, centerX: number, y: number, size: number,
    bold: boolean, color: number) {
    const estimatedWidth: number = text.length * size * 0.5
    PdfExportService.addText(page, text, centerX - estimatedWidth / 2, y, size, bold, color)
  }

  private static addText(page: pdfService.PdfPage, text: string, x: number, y: number, size: number, bold: boolean,
    color: number) {
    const textStyle: pdfService.TextStyle = new pdfService.TextStyle()
    const fontInfo: pdfService.FontInfo = new pdfService.FontInfo()
    fontInfo.fontPath = PdfExportService.FONT_PATH
    textStyle.fontInfo = fontInfo
    textStyle.textSize = size
    textStyle.textColor = color
    textStyle.isBold = bold
    textStyle.isItalic = false
    page.addTextObject(text.length === 0 ? ' ' : text, x, y, textStyle)
  }

  private static buildFileName(book: BookEntity, timestamp: number): string {
    const safeBookName: string = FileNameUtils.sanitizeFileName(book.name, '书籍日记本')
    return safeBookName + '_' + DateUtils.formatDateTimeForFileName(timestamp) + '.pdf'
  }

  private static getTemplatePaperConfig(paperSize: PaperSize, template: PdfTemplate): PdfPaperConfig {
    const baseConfig: PdfPaperConfig = PdfExportService.getPaperConfig(paperSize)
    if (template === PdfTemplate.BUNKO) {
      return {
        width: baseConfig.width,
        height: baseConfig.height,
        marginX: baseConfig.marginX,
        marginTop: baseConfig.marginTop - 10,
        marginBottom: baseConfig.marginBottom,
        contentWidth: baseConfig.contentWidth,
        coverTitleSize: baseConfig.coverTitleSize - 2,
        coverAuthorSize: baseConfig.coverAuthorSize,
        dateTitleSize: baseConfig.dateTitleSize,
        metaSize: baseConfig.metaSize + 1,
        bodySize: baseConfig.bodySize,
        footerSize: baseConfig.footerSize,
        bodyLineHeight: baseConfig.bodyLineHeight + 3,
        wrapLength: Math.max(12, baseConfig.wrapLength - 2)
      }
    }
    if (template === PdfTemplate.LETTERPRESS) {
      return {
        width: baseConfig.width,
        height: baseConfig.height,
        marginX: baseConfig.marginX + 4,
        marginTop: baseConfig.marginTop - 4,
        marginBottom: baseConfig.marginBottom + 4,
        contentWidth: baseConfig.contentWidth - 8,
        coverTitleSize: baseConfig.coverTitleSize - 6,
        coverAuthorSize: baseConfig.coverAuthorSize - 1,
        dateTitleSize: baseConfig.dateTitleSize - 2,
        metaSize: baseConfig.metaSize - 1,
        bodySize: baseConfig.bodySize,
        footerSize: baseConfig.footerSize - 1,
        bodyLineHeight: baseConfig.bodyLineHeight - 1,
        wrapLength: Math.max(14, baseConfig.wrapLength - 1)
      }
    }
    if (template === PdfTemplate.ARTBOOK) {
      return {
        width: baseConfig.width,
        height: baseConfig.height,
        marginX: baseConfig.marginX + 12,
        marginTop: baseConfig.marginTop - 8,
        marginBottom: baseConfig.marginBottom + 8,
        contentWidth: baseConfig.contentWidth - 24,
        coverTitleSize: baseConfig.coverTitleSize + 10,
        coverAuthorSize: baseConfig.coverAuthorSize,
        dateTitleSize: baseConfig.dateTitleSize + 18,
        metaSize: baseConfig.metaSize - 1,
        bodySize: baseConfig.bodySize + 1,
        footerSize: baseConfig.footerSize - 1,
        bodyLineHeight: baseConfig.bodyLineHeight - 4,
        wrapLength: Math.max(14, baseConfig.wrapLength - 3)
      }
    }
    return baseConfig
  }

  private static getTemplatePrimaryColor(template: PdfTemplate): number {
    if (template === PdfTemplate.BUNKO) {
      return 0x3C3228
    }
    if (template === PdfTemplate.LETTERPRESS) {
      return 0x4A3728
    }
    if (template === PdfTemplate.ARTBOOK) {
      return 0x1A1A1A
    }
    return PdfExportService.COLOR_DEEP_TERRACOTTA
  }

  private static getTemplateAccentColor(template: PdfTemplate): number {
    if (template === PdfTemplate.BUNKO) {
      return 0xBF4E3A
    }
    if (template === PdfTemplate.LETTERPRESS) {
      return 0x6B2D3E
    }
    if (template === PdfTemplate.ARTBOOK) {
      return 0xE0453B
    }
    return PdfExportService.COLOR_TERRACOTTA
  }

  private static getTemplateDivider(template: PdfTemplate): string {
    if (template === PdfTemplate.BUNKO) {
      return '│  読了  │'
    }
    if (template === PdfTemplate.LETTERPRESS) {
      return '──────── ✒ ────────'
    }
    if (template === PdfTemplate.ARTBOOK) {
      return '━━━━━━━━━━━━'
    }
    return '──── ✦ ────'
  }

  private static getTemplateUnderline(template: PdfTemplate): string {
    if (template === PdfTemplate.BUNKO) {
      return '─ ─ ─ ─ ─ ─'
    }
    if (template === PdfTemplate.LETTERPRESS) {
      return '────────────'
    }
    if (template === PdfTemplate.ARTBOOK) {
      return '━━━━━━━━'
    }
    return '────────'
  }

  private static getPaperConfig(paperSize: PaperSize): PdfPaperConfig {
    if (paperSize === PaperSize.A5) {
      return PdfExportService.A5_CONFIG
    }
    return PdfExportService.A4_CONFIG
  }

  private static buildTargetPath(fileName: string): string {
    return 'exports/pdf/' + fileName
  }
}
