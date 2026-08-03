import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { BookEntity } from '../../models/BookModel';
import { ExportRecordEntity } from '../../models/ExportRecordModel';
import { PAGE_PATH } from '../../pagePath';
import { BookRepository } from '../../services/repository/BookRepository';
import { ExportRecordRepository } from '../../services/repository/ExportRecordRepository';
import { FileDeleteResult, FileStorageService } from '../../services/storage/FileStorageService';
import { DateUtils } from '../../utils/DateUtils';

interface ExportHistoryItem {
  id: string
  fileName: string
  bookName: string
  paperSize: string
  createdAtText: string
  filePath: string
  fileExists: boolean
}

/**
 * 导出管理页面
 *
 * 多行说明：
 * 1. 本页面展示 export_records 表中的真实导出历史，是后续分享、预览和删除 PDF 的入口。
 * 2. 页面根据导出记录中的 bookId 补查书名，书籍被删除时用“已删除书籍”兜底，方便排查历史记录来源。
 * 3. 当前阶段 PDF 文件尚未真实生成，因此页面先展示目标路径和导出记录，后续接入文件系统后可补预览和分享能力。
 */
@HMRouter({ pageUrl: PAGE_PATH.EXPORT_MANAGER_PAGE })
@ComponentV2
export struct exportManagerPage {
  @Local records: ExportHistoryItem[] = []
  @Local loading: boolean = false
  @Local loadError: string = ''
  @Local deletingId: string = ''
  @Local showDeleteConfirm: boolean = false
  @Local pendingDeleteItem?: ExportHistoryItem = undefined

