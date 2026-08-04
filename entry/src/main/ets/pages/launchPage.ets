/**
 * 启动页
 */
import { HMDefaultGlobalAnimator, HMNavigation, HMRouterMgr } from '@hadss/hmrouter';
import { AttributeUpdater } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PAGE_PATH } from '../pagePath';

@Entry
@ComponentV2
export struct launchPage {
  modifier = new MyModifier()
  context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private videoController: VideoController = new VideoController()
  @Local hasEnteredHome: boolean = false

  build() {
    Column() {
      HMNavigation({
        navigationId: PAGE_PATH.MAIN_PAGE,
        homePageUrl: PAGE_PATH.LAUNCH_PAGE,
        options: {
          standardAnimator: HMDefaultGlobalAnimator.STANDARD_ANIMATOR,
          dialogAnimator: HMDefaultGlobalAnimator.DIALOG_ANIMATOR,
          modifier: this.modifier,
        }
      }) {
        Column() {
          Video({
            src: $r('app.media.launch_video'),
            controller: this.videoController
          })
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .controls(false)
            .autoPlay(true)
            .loop(false)
            .muted(true)
            .backgroundColor('#FFFFFF')
            .onFinish(() => {
              this.enterHomePage()
            })
            .onError(() => {
              this.enterHomePage()
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  enterHomePage() {
    if (this.hasEnteredHome) {
      return
    }
    this.hasEnteredHome = true
    HMRouterMgr.push({ pageUrl: PAGE_PATH.HOME_PAGE })
  }
}

class MyModifier extends AttributeUpdater<NavigationAttribute> {
  initializeModifier(instance: NavigationAttribute): void {
    instance.mode(NavigationMode.Stack)
    instance.titleMode(NavigationTitleMode.Mini)
    instance.hideTitleBar(true)
  }
}
