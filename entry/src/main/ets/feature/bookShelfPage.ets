import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { PAGE_PATH } from '../pagePath';

interface BookShelfItem {
  title: string
  author: string
  progressText: string
  progress: number
  records: number
  coverText: string
  coverStart: string
  coverEnd: string
}

/**
 * 书架页面
 */
@HMRouter({ pageUrl: PAGE_PATH.FEATURE_BOOKSHELF_PAGE })
@ComponentV2
export struct bookShelfPage {
  @Local selectedStatus: number = 0
  private statusTabs: string[] = ['在读', '已读完', '想读']
  private books: BookShelfItem[] = [
    {
      title: '挪威的森林',
      author: '村上春树',
      progressText: '236 / 384',
      progress: 61,
      records: 12,
      coverText: '挪',
      coverStart: '#C2865E',
      coverEnd: '#D9A784'
    },
    {
      title: '百年孤独',
      author: '加西亚·马尔克斯',
      progressText: '45%',
      progress: 45,
      records: 3,
      coverText: '百',
      coverStart: '#8EA590',
      coverEnd: '#B1C8B4'
    }
  ]

  build() {
    Column() {
      Scroll() {
        Column() {
          this.Header()
          this.StatusTabs()
          ForEach(this.books, (item: BookShelfItem) => {
            this.BookCard(item)
          }, (item: BookShelfItem) => item.title)
          this.AddBookCard()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 20, bottom: 20 })
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
    Row() {
      Column() {
        Text('我的书架')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
        Text('把每一本书酿成可回味的记录')
          .fontSize(13)
          .fontColor('#7D7872')
          .margin({ top: 6 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text('+')
        .fontSize(28)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Regular)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor('#C2865E')
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
          .fontColor(this.selectedStatus === index ? '#FFFFFF' : '#7D7872')
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
          .height(38)
          .backgroundColor(this.selectedStatus === index ? '#C2865E' : Color.Transparent)
          .borderRadius(19)
          .onClick(() => {
            this.selectedStatus = index
          })
      }, (item: string) => item)
    }
    .width('100%')
    .height(46)
    .padding(4)
    .margin({ top: 24, bottom: 16 })
    .backgroundColor('#FFFFFF')
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
          .fontColor('#2C2825')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.author)
          .fontSize(14)
          .fontColor('#7D7872')
          .margin({ top: 6 })

        Row() {
          Stack({ alignContent: Alignment.Start }) {
            Row().height(8).width('100%').backgroundColor('#F1EEE8').borderRadius(4)
            Row().height(8).width(item.progress + '%').backgroundColor('#C2865E').borderRadius(4)
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
   * 打开添加书籍页面
   *
   * 多行说明：
   * 1. 书架页保留底部 Tab 框架，只把添加新书作为二级页面压入 HMRouter 导航栈。
   * 2. 添加页保存成功后会 pop 返回书架页，后续接入真实数据刷新时可在 aboutToAppear 重新查询列表。
   * 3. 顶部加号和底部虚线卡片复用同一个方法，避免两个入口的跳转逻辑不一致。
   */
  openAddBookPage() {
    HMRouterMgr.push({ pageUrl: PAGE_PATH.BOOK_ADD_PAGE })
  }
}