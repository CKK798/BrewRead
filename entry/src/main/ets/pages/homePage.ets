import { HMRouter } from '@hadss/hmrouter';
import { PAGE_PATH } from '../pagePath';

/**
 * 应用入口页面
 */
@HMRouter({pageUrl:PAGE_PATH.HOME_PAGE})
@ComponentV2
export struct homePage{
  build() {
    Column(){
      Text('应用入口')

    }
    .backgroundColor(Color.Brown)
    .width('100%')
    .height('100%')
    .padding({ top:this.getUIContext().px2vp(AppStorage.get('topH')),bottom: this.getUIContext().px2vp(AppStorage.get("bottomH")) })
  }
}