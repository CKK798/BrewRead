import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { BookEntity } from '../../models/BookModel';
import { getMoodColor, getMoodText, ReadingEntryEntity } from '../../models/ReadingEntryModel';
import { PAGE_PATH } from '../../pagePath';
import { PdfExportResult, PdfExportService } from '../../services/export/PdfExportService';
import { BookRepository } from '../../services/repository/BookRepository';
import { ReadingEntryRepository } from '../../services/repository/ReadingEntryRepository';
import { DateUtils } from '../../utils/DateUtils';

interface BookJournalItem {
  id: string
  date: string
  mood: string
  moodColor: string
  coffee: string
  pages: string
  content: string
}

/**
 * 书籍日记本页面
 *
 * 多行说明：
 * 1. 本页面展示某一本书的完整阅读旅程，数据来源是 books 表和 reading_entries 表。
 * 2. 由于当前工程没有现成的 HMRouter 参数读取示例，入口暂时通过 AppStorage 传递 bookId，页面出现时再读取。
 * 3. 页面先完成书籍摘要和时间轴展示，后续 PDF 导出、记录编辑和记录详情都可以围绕当前 bookId 继续扩展。
 */
@HMRouter({ pageUrl: PAGE_PATH.BOOK_JOURNAL_PAGE })
@ComponentV2
export struct bookJournalPage {
  @Local book?: BookEntity = undefined
  @Local entries: BookJournalItem[] = []
  @Local loading: boolean = false
  @Local loadError: string = ''
  @Local totalPages: number = 0
  @Local coffeeCount: number = 0
  @Local showDeleteBookConfirm: boolean = false
  @Local showDeleteEntryConfirm: boolean = false
  @Local pendingDeleteEntryId: string = ''
  @Local exportMessage: string = ''
  @Local exporting: boolean = false
  private bookId: string = ''

  async aboutToAppear() {
    this.bookId = AppStorage.get<string>('selectedBookId') ?? ''
    await this.loadJournal()
  }

  build() {
    Stack() {
      Column() {
        Scroll() {
          Column() {
            this.Header()
            if (this.loading) {
              this.LoadingState()
            } else if (this.loadError.length > 0) {
              this.ErrorState()
            } else {
              this.SummaryBar()
              if (this.entries.length === 0) {
                this.EmptyState()
              } else {
                this.Timeline()
                this.ExportButton()
              }
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 20, bottom: 24 })
        }
        .align(Alignment.Top)
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%')
      .height('100%')
      if (this.showDeleteBookConfirm) {
        this.DeleteBookConfirmPanel()
      }
      if (this.showDeleteEntryConfirm) {
        this.DeleteEntryConfirmPanel()
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
        Text(this.book === undefined ? '书籍日记本' : this.book.name)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(this.book === undefined ? '阅读旅程' : this.getBookSubtitle())
          .fontSize(13)
          .fontColor('#7D7872')
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text('编辑')
        .fontSize(13)
        .fontColor('#C2865E')
        .padding({ left: 10, right: 10 })
        .height(32)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.openEditBookPage()
        })
      Text('删除')
        .fontSize(13)
        .fontColor('#B65A4B')
        .padding({ left: 10, right: 0 })
        .height(32)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.showDeleteBookConfirm = true
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  SummaryBar() {
    Row() {
      Text('☕')
        .fontSize(16)
        .margin({ right: 8 })
      Text('共 ' + this.entries.length + ' 条记录 · 配咖啡 ' + this.coffeeCount + ' 杯 · ' + this.totalPages + ' 页')
        .fontSize(13)
        .fontColor('#7D7872')
    }
    .width('100%')
    .height(44)
    .padding({ left: 14, right: 14 })
    .margin({ top: 18, bottom: 20 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
  }

  @Builder
  Timeline() {
    Column() {
      ForEach(this.entries, (item: BookJournalItem) => {
        Row() {
          Column() {
            Circle()
              .width(10)
              .height(10)
              .fill('#C2865E')
            Row()
              .width(2)
              .height(138)
              .backgroundColor('#26000000')
          }
          .width(20)
          .alignItems(HorizontalAlign.Center)
          Column() {
            Text(item.date)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2C2825')
              .margin({ bottom: 8 })
            this.EntryCard(item)
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
      }, (item: BookJournalItem) => item.id)
    }
    .width('100%')
  }

  @Builder
  EntryCard(item: BookJournalItem) {
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
            .fontColor('#2C2825')
          Text(item.coffee)
            .fontSize(14)
            .fontColor('#7D7872')
        }
        .width('100%')
        Text(item.pages)
          .fontSize(12)
          .fontColor('#A8A39C')
          .margin({ top: 6 })
        Text(item.content)
          .fontSize(16)
          .fontColor('#2C2825')
          .lineHeight(23)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 12 })
        Row() {
          Text('编辑')
            .fontSize(12)
            .fontColor('#C2865E')
            .margin({ right: 18 })
            .onClick(() => {
              this.openEditEntryPage(item.id)
            })
          Text('删除')
            .fontSize(12)
            .fontColor('#B65A4B')
            .onClick(() => {
              this.prepareDeleteEntry(item.id)
            })
        }
        .alignSelf(ItemAlign.End)
        .margin({ top: 8 })
      }
      .layoutWeight(1)
      .padding({ left: 12, right: 14, top: 14, bottom: 12 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(138)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
  }

  @Builder
  LoadingState() {
    Column() {
      Text('正在打开这本书的阅读旅程...')
        .fontSize(14)
        .fontColor('#7D7872')
    }
    .width('100%')
    .height(180)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 24 })
  }

  @Builder
  ErrorState() {
    Column() {
      Text(this.loadError)
        .fontSize(14)
        .fontColor('#B65A4B')
      Text('返回重试')
        .fontSize(13)
        .fontColor('#C2865E')
        .margin({ top: 10 })
    }
    .width('100%')
    .height(180)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 24 })
    .onClick(() => {
      HMRouterMgr.pop()
    })
  }

