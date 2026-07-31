/**
 * 启动页
 */
import { HMDefaultGlobalAnimator, HMNavigation, HMRouterMgr } from '@hadss/hmrouter';
import { AttributeUpdater } from '@kit.ArkUI';
import { PAGE_PATH } from '../pagePath';
import { common } from '@kit.AbilityKit';

@Entry
@ComponentV2
export struct launchPage {
  modifier = new MyModifier()
  context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  async aboutToAppear() {

  }

  build() {
    Column() {
      HMNavigation({
        navigationId: PAGE_PATH.MAIN_PAGE, //"配置根组件在导航栏的唯一标识 id"
        homePageUrl: PAGE_PATH.LAUNCH_PAGE, //"首页的路由名"
        options: {
          standardAnimator: HMDefaultGlobalAnimator.STANDARD_ANIMATOR, //标准动画
          dialogAnimator: HMDefaultGlobalAnimator.DIALOG_ANIMATOR, //弹窗动画
          modifier: this.modifier, //在全局修改Navigation的对象实例的属性
        }
      }) {
        Column(){
          Text('启动页')
          Button('homePage').onClick(()=>{
            HMRouterMgr.push({pageUrl:PAGE_PATH.HOME_PAGE})
          })
        }.width('100%')
        .height('100%')
      }
    }
  }
}

class MyModifier extends AttributeUpdater<NavigationAttribute> {
  // 重写原来的方法
  initializeModifier(instance: NavigationAttribute): void {
    // instance就是Navigation实例对象
    instance.mode(NavigationMode.Stack)
    instance.titleMode(NavigationTitleMode.Mini)
    instance.hideTitleBar(true)
  }
}