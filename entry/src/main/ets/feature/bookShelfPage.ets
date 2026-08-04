import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { BookEntity, BookStatus, BookWithProgress } from '../models/BookModel';
import { PAGE_PATH } from '../pagePath';
import { BookRepository } from '../services/repository/BookRepository';
import { ReadingEntryRepository } from '../services/repository/ReadingEntryRepository';
import { ThemePreferenceService } from '../services/theme/ThemePreferenceService';
import { ThemePalette } from '../theme/ThemeTokens';
import { BookUtils } from '../utils/BookUtils';

interface BookShelfItem {
  id: string
  title: string
  author: string
  progressText: string
  progress: number
  records: number
  coverText: string
  coverStart: string
}

/**
 * 书架页面
 *
 * 多行说明：
 * 1. 当前页面已经从静态示例数据切换为本地数据库数据，页面出现时会按选中的书籍状态刷新列表。
 * 2. UI 卡片仍使用 BookShelfItem 展示模型，避免页面布局直接依赖数据库字段，后续调整数据库结构不影响视图层。
 * 3. 阅读进度与记录数来自 ReadingEntryRepository，保证书架卡片可以反映真实阅读记录变化。
 */
@HMRouter({ pageUrl: PAGE_PATH.FEATURE_BOOKSHELF_PAGE })
@ComponentV2
export struct bookShelfPage {
  @Local selectedStatus: number = 0
  @Local books: BookShelfItem[] = []
  @Local loading: boolean = false
  @Local loadError: string = ''
  private statusTabs: string[] = ['在读', '已读完', '想读']
  private statusValues: BookStatus[] = [BookStatus.READING, BookStatus.FINISHED, BookStatus.WANT]

