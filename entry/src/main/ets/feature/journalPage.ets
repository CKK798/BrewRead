import { HMRouter } from '@hadss/hmrouter';
import { PAGE_PATH } from '../pagePath';

/**
 * 日历页面
 */
@HMRouter({pageUrl:PAGE_PATH.FEATURE_JOURNAL_PAGE})
@ComponentV2
export struct journalPage{
  build() {
    Column(){
      Text('journalPage')
    }
    .backgroundColor(Color.Brown)
    .width('100%')
    .height('100%')
    .padding({
      top: this.getUIContext().px2vp(AppStorage.get('topH')),
      bottom: this.getUIContext().px2vp(AppStorage.get("bottomH"))
    })
  }
}