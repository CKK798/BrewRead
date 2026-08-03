import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { ThemeMode } from '../../models/AppSettingModel';
import { PAGE_PATH } from '../../pagePath';
import { AppSettingRepository } from '../../services/repository/AppSettingRepository';

interface ThemeOptionItem {
  title: string
  desc: string
  mode: ThemeMode
}

/**
 * 外观设置页面
 *
 * 多行说明：
 * 1. 当前页面先完成主题模式偏好的持久化，真正全局换肤后续再接入 ThemeTokens 和页面刷新机制。
 * 2. 主题模式写入 app_settings.theme_mode，应用重启或后续页面加载时可以读取该偏好。
 * 3. 页面保存后显示轻量提示，不立即强制刷新全部页面，避免当前阶段引入复杂全局状态。
 */
@HMRouter({ pageUrl: PAGE_PATH.SETTINGS_PAGE })
@ComponentV2
export struct appearanceSettingsPage {
  @Local selectedMode: ThemeMode = ThemeMode.SYSTEM
  @Local loading: boolean = false
  @Local saving: boolean = false
  @Local message: string = ''
  private options: ThemeOptionItem[] = [
    { title: '跟随系统', desc: '根据系统外观自动切换', mode: ThemeMode.SYSTEM },
    { title: '晨雾浅色', desc: '温暖明亮，适合白天阅读记录', mode: ThemeMode.LIGHT },
    { title: '夜幕深色', desc: '降低夜间眩光，适合睡前回顾', mode: ThemeMode.DARK }
  ]

  async aboutToAppear() {
    await this.loadSetting()
  }

  build() {
    Column() {
      this.Header()
      Column() {
        if (this.loading) {
          this.LoadingState()
        } else {
          this.OptionList()
          if (this.message.length > 0) {
            Text(this.message)
              .fontSize(13)
              .fontColor('#7D7872')
              .margin({ top: 14 })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 18 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F4F0')
    .padding({ top: this.getUIContext().px2vp(AppStorage.get('topH')) })
  }

  @Builder
  Header() {
    Row() {
      Text('‹')
        .fontSize(32)
        .fontColor('#2C2825')
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          HMRouterMgr.pop()
        })
      Column() {
        Text('外观设置')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
        Text('选择你喜欢的啡阅主题')
          .fontSize(13)
          .fontColor('#7D7872')
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 6, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  OptionList() {
    Column() {
      ForEach(this.options, (item: ThemeOptionItem) => {
        Row() {
          Column() {
            Text(item.title)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor('#2C2825')
            Text(item.desc)
              .fontSize(12)
              .fontColor('#7D7872')
              .margin({ top: 5 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          Text(this.selectedMode === item.mode ? '✓' : '')
            .fontSize(18)
            .fontColor('#C2865E')
            .width(28)
            .textAlign(TextAlign.End)
        }
        .width('100%')
        .padding(16)
        .margin({ bottom: 12 })
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .border({ width: this.selectedMode === item.mode ? 1 : 0, color: '#C2865E' })
        .onClick(() => {
          this.saveMode(item.mode)
        })
      }, (item: ThemeOptionItem) => item.mode)
    }
    .width('100%')
  }

  @Builder
  LoadingState() {
    Column() {
      Text('正在读取外观偏好...')
        .fontSize(14)
        .fontColor('#7D7872')
    }
    .width('100%')
    .height(160)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  async loadSetting() {
    this.loading = true
    try {
      this.selectedMode = await AppSettingRepository.getThemeMode()
    } catch (err) {
      this.message = '外观偏好读取失败，将使用跟随系统'
      this.selectedMode = ThemeMode.SYSTEM
    }
    this.loading = false
  }

  /**
   * 保存主题模式
   *
   * 多行说明：
   * 1. 保存时只写入用户偏好，不立即重建页面树，避免当前阶段全局状态未完善导致页面闪烁。
   * 2. 后续接入全局主题 Store 后，可在这里同步刷新 AppStorage 或 ThemeTokens 当前值。
   * 3. 保存失败时不改变错误前的数据库状态，并用 message 告知用户重试。
   */
  async saveMode(mode: ThemeMode) {
    if (this.saving) {
      return
    }
    this.saving = true
    this.message = ''
    try {
      await AppSettingRepository.saveThemeMode(mode)
      this.selectedMode = mode
      this.message = '外观偏好已保存'
    } catch (err) {
      this.message = '保存失败，请稍后重试'
    }
    this.saving = false
  }
}