  async aboutToAppear() {
    await this.loadBooks()
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          this.Header()
          this.StatusTabs()
          if (this.loading) {
            this.LoadingState()
          } else if (this.loadError.length > 0) {
            this.ErrorState()
          } else if (this.books.length === 0) {
            this.EmptyState()
          } else {
            ForEach(this.books, (item: BookShelfItem) => {
              this.BookCard(item)
            }, (item: BookShelfItem) => item.id)
          }
          this.AddBookCard()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 20 })
      }
      .align(Alignment.Top)
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
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
    Row() {
      Column() {
        Text('我的书架')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getPalette().textPrimary)
        Text('把每一本书酿成可回味的记录')
          .fontSize(13)
          .fontColor(this.getPalette().textSecondary)
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('+')
        .fontSize(28)
        .fontColor(this.getPalette().cardBg)
        .fontWeight(FontWeight.Regular)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.getPalette().primary)
        .borderRadius(22)
        .shadow({ radius: 8, color: '#1AC2865E', offsetX: 0, offsetY: 4 })
        .onClick(() => {
          this.openAddBookPage()
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  StatusTabs() {
    Row() {
      ForEach(this.statusTabs, (item: string, index: number) => {
        Text(item)
          .fontSize(14)
          .fontWeight(this.selectedStatus === index ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.selectedStatus === index ? this.getPalette().cardBg : this.getPalette().textSecondary)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(38)
          .backgroundColor(this.selectedStatus === index ? this.getPalette().primary : Color.Transparent)
          .borderRadius(19)
          .onClick(() => {
            if (this.selectedStatus !== index) {
              this.selectedStatus = index
              this.loadBooks()
            }
          })
      }, (item: string) => item)
    }
    .width('100%')
    .height(46)
    .padding(4)
    .margin({ top: 24, bottom: 16 })
    .backgroundColor(this.getPalette().cardBg)
    .borderRadius(23)
    .border({ width: 0.5, color: '#0D000000' })
  }

  @Builder
  BookCard(item: BookShelfItem) {
    Row() {
      Text(item.coverText)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(60)
        .height(80)
        .textAlign(TextAlign.Center)
        .backgroundColor(item.coverStart)
        .borderRadius(10)
        .shadow({ radius: 6, color: '#14000000', offsetX: 0, offsetY: 3 })

      Column() {
        Text(item.title)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getPalette().textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.author)
          .fontSize(14)
          .fontColor(this.getPalette().textSecondary)
          .margin({ top: 6 })

        Row() {
          Stack({ alignContent: Alignment.Start }) {
            Row().height(8).width('100%').backgroundColor(this.getPalette().inputBg).borderRadius(4)
            Row().height(8).width(item.progress + '%').backgroundColor('this.getPalette().primary').borderRadius(4)
          }
          .layoutWeight(1)
          Text(item.progressText)
            .fontSize(12)
            .fontColor('#7D7872')
            .margin({ left: 10 })
        }
        .width('100%')
        .margin({ top: 14 })

        Text('✎ ' + item.records + ' 条记录')
          .fontSize(12)
          .fontColor('#8EA590')
          .margin({ top: 10 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      .margin({ left: 14 })
    }
    .width('100%')
    .padding(14)
    .margin({ bottom: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      this.openBookJournalPage(item.id)
    })
  }

  @Builder
  LoadingState() {
    Column() {
      Text('正在整理书架...')
        .fontSize(14)
        .fontColor('#7D7872')
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .margin({ bottom: 16 })
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
    .margin({ bottom: 16 })
    .onClick(() => {
      this.loadBooks()
    })
  }

  @Builder
  EmptyState() {
    Column() {
      Text(this.getEmptyTitle())
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      Text(this.getEmptyDesc())
        .fontSize(13)
        .fontColor('#7D7872')
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .margin({ top: 8 })
    }
    .width('100%')
    .height(150)
    .padding({ left: 24, right: 24 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .margin({ bottom: 16 })
  }

  @Builder
  AddBookCard() {
    Row() {
      Text('+')
        .fontSize(24)
        .fontColor('#C2865E')
        .margin({ right: 8 })
      Text('添加新书')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#C2865E')
    }
    .width('100%')
    .height(64)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#66FFFFFF')
    .borderRadius(14)
    .border({ width: 1, color: '#4DC2865E', style: BorderStyle.Dashed })
    .onClick(() => {
      this.openAddBookPage()
    })
  }

  /**
   * 加载书架真实数据
   *
   * 多行说明：
   * 1. 根据当前选中的三态 Tab 查询本地 books 表，保证“在读 / 已读完 / 想读”互相独立展示。
   * 2. 每本书再读取 reading_entries 表中的最大结束页和记录数，用来计算卡片进度条与记录数量。
   * 3. 加载失败时不清空用户已有页面结构，而是展示错误卡片，方便用户重试和后续排查数据库问题。
   */
  async loadBooks() {
    this.loading = true
    this.loadError = ''
    try {
      const status: BookStatus = this.statusValues[this.selectedStatus]
      const bookList: BookEntity[] = await BookRepository.queryBooksByStatus(status)
      const nextBooks: BookShelfItem[] = []
      for (let index = 0; index < bookList.length; index++) {
        nextBooks.push(await this.toBookShelfItem(bookList[index], index))
      }
      this.books = nextBooks
    } catch (err) {
      this.loadError = '书架加载失败，请稍后重试'
    }
    this.loading = false
  }

  async toBookShelfItem(book: BookEntity, index: number): Promise<BookShelfItem> {
    const currentPage: number = await ReadingEntryRepository.getMaxPageToByBookId(book.id)
    const recordCount: number = await ReadingEntryRepository.countEntriesByBookId(book.id)
    const progress: number = BookUtils.calculateProgress(currentPage, book.totalPages)
    const bookWithProgress: BookWithProgress = {
      id: book.id,
      name: book.name,
      author: book.author,
      isbn: book.isbn,
      totalPages: book.totalPages,
      coverPath: book.coverPath,
      status: book.status,
      sortOrder: book.sortOrder,
      createdAt: book.createdAt,
      updatedAt: book.updatedAt,
      currentPage: currentPage,
      progress: progress,
      recordCount: recordCount
    }
    return {
      id: book.id,
      title: book.name,
      author: book.author === undefined || book.author.length === 0 ? '未填写作者' : book.author,
      progressText: BookUtils.getProgressText(bookWithProgress),
      progress: progress,
      records: recordCount,
      coverText: BookUtils.getCoverText(book.name),
      coverStart: this.getCoverColor(index)
    }
  }

  getCoverColor(index: number): string {
    const colors: string[] = ['#C2865E', '#8EA590', '#9B5C3E', '#D9A784']
    return colors[index % colors.length]
  }

  getEmptyTitle(): string {
    if (this.selectedStatus === 2) {
      return '书架在等下一本书'
    }
    return '这里还没有书'
  }

  getEmptyDesc(): string {
    if (this.selectedStatus === 2) {
      return '标记你想读的书，它会在书架上等你'
    }
    return '添加一本书，开始记录你的阅读与咖啡时刻'
  }

  /**
   * 打开添加书籍页面
   *
   * 多行说明：
   * 1. 书架页保留底部 Tab 框架，只把添加新书作为二级页面压入 HMRouter 导航栈。
   * 2. 添加页保存成功后会 pop 返回书架页，aboutToAppear 会再次触发并刷新数据库中的真实书籍。
   * 3. 顶部加号和底部虚线卡片复用同一个方法，避免两个入口的跳转逻辑不一致。
   */
  openAddBookPage() {
    HMRouterMgr.push({ pageUrl: PAGE_PATH.BOOK_ADD_PAGE })
  }

  /**
   * 打开某本书的日记本页面
   *
   * 多行说明：
   * 1. 当前工程还没有稳定的 HMRouter 参数读取示例，因此先用 AppStorage 保存 selectedBookId 作为页面间参数兜底。
   * 2. 书籍日记本页会根据 selectedBookId 查询 books 表和 reading_entries 表，展示该书完整阅读旅程。
   * 3. 后续确认 HMRouter 参数 API 后，可以把这里替换为 push 参数传递，页面逻辑只需调整 bookId 来源。
   */
  openBookJournalPage(bookId: string) {
    AppStorage.setOrCreate('selectedBookId', bookId)
    HMRouterMgr.push({ pageUrl: PAGE_PATH.BOOK_JOURNAL_PAGE })
  }
}
