import { AppSettingEntity, SettingKey } from '../../models/AppSettingModel';
import { BookEntity, BookStatus } from '../../models/BookModel';
import { ExportRecordEntity } from '../../models/ExportRecordModel';
import { ReadingEntryEntity } from '../../models/ReadingEntryModel';
import { AppSettingRepository } from '../repository/AppSettingRepository';
import { BookRepository } from '../repository/BookRepository';
import { ExportRecordRepository } from '../repository/ExportRecordRepository';
import { ReadingEntryRepository } from '../repository/ReadingEntryRepository';
import { FileStorageService, TextFileSaveResult } from '../storage/FileStorageService';
import { DateUtils } from '../../utils/DateUtils';

export interface BackupSnapshot {
  version: number
  generatedAt: number
  books: BookEntity[]
  readingEntries: ReadingEntryEntity[]
  exportRecords: ExportRecordEntity[]
  appSettings: AppSettingEntity[]
}

export interface BackupResult {
  success: boolean
  message: string
  fileName: string
  jsonText: string
  filePath: string
}

/**
 * 备份基础服务
 *
 * 多行说明：
 * 1. 当前阶段先生成完整数据库快照 JSON，作为备份导出的核心数据结构。
 * 2. 真正写入沙箱文件、分享文件和恢复导入需要后续接入文件选择与文件系统能力，因此这里先返回 JSON 文本。
 * 3. 快照包含书籍、阅读记录、导出历史和已知应用设置，便于可用版本先具备数据迁移基础。
 */
export class BackupService {
  static async createBackupSnapshot(): Promise<BackupResult> {
    try {
      const now: number = new Date().getTime()
      const snapshot: BackupSnapshot = {
        version: 1,
        generatedAt: now,
        books: await BackupService.queryAllBooks(),
        readingEntries: await ReadingEntryRepository.queryAllEntries(),
        exportRecords: await ExportRecordRepository.queryAllRecords(),
        appSettings: await BackupService.queryKnownSettings()
      }
      const jsonText: string = JSON.stringify(snapshot)
      const fileName: string = '啡阅备份_' + DateUtils.formatDate(now) + '.json'
      const saveResult: TextFileSaveResult = await FileStorageService.saveText('backups/' + fileName, jsonText)
      return {
        success: saveResult.success,
        message: saveResult.success ? '备份文件已保存' : saveResult.message,
        fileName: fileName,
        jsonText: jsonText,
        filePath: saveResult.filePath
      }
    } catch (err) {
      return {
        success: false,
        message: '备份生成失败，请稍后重试',
        fileName: '',
        jsonText: '',
        filePath: ''
      }
    }
  }

  private static async queryAllBooks(): Promise<BookEntity[]> {
    const readingBooks: BookEntity[] = await BookRepository.queryBooksByStatus(BookStatus.READING)
    const finishedBooks: BookEntity[] = await BookRepository.queryBooksByStatus(BookStatus.FINISHED)
    const wantBooks: BookEntity[] = await BookRepository.queryBooksByStatus(BookStatus.WANT)
    return readingBooks.concat(finishedBooks).concat(wantBooks)
  }

  private static async queryKnownSettings(): Promise<AppSettingEntity[]> {
    const settings: AppSettingEntity[] = []
    const themeSetting: AppSettingEntity | undefined = await AppSettingRepository.querySetting(SettingKey.THEME_MODE)
    if (themeSetting !== undefined) {
      settings.push(themeSetting)
    }
    const paperSetting: AppSettingEntity | undefined = await AppSettingRepository.querySetting(SettingKey.DEFAULT_PAPER_SIZE)
    if (paperSetting !== undefined) {
      settings.push(paperSetting)
    }
    const lastBookSetting: AppSettingEntity | undefined = await AppSettingRepository.querySetting(SettingKey.LAST_USED_BOOK_ID)
    if (lastBookSetting !== undefined) {
      settings.push(lastBookSetting)
    }
    return settings
  }
}
