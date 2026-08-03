import { HMRouter } from '@hadss/hmrouter';
import { BookStatus } from '../models/BookModel';
import { getMoodColor, getMoodText, ReadingEntryEntity, ReadingMood } from '../models/ReadingEntryModel';
import { PAGE_PATH } from '../pagePath';
import { BookRepository } from '../services/repository/BookRepository';
import { ReadingEntryRepository } from '../services/repository/ReadingEntryRepository';

interface MoodStatItem {
  name: string
  color: string
  percent: number
}

interface TrendStatItem {
  month: string
  height: number
  readDays: number
}

interface MenuItem {
  title: string
  desc: string
  icon: string
}

/**
 * 我的页面
 *
 * 多行说明：
 * 1. 当前页面从静态展示切换为数据库真实统计，数据来源包括 books 表和 reading_entries 表。
 * 2. 概览区统计书籍状态与记录总数，心情分布统计所有记录中的 mood 占比。
 * 3. 月度趋势统计近 6 个月每月有阅读记录的天数，用于展示用户阅读连续性和活跃度。
 */
@HMRouter({ pageUrl: PAGE_PATH.FEATURE_ME_PAGE })
@ComponentV2
export struct mePage {
  @Local readingBookCount: number = 0
  @Local finishedBookCount: number = 0
  @Local entryCount: number = 0
  @Local moods: MoodStatItem[] = []
  @Local trends: TrendStatItem[] = []
  @Local loading: boolean = false
  @Local loadError: string = ''
  private menus: MenuItem[] = [
    { title: '导出管理', desc: '查看与分享已生成的 PDF', icon: '📄' },
    { title: '外观设置', desc: '浅色、深色或跟随系统', icon: '◐' },
    { title: '备份与恢复', desc: '本地数据导出与导入', icon: '↻' }
  ]

  async aboutToAppear() {
    await this.loadStatistics()
  }

