# 啡阅（BrewRead）

啡阅是一款面向 HarmonyOS NEXT 的本地单机阅读日记应用，主张用一杯咖啡陪伴每一次阅读记录。应用围绕「书籍、阅读记录、心情、咖啡、导出」构建私人阅读时间线，帮助用户记录一本书从开始阅读到完成回顾的全过程。

项目当前基于 ArkTS 与 ArkUI 开发，已搭建 HarmonyOS 应用基础工程、启动页、底部四 Tab 主框架及主要功能页面占位，后续将继续完善本地数据存储、阅读记录编辑、书籍管理、日历回顾与 PDF 导出等能力。

## 项目定位

- **本地优先**：书籍、阅读记录、图片、导出文件等数据优先保存在设备本地。
- **记录优先**：核心体验是快速记录一次阅读过程中的页码、心情、咖啡与感悟。
- **咖啡点缀**：咖啡作为阅读场景的一部分，不单独做复杂管理。
- **回顾成册**：支持按书籍或时间线回顾阅读旅程，最终导出 PDF 收藏。
- **克制开发**：不包含登录注册、云同步、社交、推荐流等非核心功能。

## 核心功能规划

### 书架

用于管理用户的书籍，包括在读、已读完、想读等状态。每本书可记录书名、作者、总页数、封面、阅读进度与关联阅读记录数量。

### 记录

用于创建每次阅读日记。一次记录可包含关联书籍、起止页码、心情、咖啡名称、阅读感悟、日期时间与现场照片。

### 日历 / 时间线

用于按日期查看阅读记录，帮助用户回顾每日阅读情况、阅读频率与情绪变化。

### 我的

用于承载导出 PDF、本地数据管理、应用设置、备份预留等辅助能力。

## 技术栈

- **平台**：HarmonyOS NEXT
- **语言**：ArkTS
- **UI 框架**：ArkUI
- **路由**：`@hadss/hmrouter`
- **测试依赖**：`@ohos/hypium`、`@ohos/hamock`
- **数据规划**：RelationalStore、本地应用沙箱文件存储
- **导出规划**：本地 PDF 导出

## 项目结构

```text
.
├── AppScope/
│   ├── app.json5                         # 应用级配置，包括 bundleName、版本、图标与应用名称
│   └── resources/                        # 应用级资源
├── entry/
│   ├── build-profile.json5               # entry 模块构建配置
│   ├── hvigorfile.ts                     # entry 模块 Hvigor 构建脚本
│   ├── oh-package.json5                  # entry 模块包配置
│   └── src/
│       ├── main/
│       │   ├── module.json5              # entry 模块声明、Ability 与页面配置
│       │   ├── ets/
│       │   │   ├── entryability/
│       │   │   │   └── EntryAbility.ets  # 应用主 Ability，负责窗口、安全区等初始化
│       │   │   ├── entrybackupability/
│       │   │   │   └── EntryBackupAbility.ets # 备份扩展 Ability 预留
│       │   │   ├── pages/
│       │   │   │   ├── launchPage.ets    # 启动入口页 / 根导航页
│       │   │   │   ├── homePage.ets      # 底部四 Tab 主页面
│       │   │   │   └── Index.ets         # 默认页面 / 工程初始页面
│       │   │   ├── feature/
│       │   │   │   ├── bookShelfPage.ets # 书架页
│       │   │   │   ├── journalPage.ets   # 阅读记录页
│       │   │   │   ├── calenderPage.ets  # 日历页
│       │   │   │   └── mePage.ets        # 我的页
│       │   │   └── pagePath.ets          # 页面路由路径常量
│       │   └── resources/
│       │       ├── base/
│       │       │   ├── element/          # 字符串、颜色、浮点等基础资源
│       │       │   ├── media/            # 应用图标、Tab 图标、启动图等媒体资源
│       │       │   └── profile/          # 页面列表、备份配置等 profile 资源
│       │       └── dark/
│       │           └── element/          # 深色模式资源
│       ├── ohosTest/                     # HarmonyOS 测试代码
│       └── test/                         # 本地单元测试代码
├── hvigor/
│   └── hvigor-config.json5               # Hvigor 全局配置
├── icon/                                 # 设计阶段图标素材
│   ├── components/
│   ├── general/
│   ├── login/
│   └── tab-bar/
├── build-profile.json5                   # 工程构建配置
├── hvigorfile.ts                         # 工程 Hvigor 构建脚本
├── oh-package.json5                      # 工程依赖配置
├── oh-package-lock.json5                 # 依赖锁定文件
├── code-linter.json5                     # 代码检查配置
├── 需求.md                               # 产品需求文档
├── 技术实现方案.md                       # 技术实现方案
└── 啡阅_UI设计建议.md                    # UI 设计建议
```

## 当前工程状态

已具备：

- HarmonyOS NEXT 应用基础工程结构。
- `entry` 主模块与 `EntryAbility`。
- `@hadss/hmrouter` 路由依赖。
- `launchPage` 启动入口。
- `homePage` 底部四 Tab 主框架雏形。
- 书架、记录、日历、我的四个功能页面占位。
- 普通态 / 激活态 Tab 图标资源。
- 备份扩展 Ability 与备份配置预留。

待完善：

- 书籍、阅读记录、图片、设置等数据模型。
- 本地数据库与服务层封装。
- 书籍新增、编辑、详情、状态管理。
- 阅读记录新增、编辑、详情与按书聚合。
- 日历视图、时间线回顾与统计展示。
- PDF 导出原型与本地文件管理。
- 可复用 UI 组件与 Design Tokens。

## 开发说明

### 安装依赖

在 DevEco Studio 或支持 HarmonyOS 工程的环境中打开项目后，根据工程配置同步依赖。项目根依赖声明位于：

```text
oh-package.json5
```

当前主要依赖：

```json5
{
  "dependencies": {
    "@hadss/hmrouter": "^1.2.0"
  },
  "devDependencies": {
    "@ohos/hypium": "1.0.25",
    "@ohos/hamock": "1.0.0"
  }
}
```

### 运行项目

1. 使用 DevEco Studio 打开项目根目录。
2. 等待依赖同步和 Hvigor 配置加载完成。
3. 选择 `entry` 模块。
4. 连接 HarmonyOS 设备或启动模拟器。
5. 点击运行，安装并启动应用。

## 文档

- `需求.md`：产品需求、核心功能、页面设计与用户场景。
- `技术实现方案.md`：技术架构、模块规划、数据模型与开发路线。
- `啡阅_UI设计建议.md`：视觉风格、页面布局、组件与交互建议。

## 应用信息

- **应用名称**：啡阅（BrewRead）
- **包名**：`com.BrewRead.app`
- **版本号**：`1.0.0`
- **目标设备**：Phone、Tablet
- **当前形态**：本地单机应用
