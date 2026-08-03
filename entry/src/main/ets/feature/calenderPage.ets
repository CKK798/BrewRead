import { HMRouter } from '@hadss/hmrouter';
import { PAGE_PATH } from '../pagePath';

interface CalendarDayItem {
  day: string
  level: number
  selected: boolean
}

/**
 * 日历页面
 */
@HMRouter({ pageUrl: PAGE_PATH.FEATURE_CALENDER_PAGE })
@ComponentV2
export struct calenderPage {
  private weeks: string[] = ['一', '二', '三', '四', '五', '六', '日']
  private days: CalendarDayItem[] = [
    { day: '', level: 0, selected: false }, { day: '', level: 0, selected: false },
    { day: '1', level: 2, selected: false }, { day: '2', level: 1, selected: false },
    { day: '3', level: 0, selected: false }, { day: '4', level: 0, selected: false }, { day: '5', level: 0, selected: false },
    { day: '6', level: 3, selected: false }, { day: '7', level: 2, selected: false }, { day: '8', level: 1, selected: false },
    { day: '9', level: 0, selected: false }, { day: '10', level: 0, selected: false }, { day: '11', level: 0, selected: false }, { day: '12', level: 2, selected: false },
    { day: '13', level: 0, selected: false }, { day: '14', level: 0, selected: false }, { day: '15', level: 3, selected: true },
    { day: '16', level: 2, selected: false }, { day: '17', level: 2, selected: false }, { day: '18', level: 0, selected: false }, { day: '19', level: 0, selected: false },
    { day: '20', level: 2, selected: false }, { day: '21', level: 0, selected: false }, { day: '22', level: 1, selected: false },
    { day: '23', level: 0, selected: false }, { day: '24', level: 2, selected: false }, { day: '25', level: 0, selected: false }, { day: '26', level: 0, selected: false },
    { day: '27', level: 2, selected: false }, { day: '28', level: 3, selected: false }, { day: '29', level: 1, selected: false },
    { day: '30', level: 0, selected: false }, { day: '31', level: 0, selected: false }
  ]

  build() {
    Column() {
      Scroll() {
        Column() {
          this.MonthHeader()
          this.WeekHeader()
          this.CalendarGrid()
          Divider().color('#1A000000').margin({ top: 22, bottom: 18 })
          this.DaySummaryCard()
          this.MonthStats()
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
      Text('2026年7月')
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
        }
      }, (item: CalendarDayItem, index: number) => index.toString())
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr')
    .rowsGap(4)
    .columnsGap(2)
    .width('100%')
  }

  @Builder
  DaySummaryCard() {
    Column() {
      Text('📅 7月15日 · 周三')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      Text('平静 · 《挪威的森林》 第34页')
        .fontSize(14)
        .fontColor('#7D7872')
        .margin({ top: 14 })
      Text('☕ 热美式')
        .fontSize(14)
        .fontColor('#7D7872')
        .margin({ top: 8 })
      Text('开头就是 37 岁的渡边在汉堡机场听到《挪威的森林》，记忆像雾一样散开。')
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
  }

  @Builder
  MonthStats() {
    Row() {
      Text('本月阅读 15 天')
        .fontSize(14)
        .fontColor('#7D7872')
      Blank()
      Text('☕ 12 杯')
        .fontSize(14)
        .fontColor('#C2865E')
    }
    .width('100%')
    .margin({ top: 18 })
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