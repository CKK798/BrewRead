import { HMRouter } from '@hadss/hmrouter';
import { BookEntity } from '../models/BookModel';
import { getMoodText, ReadingEntryEntity } from '../models/ReadingEntryModel';
import { PAGE_PATH } from '../pagePath';
import { BookRepository } from '../services/repository/BookRepository';
import { ReadingEntryRepository } from '../services/repository/ReadingEntryRepository';
import { DateUtils } from '../utils/DateUtils';

interface CalendarDayItem {
  day: string
  timestamp: number
  level: number
  selected: boolean
  entryCount: number
  readPages: number
}

interface DaySummaryItem {
  title: string
  meta: string
  coffee: string
  content: string
}

/**
 * 日历页面
 *
 * 多行说明：
 * 1. 当前页面从静态热力点切换为 reading_entries 表真实数据，按当前月份查询日期范围内的记录。
 * 2. 日历网格根据年月动态生成，自动补齐月份首日前的空白格，避免写死某个月的布局。
 * 3. 热力等级由当天阅读页数和记录数共同计算，选中日期后展示当天第一条记录摘要。
 */
@HMRouter({ pageUrl: PAGE_PATH.FEATURE_CALENDER_PAGE })
@ComponentV2
export struct calenderPage {
  @Local currentYear: number = new Date().getFullYear()
  @Local currentMonth: number = new Date().getMonth()
  @Local selectedTimestamp: number = this.getTodayStartTime()
  @Local days: CalendarDayItem[] = []
  @Local monthEntries: ReadingEntryEntity[] = []
  @Local selectedEntries: ReadingEntryEntity[] = []
  @Local daySummary?: DaySummaryItem = undefined
  @Local loading: boolean = false
  @Local loadError: string = ''
  @Local monthReadDays: number = 0
  @Local monthCoffeeCount: number = 0
  private weeks: string[] = ['一', '二', '三', '四', '五', '六', '日']

  async aboutToAppear() {
    await this.loadMonthData()
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          this.MonthHeader()
          if (this.loading) {
            this.LoadingState()
          } else if (this.loadError.length > 0) {
            this.ErrorState()
          } else {
            this.WeekHeader()
            this.CalendarGrid()
            Divider().color('#1A000000').margin({ top: 22, bottom: 18 })
            this.DaySummaryCard()
            this.MonthStats()
          }
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 22 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .backgroundColor('#F6F4F0')
    .width('100%')
    .height('100%')
  }

  @Builder
  MonthHeader() {
    Row() {
      Text('‹')
        .fontSize(28)
        .fontColor('#7D7872')
        .width(40)
        .textAlign(TextAlign.Start)
        .onClick(() => {
          this.changeMonth(-1)
        })
      Text(this.currentYear + '年' + (this.currentMonth + 1) + '月')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2C2825')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('›')
        .fontSize(28)
        .fontColor('#7D7872')
        .width(40)
        .textAlign(TextAlign.End)
        .onClick(() => {
          this.changeMonth(1)
        })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  WeekHeader() {
    Row() {
      ForEach(this.weeks, (item: string) => {
        Text(item)
          .fontSize(12)
          .fontColor('#A8A39C')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      }, (item: string) => item)
    }
    .width('100%')
    .margin({ top: 26, bottom: 12 })
  }

  @Builder
  CalendarGrid() {
    Grid() {
      ForEach(this.days, (item: CalendarDayItem, index: number) => {
        GridItem() {
          Column() {
            Text(item.day)
              .fontSize(13)
              .fontColor(item.selected ? '#FFFFFF' : '#7D7872')
              .textAlign(TextAlign.Center)
              .width(30)
              .height(24)
              .backgroundColor(item.selected ? '#C2865E' : Color.Transparent)
              .borderRadius(12)
            if (item.day !== '') {
              Circle()
                .width(this.getDotSize(item.level))
                .height(this.getDotSize(item.level))
                .fill(this.getDotColor(item.level))
                .stroke(item.selected ? '#D9A784' : Color.Transparent)
                .strokeWidth(item.selected ? 2 : 0)
                .margin({ top: 6 })
            }
          }
          .width('100%')
          .height(58)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            if (item.day !== '') {
              this.selectDay(item.timestamp)
            }
          })
        }
      }, (item: CalendarDayItem, index: number) => index.toString())
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(4)
    .columnsGap(2)
    .width('100%')
  }

  @Builder
  LoadingState() {
    Column() {
      Text('正在生成阅读热力图...')
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
      Text('点我重试')
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
      this.loadMonthData()
    })
  }

