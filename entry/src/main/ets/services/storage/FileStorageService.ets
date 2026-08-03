import { fileIo } from '@kit.CoreFileKit';

export interface TextFileSaveResult {
  success: boolean
  message: string
  filePath: string
}

export interface FileDeleteResult {
  success: boolean
  message: string
}

export interface FileCopyResult {
  success: boolean
  message: string
}

/**
 * 文件存储服务
 *
 * 多行说明：
 * 1. 本服务封装文本文件写入能力，备份 JSON、导出文本和后续 PDF 元数据都可以复用。
 * 2. 当前通过 AppStorage.appFilesDir 获取应用沙箱 files 目录，避免页面层直接依赖文件系统细节。
 * 3. 写入失败时返回结构化错误结果，页面根据 message 展示提示，避免异常直接中断用户流程。
 */
export class FileStorageService {
  static async saveText(relativePath: string, content: string): Promise<TextFileSaveResult> {
    const fullPath: string = FileStorageService.buildFullPath(relativePath)
    if (fullPath.length === 0) {
      return { success: false, message: '文件目录未初始化，暂不能保存文件', filePath: '' }
    }
    try {
      FileStorageService.ensureParentDir(fullPath)
      const file = fileIo.openSync(fullPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC)
      fileIo.writeSync(file.fd, content)
      fileIo.closeSync(file)
      return { success: true, message: '文件已保存', filePath: fullPath }
    } catch (err) {
      return { success: false, message: '文件保存失败，请稍后重试', filePath: fullPath }
    }
  }

  static buildFullPath(relativePath: string): string {
    const baseDir: string = AppStorage.get<string>('appFilesDir') ?? ''
    if (baseDir.length === 0) {
      return ''
    }
    return baseDir + '/' + relativePath
  }

  static ensureParentDirForFile(fullPath: string): boolean {
    try {
      FileStorageService.ensureParentDir(fullPath)
      return true
    } catch (err) {
      return false
    }
  }

  static exists(filePath: string): boolean {
    if (filePath.length === 0) {
      return false
    }
    try {
      return fileIo.accessSync(filePath)
    } catch (err) {
      return false
    }
  }

  static deleteFile(filePath: string): FileDeleteResult {
    if (filePath.length === 0) {
      return { success: true, message: '文件路径为空，仅删除记录' }
    }
    if (!FileStorageService.exists(filePath)) {
      return { success: true, message: '文件不存在，仅删除记录' }
    }
    try {
      fileIo.unlinkSync(filePath)
      return { success: true, message: '文件已删除' }
    } catch (err) {
      return { success: false, message: '文件删除失败，请稍后重试' }
    }
  }

  static copyFile(sourcePath: string, targetPath: string): FileCopyResult {
    if (!FileStorageService.exists(sourcePath)) {
      return { success: false, message: '源文件不存在，请重新导出 PDF' }
    }
    if (targetPath.length === 0) {
      return { success: false, message: '目标路径为空，无法保存文件' }
    }
    try {
      FileStorageService.ensureParentDir(targetPath)
      fileIo.copyFileSync(sourcePath, targetPath)
      return { success: true, message: 'PDF 已保存到你选择的位置' }
    } catch (err) {
      return { success: false, message: 'PDF 保存到可见位置失败，请稍后重试' }
    }
  }

  private static ensureParentDir(fullPath: string): void {
    const splitIndex: number = fullPath.lastIndexOf('/')
    if (splitIndex <= 0) {
      return
    }
    const dirPath: string = fullPath.substring(0, splitIndex)
    if (!fileIo.accessSync(dirPath)) {
      fileIo.mkdirSync(dirPath, true)
    }
  }
}
