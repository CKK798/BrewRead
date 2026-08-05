import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { BookEntity } from '../models/BookModel';
import { getMoodColor, getMoodText, ReadingEntryEntity } from '../models/ReadingEntryModel';
import { PAGE_PATH } from '../pagePath';
import { BookRepository } from '../services/repository/BookRepository';
import { ReadingEntryRepository } from '../services/repository/ReadingEntryRepository';
import { DataRefreshService } from '../services/refresh/DataRefreshService';
import { ThemePreferenceService } from '../services/theme/ThemePreferenceService';
import { ThemePalette } from '../theme/ThemeTokens';
import { DateUtils } from '../utils/DateUtils';

interface JournalEntryItem {
  id: string
  bookId: string
  date: string
  bookName: string
  mood: string
  moodColor: string
  coffee: string
  pages: string
  content: string
}

interface ExportBookOption {
  bookId: string
  bookName: string
  entryCount: number
}

/**
 * 记录页面
 *
 * 多行说明：
 * 1. 当前记录页已经从静态示例时间线切换为本地 reading_entries 表真实数据。
 * 2. 页面加载记录后会根据 bookId 补查书籍名称，让时间线可以展示“心情 · 书名 · 咖啡”的完整上下文。
 * 3. 写记录页保存成功返回后，aboutToAppear 会重新查询时间线，保证一级页面数据及时刷新。
 */
@HMRouter({ pageUrl: PAGE_PATH.FEATURE_JOURNAL_PAGE })
@ComponentV2
export struct journalPage {
  @Local entries: JournalEntryItem[] = []
  @Local loading: boolean = false
  @Local loadError: string = ''
  @Local totalCoffeeCount: number = 0
  @Local totalReadPages: number = 0
  @Local showExportBookSelector: boolean = false
  @Local exportBooks: ExportBookOption[] = []
  private readonly refreshOwnerId: string = 'journalPage'

  async aboutToAppear() {
    DataRefreshService.registerBookListener(this.refreshOwnerId, () => {
      this.loadEntries()
    })
    DataRefreshService.registerEntryListener(this.refreshOwnerId, () => {
      this.loadEntries()
    })
    await this.loadEntries()
  }

  aboutToDisappear() {
    DataRefreshService.unregisterBookListener(this.refreshOwnerId)
    DataRefreshService.unregisterEntryListener(this.refreshOwnerId)
  }

