/**
 * PDF 导出记录模型
 *
 * 多行说明：
 * 1. ExportRecordEntity 记录每次导出的 PDF 文件位置和纸张规格，供“导出管理”页面展示。
 * 2. paperSize 使用枚举限制为 A4/A5，避免导出服务层接收到无法排版的非法值。
 * 3. filePath 指向应用沙箱中的实际文件，fileName 用于列表展示与分享时的默认名称。
 */
export enum PaperSize {
  A4 = 'A4',
  A5 = 'A5'
}

export enum PdfTemplate {
  MINIMALIST = '极简留白杂志风',
  BUNKO = '日式文库本风',
  LETTERPRESS = '复古信笺风',
  ARTBOOK = '现代画册风'
}

export interface ExportRecordEntity {
  id: string
  bookId: string
  filePath: string
  paperSize: PaperSize
  template: PdfTemplate
  fileName: string
  fileSize: number
  pageCount: number
  createdAt: number
  updatedAt: number
}