  async aboutToAppear() {
    await this.loadExportRecords()
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        Scroll() {
          Column() {
            if (this.loading) {
              this.LoadingState()
            } else if (this.loadError.length > 0) {
              this.ErrorState()
            } else if (this.records.length === 0) {
              this.EmptyState()
            } else {
              this.RecordList()
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 14, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      if (this.showDeleteConfirm) {
        this.DeleteConfirmPanel()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F4F0')
    .padding({ top: this.getUIContext().px2vp(AppStorage.get('topH')) })
  }

  @Builder
  Header() {
    Row() {
      Text('‹')
        .fontSize(32)
        .fontColor('#2C2825')
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          HMRouterMgr.pop()
        })
      Column() {
        Text('导出管理')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
        Text('查看已经生成的书籍日记本导出记录')
          .fontSize(13)
          .fontColor('#7D7872')
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 6, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  RecordList() {
    Column() {
      ForEach(this.records, (item: ExportHistoryItem) => {
        this.RecordCard(item)
      }, (item: ExportHistoryItem) => item.id)
    }
    .width('100%')
  }

  @Builder
  RecordCard(item: ExportHistoryItem) {
    Column() {
      Row() {
        Text('PDF')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .width(42)
          .height(42)
          .textAlign(TextAlign.Center)
          .backgroundColor('#C2865E')
          .borderRadius(21)
        Column() {
          Text(item.fileName)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2C2825')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(item.bookName + ' · ' + item.paperSize + ' · ' + item.createdAtText)
            .fontSize(12)
            .fontColor('#7D7872')
            .margin({ top: 5 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')
      Text(item.filePath)
        .fontSize(12)
        .fontColor('#A8A39C')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 12 })
      Row() {
        Text(item.fileExists ? '文件可用' : '文件缺失')
          .fontSize(12)
          .fontColor(item.fileExists ? '#8EA590' : '#B65A4B')
          .padding({ left: 8, right: 8 })
          .height(24)
          .textAlign(TextAlign.Center)
          .backgroundColor(item.fileExists ? '#1A8EA590' : '#1AB65A4B')
          .borderRadius(12)
        Blank()
        Text(this.deletingId === item.id ? '删除中...' : '删除记录')
          .fontSize(12)
          .fontColor('#B65A4B')
          .onClick(() => {
            this.prepareDeleteRecord(item)
          })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .margin({ bottom: 14 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  LoadingState() {
    Column() {
      Text('正在整理导出记录...')
        .fontSize(14)
        .fontColor('#7D7872')
    }
    .width('100%')
    .height(160)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  ErrorState() {
    Column() {
      Text(this.loadError)
        .fontSize(14)
        .fontColor('#B65A4B')
      Text('点我重试')
        .fontSize(13)
        .fontColor('#C2865E')
        .margin({ top: 10 })
    }
    .width('100%')
    .height(160)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .onClick(() => {
      this.loadExportRecords()
    })
  }

  @Builder
  EmptyState() {
    Column() {
      Text('还没有导出记录')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      Text('在书籍日记本里点击“导出为 PDF”后，记录会显示在这里')
        .fontSize(13)
        .fontColor('#7D7872')
        .lineHeight(20)
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 32, bottom: 32 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  DeleteConfirmPanel() {
    Column() {
      Blank()
      Column() {
        Text('删除导出文件？')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
        Text(this.getDeleteConfirmText())
          .fontSize(14)
          .fontColor('#7D7872')
          .lineHeight(21)
          .margin({ top: 10 })
        Row() {
          Text('取消')
            .fontSize(15)
            .fontColor('#7D7872')
            .layoutWeight(1)
            .height(42)
            .textAlign(TextAlign.Center)
            .backgroundColor('#F1EEE8')
            .borderRadius(21)
            .onClick(() => {
              this.cancelDeleteRecord()
            })
          Text('确认删除')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
            .height(42)
            .textAlign(TextAlign.Center)
            .backgroundColor('#B65A4B')
            .borderRadius(21)
            .margin({ left: 12 })
            .onClick(() => {
              this.confirmDeleteRecord()
            })
        }
        .width('100%')
        .margin({ top: 22 })
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius({ topLeft: 22, topRight: 22 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#66000000')
  }

  /**
   * 加载导出历史
   *
   * 多行说明：
   * 1. 先读取 export_records 表全部历史，再根据 bookId 补查书名用于列表展示。
   * 2. 如果原书籍已删除，导出历史仍保留并显示“已删除书籍”，避免历史记录突然消失。
   * 3. 加载失败时保留错误提示和重试入口，方便排查数据库或导出记录表问题。
   */
  async loadExportRecords() {
    this.loading = true
    this.loadError = ''
    try {
      const recordList: ExportRecordEntity[] = await ExportRecordRepository.queryAllRecords()
      const nextRecords: ExportHistoryItem[] = []
      for (let index = 0; index < recordList.length; index++) {
        nextRecords.push(await this.toHistoryItem(recordList[index]))
      }
      this.records = nextRecords
    } catch (err) {
      this.loadError = '导出记录加载失败，请稍后重试'
    }
    this.loading = false
  }

  async toHistoryItem(record: ExportRecordEntity): Promise<ExportHistoryItem> {
    const book: BookEntity | undefined = await BookRepository.queryBookById(record.bookId)
    return {
      id: record.id,
      fileName: record.fileName,
      bookName: book === undefined ? '已删除书籍' : book.name,
      paperSize: record.paperSize,
      createdAtText: DateUtils.formatDate(record.createdAt),
      filePath: record.filePath,
      fileExists: FileStorageService.exists(record.filePath)
    }
  }

  prepareDeleteRecord(item: ExportHistoryItem) {
    this.pendingDeleteItem = item
    this.showDeleteConfirm = true
  }

  cancelDeleteRecord() {
    this.pendingDeleteItem = undefined
    this.showDeleteConfirm = false
  }

  async confirmDeleteRecord() {
    if (this.pendingDeleteItem === undefined) {
      this.showDeleteConfirm = false
      return
    }
    await this.deleteRecord(this.pendingDeleteItem)
  }

  getDeleteConfirmText(): string {
    if (this.pendingDeleteItem === undefined) {
      return '将删除导出历史记录。'
    }
    if (this.pendingDeleteItem.fileExists) {
      return '将同时删除沙箱中的 PDF 文件和导出历史记录，操作后无法恢复。'
    }
    return '当前文件已缺失，将只删除导出历史记录。'
  }

  /**
   * 删除导出记录和真实文件
   *
   * 多行说明：
   * 1. 删除导出记录前先要求用户二次确认，避免误删真实 PDF 文件。
   * 2. 如果文件本来不存在，FileStorageService.deleteFile 会视为成功，并继续删除数据库历史。
   * 3. 如果真实文件删除失败，则停止删除数据库记录，保留用户可重试的历史入口。
   */
  async deleteRecord(item: ExportHistoryItem) {
    if (this.deletingId.length > 0) {
      return
    }
    this.deletingId = item.id
    try {
      const deleteResult: FileDeleteResult = FileStorageService.deleteFile(item.filePath)
      if (!deleteResult.success) {
        this.loadError = deleteResult.message
        this.deletingId = ''
        return
      }
      await ExportRecordRepository.deleteRecord(item.id)
      this.pendingDeleteItem = undefined
      this.showDeleteConfirm = false
      await this.loadExportRecords()
    } catch (err) {
      this.showDeleteConfirm = false
      this.loadError = '导出记录删除失败，请稍后重试'
    }
    this.deletingId = ''
  }
}
