import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { BookEntity } from '../../models/BookModel';
import { getMoodText, ReadingEntryEntity, ReadingMood } from '../../models/ReadingEntryModel';
import { PAGE_PATH } from '../../pagePath';
import { BookRepository } from '../../services/repository/BookRepository';
import { ReadingEntryRepository } from '../../services/repository/ReadingEntryRepository';
import { ThemePreferenceService } from '../../services/theme/ThemePreferenceService';
import { ThemePalette } from '../../theme/ThemeTokens';
import { DateUtils } from '../../utils/DateUtils';

interface FinishCeremonyStats {
  recordCount: number
  readDays: number
  topMood: string
  topCoffee: string
  longestReflection: string
}

/**
 * 读完仪式页面
 *
 * 多行说明：
 * 1. 本页面基于某本书的阅读记录生成旅程总结，为“标记已读完”提供仪式感承接。
 * 2. 当前先从书籍日记本手动进入，后续可在书籍状态切换为已读完时自动跳转。
 * 3. 页面展示阅读天数、记录数、主导心情、最常咖啡和最长感悟，并提示用户导出完整 PDF。
 */
@HMRouter({ pageUrl: PAGE_PATH.FINISH_CEREMONY_PAGE })
@ComponentV2
export struct finishCeremonyPage {
  @Local book?: BookEntity = undefined
  @Local stats: FinishCeremonyStats = {
    recordCount: 0,
    readDays: 0,
    topMood: '平静',
    topCoffee: '还没有咖啡记忆',
    longestReflection: '还没有留下足够长的感悟。'
  }
  @Local loading: boolean = false
  @Local loadError: string = ''
  private bookId: string = ''

  async aboutToAppear() {
    this.bookId = AppStorage.get<string>('selectedBookId') ?? ''
    await this.loadCeremony()
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
          } else {
            this.CeremonyCard()
            this.ExportHintCard()
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 18, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('this.getPalette().pageBg')
    .padding({ top: this.getUIContext().px2vp(AppStorage.get('topH')) })
  }

  @Builder
  Header() {
    Row() {
      Text('‹')
        .fontSize(32)
        .fontColor('this.getPalette().textPrimary')
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          HMRouterMgr.pop()
        })
      Column() {
        Text('读完仪式')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
        Text(this.book === undefined ? '为一本书好好收尾' : this.book.name)
          .fontSize(13)
          .fontColor('this.getPalette().textSecondary')
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
  CeremonyCard() {
    Column() {
      Text('你完成了一段阅读旅程')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2C2825')
      Text(this.book === undefined ? '' : '《' + this.book.name + '》')
        .fontSize(18)
        .fontColor('this.getPalette().primary')
        .margin({ top: 8 })
      Row() {
        this.StatPill('记录', this.stats.recordCount.toString(), '条')
        this.StatPill('阅读', this.stats.readDays.toString(), '天')
      }
      .width('100%')
      .margin({ top: 20 })
      Text('大多数时候，你是“' + this.stats.topMood + '”地读完它。')
        .fontSize(15)
        .fontColor('#2C2825')
        .lineHeight(23)
        .margin({ top: 18 })
      Text('最常陪在旁边的是：' + this.stats.topCoffee)
        .fontSize(15)
        .fontColor('#7D7872')
        .lineHeight(23)
        .margin({ top: 8 })
      Text('最长的一段感悟')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
        .margin({ top: 20 })
      Text(this.stats.longestReflection)
        .fontSize(14)
        .fontColor('#7D7872')
        .lineHeight(22)
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('this.getPalette().cardBg')
    .borderRadius(18)
  }

  @Builder
  StatPill(label: string, value: string, unit: string) {
    Column() {
      Row() {
        Text(value)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#C2865E')
        Text(unit)
          .fontSize(12)
          .fontColor('#7D7872')
          .margin({ left: 2, top: 8 })
      }
      Text(label)
        .fontSize(12)
        .fontColor('#7D7872')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .height(82)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F1EEE8')
    .borderRadius(14)
    .margin({ right: label === '阅读' ? 0 : 10 })
  }

  @Builder
  ExportHintCard() {
    Column() {
      Text('现在可以导出完整 PDF 了')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      Text('回到书籍日记本，点击“导出为 PDF”，把这段阅读旅程保存成册。')
        .fontSize(13)
        .fontColor('#7D7872')
        .lineHeight(21)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  LoadingState() {
    Column() {
      Text('正在整理读完仪式...')
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
      this.loadCeremony()
    })
  }

  async loadCeremony() {
    if (this.bookId.length === 0) {
      this.loadError = '没有找到要总结的书籍'
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
      const entries: ReadingEntryEntity[] = await ReadingEntryRepository.queryEntriesByBookId(this.bookId)
      this.stats = this.buildStats(entries)
    } catch (err) {
      this.loadError = '读完仪式加载失败，请稍后重试'
    }
    this.loading = false
  }

  buildStats(entries: ReadingEntryEntity[]): FinishCeremonyStats {
    return {
      recordCount: entries.length,
      readDays: this.countReadDays(entries),
      topMood: this.getTopMood(entries),
      topCoffee: this.getTopCoffee(entries),
      longestReflection: this.getLongestReflection(entries)
    }
  }

  countReadDays(entries: ReadingEntryEntity[]): number {
    const days: string[] = []
    entries.forEach((entry: ReadingEntryEntity) => {
      const key: string = DateUtils.formatDate(entry.date)
      if (days.indexOf(key) < 0) {
        days.push(key)
      }
    })
    return days.length
  }

  getTopMood(entries: ReadingEntryEntity[]): string {
    const moodList: ReadingMood[] = [ReadingMood.HAPPY, ReadingMood.CALM, ReadingMood.NEUTRAL, ReadingMood.PENSIVE, ReadingMood.SAD]
    let topMood: ReadingMood = ReadingMood.CALM
    let topCount: number = 0
    moodList.forEach((mood: ReadingMood) => {
      const count: number = entries.filter((entry: ReadingEntryEntity) => entry.mood === mood).length
      if (count > topCount) {
        topMood = mood
        topCount = count
      }
    })
    return getMoodText(topMood)
  }

  getTopCoffee(entries: ReadingEntryEntity[]): string {
    const coffeeNames: string[] = []
    entries.forEach((entry: ReadingEntryEntity) => {
      if (entry.coffee !== undefined && entry.coffee.trim().length > 0 && coffeeNames.indexOf(entry.coffee.trim()) < 0) {
        coffeeNames.push(entry.coffee.trim())
      }
    })
    if (coffeeNames.length === 0) {
      return '还没有咖啡记忆'
    }
    let topCoffee: string = coffeeNames[0]
    let topCount: number = 0
    coffeeNames.forEach((coffeeName: string) => {
      const count: number = entries.filter((entry: ReadingEntryEntity) => entry.coffee !== undefined && entry.coffee.trim() === coffeeName).length
      if (count > topCount) {
        topCoffee = coffeeName
        topCount = count
      }
    })
    return topCoffee + '（' + topCount + ' 次）'
  }

  getLongestReflection(entries: ReadingEntryEntity[]): string {
    if (entries.length === 0) {
      return '还没有留下足够长的感悟。'
    }
    let longest: string = entries[0].content
    entries.forEach((entry: ReadingEntryEntity) => {
      if (entry.content.length > longest.length) {
        longest = entry.content
      }
    })
    return longest.length === 0 ? '还没有留下足够长的感悟。' : longest
  }
}
