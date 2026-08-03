/**
 * 阅读记录领域模型
 *
 * 多行说明：
 * 1. ReadingMood 是写记录时的核心必填项，后续也会用于日历热力图和我的页心情分布统计。
 * 2. ReadingEntryEntity 保存一次阅读记录的完整信息，bookId 与 BookEntity.id 关联。
 * 3. 页面展示层可以通过 getMoodText 和 getMoodColor 取得稳定的文案与语义色，不需要重复判断枚举。
 */
export enum ReadingMood {
  HAPPY = 'happy',
  CALM = 'calm',
  NEUTRAL = 'neutral',
  SAD = 'sad',
  PENSIVE = 'pensive'
}

export interface ReadingEntryEntity {
  id: string
  bookId: string
  date: number
  pageFrom?: number
  pageTo?: number
  mood: ReadingMood
  coffee?: string
  content: string
  photoPath?: string
  createdAt: number
  updatedAt: number
}

export function getMoodText(mood: ReadingMood): string {
  if (mood === ReadingMood.HAPPY) {
    return '开心'
  }
  if (mood === ReadingMood.CALM) {
    return '平静'
  }
  if (mood === ReadingMood.NEUTRAL) {
    return '一般'
  }
  if (mood === ReadingMood.SAD) {
    return '感伤'
  }
  return '沉思'
}

export function getMoodColor(mood: ReadingMood): string {
  if (mood === ReadingMood.HAPPY) {
    return '#E8956C'
  }
  if (mood === ReadingMood.CALM) {
    return '#8CB89A'
  }
  if (mood === ReadingMood.NEUTRAL) {
    return '#A09890'
  }
  if (mood === ReadingMood.SAD) {
    return '#9098B8'
  }
  return '#8090A8'
}
