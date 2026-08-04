import { HMRouter, HMRouterMgr } from '@hadss/hmrouter';
import { BookEntity, BookStatus } from '../../models/BookModel';
import { ReadingEntryEntity, ReadingMood, getMoodColor, getMoodText } from '../../models/ReadingEntryModel';
import { PAGE_PATH } from '../../pagePath';
import { BookRepository } from '../../services/repository/BookRepository';
import { ReadingEntryRepository } from '../../services/repository/ReadingEntryRepository';
import { ThemePreferenceService } from '../../services/theme/ThemePreferenceService';
import { ThemePalette, BrewFontSize, BrewRadius, BrewSpacing, BrewTheme } from '../../theme/ThemeTokens';
import { IdUtils } from '../../utils/IdUtils';
import { ValidationResult, ValidationUtils } from '../../utils/ValidationUtils';

/**
 * 写阅读记录页面
 *
 * 多行说明：
 * 1. 本页面打通“选择书籍 → 填写阅读感悟 → 保存记录”的核心写记录流程，是阅读闭环的关键入口。
 * 2. 书籍列表从 BookRepository 读取在读和已读完书籍，避免用户给“想读”书直接写进度记录。
 * 3. 保存前复用 ValidationUtils 校验必填项和页码范围，校验通过后写入 ReadingEntryRepository。
 */
@HMRouter({ pageUrl: PAGE_PATH.ENTRY_EDIT_PAGE })
@ComponentV2
export struct entryEditPage {
  @Local books: BookEntity[] = []
  @Local selectedBookId: string = ''
  @Local selectedMood: ReadingMood = ReadingMood.CALM
  @Local pageFromText: string = ''
  @Local pageToText: string = ''
  @Local coffee: string = ''
  @Local content: string = ''
  @Local isHighlight: boolean = false
  @Local errorMessage: string = ''
  @Local loadingBooks: boolean = false
  @Local saving: boolean = false
  @Local editingEntryId: string = ''
  @Local originalEntry?: ReadingEntryEntity = undefined
  private moods: ReadingMood[] = [ReadingMood.HAPPY, ReadingMood.CALM, ReadingMood.NEUTRAL, ReadingMood.PENSIVE, ReadingMood.SAD]

  async aboutToAppear() {
    this.editingEntryId = AppStorage.get<string>('selectedEntryId') ?? ''
    this.selectedBookId = AppStorage.get<string>('selectedBookId') ?? ''
    await this.loadSelectableBooks()
    if (this.editingEntryId.length > 0) {
      await this.loadEditingEntry()
    }
  }

