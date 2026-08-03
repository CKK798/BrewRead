import { HMRouter } from '@hadss/hmrouter';
import { PAGE_PATH } from '../pagePath';

interface MoodStatItem {
  name: string
  color: string
  percent: number
}

interface MenuItem {
  title: string
  desc: string
  icon: string
}

/**
 * 我的页面
 */
@HMRouter({ pageUrl: PAGE_PATH.FEATURE_ME_PAGE })
@ComponentV2
export struct mePage {
  private moods: MoodStatItem[] = [
    { name: '开心', color: '#E8956C', percent: 28 },
    { name: '平静', color: '#8CB89A', percent: 34 },
    { name: '沉思', color: '#8090A8', percent: 22 },
    { name: '感伤', color: '#9098B8', percent: 10 },
    { name: '其他', color: '#A09890', percent: 6 }
  ]
  private menus: MenuItem[] = [
    { title: '导出管理', desc: '查看与分享已生成的 PDF', icon: '📄' },
    { title: '外观设置', desc: '浅色、深色或跟随系统', icon: '◐' },
    { title: '备份与恢复', desc: '本地数据导出与导入', icon: '↻' }
  ]

  build() {
    Column() {
      Scroll() {
        Column() {
          this.ProfileHeader()
          this.OverviewCards()
          this.MoodCard()
          this.TrendCard()
          this.MenuList()
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
  OverviewCards() {
    Row() {
      this.StatBlock('在读', '2', '本')
      this.StatBlock('已读', '8', '本')
      this.StatBlock('记录', '42', '条')
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
        this.TrendBar('2月', 38)
        this.TrendBar('3月', 54)
        this.TrendBar('4月', 46)
        this.TrendBar('5月', 70)
        this.TrendBar('6月', 58)
        this.TrendBar('7月', 82)
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
  TrendBar(month: string, height: number) {
    Column() {
      Row()
        .width(18)
        .height(height)
        .backgroundColor('#C2865E')
        .borderRadius(9)
      Text(month)
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
}