/**
 * ID 生成工具
 *
 * 多行说明：
 * 1. 当前应用是本地单机读书日记，实体 id 只需要在本地数据库内保持足够稳定和唯一。
 * 2. 这里使用时间戳 + 随机数生成轻量 id，避免引入额外依赖，也方便后续排查记录创建时间。
 * 3. 如果未来接入云同步，可以在 Repository 层替换为 UUID 或服务端 id，而不影响页面表单逻辑。
 */
export class IdUtils {
  static createId(prefix: string): string {
    const now: number = new Date().getTime()
    const random: number = Math.floor(Math.random() * 1000000)
    return prefix + '_' + now.toString() + '_' + random.toString()
  }
}