  build() {
    Stack() {
      Column() {
        Scroll() {
          Column() {
            this.Header()
            this.SummaryBar()
            if (this.loading) {
              this.LoadingState()
            } else if (this.loadError.length > 0) {
              this.ErrorState()
            } else if (this.entries.length === 0) {
              this.EmptyState()
            } else {
              this.Timeline()
              this.ExportButton()
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 20, bottom: 22 })
        }
        .align(Alignment.Top)
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      if (this.showExportBookSelector) {
        this.ExportBookSelectorPanel()
      }
    }
    .backgroundColor(this.getPalette().pageBg)
    .width('100%')
    .height('100%')
  }

  getPalette(): ThemePalette {
    return ThemePreferenceService.getCurrentPalette()
  }

  @Builder
  Header() {
    Column() {
      Row() {
        Text('阅读记录')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getPalette().textPrimary)
          .layoutWeight(1)
        Text('写记录')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getPalette().cardBg)
          .padding({ left: 16, right: 16 })
          .height(38)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.getPalette().primary)
          .borderRadius(19)
          .onClick(() => {
            this.openEntryEditPage()
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('把读过的句子，慢慢酿成日记')
        .fontSize(15)
        .fontColor(this.getPalette().textSecondary)
        .margin({ top: 18 })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  SummaryBar() {
    Row() {
      Text('☕')
        .fontSize(16)
        .margin({ right: 8 })
      Text('共 ' + this.entries.length + ' 条记录 · 配咖啡 ' + this.totalCoffeeCount + ' 杯 · ' + this.totalReadPages + ' 页')
        .fontSize(13)
        .fontColor('this.getPalette().textSecondary')
    }
    .width('100%')
    .height(44)
    .padding({ left: 14, right: 14 })
    .margin({ top: 16, bottom: 20 })
    .backgroundColor('this.getPalette().cardBg')
    .borderRadius(14)
    .border({ width: 0.5, color: '#0D000000' })
  }

  @Builder
  Timeline() {
    Column() {
      ForEach(this.entries, (item: JournalEntryItem) => {
        Row() {
          Column() {
            Circle()
              .width(10)
              .height(10)
              .fill('this.getPalette().primary')
            Row()
              .width(2)
              .height(136)
              .backgroundColor('#26000000')
          }
          .width(20)
          .alignItems(HorizontalAlign.Center)

          Column() {
            Text(item.date)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getPalette().textPrimary)
              .margin({ bottom: 8 })
            this.EntryCard(item)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
      }, (item: JournalEntryItem) => item.id)
    }
    .width('100%')
  }

  @Builder
  EntryCard(item: JournalEntryItem) {
    Row() {
      Row()
        .width(3)
        .height('100%')
        .backgroundColor(item.moodColor)
        .borderRadius(2)
      Column() {
        Row() {
          Text(item.mood)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('this.getPalette().textPrimary')
          Text(' · ' + item.bookName)
            .fontSize(14)
            .fontColor('#7D7872')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        Text(item.pages + item.coffee)
          .fontSize(12)
          .fontColor(this.getPalette().textTertiary)
          .margin({ top: 6 })
        Text(item.content)
          .fontSize(16)
          .fontColor('#2C2825')
          .lineHeight(23)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 12 })
        Text('展开 ↓')
          .fontSize(12)
          .fontColor('#C2865E')
          .alignSelf(ItemAlign.End)
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .padding({ left: 12, right: 14, top: 14, bottom: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(140)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  LoadingState() {
    Column() {
      Text('正在翻阅记录...')
        .fontSize(14)
        .fontColor('#7D7872')
    }
    .width('100%')
    .height(130)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
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
    .height(130)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .onClick(() => {
      this.loadEntries()
    })
  }

  @Builder
  EmptyState() {
    Column() {
      Text('还没有写下第一条阅读记录')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      Text('选一本书，留下今天的心情、页码和感悟')
        .fontSize(13)
        .fontColor('#7D7872')
        .lineHeight(20)
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
      Text('去写记录')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .height(38)
        .padding({ left: 18, right: 18 })
        .textAlign(TextAlign.Center)
        .backgroundColor('#C2865E')
        .borderRadius(19)
        .margin({ top: 18 })
        .onClick(() => {
          this.openEntryEditPage()
        })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 28, bottom: 28 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
  }

  @Builder
  ExportButton() {
    Row() {
      Text('📄')
        .fontSize(17)
        .margin({ right: 8 })
      Text('选择书籍导出 PDF')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
    }
    .width('100%')
    .height(50)
    .justifyContent(FlexAlign.Center)
    .margin({ top: 6 })
    .backgroundColor('#C2865E')
    .borderRadius(25)
    .shadow({ radius: 10, color: '#1FC2865E', offsetX: 0, offsetY: 4 })
    .onClick(() => {
      this.prepareExportFromJournal()
    })
  }

  @Builder
  ExportBookSelectorPanel() {
    Column() {
      Blank()
      Column() {
        Row() {
          Column() {
            Text('选择要导出的书')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2C2825')
            Text('PDF 会按单本书的阅读日记本生成')
              .fontSize(13)
              .fontColor('#7D7872')
              .margin({ top: 6 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text('取消')
            .fontSize(14)
            .fontColor('#7D7872')
            .onClick(() => {
              this.showExportBookSelector = false
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        ForEach(this.exportBooks, (item: ExportBookOption) => {
          Row() {
            Column() {
              Text(item.bookName)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2C2825')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(item.entryCount + ' 条阅读记录')
                .fontSize(12)
                .fontColor('#A8A39C')
                .margin({ top: 5 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Text('›')
              .fontSize(22)
              .fontColor('#A8A39C')
          }
          .width('100%')
          .padding({ top: 14, bottom: 14 })
          .border({ width: { bottom: 0.5 }, color: '#12000000' })
          .onClick(() => {
            this.openBookJournalForExport(item.bookId)
          })
        }, (item: ExportBookOption) => item.bookId)
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
   * 加载真实阅读记录时间线
   *
   * 多行说明：
   * 1. 先从 reading_entries 表按日期倒序读取记录，保证时间线天然是最近记录优先。
   * 2. 再根据每条记录的 bookId 查询 books 表，补充书籍名称；书籍被删除时用“已删除书籍”兜底。
   * 3. 加载过程中同步计算咖啡杯数和阅读页数，用于顶部摘要栏展示整体阅读状态。
   */
  async loadEntries() {
    this.loading = true
    this.loadError = ''
    try {
      const entryList: ReadingEntryEntity[] = await ReadingEntryRepository.queryAllEntries()
      const nextEntries: JournalEntryItem[] = []
      let coffeeCount: number = 0
      let readPages: number = 0
      for (let index = 0; index < entryList.length; index++) {
        const entry: ReadingEntryEntity = entryList[index]
        const book: BookEntity | undefined = await BookRepository.queryBookById(entry.bookId)
        if (entry.coffee !== undefined && entry.coffee.length > 0) {
          coffeeCount++
        }
        readPages += this.calculateReadPages(entry)
        nextEntries.push(this.toJournalEntryItem(entry, book))
      }
      this.entries = nextEntries
      this.exportBooks = this.buildExportBookOptions(nextEntries)
      this.totalCoffeeCount = coffeeCount
      this.totalReadPages = readPages
    } catch (err) {
      this.loadError = '阅读记录加载失败，请稍后重试'
    }
    this.loading = false
  }

  toJournalEntryItem(entry: ReadingEntryEntity, book?: BookEntity): JournalEntryItem {
    return {
      id: entry.id,
      bookId: entry.bookId,
      date: DateUtils.formatMonthDay(entry.date) + ' · ' + DateUtils.getWeekdayText(entry.date),
      bookName: book === undefined ? '已删除书籍' : book.name,
      mood: getMoodText(entry.mood),
      moodColor: getMoodColor(entry.mood),
      coffee: entry.coffee === undefined || entry.coffee.length === 0 ? '' : ' · ☕ ' + entry.coffee,
      pages: this.getPageText(entry),
      content: entry.content
    }
  }

  getPageText(entry: ReadingEntryEntity): string {
    if (entry.pageFrom !== undefined && entry.pageTo !== undefined) {
      return '第 ' + entry.pageFrom + ' — ' + entry.pageTo + ' 页'
    }
    if (entry.pageTo !== undefined) {
      return '读到第 ' + entry.pageTo + ' 页'
    }
    return '未填写页码'
  }

  calculateReadPages(entry: ReadingEntryEntity): number {
    if (entry.pageFrom !== undefined && entry.pageTo !== undefined && entry.pageTo >= entry.pageFrom) {
      return entry.pageTo - entry.pageFrom + 1
    }
    return 0
  }

  buildExportBookOptions(entries: JournalEntryItem[]): ExportBookOption[] {
    const options: ExportBookOption[] = []
    entries.forEach((entry: JournalEntryItem) => {
      if (entry.bookName === '已删除书籍') {
        return
      }
      const exists: ExportBookOption | undefined = options.find((item: ExportBookOption) => item.bookId === entry.bookId)
      if (exists === undefined) {
        options.push({ bookId: entry.bookId, bookName: entry.bookName, entryCount: 1 })
      } else {
        exists.entryCount++
      }
    })
    return options
  }

  prepareExportFromJournal() {
    if (this.exportBooks.length === 0) {
      this.loadError = '没有可导出的书籍记录'
      return
    }
    if (this.exportBooks.length === 1) {
      this.openBookJournalForExport(this.exportBooks[0].bookId)
      return
    }
    this.showExportBookSelector = true
  }

  openBookJournalForExport(bookId: string) {
    this.showExportBookSelector = false
    AppStorage.setOrCreate('selectedBookId', bookId)
    HMRouterMgr.push({ pageUrl: PAGE_PATH.PDF_EXPORT_EDIT_PAGE })
  }

  /**
   * 打开写阅读记录页面
   *
   * 多行说明：
   * 1. 记录页作为一级 Tab 保持时间线展示职责，写记录表单通过二级页面承载，避免页面过重。
   * 2. 使用 PAGE_PATH.ENTRY_EDIT_PAGE 复用新增和编辑记录页面，后续可通过路由参数区分新建或编辑。
   * 3. 写记录页保存成功后 pop 返回记录页，aboutToAppear 会再次触发并刷新真实时间线。
   */
  openEntryEditPage() {
    AppStorage.setOrCreate('selectedEntryId', '')
    HMRouterMgr.push({ pageUrl: PAGE_PATH.ENTRY_EDIT_PAGE })
  }
}
