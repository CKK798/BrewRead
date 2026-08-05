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
  private countdownTimer: number | undefined = undefined
  private readonly countdownTotal: number = 5
  @Local hasEnteredHome: boolean = false
  @Local countdown: number = 5

  aboutToAppear() {
    this.countdown = this.countdownTotal
    this.startCountdown()
  }

  aboutToDisappear() {
    this.clearCountdown()
  }

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
        Stack({alignContent:Alignment.TopEnd}){
          Column() {
            Video({
              src: $r('app.media.launch_video'),
              controller: this.videoController
            })
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
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

          /**视频倒计时组件*/
          Row() {
            Text(`跳过 ${this.countdown}s`)
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
          }
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .margin({ top: 34, right: 16 })
          .borderRadius(999)
          .backgroundColor('rgba(0, 0, 0, 0.45)')
          .onClick(() => {
            this.enterHomePage()
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  private startCountdown() {
    this.clearCountdown()
    this.countdownTimer = setInterval(() => {
      if (this.hasEnteredHome) {
        this.clearCountdown()
        return
      }

      if (this.countdown <= 1) {
        this.countdown = 0
        this.clearCountdown()
        this.enterHomePage()
        return
      }

      this.countdown -= 1
    }, 1000)
  }

  private clearCountdown() {
    if (this.countdownTimer !== undefined) {
      clearInterval(this.countdownTimer)
      this.countdownTimer = undefined
    }
  }

  enterHomePage() {
    if (this.hasEnteredHome) {
      return
    }
    this.hasEnteredHome = true
    this.clearCountdown()
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