  getPalette(): ThemePalette {
    return ThemePreferenceService.getCurrentPalette()
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.BookSelector()
          this.MoodSelector()
          this.PageInputs()
          this.CoffeeInput()
          this.ContentInput()
          this.HighlightSwitch()
          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(BrewFontSize.caption)
              .fontColor('#B65A4B')
              .margin({ top: 8 })
          }
          this.SaveButton()
        }
        .width('100%')
        .padding({ left: BrewSpacing.pagePadding, right: BrewSpacing.pagePadding, top: 16, bottom: 28 })
      }
      .align(Alignment.Top)
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
        Text(this.isEditMode() ? '编辑阅读记录' : '写阅读记录')
          .fontSize(BrewFontSize.title)
          .fontWeight(FontWeight.Bold)
          .fontColor(BrewTheme.light.textPrimary)
        Text('把这一刻的阅读和咖啡留下来')
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
  BookSelector() {
    Column() {
      this.SectionTitle('选择书籍', true)
      if (this.loadingBooks) {
        Text('正在读取书架...')
          .fontSize(BrewFontSize.secondary)
          .fontColor(BrewTheme.light.textSecondary)
          .width('100%')
          .height(54)
          .textAlign(TextAlign.Center)
          .backgroundColor(BrewTheme.light.cardBg)
          .borderRadius(BrewRadius.small)
      } else if (this.books.length === 0) {
        Column() {
          Text('书架里还没有可记录的书')
            .fontSize(BrewFontSize.secondary)
            .fontColor(BrewTheme.light.textPrimary)
          Text('请先添加一本在读或已读完的书')
            .fontSize(BrewFontSize.caption)
            .fontColor(BrewTheme.light.textSecondary)
            .margin({ top: 6 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor(BrewTheme.light.cardBg)
        .borderRadius(BrewRadius.small)
      } else {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.books, (book: BookEntity) => {
            Text(book.name)
              .fontSize(BrewFontSize.secondary)
              .fontColor(this.selectedBookId === book.id ? '#FFFFFF' : BrewTheme.light.textSecondary)
              .padding({ left: 14, right: 14 })
              .height(36)
              .textAlign(TextAlign.Center)
              .backgroundColor(this.selectedBookId === book.id ? BrewTheme.light.primary : BrewTheme.light.cardBg)
              .borderRadius(18)
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.selectedBookId = book.id
              })
          }, (book: BookEntity) => book.id)
        }
        .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 18 })
  }

  @Builder
  MoodSelector() {
    Column() {
      this.SectionTitle('今天的心情', true)
      Row() {
        ForEach(this.moods, (mood: ReadingMood) => {
          Text(getMoodText(mood))
            .fontSize(BrewFontSize.caption)
            .fontColor(this.selectedMood === mood ? '#FFFFFF' : BrewTheme.light.textSecondary)
            .textAlign(TextAlign.Center)
            .layoutWeight(1)
            .height(38)
            .backgroundColor(this.selectedMood === mood ? getMoodColor(mood) : BrewTheme.light.cardBg)
            .borderRadius(19)
            .margin({ right: mood === ReadingMood.SAD ? 0 : 6 })
            .onClick(() => {
              this.selectedMood = mood
            })
        }, (mood: ReadingMood) => mood)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 18 })
  }

  @Builder
  PageInputs() {
    Row() {
      Column() {
        this.SectionTitle('起始页', false)
        TextInput({ placeholder: '可选', text: this.pageFromText })
          .height(46)
          .fontSize(BrewFontSize.body)
          .backgroundColor(BrewTheme.light.cardBg)
          .borderRadius(BrewRadius.small)
          .onChange((text: string) => {
            this.pageFromText = text
          })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Column() {
        this.SectionTitle('结束页', false)
        TextInput({ placeholder: '可选', text: this.pageToText })
          .height(46)
          .fontSize(BrewFontSize.body)
          .backgroundColor(BrewTheme.light.cardBg)
          .borderRadius(BrewRadius.small)
          .onChange((text: string) => {
            this.pageToText = text
          })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .margin({ bottom: 18 })
  }

  @Builder
  CoffeeInput() {
    Column() {
      this.SectionTitle('配咖啡', false)
      TextInput({ placeholder: '例如 热美式、冰拿铁', text: this.coffee })
        .height(46)
        .fontSize(BrewFontSize.body)
        .backgroundColor(BrewTheme.light.cardBg)
        .borderRadius(BrewRadius.small)
        .onChange((text: string) => {
          this.coffee = text
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 18 })
  }

  @Builder
  ContentInput() {
    Column() {
      this.SectionTitle('阅读感悟', true)
      TextArea({ placeholder: '写下这一段阅读带给你的触动...', text: this.content })
        .height(210)
        .fontSize(BrewFontSize.body)
        .fontColor(BrewTheme.light.textPrimary)
        .placeholderColor(BrewTheme.light.textTertiary)
        .backgroundColor(BrewTheme.light.cardBg)
        .borderRadius(BrewRadius.card)
        .padding(14)
        .onChange((text: string) => {
          this.content = text
        })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .margin({ bottom: 12 })
  }

  @Builder
  HighlightSwitch() {
    Row() {
      Column() {
        Text('标记为金句')
          .fontSize(BrewFontSize.secondary)
          .fontWeight(FontWeight.Medium)
          .fontColor(BrewTheme.light.textPrimary)
        Text('以后可以集中回看这一条特别想留下的话')
          .fontSize(BrewFontSize.caption)
          .fontColor(BrewTheme.light.textSecondary)
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(this.isHighlight ? '★' : '☆')
        .fontSize(26)
        .fontColor(this.isHighlight ? BrewTheme.light.primary : BrewTheme.light.textTertiary)
        .width(44)
        .height(44)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding(14)
    .backgroundColor(BrewTheme.light.cardBg)
    .borderRadius(BrewRadius.card)
    .margin({ bottom: 12 })
    .onClick(() => {
      this.isHighlight = !this.isHighlight
    })
  }

  @Builder
  SectionTitle(title: string, required: boolean) {
    Row() {
      Text(title)
        .fontSize(BrewFontSize.secondary)
        .fontWeight(FontWeight.Medium)
        .fontColor(BrewTheme.light.textPrimary)
      if (required) {
        Text(' *')
          .fontSize(BrewFontSize.secondary)
          .fontColor('#B65A4B')
      }
    }
    .margin({ bottom: 8 })
  }

  @Builder
  SaveButton() {
    Text(this.saving ? '保存中...' : (this.isEditMode() ? '保存修改' : '保存记录'))
      .fontSize(BrewFontSize.body)
      .fontWeight(FontWeight.Medium)
      .fontColor('#FFFFFF')
      .width('100%')
      .height(50)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.saving ? '#80C2865E' : BrewTheme.light.primary)
      .borderRadius(25)
      .margin({ top: 8 })
      .onClick(() => {
        this.saveEntry()
      })
  }

  /**
   * 加载可写记录的书籍
   *
   * 多行说明：
   * 1. 写记录优先面向“在读”书籍，同时允许用户给“已读完”书籍补记过往阅读。
   * 2. “想读”书籍还没有阅读进度，暂不进入写记录候选，避免用户误填无效记录。
   * 3. 加载完成后默认选中第一本书，减少用户打开页面后的必填操作成本。
   */
  async loadSelectableBooks() {
    this.loadingBooks = true
    try {
      const readingBooks: BookEntity[] = await BookRepository.queryBooksByStatus(BookStatus.READING)
      const finishedBooks: BookEntity[] = await BookRepository.queryBooksByStatus(BookStatus.FINISHED)
      this.books = readingBooks.concat(finishedBooks)
      if (this.selectedBookId.length === 0 && this.books.length > 0) {
        this.selectedBookId = this.books[0].id
      }
    } catch (err) {
      this.errorMessage = '书籍加载失败，请返回书架检查数据'
    }
    this.loadingBooks = false
  }

  async saveEntry() {
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
    const entry: ReadingEntryEntity = this.buildSavingEntry(now)

    try {
      if (this.isEditMode()) {
        await ReadingEntryRepository.updateEntry(entry)
      } else {
        await ReadingEntryRepository.insertEntry(entry)
      }
      AppStorage.setOrCreate('selectedEntryId', '')
      HMRouterMgr.pop()
    } catch (err) {
      this.errorMessage = '保存失败，请稍后重试'
      this.saving = false
    }
  }

  /**
   * 加载待编辑的阅读记录
   *
   * 多行说明：
   * 1. 编辑模式通过 AppStorage.selectedEntryId 获取记录 id，再从 Repository 读取完整实体。
   * 2. 原始记录保存在 originalEntry 中，保存修改时继续复用原 id、createdAt 和 date，避免编辑后时间线顺序突变。
   * 3. 如果记录不存在，会展示明确错误，避免用户在空表单里误保存成一条新记录。
   */
  async loadEditingEntry() {
    const entry: ReadingEntryEntity | undefined = await ReadingEntryRepository.queryEntryById(this.editingEntryId)
    if (entry === undefined) {
      this.errorMessage = '要编辑的记录不存在'
      return
    }
    this.originalEntry = entry
    this.selectedBookId = entry.bookId
    this.selectedMood = entry.mood
    this.pageFromText = entry.pageFrom === undefined ? '' : entry.pageFrom.toString()
    this.pageToText = entry.pageTo === undefined ? '' : entry.pageTo.toString()
    this.coffee = entry.coffee === undefined ? '' : entry.coffee
    this.content = entry.content
    this.isHighlight = entry.isHighlight === true
  }

  buildSavingEntry(now: number): ReadingEntryEntity {
    if (this.isEditMode() && this.originalEntry !== undefined) {
      return {
        id: this.originalEntry.id,
        bookId: this.selectedBookId,
        date: this.originalEntry.date,
        pageFrom: this.parsePage(this.pageFromText),
        pageTo: this.parsePage(this.pageToText),
        mood: this.selectedMood,
        coffee: this.coffee.trim().length > 0 ? this.coffee.trim() : undefined,
        content: this.content.trim(),
        photoPath: this.originalEntry.photoPath,
        isHighlight: this.isHighlight,
        createdAt: this.originalEntry.createdAt,
        updatedAt: now
      }
    }
    return {
      id: IdUtils.createId('entry'),
      bookId: this.selectedBookId,
      date: now,
      pageFrom: this.parsePage(this.pageFromText),
      pageTo: this.parsePage(this.pageToText),
      mood: this.selectedMood,
      coffee: this.coffee.trim().length > 0 ? this.coffee.trim() : undefined,
      content: this.content.trim(),
      isHighlight: this.isHighlight,
      createdAt: now,
      updatedAt: now
    }
  }

  isEditMode(): boolean {
    return this.editingEntryId.length > 0
  }

  validateForm(): ValidationResult {
    if (this.selectedBookId.length === 0) {
      return ValidationUtils.fail('请选择书籍')
    }
    let result: ValidationResult = ValidationUtils.validateMood(this.selectedMood)
    if (!result.valid) {
      return result
    }
    result = ValidationUtils.validateCoffee(this.coffee)
    if (!result.valid) {
      return result
    }
    result = ValidationUtils.validatePageRange(this.parsePageValue(this.pageFromText), this.parsePageValue(this.pageToText))
    if (!result.valid) {
      return result
    }
    return ValidationUtils.validateContent(this.content)
  }

  parsePage(text: string): number | undefined {
    const value: number = this.parsePageValue(text)
    if (value <= 0) {
      return undefined
    }
    return value
  }

  parsePageValue(text: string): number {
    const value: number = Number(text.trim())
    if (text.trim().length === 0 || value <= 0) {
      return 0
    }
    return value
  }
}
