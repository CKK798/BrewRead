
/**
 * 页面跳转路由管理
 *
 * 多行说明：
 * 1. 所有页面路径都集中在 PAGE_PATH 中维护，避免页面里散落硬编码字符串。
 * 2. 一级 Feature 页面继续服务底部 Tab；二级页面作为后续添加书籍、写记录、设置等功能入口。
 * 3. 项目统一使用 HMRouter 路由体系，新增页面时只需要在这里补常量并在页面添加 @HMRouter。
 */
export class PAGE_PATH {
  /**根组件在导航栏唯一标识*/
  static readonly MAIN_PAGE: string = "mainNavigation"
  /**启动页*/
  static readonly LAUNCH_PAGE: string = "launchPage"
  /**主页面*/
  static readonly HOME_PAGE: string = "homePage"

  /**书架一级页面*/
  static readonly FEATURE_BOOKSHELF_PAGE: string = "bookShelfPage"
  /**日历一级页面*/
  static readonly FEATURE_CALENDER_PAGE: string = "calenderPage"
  /**记录一级页面*/
  static readonly FEATURE_JOURNAL_PAGE: string = "journalPage"
  /**我的一级页面*/
  static readonly FEATURE_ME_PAGE: string = "mePage"

  /**添加书籍页面*/
  static readonly BOOK_ADD_PAGE: string = "bookAddPage"
  /**书籍详情页面*/
  static readonly BOOK_DETAIL_PAGE: string = "bookDetailPage"
  /**编辑书籍页面*/
  static readonly BOOK_EDIT_PAGE: string = "bookEditPage"
  /**新建阅读记录页面*/
  static readonly ENTRY_NEW_PAGE: string = "entryNewPage"
  /**编辑阅读记录页面*/
  static readonly ENTRY_EDIT_PAGE: string = "entryEditPage"
  /**某本书的日记本时间线页面*/
  static readonly BOOK_JOURNAL_PAGE: string = "bookJournalPage"
  /**单日记录详情页面*/
  static readonly DAY_DETAIL_PAGE: string = "dayDetailPage"
  /**导出管理页面*/
  static readonly EXPORT_MANAGER_PAGE: string = "exportManagerPage"
  /**设置页面*/
  static readonly SETTINGS_PAGE: string = "settingsPage"
  /**备份与恢复页面*/
  static readonly BACKUP_PAGE: string = "backupPage"
  /**PDF 预览页面*/
  static readonly PDF_PREVIEW_PAGE: string = "pdfPreviewPage"
}