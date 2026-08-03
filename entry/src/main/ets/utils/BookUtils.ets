import { BookWithProgress } from '../models/BookModel';

/**
 * 书籍业务工具
 *
 * 多行说明：
 * 1. 这里封装书架卡片常用的展示计算，例如封面首字、阅读进度和进度文案。
 * 2. 工具函数保持纯计算，不读取数据库；Repository 取到记录后再调用这些函数组装 BookWithProgress。
 * 3. 页面后续接入真实数据时，优先使用这些函数，避免 UI 层散落业务计算。
 */
export class BookUtils {
  static getCoverText(bookName: string): string {
    const text: string = bookName.trim()
    if (text.length === 0) {
      return '书'
    }
    return text.substring(0, 1)
  }

  static calculateProgress(currentPage: number, totalPages?: number): number {
    if (totalPages === undefined || totalPages <= 0 || currentPage <= 0) {
      return 0
    }
    const percent: number = Math.floor((currentPage / totalPages) * 100)
    if (percent > 100) {
      return 100
    }
    return percent
  }

  static getProgressText(book: BookWithProgress): string {
    if (book.totalPages !== undefined && book.totalPages > 0) {
      return book.currentPage.toString() + ' / ' + book.totalPages.toString()
    }
    return book.progress.toString() + '%'
  }
}
