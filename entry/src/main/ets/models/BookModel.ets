/**
 * 书籍领域模型
 *
 * 多行说明：
 * 1. BookStatus 对应数据库 books.status 字段，页面筛选、状态切换和统计都基于这个枚举。
 * 2. BookEntity 是服务层和页面层共享的数据结构，字段名保持 ArkTS 驼峰风格。
 * 3. 后续写入数据库时，Repository 层负责把 totalPages、coverPath 等字段映射为表中的下划线字段。
 */
export enum BookStatus {
  READING = 'reading',
  FINISHED = 'finished',
  WANT = 'want'
}

export interface BookEntity {
  id: string
  name: string
  author?: string
  isbn?: string
  totalPages?: number
  coverPath?: string
  status: BookStatus
  sortOrder: number
  createdAt: number
  updatedAt: number
}

export interface BookWithProgress extends BookEntity {
  currentPage: number
  progress: number
  recordCount: number
}

export function getBookStatusText(status: BookStatus): string {
  if (status === BookStatus.READING) {
    return '在读'
  }
  if (status === BookStatus.FINISHED) {
    return '已读完'
  }
  return '想读'
}
