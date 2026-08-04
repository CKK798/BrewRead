import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { BookEntity } from '../../models/BookModel';
import { getMoodColor, getMoodText, ReadingEntryEntity } from '../../models/ReadingEntryModel';
import { PAGE_PATH } from '../../pagePath';
import { BookRepository } from '../../services/repository/BookRepository';
import { ReadingEntryRepository } from '../../services/repository/ReadingEntryRepository';
import { ThemePreferenceService } from '../../services/theme/ThemePreferenceService';
import { ThemePalette } from '../../theme/ThemeTokens';
import { DateUtils } from '../../utils/DateUtils';

interface HighlightEntryItem {
  id: string
  bookId: string
  bookName: string
  date: string
  mood: string
  moodColor: string
  content: string
}

/**
 * 我的金句页面
 *
 * 多行说明：
 * 1. 本页面集中展示被标记为金句的阅读感悟，让散落在各本书中的高价值内容可以被反复回看。
 * 2. 页面根据 entry.bookId 补查书名，书籍被删除时用“已删除书籍”兜底展示。
 * 3. 点击金句卡片会进入记录编辑页，用户可以取消星标或继续编辑这条阅读记录。
 */
@HMRouter({ pageUrl: PAGE_PATH.HIGHLIGHT_ENTRIES_PAGE })
@ComponentV2
export struct highlightEntriesPage {
  @Local entries: HighlightEntryItem[] = []
  @Local loading: boolean = false
  @Local loadError: string = ''

  async aboutToAppear() {
    await this.loadHighlights()
  }

  getPalette(): ThemePalette {
    return ThemePreferenceService.getCurrentPalette()
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          if (this.loading) {
            this.LoadingState()
          } else if (this.loadError.length > 0) {
            this.ErrorState()
          } else if (this.entries.length === 0) {
            this.EmptyState()
          } else {
            this.HighlightList()
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
    .backgroundColor(this.getPalette().pageBg)
    .padding({ top: this.getUIContext().px2vp(AppStorage.get('topH')) })
  }

  @Builder
  Header() {
    Row() {
      Text('‹')
        .fontSize(32)
        .fontColor(this.getPalette().textPrimary)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          HMRouterMgr.pop()
        })
      Column() {
        Text('我的金句')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
        Text('集中回看那些特别想留下的话')
          .fontSize(13)
          .fontColor(this.getPalette().textSecondary)
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
  HighlightList() {
    Column() {
      ForEach(this.entries, (item: HighlightEntryItem) => {
        this.HighlightCard(item)
      }, (item: HighlightEntryItem) => item.id)
    }
    .width('100%')
  }

  @Builder
  HighlightCard(item: HighlightEntryItem) {
    Column() {
      Row() {
        Text('★')
          .fontSize(18)
          .fontColor('this.getPalette().primary')
          .width(32)
        Column() {
          Text(item.bookName)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor('#2C2825')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(item.date + ' · ' + item.mood)
            .fontSize(12)
            .fontColor('#7D7872')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      Text(item.content)
        .fontSize(15)
        .fontColor('#2C2825')
        .lineHeight(23)
        .margin({ top: 12 })
      Row()
        .width('100%')
        .height(3)
        .backgroundColor(item.moodColor)
        .borderRadius(2)
        .margin({ top: 14 })
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 14 })
    .backgroundColor('this.getPalette().cardBg')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      this.openEntryEditor(item)
    })
  }

  @Builder
  LoadingState() {
    Column() {
      Text('正在整理你的金句...')
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
      this.loadHighlights()
    })
  }

  @Builder
  EmptyState() {
    Column() {
      Text('还没有金句')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      Text('在写记录时点亮星标，那些特别想留下的话会集中显示在这里')
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

  async loadHighlights() {
    this.loading = true
    this.loadError = ''
    try {
      const entryList: ReadingEntryEntity[] = await ReadingEntryRepository.queryHighlightEntries()
      const nextEntries: HighlightEntryItem[] = []
      for (let index = 0; index < entryList.length; index++) {
        nextEntries.push(await this.toHighlightItem(entryList[index]))
      }
      this.entries = nextEntries
    } catch (err) {
      this.loadError = '金句加载失败，请稍后重试'
    }
    this.loading = false
  }

  async toHighlightItem(entry: ReadingEntryEntity): Promise<HighlightEntryItem> {
    const book: BookEntity | undefined = await BookRepository.queryBookById(entry.bookId)
    return {
      id: entry.id,
      bookId: entry.bookId,
      bookName: book === undefined ? '已删除书籍' : book.name,
      date: DateUtils.formatChineseDate(entry.date),
      mood: getMoodText(entry.mood),
      moodColor: getMoodColor(entry.mood),
      content: entry.content
    }
  }

  openEntryEditor(item: HighlightEntryItem) {
    AppStorage.setOrCreate('selectedBookId', item.bookId)
    AppStorage.setOrCreate('selectedEntryId', item.id)
    HMRouterMgr.push({ pageUrl: PAGE_PATH.ENTRY_EDIT_PAGE })
  }
}
