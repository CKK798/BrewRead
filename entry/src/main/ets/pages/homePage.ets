import { HMRouter } from '@hadss/hmrouter';
import { bookShelfPage } from '../feature/bookShelfPage';
import { calenderPage } from '../feature/calenderPage';
import { journalPage } from '../feature/journalPage';
import { mePage } from '../feature/mePage';
import { PAGE_PATH } from '../pagePath';

interface tabItem {
  title: string
  img: ResourceStr
  activeImg: ResourceStr
}

//功能页面枚举定义
const enum PAGE_TABS {
  BOOKSHELF,
  JOURNAL,
  CALENDER,
  ME,
}

const TAB_DEFAULT_INDEX: number = PAGE_TABS.BOOKSHELF;
const TAB_BAR_HEIGHT: number = 60;
const TAB_BAR_MARGIN: number = 16;
const TAB_BAR_BOTTOM_GAP: number = 8;
const TAB_CONTENT_BOTTOM_SPACE: number = 76;
const TAB_SWITCH_DELAY: number = 80;

/**
 * 应用入口页面
 */
@HMRouter({ pageUrl: PAGE_PATH.HOME_PAGE })
@ComponentV2
export struct homePage {
  @Local chooseIndex: number = TAB_DEFAULT_INDEX
  /**默认tabContent内容*/
  @Local currentIndex: number = TAB_DEFAULT_INDEX
  private tabsController: TabsController = new TabsController()
  @Local tabList: tabItem[] = [
    {
      title: '书架',
      img: $r('app.media.icon_tab_bookshelf'),
      activeImg: $r('app.media.icon_tab_bookshelf_active')
    },
    {
      title: '记录',
      img: $r('app.media.icon_tab_journal'),
      activeImg: $r('app.media.icon_tab_journal_active')
    },
    {
      title: '日历',
      img: $r('app.media.icon_tab_calendar'),
      activeImg: $r('app.media.icon_tab_calendar_active')
    },
    {
      title: '我的',
      img: $r('app.media.icon_tab_me'),
      activeImg: $r('app.media.icon_tab_me_active')
    },
  ]

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Tabs({ barPosition: BarPosition.End, controller: this.tabsController, index: this.currentIndex }) {
        TabContent() {
          bookShelfPage()
        }

        TabContent() {
          journalPage()
        }

        TabContent() {
          calenderPage()
        }

        TabContent() {
          mePage()
        }
      }
      .barHeight(0)
      .scrollable(false)
      .animationDuration(240)
      .onChange((index: number) => {
        this.onContentChange(index)
      })
      .width('100%')
      .height('100%')
      .padding({ bottom: TAB_CONTENT_BOTTOM_SPACE + this.getBottomSafeArea() })

      Row() {
        ForEach(this.tabList, (item: tabItem, index: number) => {
          this.TabBuilder(item, index)
        }, (item: tabItem) => item.title)
      }
      .width('100%')
      .height(TAB_BAR_HEIGHT)
      .padding({ left: 4, right: 4, top: 4, bottom: 4 })
      .margin({
        left: TAB_BAR_MARGIN,
        right: TAB_BAR_MARGIN,
        bottom: TAB_BAR_BOTTOM_GAP + this.getBottomSafeArea()
      })
      .backgroundColor('#D9FFFFFF')
      .border({ width: 0.5, color: '#0F000000' })
      .borderRadius(22)
      .shadow({ radius: 12, color: '#10000000', offsetX: 0, offsetY: 2 })
    }
    .backgroundColor('#F8F5F0')
    .width('100%')
    .height('100%')
    .padding({
      top: this.getUIContext().px2vp(AppStorage.get('topH'))
    })
  }

  onTabChange(index: number) {
    if (index === this.chooseIndex) {
      return;
    }

    this.chooseIndex = index;
    animateTo({ duration: 300, curve: Curve.Friction }, () => {
      this.tabsController.changeIndex(index)
    })
    setTimeout(() => {
      this.currentIndex = index;
    }, TAB_SWITCH_DELAY)
  }

  onContentChange(index: number) {
    this.chooseIndex = index;
    this.currentIndex = index;
  }

  getBottomSafeArea(): number {
    return this.getUIContext().px2vp(AppStorage.get('bottomH'))
  }

  /**
   * tab自定义
   */
  @Builder
  TabBuilder(item: tabItem, index: number) {
    Column() {
      if (this.chooseIndex === index) {
        Image(item.activeImg)
          .width(22)
          .height(22)
          .fillColor('#C2865E')
      } else {
        Image(item.img)
          .width(22)
          .height(22)
      }
      Text(item.title)
        .fontSize(10)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.chooseIndex === index ? '#C2865E' : '#99000000')
        .margin({ top: 2 })
    }
    .width('25%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .borderRadius(16)
    .backgroundColor(this.chooseIndex === index ? '#14C2865E' : Color.Transparent)
    .animation({ duration: 300, curve: Curve.Friction })
    .onClick(() => {
      this.onTabChange(index)
    })
  }
}