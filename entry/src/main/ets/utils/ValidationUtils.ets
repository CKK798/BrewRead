import { BookStatus } from '../models/BookModel';
import { ReadingMood } from '../models/ReadingEntryModel';

export interface ValidationResult {
  valid: boolean
  message: string
}

/**
 * 表单校验工具
 *
 * 多行说明：
 * 1. 校验规则来自技术实现方案第 9 节，先沉淀为纯函数，方便页面、Repository 和测试复用。
 * 2. 每个函数只判断一类输入并返回统一 ValidationResult，页面可以直接展示 message。
 * 3. 这里不直接操作 UI 或数据库，保持工具层无副作用，后续接入保存流程时更容易定位问题。
 */
export class ValidationUtils {
  static success(): ValidationResult {
    return { valid: true, message: '' }
  }

  static fail(message: string): ValidationResult {
    return { valid: false, message: message }
  }

  static validateBookName(name: string): ValidationResult {
    const text: string = name.trim()
    if (text.length < 1) {
      return ValidationUtils.fail('请输入书名')
    }
    if (text.length > 100) {
      return ValidationUtils.fail('书名不能超过 100 字')
    }
    return ValidationUtils.success()
  }

  static validateAuthor(author: string): ValidationResult {
    if (author.trim().length > 80) {
      return ValidationUtils.fail('作者不能超过 80 字')
    }
    return ValidationUtils.success()
  }

  static normalizeIsbn(isbn: string): string {
    return isbn.replace(/-/g, '').replace(/ /g, '').trim()
  }

  static validateIsbn(isbn: string): ValidationResult {
    const normalized: string = ValidationUtils.normalizeIsbn(isbn)
    if (normalized.length === 0) {
      return ValidationUtils.success()
    }
    if (!/^\d{10}$|^\d{13}$/.test(normalized)) {
      return ValidationUtils.fail('ISBN 需为 10 或 13 位数字')
    }
    return ValidationUtils.success()
  }

  static validateTotalPages(totalPages: number): ValidationResult {
    if (totalPages <= 0 || totalPages > 99999) {
      return ValidationUtils.fail('总页数需在 1 到 99999 之间')
    }
    return ValidationUtils.success()
  }

  static validateBookStatus(status: BookStatus): ValidationResult {
    if (status === BookStatus.READING || status === BookStatus.FINISHED || status === BookStatus.WANT) {
      return ValidationUtils.success()
    }
    return ValidationUtils.fail('书籍状态不正确')
  }

  static validateMood(mood: ReadingMood): ValidationResult {
    if (mood === ReadingMood.HAPPY || mood === ReadingMood.CALM || mood === ReadingMood.NEUTRAL ||
      mood === ReadingMood.SAD || mood === ReadingMood.PENSIVE) {
      return ValidationUtils.success()
    }
    return ValidationUtils.fail('请选择心情')
  }

  static validateContent(content: string): ValidationResult {
    const text: string = content.trim()
    if (text.length < 1) {
      return ValidationUtils.fail('请输入阅读感悟')
    }
    if (text.length > 5000) {
      return ValidationUtils.fail('阅读感悟不能超过 5000 字')
    }
    return ValidationUtils.success()
  }

  static validateCoffee(coffee: string): ValidationResult {
    if (coffee.trim().length > 50) {
      return ValidationUtils.fail('咖啡名称不能超过 50 字')
    }
    return ValidationUtils.success()
  }

  static validatePageRange(pageFrom: number, pageTo: number): ValidationResult {
    if (pageFrom < 0 || pageTo < 0) {
      return ValidationUtils.fail('页码不能小于 0')
    }
    if (pageFrom > 0 && pageTo > 0 && pageTo < pageFrom) {
      return ValidationUtils.fail('结束页不能小于起始页')
    }
    return ValidationUtils.success()
  }
}