  @Builder
  EmptyState() {
    Column() {
      Text('这本书还没有阅读记录')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      Text('写下第一段阅读感悟，让这段旅程开始')
        .fontSize(13)
        .fontColor('#7D7872')
        .margin({ top: 8 })
      Text('写记录')
        .fontSize(14)
        .fontColor('#FFFFFF')
        .height(38)
        .padding({ left: 18, right: 18 })
        .textAlign(TextAlign.Center)
        .backgroundColor('#C2865E')
        .borderRadius(19)
        .margin({ top: 18 })
        .onClick(() => {
          this.openNewEntryPage()
        })
    }
    .width('100%')
    .padding({ top: 28, bottom: 28 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  ExportButton() {
    Column() {
      Row() {
        Text(this.exporting ? '正在导出...' : '📄 导出为 PDF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      .height(50)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(this.exporting ? '#80C2865E' : '#C2865E')
      .borderRadius(25)
      .onClick(() => {
        this.exportCurrentBook()
      })
      if (this.exportMessage.length > 0) {
        Text(this.exportMessage)
          .fontSize(12)
          .fontColor('#7D7872')
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .margin({ top: 8 })
  }

  @Builder
  DeleteBookConfirmPanel() {
    this.ConfirmPanel('删除这本书？', '这会同时删除这本书下的阅读记录，操作后无法恢复。', '删除书籍', () => {
      this.deleteCurrentBook()
    }, () => {
      this.showDeleteBookConfirm = false
    })
  }

  @Builder
  DeleteEntryConfirmPanel() {
    this.ConfirmPanel('删除这条记录？', '删除后这条阅读感悟、页码和咖啡信息将无法恢复。', '删除记录', () => {
      this.deleteEntry(this.pendingDeleteEntryId)
    }, () => {
      this.showDeleteEntryConfirm = false
      this.pendingDeleteEntryId = ''
    })
  }

  @Builder
  ConfirmPanel(title: string, desc: string, dangerText: string, onConfirm: () => void, onCancel: () => void) {
    Column() {
      Blank()
      Column() {
        Text(title)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
        Text(desc)
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
            .onClick(onCancel)
          Text(dangerText)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .layoutWeight(1)
            .height(42)
            .textAlign(TextAlign.Center)
            .backgroundColor('#B65A4B')
            .borderRadius(21)
            .margin({ left: 12 })
            .onClick(onConfirm)
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
   * 导出当前书籍日记本
   *
   * 多行说明：
   * 1. 当前按钮先接入 PdfExportService 的基础链路，生成导出历史记录并返回提示。
   * 2. 如果当前书籍未加载成功，则阻止导出，避免生成没有 bookId 的无效导出记录。
   * 3. 后续真正接入 PDF 文件绘制后，这个入口不需要改变，只需要增强服务内部实现。
   */
  async exportCurrentBook() {
    if (this.exporting) {
      return
    }
    if (this.book === undefined) {
      this.exportMessage = '书籍未加载，暂不能导出'
      return
    }
    this.exporting = true
    this.exportMessage = ''
    const result: PdfExportResult = await PdfExportService.exportBookJournal(this.book)
    this.exportMessage = result.message
    this.exporting = false
  }

  /**
   * 加载当前书籍的阅读旅程
   *
   * 多行说明：
   * 1. 先确认 AppStorage 中存在入口传入的 selectedBookId，再查询书籍和对应记录。
   * 2. 统计页数时只累计起始页和结束页都存在且范围有效的记录，避免缺页码数据污染摘要。
   * 3. 书籍不存在或没有 bookId 时返回明确错误，避免页面展示一个无法定位数据来源的空时间线。
   */
  async loadJournal() {
    if (this.bookId.length === 0) {
      this.loadError = '没有找到要查看的书籍'
      return
    }
    this.loading = true
    this.loadError = ''
    try {
      this.book = await BookRepository.queryBookById(this.bookId)
      if (this.book === undefined) {
        this.loadError = '书籍不存在或已被删除'
        this.loading = false
        return
      }
      const entryList: ReadingEntryEntity[] = await ReadingEntryRepository.queryEntriesByBookId(this.bookId)
      this.entries = entryList.map((entry: ReadingEntryEntity) => this.toJournalItem(entry))
      this.totalPages = this.calculateTotalPages(entryList)
      this.coffeeCount = this.countCoffee(entryList)
    } catch (err) {
      this.loadError = '书籍日记本加载失败，请稍后重试'
    }
    this.loading = false
  }

  toJournalItem(entry: ReadingEntryEntity): BookJournalItem {
    return {
      id: entry.id,
      date: DateUtils.formatChineseDate(entry.date),
      mood: getMoodText(entry.mood),
      moodColor: getMoodColor(entry.mood),
      coffee: entry.coffee === undefined || entry.coffee.length === 0 ? '' : ' · ☕ ' + entry.coffee,
      pages: this.getPageText(entry),
      content: entry.content
    }
  }

  calculateTotalPages(entries: ReadingEntryEntity[]): number {
    let total: number = 0
    entries.forEach((entry: ReadingEntryEntity) => {
      if (entry.pageFrom !== undefined && entry.pageTo !== undefined && entry.pageTo >= entry.pageFrom) {
        total += entry.pageTo - entry.pageFrom + 1
      }
    })
    return total
  }

  countCoffee(entries: ReadingEntryEntity[]): number {
    let total: number = 0
    entries.forEach((entry: ReadingEntryEntity) => {
      if (entry.coffee !== undefined && entry.coffee.length > 0) {
        total++
      }
    })
    return total
  }

  getPageText(entry: ReadingEntryEntity): string {
    if (entry.pageFrom !== undefined && entry.pageTo !== undefined) {
      return '第 ' + entry.pageFrom + ' — ' + entry.pageTo + ' 页'
    }
    if (entry.pageTo !== undefined) {
      return '第 ' + entry.pageTo + ' 页'
    }
    return '未填写页码'
  }

  /**
   * 打开新建阅读记录页面
   *
   * 多行说明：
   * 1. 新建记录前必须清空 selectedEntryId，避免用户上次编辑过记录后再次进入时误判为编辑模式。
   * 2. 同时保留 selectedBookId，让写记录页后续可以默认选中当前书籍。
   * 3. 当前写记录页已兼容新建和编辑两种模式，入口侧负责传递清晰的上下文。
   */
  openNewEntryPage() {
    AppStorage.setOrCreate('selectedEntryId', '')
    AppStorage.setOrCreate('selectedBookId', this.bookId)
    HMRouterMgr.push({ pageUrl: PAGE_PATH.ENTRY_EDIT_PAGE })
  }

  /**
   * 打开编辑阅读记录页面
   *
   * 多行说明：
   * 1. 编辑记录时写入 selectedEntryId，写记录页会据此读取原始记录并进入编辑模式。
   * 2. selectedBookId 继续保留当前书籍，便于编辑页在书籍候选列表中定位上下文。
   * 3. 编辑成功返回后，本页 aboutToAppear 会重新加载时间线和摘要统计。
   */
  openEditEntryPage(entryId: string) {
    AppStorage.setOrCreate('selectedEntryId', entryId)
    AppStorage.setOrCreate('selectedBookId', this.bookId)
    HMRouterMgr.push({ pageUrl: PAGE_PATH.ENTRY_EDIT_PAGE })
  }

  prepareDeleteEntry(entryId: string) {
    this.pendingDeleteEntryId = entryId
    this.showDeleteEntryConfirm = true
  }

  /**
   * 删除单条阅读记录
   *
   * 多行说明：
   * 1. 删除记录只调用 ReadingEntryRepository.deleteEntry，不影响书籍自身数据。
   * 2. 删除成功后立即重新加载当前书籍日记本，确保记录数、咖啡数和阅读页数同步刷新。
   * 3. 删除完成后清理 pendingDeleteEntryId 和 selectedEntryId，避免后续进入写记录页误判编辑上下文。
   */
  async deleteEntry(entryId: string) {
    try {
      await ReadingEntryRepository.deleteEntry(entryId)
      this.showDeleteEntryConfirm = false
      this.pendingDeleteEntryId = ''
      AppStorage.setOrCreate('selectedEntryId', '')
      await this.loadJournal()
    } catch (err) {
      this.showDeleteEntryConfirm = false
      this.loadError = '删除记录失败，请稍后重试'
    }
  }

  /**
   * 打开编辑书籍页面
   *
   * 多行说明：
   * 1. 编辑页和当前页使用同一个 selectedBookId，保证用户编辑的就是当前正在查看的书籍。
   * 2. 编辑成功后返回本页，aboutToAppear 会重新加载书籍信息和记录摘要。
   * 3. 当前仍使用 AppStorage 作为参数兜底，后续可替换为 HMRouter 标准参数。
   */
  openEditBookPage() {
    AppStorage.setOrCreate('selectedBookId', this.bookId)
    HMRouterMgr.push({ pageUrl: PAGE_PATH.BOOK_EDIT_PAGE })
  }

  /**
   * 删除当前书籍
   *
   * 多行说明：
   * 1. 删除操作调用 BookRepository.deleteBook，数据库外键负责级联清理该书的阅读记录。
   * 2. 当前先提供直接删除能力，后续应升级为确认弹窗，避免误触导致数据丢失。
   * 3. 删除成功后返回上一页，书架页 aboutToAppear 会重新加载真实书籍列表。
   */
  async deleteCurrentBook() {
    if (this.bookId.length === 0) {
      this.loadError = '没有找到要删除的书籍'
      return
    }
    try {
      await BookRepository.deleteBook(this.bookId)
      this.showDeleteBookConfirm = false
      AppStorage.setOrCreate('selectedBookId', '')
      AppStorage.setOrCreate('selectedEntryId', '')
      HMRouterMgr.pop()
    } catch (err) {
      this.showDeleteBookConfirm = false
      this.loadError = '删除失败，请稍后重试'
    }
  }

  getBookSubtitle(): string {
    if (this.book === undefined) {
      return '阅读旅程'
    }
    if (this.book.author === undefined || this.book.author.length === 0) {
      return '阅读旅程'
    }
    return this.book.author
  }
}
