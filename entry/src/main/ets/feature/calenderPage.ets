import { HMRouter } from '@hadss/hmrouter';
import { PAGE_PATH } from '../pagePath';

/**
 * 记录页面
 */
@HMRouter({pageUrl:PAGE_PATH.FEATURE_CALENDER_PAGE})
@ComponentV2
export struct calenderPage{
  build() {
    Column(){
      Text('calenderPage')
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