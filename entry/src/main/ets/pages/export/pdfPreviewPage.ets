import { common, Want } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { PAGE_PATH } from '../../pagePath';
import { FileCopyResult, FileStorageService } from '../../services/storage/FileStorageService';
import { ThemePreferenceService } from '../../services/theme/ThemePreferenceService';
import { ThemePalette } from '../../theme/ThemeTokens';

/**
 * PDF 文件详情 / 预览占位页面
 *
 * 多行说明：
 * 1. 当前页面先承接导出管理页的文件详情查看能力，展示文件名、路径和文件状态。
 * 2. 模拟器暂时无法稳定验证系统 PDF 预览能力，因此本阶段先做预览占位和排查信息展示。
 * 3. 后续接入系统文件预览或 PDF 组件时，可在当前页面内扩展，不需要改导出管理页跳转链路。
 */
@HMRouter({ pageUrl: PAGE_PATH.PDF_PREVIEW_PAGE })
@ComponentV2
export struct pdfPreviewPage {
  @Local fileName: string = ''
  @Local filePath: string = ''
  @Local fileExists: boolean = false
  @Local openMessage: string = ''

  aboutToAppear() {
    this.fileName = AppStorage.get<string>('previewPdfFileName') ?? ''
    this.filePath = AppStorage.get<string>('previewPdfFilePath') ?? ''
    this.fileExists = FileStorageService.exists(this.filePath)
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.FileInfoCard()
          this.PreviewPlaceholder()
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
      Column() {
        Text('PDF 文件详情')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('this.getPalette().textPrimary')
        Text('查看导出文件状态与保存路径')
          .fontSize(13)
          .fontColor(this.getPalette().textSecondary)
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 6, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  getPalette(): ThemePalette {
    return ThemePreferenceService.getCurrentPalette()
  }

  async openPdfFile() {
    if (!this.fileExists) {
      this.openMessage = '文件不存在，请返回书籍日记本重新导出。'
      return
    }
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const want: Want = {
        action: 'ohos.want.action.viewData',
        uri: 'file://' + this.filePath,
        type: 'application/pdf'
      }
      await context.startAbility(want)
      this.openMessage = '已尝试调用系统 PDF 查看器打开。'
    } catch (err) {
      this.openMessage = '直接打开失败：应用沙箱路径通常不能被外部 PDF 查看器访问，请优先使用“保存到可见位置”。'
    }
  }

  async savePdfToVisibleLocation() {
    if (!this.fileExists) {
      this.openMessage = '文件不存在，请返回书籍日记本重新导出。'
      return
    }
    try {
      const documentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [this.fileName.length === 0 ? '啡阅导出.pdf' : this.fileName]
      const documentViewPicker = new picker.DocumentViewPicker()
      const uriList: string[] = await documentViewPicker.save(documentSaveOptions)
      if (uriList.length === 0) {
        this.openMessage = '没有选择保存位置。'
        return
      }
      const targetUri: string = uriList[0]
      const copyResult: FileCopyResult = FileStorageService.copyFile(this.filePath, targetUri)
      this.openMessage = copyResult.message
    } catch (err) {
      this.openMessage = '保存失败：当前系统文件保存器不可用或未授权，请稍后重试。'
    }
  }

  @Builder
  FileInfoCard() {
    Column() {
      Row() {
        Text('PDF')
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getPalette().cardBg)
          .width(46)
          .height(46)
          .textAlign(TextAlign.Center)
          .backgroundColor(this.getPalette().primary)
          .borderRadius(23)
        Column() {
          Text(this.fileName.length === 0 ? '未获取到文件名' : this.fileName)
            .fontSize(17)
            .fontWeight(FontWeight.Medium)
            .fontColor('this.getPalette().textPrimary')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.fileExists ? '文件可用' : '文件缺失')
            .fontSize(12)
            .fontColor(this.fileExists ? '#8EA590' : '#B65A4B')
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')
      Text('保存路径')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
        .margin({ top: 18 })
      Text(this.filePath.length === 0 ? '未获取到文件路径' : this.filePath)
        .fontSize(12)
        .fontColor(this.getPalette().textSecondary)
        .lineHeight(18)
        .margin({ top: 8 })
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor(this.getPalette().cardBg)
    .borderRadius(16)
  }

  @Builder
  PreviewPlaceholder() {
    Column() {
      Text('预览能力待接入')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#2C2825')
      Text('当前已生成并保存 PDF 文件。模拟器环境暂不验证系统 PDF 预览，后续可在这里接入 PDF 组件或系统文件打开能力。')
        .fontSize(13)
        .fontColor('this.getPalette().textSecondary')
        .lineHeight(21)
        .textAlign(TextAlign.Center)
        .margin({ top: 10 })
      Text(this.fileExists ? '保存到可见位置' : '文件不存在，请返回重新导出')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.fileExists ? this.getPalette().cardBg : '#B65A4B')
        .width('100%')
        .height(42)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.fileExists ? this.getPalette().primary : this.getPalette().inputBg)
        .borderRadius(21)
        .margin({ top: 16 })
        .onClick(() => {
          this.savePdfToVisibleLocation()
        })
      Text(this.fileExists ? '尝试直接打开 PDF' : '')
        .fontSize(13)
        .fontColor(this.getPalette().primary)
        .margin({ top: 12 })
        .onClick(() => {
          this.openPdfFile()
        })
      if (this.openMessage.length > 0) {
        Text(this.openMessage)
          .fontSize(12)
          .fontColor(this.getPalette().textSecondary)
          .lineHeight(18)
          .textAlign(TextAlign.Center)
          .margin({ top: 12 })
      }
    }
    .width('100%')
    .padding({ left: 22, right: 22, top: 34, bottom: 34 })
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 16 })
    .backgroundColor('this.getPalette().cardBg')
    .borderRadius(16)
  }
}
