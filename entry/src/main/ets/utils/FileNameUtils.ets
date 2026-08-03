/**
 * 文件名清洗工具
 *
 * 多行说明：
 * 1. PDF 导出文件名会基于书名生成，但书名可能包含系统不允许的路径字符。
 * 2. sanitizeFileName 会移除常见非法字符并限制长度，避免后续创建文件时失败。
 * 3. 当清洗结果为空时使用 fallback，保证导出服务始终能得到可写入的文件名。
 */
export class FileNameUtils {
  static sanitizeFileName(name: string, fallback: string = '啡阅导出'): string {
    const cleaned: string = name.replace(/[\\/:*?"<>|]/g, '').replace(/\s+/g, ' ').trim()
    if (cleaned.length === 0) {
      return fallback
    }
    if (cleaned.length > 60) {
      return cleaned.substring(0, 60)
    }
    return cleaned
  }
}
