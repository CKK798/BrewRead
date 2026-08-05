import { HMRouter } from '@hadss/hmrouter';
import { CJCalendar, CJCalendarControl, CJCellStyle, CJDateItem, CJViewModel, OptMode } from 'cjcalendar';
import { BookEntity } from '../models/BookModel';
import { getMoodText, ReadingEntryEntity } from '../models/ReadingEntryModel';
import { PAGE_PATH } from '../pagePath';
import { BookRepository } from '../services/repository/BookRepository';
import { ReadingEntryRepository } from '../services/repository/ReadingEntryRepository';
import { DataRefreshService } from '../services/refresh/DataRefreshService';
import { ThemePreferenceService } from '../services/theme/ThemePreferenceService';
import { ThemePalette } from '../theme/ThemeTokens';
import { DateUtils } from '../utils/DateUtils';

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
 * 1. 日历主体使用 cjcalendar 单选月视图，避免自绘 Grid 在不同月份首日偏移和选中态刷新上的问题。
 * 2. reading_entries 表仍是热力、月统计和当日摘要的数据源，月份切换、日期点击和数据变更都会重新查询或刷新展示。
 * 3. 有阅读记录的日期会显示“记”标注，选中日期后底部摘要同步展示当天第一条阅读记录。
 */
@HMRouter({ pageUrl: PAGE_PATH.FEATURE_CALENDER_PAGE })
@ComponentV2
export struct calenderPage {
  @Local currentYear: number = new Date().getFullYear()
  @Local currentMonth: number = new Date().getMonth()
  @Local selectedTimestamp: number = this.getTodayStartTime()
  @Local selectedItems: string[] = [DateUtils.formatDate(this.getTodayStartTime())]
  @Local monthEntries: ReadingEntryEntity[] = []
  @Local selectedEntries: ReadingEntryEntity[] = []
  @Local daySummary?: DaySummaryItem = undefined
  @Local loading: boolean = false
  @Local loadError: string = ''
  @Local monthReadDays: number = 0
  @Local monthCoffeeCount: number = 0
  private readonly refreshOwnerId: string = 'calenderPage'
  private calendarController: CJCalendarControl = new CJCalendarControl()
  private cellStyle: CJCellStyle = new CJCellStyle()

  aboutToAppear() {
    this.initCalendarStyle()
    DataRefreshService.registerBookListener(this.refreshOwnerId, () => {
      this.refreshSelectedDaySummary()
    })
    DataRefreshService.registerEntryListener(this.refreshOwnerId, () => {
      this.loadMonthData()
    })
    this.loadMonthData()
  }

  aboutToDisappear() {
    DataRefreshService.unregisterBookListener(this.refreshOwnerId)
    DataRefreshService.unregisterEntryListener(this.refreshOwnerId)
  }

