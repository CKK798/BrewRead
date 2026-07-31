import { HMRouter } from '@hadss/hmrouter';
import { PAGE_PATH } from '../pagePath';

/**
 * 我的页面
 */
@HMRouter({pageUrl:PAGE_PATH.FEATURE_ME_PAGE})
@ComponentV2
export struct mePage{
  build() {
    Column(){
      Text('mePage')
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