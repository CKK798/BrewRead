import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { PAGE_PATH } from '../../pagePath';
import { ThemePalette } from '../../theme/ThemeTokens';
import { ThemePreferenceService } from '../../services/theme/ThemePreferenceService';

/**
 * 设置页面
 *
 * 多行说明：
 * 1. 当前设置页仅作为“我的”页面右上角设置入口的承接页面。
 * 2. 具体设置功能暂不展示，后续功能明确后再逐步补充对应设置项。
 * 3. 页面保留统一返回逻辑和主题背景，避免进入后出现无导航的空白状态。
 */
@HMRouter({ pageUrl: PAGE_PATH.SETTINGS_PAGE })
@ComponentV2
export struct appearanceSettingsPage {
  build() {
    Column() {
      this.Header()
      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getPalette().pageBg)
    .padding({ top: this.getUIContext().px2vp(AppStorage.get('topH')) })
  }

  @Builder
  Header() {
    Row() {
      Text('‹')
        .fontSize(32)
        .fontColor(this.getPalette().textPrimary)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          HMRouterMgr.pop()
        })
      Text('设置')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getPalette().textPrimary)
        .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 6, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  getPalette(): ThemePalette {
    return ThemePreferenceService.getCurrentPalette()
  }
}
