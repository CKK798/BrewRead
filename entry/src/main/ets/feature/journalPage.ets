import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { PAGE_PATH } from '../pagePath';

interface JournalEntryItem {
  date: string
  mood: string
  moodColor: string
  coffee: string
  pages: string
  content: string
}

/**
 * 记录页面
 */
@HMRouter({ pageUrl: PAGE_PATH.FEATURE_JOURNAL_PAGE })
@ComponentV2
export struct journalPage {
  private entries: JournalEntryItem[] = [
    {
      date: '7月28日',
      mood: '感伤',
      moodColor: '#9098B8',
      coffee: '手冲曼特宁',
      pages: '第 73 — 105 页',
      content: '直子生日那晚的描写让人有一种安静而绵长的窒息感，像雨停后仍留在叶片上的水。'
    },
    {
      date: '7月20日',
      mood: '沉思',
      moodColor: '#8090A8',
      coffee: '冰拿铁',
      pages: '第 35 — 72 页',
      content: '渡边的旁观与迟疑并不冷漠，更像是在青春里无法命名的自我保护。'
    },
    {
      date: '7月15日',
      mood: '平静',
      moodColor: '#8CB89A',
      coffee: '热美式',
      pages: '第 1 — 34 页',
      content: '开头从记忆的入口缓缓进入，音乐、机场与三十七岁的回望，让整本书有了雾气。'
    }
  ]

  build() {
    Column() {
      Scroll() {
        Column() {
          this.Header()
          this.SummaryBar()
          this.Timeline()
          this.ExportButton()
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
  Header() {
    Column() {
      Row() {
        Text('阅读记录')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
          .layoutWeight(1)
        Text('写记录')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .padding({ left: 16, right: 16 })
          .height(38)
          .textAlign(TextAlign.Center)
          .backgroundColor('#C2865E')
          .borderRadius(19)
          .onClick(() => {
            this.openEntryEditPage()
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('挪威的森林')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
        .margin({ top: 22 })
      Text('村上春树 · 2026')
        .fontSize(14)
        .fontColor('#7D7872')
        .margin({ top: 4 })
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
      Text('共 12 条记录 · 配咖啡 9 杯 · 363 页')
        .fontSize(13)
        .fontColor('#7D7872')
    }
    .width('100%')
    .height(44)
    .padding({ left: 14, right: 14 })
    .margin({ top: 16, bottom: 20 })
    .backgroundColor('#FFFFFF')
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
              .fill('#C2865E')
            Row()
              .width(2)
              .height(128)
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
      }, (item: JournalEntryItem) => item.date)
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
            .fontColor('#2C2825')
          Text(' · ' + item.coffee)
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
    .height(132)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .shadow({ radius: 8, color: '#0A000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  ExportButton() {
    Row() {
      Text('📄')
        .fontSize(17)
        .margin({ right: 8 })
      Text('导出为 PDF')
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
  }

  /**
   * 打开写阅读记录页面
   *
   * 多行说明：
   * 1. 记录页作为一级 Tab 保持时间线展示职责，写记录表单通过二级页面承载，避免页面过重。
   * 2. 使用 PAGE_PATH.ENTRY_EDIT_PAGE 复用新增和编辑记录页面，后续可通过路由参数区分新建或编辑。
   * 3. 写记录页保存成功后 pop 返回记录页，后续记录页接入真实数据时可在 aboutToAppear 刷新时间线。
   */
  openEntryEditPage() {
    HMRouterMgr.push({ pageUrl: PAGE_PATH.ENTRY_EDIT_PAGE })
  }
}