  @Builder
  DaySummaryCard() {
    if (this.daySummary === undefined) {
      Column() {
        Text('📅 ' + DateUtils.formatMonthDay(this.selectedTimestamp) + ' · ' + DateUtils.getWeekdayText(this.selectedTimestamp))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2C2825')
        Text('这一天还没有阅读记录')
          .fontSize(14)
          .fontColor('#7D7872')
          .margin({ top: 14 })
        Text('之后可以从这里补记当天的阅读时刻')
          .fontSize(16)
          .fontColor('#2C2825')
          .lineHeight(24)
          .margin({ top: 16 })
      }
      .width('100%')
      .padding(18)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
    } else {
      Column() {
        Text(this.daySummary.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2C2825')
        Text(this.daySummary.meta)
          .fontSize(14)
          .fontColor('#7D7872')
          .margin({ top: 14 })
        if (this.daySummary.coffee.length > 0) {
          Text(this.daySummary.coffee)
            .fontSize(14)
            .fontColor('#7D7872')
            .margin({ top: 8 })
        }
        Text(this.daySummary.content)
          .fontSize(16)
          .fontColor('#2C2825')
          .lineHeight(24)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 16 })
      }
      .width('100%')
      .padding(18)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor('#FFFFFF')
      .borderRadius(16)
      .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
    }
  }

  @Builder
  MonthStats() {
    Row() {
      Text('本月阅读 ' + this.monthReadDays + ' 天')
        .fontSize(14)
        .fontColor('#7D7872')
      Blank()
      Text('☕ ' + this.monthCoffeeCount + ' 杯')
        .fontSize(14)
        .fontColor('#C2865E')
    }
    .width('100%')
    .margin({ top: 18 })
  }

  /**
   * 加载月份阅读记录并生成热力网格
   *
   * 多行说明：
   * 1. 月份范围使用当前年月的第一天 00:00 到下个月第一天前 1ms，避免跨月记录混入当前热力图。
   * 2. 查询完成后先生成日历格子，再根据每天记录数和页数计算热力等级，保证 UI 与真实数据同步。
   * 3. 如果当前选中日期不在月份内，则自动选中当月 1 号，保证底部摘要始终有明确日期上下文。
   */
  async loadMonthData() {
    this.loading = true
    this.loadError = ''
    try {
      const startTime: number = new Date(this.currentYear, this.currentMonth, 1).getTime()
      const endTime: number = new Date(this.currentYear, this.currentMonth + 1, 1).getTime() - 1
      this.monthEntries = await ReadingEntryRepository.queryEntriesByDateRange(startTime, endTime)
      if (this.selectedTimestamp < startTime || this.selectedTimestamp > endTime) {
        this.selectedTimestamp = startTime
      }
      this.buildCalendarDays()
      await this.refreshSelectedDaySummary()
    } catch (err) {
      this.loadError = '日历数据加载失败，请稍后重试'
    }
    this.loading = false
  }

  buildCalendarDays() {
    const monthFirstDay: Date = new Date(this.currentYear, this.currentMonth, 1)
    const monthDays: number = new Date(this.currentYear, this.currentMonth + 1, 0).getDate()
    const firstWeekDay: number = this.getMondayFirstWeekDay(monthFirstDay.getDay())
    const nextDays: CalendarDayItem[] = []
    for (let index = 0; index < firstWeekDay; index++) {
      nextDays.push({ day: '', timestamp: 0, level: 0, selected: false, entryCount: 0, readPages: 0 })
    }
    let readDays: number = 0
    let coffeeCount: number = 0
    for (let day = 1; day <= monthDays; day++) {
      const timestamp: number = new Date(this.currentYear, this.currentMonth, day).getTime()
      const dayEntries: ReadingEntryEntity[] = this.getEntriesByDay(timestamp)
      const readPages: number = this.calculateDayReadPages(dayEntries)
      const level: number = this.calculateHeatLevel(dayEntries.length, readPages)
      if (dayEntries.length > 0) {
        readDays++
      }
      coffeeCount += this.countCoffee(dayEntries)
      nextDays.push({
        day: day.toString(),
        timestamp: timestamp,
        level: level,
        selected: this.isSameDay(timestamp, this.selectedTimestamp),
        entryCount: dayEntries.length,
        readPages: readPages
      })
    }
    this.days = nextDays
    this.monthReadDays = readDays
    this.monthCoffeeCount = coffeeCount
  }

  async refreshSelectedDaySummary() {
    this.selectedEntries = this.getEntriesByDay(this.selectedTimestamp)
    if (this.selectedEntries.length === 0) {
      this.daySummary = undefined
      return
    }
    const entry: ReadingEntryEntity = this.selectedEntries[0]
    const book: BookEntity | undefined = await BookRepository.queryBookById(entry.bookId)
    this.daySummary = {
      title: '📅 ' + DateUtils.formatMonthDay(entry.date) + ' · ' + DateUtils.getWeekdayText(entry.date),
      meta: getMoodText(entry.mood) + ' · 《' + (book === undefined ? '已删除书籍' : book.name) + '》 ' + this.getPageText(entry),
      coffee: entry.coffee === undefined || entry.coffee.length === 0 ? '' : '☕ ' + entry.coffee,
      content: entry.content
    }
  }

  selectDay(timestamp: number) {
    this.selectedTimestamp = timestamp
    this.days = this.days.map((item: CalendarDayItem) => {
      const nextItem: CalendarDayItem = {
        day: item.day,
        timestamp: item.timestamp,
        level: item.level,
        selected: item.timestamp > 0 && this.isSameDay(item.timestamp, timestamp),
        entryCount: item.entryCount,
        readPages: item.readPages
      }
      return nextItem
    })
    this.refreshSelectedDaySummary()
  }

  changeMonth(offset: number) {
    const nextDate: Date = new Date(this.currentYear, this.currentMonth + offset, 1)
    this.currentYear = nextDate.getFullYear()
    this.currentMonth = nextDate.getMonth()
    this.selectedTimestamp = nextDate.getTime()
    this.loadMonthData()
  }

  getEntriesByDay(timestamp: number): ReadingEntryEntity[] {
    return this.monthEntries.filter((entry: ReadingEntryEntity) => this.isSameDay(entry.date, timestamp))
  }

  isSameDay(left: number, right: number): boolean {
    const leftDate: Date = new Date(left)
    const rightDate: Date = new Date(right)
    return leftDate.getFullYear() === rightDate.getFullYear() && leftDate.getMonth() === rightDate.getMonth() &&
      leftDate.getDate() === rightDate.getDate()
  }

  getMondayFirstWeekDay(day: number): number {
    if (day === 0) {
      return 6
    }
    return day - 1
  }

  calculateDayReadPages(entries: ReadingEntryEntity[]): number {
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

  calculateHeatLevel(entryCount: number, readPages: number): number {
    if (entryCount === 0) {
      return 0
    }
    if (readPages > 20 || entryCount >= 3) {
      return 3
    }
    if (readPages >= 5 || entryCount >= 2) {
      return 2
    }
    return 1
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

  getTodayStartTime(): number {
    const now: Date = new Date()
    return new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()
  }

  getDotSize(level: number): number {
    if (level === 1) {
      return 8
    }
    if (level === 2) {
      return 12
    }
    if (level === 3) {
      return 16
    }
    return 5
  }

  getDotColor(level: number): string {
    if (level === 1) {
      return '#33D9A784'
    }
    if (level === 2) {
      return '#66D9A784'
    }
    if (level === 3) {
      return '#B3C2865E'
    }
    return '#00000000'
  }
}
