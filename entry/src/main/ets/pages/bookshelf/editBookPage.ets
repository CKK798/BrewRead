import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { BookEntity, BookStatus } from '../../models/BookModel';
import { PAGE_PATH } from '../../pagePath';
import { BookRepository } from '../../services/repository/BookRepository';
import { BrewFontSize, BrewRadius, BrewSpacing, BrewTheme } from '../../theme/ThemeTokens';
import { ValidationResult, ValidationUtils } from '../../utils/ValidationUtils';

/**
 * 编辑书籍页面
 *
 * 多行说明：
 * 1. 该页面复用添加书籍页的字段规则，但通过 selectedBookId 加载已有实体，避免编辑时重新生成 id。
 * 2. 页面保存时只更新书籍自身字段，createdAt、sortOrder 和 id 保持原值，确保书架顺序和关联阅读记录不受影响。
 * 3. 书籍不存在、加载失败或校验失败时保留错误信息，避免用户误以为数据已经保存。
 */
@HMRouter({ pageUrl: PAGE_PATH.BOOK_EDIT_PAGE })
@ComponentV2
export struct editBookPage {
  @Local bookId: string = ''
  @Local bookName: string = ''
  @Local author: string = ''
  @Local isbn: string = ''
  @Local totalPagesText: string = ''
  @Local selectedStatus: BookStatus = BookStatus.READING
  @Local loading: boolean = false
  @Local saving: boolean = false
  @Local errorMessage: string = ''
  private statusList: BookStatus[] = [BookStatus.READING, BookStatus.FINISHED, BookStatus.WANT]

  async aboutToAppear() {
    this.bookId = AppStorage.get<string>('selectedBookId') ?? ''
    await this.loadBook()
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          if (this.loading) {
            Text('正在读取书籍信息...')
              .fontSize(BrewFontSize.secondary)
              .fontColor(BrewTheme.light.textSecondary)
              .width('100%')
              .height(120)
              .textAlign(TextAlign.Center)
          } else {
            this.InputGroup('书名', '请输入书名', this.bookName, true)
            this.InputGroup('作者', '请输入作者', this.author, false)
            this.InputGroup('ISBN', '可选，10 或 13 位数字', this.isbn, false)
            this.InputGroup('总页数', '可选，例如 384', this.totalPagesText, false)
            this.StatusSelector()
            if (this.errorMessage.length > 0) {
              Text(this.errorMessage)
                .fontSize(BrewFontSize.caption)
                .fontColor('#B65A4B')
                .margin({ top: 8 })
            }
            this.SaveButton()
          }
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
      Text('编辑书籍')
        .fontSize(BrewFontSize.title)
        .fontWeight(FontWeight.Bold)
        .fontColor(BrewTheme.light.textPrimary)
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
          .fontColor(BrewTheme.light.textPrimary)
        if (required) {
          Text(' *')
            .fontSize(BrewFontSize.secondary)
            .fontColor('#B65A4B')
        }
      }
      .margin({ bottom: 8 })
      TextInput({ placeholder: placeholder, text: value })
        .height(48)
        .fontSize(BrewFontSize.body)
        .backgroundColor(BrewTheme.light.cardBg)
        .borderRadius(BrewRadius.small)
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
        .fontColor(BrewTheme.light.textPrimary)
        .margin({ bottom: 8 })
      Row() {
        ForEach(this.statusList, (status: BookStatus) => {
          Text(this.getStatusText(status))
            .fontSize(BrewFontSize.secondary)
            .fontColor(this.selectedStatus === status ? '#FFFFFF' : BrewTheme.light.textSecondary)
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
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 20 })
  }

  @Builder
  SaveButton() {
    Text(this.saving ? '保存中...' : '保存修改')
      .fontSize(BrewFontSize.body)
      .fontColor('#FFFFFF')
      .width('100%')
      .height(50)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.saving ? '#80C2865E' : BrewTheme.light.primary)
      .borderRadius(25)
      .onClick(() => {
        this.saveBook()
      })
  }

  async loadBook() {
    if (this.bookId.length === 0) {
      this.errorMessage = '没有找到要编辑的书籍'
      return
    }
    this.loading = true
    try {
      const book: BookEntity | undefined = await BookRepository.queryBookById(this.bookId)
      if (book === undefined) {
        this.errorMessage = '书籍不存在或已被删除'
      } else {
        this.bookName = book.name
        this.author = book.author ?? ''
        this.isbn = book.isbn ?? ''
        this.totalPagesText = book.totalPages === undefined ? '' : book.totalPages.toString()
        this.selectedStatus = book.status
      }
    } catch (err) {
      this.errorMessage = '书籍加载失败，请稍后重试'
    }
    this.loading = false
  }

  async saveBook() {
    const validation: ValidationResult = this.validateForm()
    if (!validation.valid || this.saving) {
      this.errorMessage = validation.message
      return
    }
    this.saving = true
    try {
      const oldBook: BookEntity | undefined = await BookRepository.queryBookById(this.bookId)
      if (oldBook === undefined) {
        this.errorMessage = '书籍不存在或已被删除'
        this.saving = false
        return
      }
      const pages: number = this.parseTotalPages()
      const updatedBook: BookEntity = {
        id: oldBook.id,
        name: this.bookName.trim(),
        author: this.author.trim().length === 0 ? undefined : this.author.trim(),
        isbn: ValidationUtils.normalizeIsbn(this.isbn),
        totalPages: pages > 0 ? pages : undefined,
        coverPath: oldBook.coverPath,
        status: this.selectedStatus,
        sortOrder: oldBook.sortOrder,
        createdAt: oldBook.createdAt,
        updatedAt: new Date().getTime()
      }
      await BookRepository.updateBook(updatedBook)
      if (oldBook.status !== BookStatus.FINISHED && updatedBook.status === BookStatus.FINISHED) {
        AppStorage.setOrCreate('selectedBookId', updatedBook.id)
        HMRouterMgr.push({ pageUrl: PAGE_PATH.FINISH_CEREMONY_PAGE })
      } else {
        HMRouterMgr.pop()
      }
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
    if (this.totalPagesText.trim().length > 0) {
      result = ValidationUtils.validateTotalPages(this.parseTotalPages())
      if (!result.valid) {
        return result
      }
    }
    return ValidationUtils.validateBookStatus(this.selectedStatus)
  }

  onInputChange(label: string, text: string) {
    if (label === '书名') this.bookName = text
    else if (label === '作者') this.author = text
    else if (label === 'ISBN') this.isbn = text
    else if (label === '总页数') this.totalPagesText = text
  }

  parseTotalPages(): number {
    return this.totalPagesText.trim().length === 0 ? 0 : Number(this.totalPagesText)
  }

  getStatusText(status: BookStatus): string {
    if (status === BookStatus.READING) return '在读'
    if (status === BookStatus.FINISHED) return '已读完'
    return '想读'
  }
}