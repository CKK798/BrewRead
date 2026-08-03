import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { PAGE_PATH } from '../../pagePath';
import { BackupResult, BackupService } from '../../services/backup/BackupService';
import { ThemePreferenceService } from '../../services/theme/ThemePreferenceService';
import { ThemePalette } from '../../theme/ThemeTokens';

/**
 * 备份与恢复页面
 *
 * 多行说明：
 * 1. 当前页面先提供生成备份快照的入口，让可用版本具备数据导出基础能力。
 * 2. 备份服务当前返回 JSON 文本和建议文件名，真实文件写入与系统分享后续再接入。
 * 3. 恢复导入需要文件选择、版本校验和冲突处理，本阶段先展示规划状态，避免用户误以为已可恢复。
 */
@HMRouter({ pageUrl: PAGE_PATH.BACKUP_PAGE })
@ComponentV2
export struct backupPage {
  @Local backingUp: boolean = false
  @Local message: string = ''
  @Local fileName: string = ''
  @Local filePath: string = ''
  @Local jsonPreview: string = ''

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.BackupCard()
          this.RestoreCard()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 24 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('this.getPalette().pageBg')
    .padding({ top: this.getUIContext().px2vp(AppStorage.get('topH')) })
  }

  @Builder
  Header() {
    Row() {
      Text('‹')
        .fontSize(32)
        .fontColor('this.getPalette().textPrimary')
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          HMRouterMgr.pop()
        })
      Column() {
        Text('备份与恢复')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C2825')
        Text('保护你的书籍、记录和设置')
          .fontSize(13)
          .fontColor('this.getPalette().textSecondary')
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
  BackupCard() {
    Column() {
      Text('导出备份')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      Text('生成包含书籍、阅读记录、导出历史和应用设置的 JSON 快照。')
        .fontSize(13)
        .fontColor('#7D7872')
        .lineHeight(20)
        .margin({ top: 8 })
      Text(this.backingUp ? '正在生成...' : '生成备份快照')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('this.getPalette().cardBg')
        .width('100%')
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.backingUp ? '#80C2865E' : 'this.getPalette().primary')
        .borderRadius(22)
        .margin({ top: 18 })
        .onClick(() => {
          this.createBackup()
        })
      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(13)
          .fontColor('#7D7872')
          .margin({ top: 14 })
      }
      if (this.fileName.length > 0) {
        Text('文件名：' + this.fileName)
          .fontSize(12)
          .fontColor('this.getPalette().textTertiary')
          .margin({ top: 8 })
      }
      if (this.filePath.length > 0) {
        Text('保存路径：' + this.filePath)
          .fontSize(12)
          .fontColor('#A8A39C')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 8 })
      }
      if (this.jsonPreview.length > 0) {
        Text(this.jsonPreview)
          .fontSize(11)
          .fontColor('#A8A39C')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }

  @Builder
  RestoreCard() {
    Column() {
      Text('恢复导入')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      Text('恢复导入需要文件选择、备份版本校验和冲突处理，后续版本开放。')
        .fontSize(13)
        .fontColor('#7D7872')
        .lineHeight(20)
        .margin({ top: 8 })
      Text('暂未开放')
        .fontSize(15)
        .fontColor('#A8A39C')
        .width('100%')
        .height(44)
        .textAlign(TextAlign.Center)
        .backgroundColor('#F1EEE8')
        .borderRadius(22)
        .margin({ top: 18 })
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .margin({ top: 16 })
  }

  /**
   * 生成备份快照
   *
   * 多行说明：
   * 1. 生成过程调用 BackupService 汇总数据库中的核心表数据，页面只负责展示结果。
   * 2. 当前先展示 JSON 预览和建议文件名，后续接入文件写入后可直接把 jsonText 保存到沙箱或分享。
   * 3. 失败时保留错误文案，避免用户误以为备份已经成功完成。
   */
  async createBackup() {
    if (this.backingUp) {
      return
    }
    this.backingUp = true
    this.message = ''
    this.fileName = ''
    this.filePath = ''
    this.jsonPreview = ''
    const result: BackupResult = await BackupService.createBackupSnapshot()
    this.message = result.message
    this.fileName = result.fileName
    this.filePath = result.filePath
    if (result.success) {
      this.jsonPreview = result.jsonText
    }
    this.backingUp = false
  }
}
