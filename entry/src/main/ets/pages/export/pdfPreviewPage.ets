import { picker } from '@kit.CoreFileKit';
import { pdfService, pdfViewManager, PdfView } from '@kit.PDFKit';
import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { PAGE_PATH } from '../../pagePath';
import { FileCopyResult, FileStorageService } from '../../services/storage/FileStorageService';
import { ThemePreferenceService } from '../../services/theme/ThemePreferenceService';
import { ThemePalette } from '../../theme/ThemeTokens';

/**
 * PDF 文件详情 / 预览页面
 *
 * 多行说明：
 * 1. 本页面使用 PDFKit 的 PdfView 组件直接加载应用沙箱中的 PDF，避免外部查看器无法访问沙箱路径。
 * 2. 页面同时保留“保存到可见位置”，用于把沙箱 PDF 导出到用户可在文件管理器中找到的位置。
 * 3. 如果 PDF 文件大小为 0B 或解析失败，页面会展示明确提示，避免误判为预览组件问题。
 */
@HMRouter({ pageUrl: PAGE_PATH.PDF_PREVIEW_PAGE })
@ComponentV2
export struct pdfPreviewPage {
  private controller: pdfViewManager.PdfController = new pdfViewManager.PdfController()
  @Local fileName: string = ''
  @Local filePath: string = ''
  @Local fileExists: boolean = false
  @Local fileSize: number = 0
  @Local currentPage: number = 0
  @Local totalPage: number = 0
  @Local previewReady: boolean = false
  @Local openMessage: string = ''

  aboutToAppear() {
    this.fileName = AppStorage.get<string>('previewPdfFileName') ?? ''
    this.filePath = AppStorage.get<string>('previewPdfFilePath') ?? ''
    this.fileExists = FileStorageService.exists(this.filePath)
    this.fileSize = FileStorageService.getFileSize(this.filePath)
    this.loadPdfPreview()
  }

  aboutToDisappear() {
    this.controller.releaseDocument()
  }

  build() {
    Column() {
      this.Header()
      this.FileInfoCard()
      this.PdfPreviewArea()
      this.ActionCard()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getPalette().pageBg)
    .padding({ left: 16, right: 16, top: this.getUIContext().px2vp(AppStorage.get('topH')) + 8, bottom: 18 })
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
        Text('PDF 文件预览')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getPalette().textPrimary)
        Text(this.previewReady ? '已加载 ' + this.totalPage + ' 页' : '查看导出文件状态与预览结果')
          .fontSize(13)
          .fontColor(this.getPalette().textSecondary)
          .margin({ top: 5 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
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
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getPalette().textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.getFileStateText())
            .fontSize(12)
            .fontColor(this.fileExists && this.fileSize > 0 ? '#8EA590' : '#B65A4B')
            .margin({ top: 6 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')
      Text(this.filePath.length === 0 ? '未获取到文件路径' : this.filePath)
        .fontSize(11)
        .fontColor(this.getPalette().textTertiary)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 12 })
    }
    .width('100%')
    .padding(14)
    .alignItems(HorizontalAlign.Start)
    .margin({ top: 12 })
    .backgroundColor(this.getPalette().cardBg)
    .borderRadius(16)
  }

  @Builder
  PdfPreviewArea() {
    Column() {
      if (this.previewReady) {
        PdfView({
          controller: this.controller,
          pageFit: pdfService.PageFit.FIT_WIDTH,
          showScroll: true
        })
          .width('100%')
          .height('100%')
      } else {
        Column() {
          Text('PDF 暂无法预览')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.getPalette().textPrimary)
          Text(this.openMessage.length === 0 ? '如果文件大小为 0B，说明 PDFKit 生成文件为空，需要重新导出并查看导出提示。' : this.openMessage)
            .fontSize(13)
            .fontColor(this.getPalette().textSecondary)
            .lineHeight(21)
            .textAlign(TextAlign.Center)
            .margin({ top: 10 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .padding(20)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .margin({ top: 12 })
    .backgroundColor(this.getPalette().cardBg)
    .borderRadius(16)
  }

  @Builder
  ActionCard() {
    Column() {
      Row() {
        Text(this.previewReady ? '第 ' + (this.currentPage + 1) + ' / ' + this.totalPage + ' 页' : '预览未就绪')
          .fontSize(12)
          .fontColor(this.getPalette().textSecondary)
        Blank()
        Text('重新加载')
          .fontSize(12)
          .fontColor(this.getPalette().primary)
          .onClick(() => {
            this.loadPdfPreview()
          })
      }
      .width('100%')
      Text(this.fileExists ? '保存到可见位置' : '文件不存在，请返回重新导出')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.fileExists ? this.getPalette().cardBg : '#B65A4B')
        .width('100%')
        .height(42)
        .textAlign(TextAlign.Center)
        .backgroundColor(this.fileExists ? this.getPalette().primary : this.getPalette().inputBg)
        .borderRadius(21)
        .margin({ top: 12 })
        .onClick(() => {
          this.savePdfToVisibleLocation()
        })
      if (this.openMessage.length > 0 && this.previewReady) {
        Text(this.openMessage)
          .fontSize(12)
          .fontColor(this.getPalette().textSecondary)
          .lineHeight(18)
          .textAlign(TextAlign.Center)
          .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding(14)
    .margin({ top: 12 })
    .backgroundColor(this.getPalette().cardBg)
    .borderRadius(16)
  }

  getPalette(): ThemePalette {
    return ThemePreferenceService.getCurrentPalette()
  }

  getFileStateText(): string {
    if (!this.fileExists) {
      return '文件缺失'
    }
    if (this.fileSize <= 0) {
      return '文件为空 0B'
    }
    return '文件可用 · ' + this.fileSize + ' B'
  }

  async loadPdfPreview() {
    this.previewReady = false
    this.totalPage = 0
    this.currentPage = 0
    this.controller.releaseDocument()
    this.fileExists = FileStorageService.exists(this.filePath)
    this.fileSize = FileStorageService.getFileSize(this.filePath)
    if (!this.fileExists) {
      this.openMessage = '文件不存在，请返回书籍日记本重新导出。'
      return
    }
    if (this.fileSize <= 0) {
      this.openMessage = 'PDF 文件大小为 0B，无法预览。请重新导出；新版本已拦截 0B 文件继续写入导出历史。'
      return
    }
    try {
      this.controller.registerPageChangedListener((pageIndex: number) => {
        this.currentPage = pageIndex
      })
      const loadResult = await this.controller.loadDocument(this.filePath)
      if (loadResult === pdfService.ParseResult.PARSE_SUCCESS) {
        this.totalPage = this.controller.getPageCount()
        this.previewReady = true
        this.openMessage = ''
      } else {
        this.openMessage = 'PDF 解析失败，文件可能已损坏或当前 PDFKit 生成内容不兼容。'
      }
    } catch (err) {
      this.openMessage = 'PDF 预览失败，请确认文件不是 0B，并尝试重新导出。'
    }
  }

  async savePdfToVisibleLocation() {
    if (!this.fileExists) {
      this.openMessage = '文件不存在，请返回书籍日记本重新导出。'
      return
    }
    if (this.fileSize <= 0) {
      this.openMessage = 'PDF 文件大小为 0B，无法保存为可打开文件，请重新导出。'
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
      const copyResult: FileCopyResult = FileStorageService.copyFile(this.filePath, uriList[0])
      this.openMessage = copyResult.message
    } catch (err) {
      this.openMessage = '保存失败：当前系统文件保存器不可用或目标 URI 无法直接写入。'
    }
  }
}