  build() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Scroll() {
          Column() {
            if (this.loading) {
              this.LoadingState()
            } else if (this.loadError.length > 0) {
              this.ErrorState()
            } else {
              this.CalendarPanel()
              Divider().color(this.getPalette().divider).margin({ top: 18, bottom: 18 })
              this.DaySummaryCard()
              this.MonthStats()
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

      if (this.shouldShowTodayButton()) {
        this.TodayFloatingButton()
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
  CalendarPanel() {
    Column() {
      CJCalendar({
        controller: this.calendarController,
        optMode: OptMode.SINGLE,
        viewModel: CJViewModel.MONTH,
        defSelectedItems: this.selectedItems,
        initShowDate: new Date(this.currentYear, this.currentMonth, 1),
        cjCellStyle: this.cellStyle,
        titleFormat: 'yyyy年MM月',
        titleFontSize: 26,
        titleFontColor: this.getPalette().textPrimary,
        titleBackgroundColor: Color.Transparent,
        weekTitleFontColor: this.getPalette().textTertiary,
        showFastToday: false,
        showToolbar: true,
        showLunar: false,
        showJieRi: false,
        showJieQi: false,
        onlyShowCurrMonthDay: true,
        onlyShowDateArea: true,
        onInitFinish: () => {
          this.refreshCalendarMarks()
          this.calendarController.selectItems(this.selectedItems)
        },
        onMonthChanged: (month: CJDateItem) => {
          this.handleMonthChanged(month)
        },
        onSelectedChanged: (items: Array<CJDateItem>) => {
          if (items.length > 0) {
            this.selectDay(this.getDateItemTimestamp(items[0]))
          }
        },
        onCellItemClick: (item: CJDateItem) => {
          this.selectDay(this.getDateItemTimestamp(item))
          return true
        },
        reBuildCellItem: (item: CJDateItem) => {
          const timestamp: number = this.getDateItemTimestamp(item)
          const dayEntries: ReadingEntryEntity[] = this.getEntriesByDay(timestamp)
          if (dayEntries.length > 0) {
            item.markText = '记'
          } else {
            item.markText = ''
          }
          return true
        },
        buildCellStyle: (item: CJDateItem) => {
          return this.buildCalendarCellStyle(item)
        }
      })
    }
    .width('100%')
    .padding({ left: 2, right: 2, bottom: 6 })
    .backgroundColor(Color.Transparent)
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
    .backgroundColor(this.getPalette().cardBg)
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
        .fontColor(this.getPalette().primary)
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
          .fontColor(this.getPalette().textPrimary)
        Text('这一天还没有阅读记录')
          .fontSize(14)
          .fontColor('#7D7872')
          .margin({ top: 14 })
        Text('之后可以从这里补记当天的阅读时刻')
          .fontSize(16)
          .fontColor(this.getPalette().textPrimary)
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

  @Builder
  TodayFloatingButton() {
    Text('今')
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.getPalette().primary)
      .width(48)
      .height(48)
      .textAlign(TextAlign.Center)
      .backgroundColor('#CCFFFFFF')
      .borderRadius(24)
      .border({ width: 1, color: '#33C2865E' })
      .shadow({ radius: 10, color: '#14000000', offsetX: 0, offsetY: 3 })
      .margin({ right: 18, bottom: 18 })
      .onClick(() => {
        this.backToday()
      })
  }

  initCalendarStyle() {
    this.cellStyle.fontSize = 14
    this.cellStyle.fontColor = this.getPalette().textPrimary
    this.cellStyle.todayFontColor = this.getPalette().primary
    this.cellStyle.todayBackgroundColor = '#00FFFFFF'
    this.cellStyle.selectFontColor = '#FFFFFF'
    this.cellStyle.selectItemBackgroundColor = this.getPalette().primary
    this.cellStyle.itemBackgroundColor = '#00FFFFFF'
    this.cellStyle.markFontSize = 10
    this.cellStyle.markFontColor = '#D9A784'
    this.cellStyle.markFontWeight = FontWeight.Medium
    this.cellStyle.markAlignment = Alignment.Bottom
  }

  async loadMonthData() {
    this.loading = true
    this.loadError = ''
    try {
      const startTime: number = new Date(this.currentYear, this.currentMonth, 1).getTime()
      const endTime: number = new Date(this.currentYear, this.currentMonth + 1, 1).getTime() - 1
      this.monthEntries = await ReadingEntryRepository.queryEntriesByDateRange(startTime, endTime)
      if (this.selectedTimestamp < startTime || this.selectedTimestamp > endTime) {
        this.selectedTimestamp = this.getMonthDefaultSelectedTime(startTime, endTime)
      }
      this.selectedItems = [DateUtils.formatDate(this.selectedTimestamp)]
      this.refreshMonthStats()
      await this.refreshSelectedDaySummary()
      this.refreshCalendarMarks()
    } catch (err) {
      this.loadError = '日历数据加载失败，请稍后重试'
    }
    this.loading = false
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
    this.selectedTimestamp = this.getDayStartTime(timestamp)
    this.selectedItems = [DateUtils.formatDate(this.selectedTimestamp)]
    this.refreshSelectedDaySummary()
  }

  handleMonthChanged(month: CJDateItem) {
    const timestamp: number = this.getDateItemTimestamp(month)
    const date: Date = new Date(timestamp)
    if (date.getFullYear() === this.currentYear && date.getMonth() === this.currentMonth) {
      return
    }
    this.currentYear = date.getFullYear()
    this.currentMonth = date.getMonth()
    const startTime: number = new Date(this.currentYear, this.currentMonth, 1).getTime()
    const endTime: number = new Date(this.currentYear, this.currentMonth + 1, 1).getTime() - 1
    if (this.selectedTimestamp < startTime || this.selectedTimestamp > endTime) {
      this.selectedTimestamp = startTime
      this.selectedItems = [DateUtils.formatDate(this.selectedTimestamp)]
    }
    this.loadMonthData()
  }

  backToday() {
    const today: number = this.getTodayStartTime()
    const date: Date = new Date(today)
    this.currentYear = date.getFullYear()
    this.currentMonth = date.getMonth()
    this.selectedTimestamp = today
    this.selectedItems = [DateUtils.formatDate(today)]
    this.calendarController.backToday()
    this.loadMonthData()
  }

  shouldShowTodayButton(): boolean {
    const today: Date = new Date()
    return this.currentYear !== today.getFullYear() || this.currentMonth !== today.getMonth()
  }

  refreshCalendarMarks() {
    this.calendarController.refresh()
    this.calendarController.selectItems(this.selectedItems)
  }

  refreshMonthStats() {
    let readDays: string[] = []
    let coffeeCount: number = 0
    this.monthEntries.forEach((entry: ReadingEntryEntity) => {
      const dayKey: string = DateUtils.formatDate(entry.date)
      if (readDays.indexOf(dayKey) < 0) {
        readDays.push(dayKey)
      }
      if (entry.coffee !== undefined && entry.coffee.length > 0) {
        coffeeCount++
      }
    })
    this.monthReadDays = readDays.length
    this.monthCoffeeCount = coffeeCount
  }

  buildCalendarCellStyle(item: CJDateItem): CJCellStyle {
    const style: CJCellStyle = new CJCellStyle()
    style.fontSize = 14
    style.fontColor = this.getPalette().textPrimary
    style.todayFontColor = this.getPalette().primary
    style.todayBackgroundColor = '#00FFFFFF'
    style.selectFontColor = '#FFFFFF'
    style.selectItemBackgroundColor = this.getPalette().primary
    style.itemBackgroundColor = '#00FFFFFF'
    style.markFontSize = 10
    style.markFontColor = '#D9A784'
    style.markFontWeight = FontWeight.Medium
    style.markAlignment = Alignment.Bottom

    const timestamp: number = this.getDateItemTimestamp(item)
    const dayEntries: ReadingEntryEntity[] = this.getEntriesByDay(timestamp)
    if (dayEntries.length > 0 && !item.isSelected) {
      const level: number = this.calculateHeatLevel(dayEntries.length, this.calculateDayReadPages(dayEntries))
      style.itemBackgroundColor = this.getHeatBackgroundColor(level)
      style.fontColor = this.getPalette().textPrimary
    }
    return style
  }

  getMonthDefaultSelectedTime(startTime: number, endTime: number): number {
    const today: number = this.getTodayStartTime()
    if (today >= startTime && today <= endTime) {
      return today
    }
    return startTime
  }

  getDateItemTimestamp(item: CJDateItem): number {
    if (item.time > 0) {
      return this.getDayStartTime(item.time)
    }
    return new Date(item.fullYear, item.month - 1, item.date).getTime()
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

  calculateDayReadPages(entries: ReadingEntryEntity[]): number {
    let total: number = 0
    entries.forEach((entry: ReadingEntryEntity) => {
      if (entry.pageFrom !== undefined && entry.pageTo !== undefined && entry.pageTo >= entry.pageFrom) {
        total += entry.pageTo - entry.pageFrom + 1
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

  getHeatBackgroundColor(level: number): string {
    if (level === 1) {
      return '#1AD9A784'
    }
    if (level === 2) {
      return '#33D9A784'
    }
    if (level === 3) {
      return '#4DC2865E'
    }
    return '#00FFFFFF'
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

  getDayStartTime(timestamp: number): number {
    const date: Date = new Date(timestamp)
    return new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime()
  }
}