  build() {
    Column() {
      Scroll() {
        Column() {
          this.ProfileHeader()
          if (this.loading) {
            this.LoadingState()
          } else if (this.loadError.length > 0) {
            this.ErrorState()
          } else {
            this.OverviewCards()
            this.MoodCard()
            this.TrendCard()
            this.MenuList()
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
  ProfileHeader() {
    Row() {
      Text('啡')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .width(58)
        .height(58)
        .textAlign(TextAlign.Center)
        .backgroundColor('#C2865E')
        .borderRadius(29)
      Column() {
        Text('我的啡阅')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
        Text('在阅读里，慢慢看见自己')
          .fontSize(13)
          .fontColor('#7D7872')
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 14 })
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  LoadingState() {
    Column() {
      Text('正在整理你的阅读画像...')
        .fontSize(14)
        .fontColor('#7D7872')
    }
    .width('100%')
    .height(150)
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
    .height(150)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 24 })
    .onClick(() => {
      this.loadStatistics()
    })
  }

  @Builder
  OverviewCards() {
    Row() {
      this.StatBlock('在读', this.readingBookCount.toString(), '本')
      this.StatBlock('已读', this.finishedBookCount.toString(), '本')
      this.StatBlock('记录', this.entryCount.toString(), '条')
    }
    .width('100%')
    .margin({ top: 24 })
  }

  @Builder
  StatBlock(label: string, value: string, unit: string) {
    Column() {
      Row() {
        Text(value)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#C2865E')
        Text(unit)
          .fontSize(12)
          .fontColor('#7D7872')
          .margin({ left: 2, top: 8 })
      }
      Text(label)
        .fontSize(13)
        .fontColor('#7D7872')
        .margin({ top: 6 })
    }
    .layoutWeight(1)
    .height(88)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .margin({ right: label === '记录' ? 0 : 10 })
    .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  MoodCard() {
    Column() {
      Text('心情分布')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      if (this.entryCount === 0) {
        Text('写下第一条记录后，这里会生成你的阅读情绪画像')
          .fontSize(13)
          .fontColor('#7D7872')
          .lineHeight(20)
          .margin({ top: 14 })
      } else {
        ForEach(this.moods, (item: MoodStatItem) => {
          Row() {
            Text(item.name)
              .fontSize(13)
              .fontColor('#7D7872')
              .width(42)
            Stack({ alignContent: Alignment.Start }) {
              Row().width('100%').height(8).backgroundColor('#F1EEE8').borderRadius(4)
              Row().width(item.percent + '%').height(8).backgroundColor(item.color).borderRadius(4)
            }
            .layoutWeight(1)
            Text(item.percent + '%')
              .fontSize(12)
              .fontColor('#A8A39C')
              .width(38)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .margin({ top: 14 })
        }, (item: MoodStatItem) => item.name)
      }
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  TrendCard() {
    Column() {
      Row() {
        Text('月度趋势')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2C2825')
        Blank()
        Text('近 6 个月')
          .fontSize(12)
          .fontColor('#A8A39C')
      }
      .width('100%')
      Row() {
        ForEach(this.trends, (item: TrendStatItem) => {
          this.TrendBar(item)
        }, (item: TrendStatItem) => item.month)
      }
      .width('100%')
      .height(116)
      .alignItems(VerticalAlign.Bottom)
      .margin({ top: 16 })
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  TrendBar(item: TrendStatItem) {
    Column() {
      Row()
        .width(18)
        .height(item.height)
        .backgroundColor(item.readDays > 0 ? '#C2865E' : '#E7E1D8')
        .borderRadius(9)
      Text(item.month)
        .fontSize(11)
        .fontColor('#A8A39C')
        .margin({ top: 8 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  MenuList() {
    Column() {
      ForEach(this.menus, (item: MenuItem) => {
        Row() {
          Text(item.icon)
            .fontSize(18)
            .width(38)
            .height(38)
            .textAlign(TextAlign.Center)
            .backgroundColor('#F1EEE8')
            .borderRadius(19)
          Column() {
            Text(item.title)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2C2825')
            Text(item.desc)
              .fontSize(12)
              .fontColor('#A8A39C')
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: 12 })
          Text('›')
            .fontSize(22)
            .fontColor('#A8A39C')
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      }, (item: MenuItem) => item.title)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 4 })
    .margin({ top: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
  }

  /**
   * 加载我的页真实统计
   *
   * 多行说明：
   * 1. 书籍概览从 books 表按状态查询，分别得到在读和已读完数量。
   * 2. 阅读记录从 reading_entries 表一次性读取，后续心情分布和月度趋势都基于这份记录集合计算。
   * 3. 统计失败时保留页面骨架并展示可重试错误状态，避免用户看到空白页面。
   */
  async loadStatistics() {
    this.loading = true
    this.loadError = ''
    try {
      const readingBooks = await BookRepository.queryBooksByStatus(BookStatus.READING)
      const finishedBooks = await BookRepository.queryBooksByStatus(BookStatus.FINISHED)
      const entries: ReadingEntryEntity[] = await ReadingEntryRepository.queryAllEntries()
      this.readingBookCount = readingBooks.length
      this.finishedBookCount = finishedBooks.length
      this.entryCount = entries.length
      this.moods = this.buildMoodStats(entries)
      this.trends = this.buildTrendStats(entries)
    } catch (err) {
      this.loadError = '阅读统计加载失败，请稍后重试'
    }
    this.loading = false
  }

  buildMoodStats(entries: ReadingEntryEntity[]): MoodStatItem[] {
    const moodList: ReadingMood[] = [ReadingMood.HAPPY, ReadingMood.CALM, ReadingMood.NEUTRAL, ReadingMood.PENSIVE, ReadingMood.SAD]
    const stats: MoodStatItem[] = []
    for (let index = 0; index < moodList.length; index++) {
      const mood: ReadingMood = moodList[index]
      const count: number = entries.filter((entry: ReadingEntryEntity) => entry.mood === mood).length
      const item: MoodStatItem = {
        name: getMoodText(mood),
        color: getMoodColor(mood),
        percent: entries.length === 0 ? 0 : Math.round((count / entries.length) * 100)
      }
      stats.push(item)
    }
    return stats
  }

  buildTrendStats(entries: ReadingEntryEntity[]): TrendStatItem[] {
    const stats: TrendStatItem[] = []
    const now: Date = new Date()
    for (let index = 5; index >= 0; index--) {
      const monthDate: Date = new Date(now.getFullYear(), now.getMonth() - index, 1)
      const readDays: number = this.countReadDaysInMonth(entries, monthDate.getFullYear(), monthDate.getMonth())
      const item: TrendStatItem = {
        month: (monthDate.getMonth() + 1).toString() + '月',
        height: readDays === 0 ? 8 : Math.min(96, 20 + readDays * 6),
        readDays: readDays
      }
      stats.push(item)
    }
    return stats
  }

  countReadDaysInMonth(entries: ReadingEntryEntity[], year: number, month: number): number {
    const days: string[] = []
    entries.forEach((entry: ReadingEntryEntity) => {
      const date: Date = new Date(entry.date)
      if (date.getFullYear() === year && date.getMonth() === month) {
        const key: string = date.getFullYear().toString() + '-' + date.getMonth().toString() + '-' + date.getDate().toString()
        if (days.indexOf(key) < 0) {
          days.push(key)
        }
      }
    })
    return days.length
  }
}
