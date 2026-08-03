/**
 * 日期格式化工具
 *
 * 多行说明：
 * 1. 阅读记录、日历摘要和 PDF 文件名都需要稳定的日期文案，这里统一封装格式化逻辑。
 * 2. 输入统一使用毫秒时间戳，和数据库中 date、createdAt、updatedAt 的 number 类型保持一致。
 * 3. ArkTS 页面层只负责展示返回的字符串，避免每个页面重复创建 Date 并拼接中文日期。
 */
export class DateUtils {
  static pad(value: number): string {
    if (value < 10) {
      return '0' + value.toString()
    }
    return value.toString()
  }

  static formatMonthDay(timestamp: number): string {
    const date: Date = new Date(timestamp)
    return (date.getMonth() + 1).toString() + '月' + date.getDate().toString() + '日'
  }

  static formatDate(timestamp: number): string {
    const date: Date = new Date(timestamp)
    return date.getFullYear().toString() + '-' + DateUtils.pad(date.getMonth() + 1) + '-' + DateUtils.pad(date.getDate())
  }

  static formatChineseDate(timestamp: number): string {
    const date: Date = new Date(timestamp)
    return date.getFullYear().toString() + '年' + (date.getMonth() + 1).toString() + '月' + date.getDate().toString() + '日'
  }

  static getWeekdayText(timestamp: number): string {
    const weekdays: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    const date: Date = new Date(timestamp)
    return weekdays[date.getDay()]
  }
}
