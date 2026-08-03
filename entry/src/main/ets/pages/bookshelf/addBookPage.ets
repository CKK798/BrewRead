import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { BookEntity, BookStatus } from '../../models/BookModel';
import { PAGE_PATH } from '../../pagePath';
import { BookRepository } from '../../services/repository/BookRepository';
import { BrewFontSize, BrewRadius, BrewSpacing, BrewTheme } from '../../theme/ThemeTokens';
import { IdUtils } from '../../utils/IdUtils';
import { ValidationResult, ValidationUtils } from '../../utils/ValidationUtils';

/**
 * 添加书籍页面
 *
 * 多行说明：
 * 1. 本页面是书架模块 CRUD 闭环的第一个可写入口，负责收集书名、作者、ISBN、总页数和阅读状态。
 * 2. 保存前统一调用 ValidationUtils 校验输入，页面只负责展示错误文案，具体规则沉淀在工具层方便复用。
 * 3. 校验通过后组装 BookEntity 并调用 BookRepository.insertBook 写入本地数据库，成功后返回上一页。
 */
@HMRouter({ pageUrl: PAGE_PATH.BOOK_ADD_PAGE })
@ComponentV2
export struct addBookPage {
  @Local bookName: string = ''
  @Local author: string = ''
  @Local isbn: string = ''
  @Local totalPagesText: string = ''
  @Local selectedStatus: BookStatus = BookStatus.READING
  @Local errorMessage: string = ''
  @Local saving: boolean = false
  private statusList: BookStatus[] = [BookStatus.READING, BookStatus.FINISHED, BookStatus.WANT]

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.InputGroup('书名', '请输入书名', this.bookName, true)
          this.InputGroup('作者', '请输入作者', this.author, false)
          this.InputGroup('ISBN', '可选，10 或 13 位数字', this.isbn, false)
          this.InputGroup('总页数', '可选，例如 384', this.totalPagesText, false)
          this.StatusSelector()
          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(BrewFontSize.caption)
              .fontColor('#B65A4B')
              .margin({ top: BrewSpacing.smallGap })
          }
          this.SaveButton()
        }
        .width('100%')
        .padding({ left: BrewSpacing.pagePadding, right: BrewSpacing.pagePadding, top: 18, bottom: 28 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(BrewTheme.light.pageBg)
    .padding({ top: this.getUIContext().px2vp(AppStorage.get('topH')) })
  }

  @Builder
  Header() {
    Row() {
      Text('‹')
        .fontSize(32)
        .fontColor(BrewTheme.light.textPrimary)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          HMRouterMgr.pop()
        })
      Column() {
        Text('添加新书')
          .fontSize(BrewFontSize.title)
          .fontWeight(FontWeight.Bold)
          .fontColor(BrewTheme.light.textPrimary)
        Text('标记你想读或正在读的书')
          .fontSize(BrewFontSize.caption)
          .fontColor(BrewTheme.light.textSecondary)
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ left: 6, right: BrewSpacing.pagePadding, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  InputGroup(label: string, placeholder: string, value: string, required: boolean) {
    Column() {
      Row() {
        Text(label)
          .fontSize(BrewFontSize.secondary)
          .fontWeight(FontWeight.Medium)
          .fontColor(BrewTheme.light.textPrimary)
        if (required) {
          Text(' *')
            .fontSize(BrewFontSize.secondary)
            .fontColor('#B65A4B')
        }
      }
      .width('100%')
      .margin({ bottom: 8 })

      TextInput({ placeholder: placeholder, text: value })
        .height(48)
        .fontSize(BrewFontSize.body)
        .fontColor(BrewTheme.light.textPrimary)
        .placeholderColor(BrewTheme.light.textTertiary)
        .backgroundColor(BrewTheme.light.cardBg)
        .borderRadius(BrewRadius.small)
        .padding({ left: 14, right: 14 })
        .border({ width: 0.5, color: '#0D000000' })
        .onChange((text: string) => {
          this.onInputChange(label, text)
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 18 })
  }

  @Builder
  StatusSelector() {
    Column() {
      Text('阅读状态')
        .fontSize(BrewFontSize.secondary)
        .fontWeight(FontWeight.Medium)
        .fontColor(BrewTheme.light.textPrimary)
        .margin({ bottom: 8 })
      Row() {
        ForEach(this.statusList, (status: BookStatus) => {
          Text(this.getStatusText(status))
            .fontSize(BrewFontSize.secondary)
            .fontColor(this.selectedStatus === status ? '#FFFFFF' : BrewTheme.light.textSecondary)
            .fontWeight(this.selectedStatus === status ? FontWeight.Medium : FontWeight.Regular)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .height(38)
            .backgroundColor(this.selectedStatus === status ? BrewTheme.light.primary : Color.Transparent)
            .borderRadius(19)
            .onClick(() => {
              this.selectedStatus = status
            })
        }, (status: BookStatus) => status)
      }
      .width('100%')
      .height(46)
      .padding(4)
      .backgroundColor(BrewTheme.light.cardBg)
      .borderRadius(23)
      .border({ width: 0.5, color: '#0D000000' })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 20 })
  }

  @Builder
  SaveButton() {
    Text(this.saving ? '保存中...' : '保存书籍')
      .fontSize(BrewFontSize.body)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .width('100%')
      .height(50)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.saving ? '#80C2865E' : BrewTheme.light.primary)
      .borderRadius(25)
      .shadow({ radius: 10, color: '#1FC2865E', offsetX: 0, offsetY: 4 })
      .onClick(() => {
        this.saveBook()
      })
  }

  onInputChange(label: string, text: string) {
    if (label === '书名') {
      this.bookName = text
    } else if (label === '作者') {
      this.author = text
    } else if (label === 'ISBN') {
      this.isbn = text
    } else if (label === '总页数') {
      this.totalPagesText = text
    }
  }

  async saveBook() {
    if (this.saving) {
      return
    }
    const validation: ValidationResult = this.validateForm()
    if (!validation.valid) {
      this.errorMessage = validation.message
      return
    }

    this.saving = true
    this.errorMessage = ''
    const now: number = new Date().getTime()
    const pages: number = this.parseTotalPages()
    const book: BookEntity = {
      id: IdUtils.createId('book'),
      name: this.bookName.trim(),
      author: this.author.trim().length > 0 ? this.author.trim() : undefined,
      isbn: ValidationUtils.normalizeIsbn(this.isbn),
      totalPages: pages > 0 ? pages : undefined,
      status: this.selectedStatus,
      sortOrder: now,
      createdAt: now,
      updatedAt: now
    }

    try {
      await BookRepository.insertBook(book)
      HMRouterMgr.pop()
    } catch (err) {
      this.errorMessage = '保存失败，请稍后重试'
      this.saving = false
    }
  }

  validateForm(): ValidationResult {
    let result: ValidationResult = ValidationUtils.validateBookName(this.bookName)
    if (!result.valid) {
      return result
    }
    result = ValidationUtils.validateAuthor(this.author)
    if (!result.valid) {
      return result
    }
    result = ValidationUtils.validateIsbn(this.isbn)
    if (!result.valid) {
      return result
    }
    const pages: number = this.parseTotalPages()
    if (this.totalPagesText.trim().length > 0) {
      result = ValidationUtils.validateTotalPages(pages)
      if (!result.valid) {
        return result
      }
    }
    return ValidationUtils.validateBookStatus(this.selectedStatus)
  }

  parseTotalPages(): number {
    const text: string = this.totalPagesText.trim()
    if (text.length === 0) {
      return 0
    }
    return Number(text)
  }

  getStatusText(status: BookStatus): string {
    if (status === BookStatus.READING) {
      return '在读'
    }
    if (status === BookStatus.FINISHED) {
      return '已读完'
    }
    return '想读'
  }
}
