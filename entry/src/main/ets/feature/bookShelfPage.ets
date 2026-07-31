import { HMRouter } from '@hadss/hmrouter';
import { PAGE_PATH } from '../pagePath';

/**
 * 书架页面
 */
@HMRouter({pageUrl:PAGE_PATH.FEATURE_BOOKSHELF_PAGE})
@ComponentV2
export struct bookShelfPage{
  build() {
    Column(){
      Text('bookShelfPage')
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