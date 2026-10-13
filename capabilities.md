# PRDay — 配置文档

生成时间：2026-10-13

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强功能**。不配置这些项，App 下载后仍可正常使用所有核心功能（训练计划、打卡、PR 记录、Streak、热风险旗、AI 端侧问答）。配置后获得完整体验（订阅收款、家长周报云同步、跨设备同步）。

### 🔵 IAP StoreKit 订阅产品（必须配置，否则无法收款）

**影响功能**：不创建订阅产品，用户点击订阅会提示"无法加载购买选项"；Pro 功能无法解锁变现。

**已自动配置部分**：
- ✅ StoreKit 2 代码完成（PurchaseManager.swift，产品 ID 与 price.md 一致）
- ✅ 本地测试用 `PRDay/PRDay.storekit` 已创建（含 7 天试用），Xcode 运行即可测试完整订阅流程
- ✅ Paywall 已含隐私政策/条款链接与自动续订披露

**请手动配置（仅你能访问 App Store Connect）**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → PRDay（若尚未创建 App，先以 Bundle ID `com.zzoutuo.PRDay` 创建）
2. 左侧 **功能（Features）** → **App 内购买项目 / 订阅（Subscriptions）**
3. 创建订阅组 **PRDay Pro**，然后在组内创建两个产品：

| 产品 | Reference Name | Product ID | 价格 | 试用 |
|------|---------------|-----------|------|------|
| 月付 | PRDay Pro Monthly | `com.zzoutuo.PRDay.pro.monthly` | $7.99/月 | 7天免费试用（Free Trial） |
| 年付 | PRDay Pro Annual | `com.zzoutuo.PRDay.pro.yearly` | $49.99/年 | 7天免费试用（Free Trial） |

4. 每个产品的 Display Name / Description 从 `price.md` 复制：
   - 月付描述：`Adaptive plans, parent reports, all PR tools`
   - 年付描述：`A full year of adaptive training and reports`
5. 年付设为组内**推荐**（App 内 Paywall 已默认选中年付）
6. ⚠️ 本地化语言先只加 English (U.S.)
7. 创建后等待 1-2 小时生效，再提交 App 审核

---

### 🟡 CloudKit Schema 上线 Production（家长周报跨设备/家庭共享增强）

**增强功能**：多设备同步 + 家长周报通过 CKShare 共享到家长设备
**不配置的影响**：App 完全正常（本地 SwiftData 优先），仅单设备使用、家长共享不可用
**当前状态**：CloudKit 容器 `iCloud.com.zzoutuo.PRDay` 已在开发者门户自动注册（真机签名验证通过），SwiftData 已配 `cloudKitDatabase: .automatic`

**配置步骤**：
1. 真机安装 App 并登录 iCloud，跑一遍核心流程（产生 SwiftData 上云记录）
2. 打开 [CloudKit Console](https://icloud.developer.apple.com) → 选择容器 `iCloud.com.zzoutuo.PRDay`
3. **Deploy Schema Changes to Production...** → 确认部署（或让 AI 通过浏览器自动化完成，无需你手动操作）
4. 家长共享的 `WeeklyReport`（自定义 CKRecord）位于 `PRDayFamilyZone`，首次"创建家庭共享"后自动出现在 Development 环境，同样随 Schema 部署上线

---

### 🟢 App Store Connect 审核信息配置（防拒审，提交前必须）

**影响功能**：不配置会导致 Guideline 2.1(a)（App 完整性）拒审风险

**配置步骤**：
1. App Store Connect → 你的 App → **App Review Information**
2. **Notes** 字段：粘贴项目根目录 `app_review_info.md` 的 "Review Notes" 全部内容（已含 AI BYO 模式、HealthKit、WeatherKit、青少年安全、订阅测试说明）
3. ⚠️ **WeatherKit 附加要求（Guideline 5.2.5）**：Notes 中需附一段**真机录屏**，展示 App 内天气归属位置（Today 天气卡右下角" Apple Weather"、Me→Legal 的"Weather — Data Source"行、PR 分享卡）
4. **Privacy Policy URL**：`https://asunnyboy861.github.io/PRDay/privacy.html`
5. **Terms of Use (EULA)** 字段或描述内：`https://asunnyboy861.github.io/PRDay/terms.html`
6. Support URL：`https://asunnyboy861.github.io/PRDay/support.html`

**`app_review_info.md` 位置**：项目根目录（PHASE 4+5 已生成）

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| iCloud / CloudKit | 容器 `iCloud.com.zzoutuo.PRDay`，真机签名验证通过，门户已注册（Dev+Prod） | ✅ 已配置 |
| Push Notifications | aps-environment=development 已签名生效 | ✅ 已配置 |
| HealthKit | entitlement 已注册，UI 已按 Guideline 2.5.1 标识（含 Learn More + InfoView） | ✅ 已配置 |
| Background Modes | remote-notification（Info.plist） | ✅ 已配置 |
| WeatherKit | App ID 服务随自动签名注册，Apple Weather 归属组件已内置（Guideline 5.2.5 合规） | ✅ 已配置 |
| In-App Purchase | 默认能力，StoreKit 2 代码 + 本地 .storekit 测试配置 | ✅ 已配置 |
| 隐私清单 | PrivacyInfo.xcprivacy（UserDefaults CA92.1 + FileTimestamp C617.1） | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | `https://msg.calcs.top/api/feedback`（Cloudflare Workers），ContactSupportView 已内置 7 主题宫格 | ✅ 已部署 |
| GLM 云 AI 代理 | Worker `cramjam-api.calcs.top`，appId=`prday` ↔ `com.zzoutuo.PRDay` 已入 D1 白名单；E2E 200/400/401/405 全通过；devKey 在 gitignored `PRDay/GLMProxySecret.txt` 且 Release 构建已排除 | ✅ 已配置 |
| GitHub Pages | Landing + Support + Privacy + Terms 已部署 | ✅ 已上线 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | MVVM：20 项主功能全部实现（WBGT 引擎/计划引擎/配速引擎/Streak 引擎均有单测，27/27 通过） | ✅ 已完成 |
| 订阅 | StoreKit 2 + 响应式 isPro 绑定 + Paywall 法律链接 | ✅ 已完成 |
| AI 模块 | Apple Intelligence 端侧默认 + BYO 多供应商（Keychain）+ GLM Worker + 端侧兜底 | ✅ 已完成 |
| 联系客服 | 7 主题宫格 + 必填校验 + 隐私文案 + 成功/失败反馈 | ✅ 已完成 |
| App Review 信息 | app_review_info.md（审核员指引） | ✅ 已完成 |

### 💡 使用提示（非开发者配置，App 内操作即可）

**AI 功能**：App 默认使用 Apple Intelligence（设备端，免费无需配置）。不支持的设备上自动降级为离线模板教练，永不定死。用户也可在 **Me → AI Settings (BYO Key)** 输入自己的 API Key（GLM/OpenAI/Claude/Gemini/DeepSeek/自定义）解锁无限 AI——这是用户操作，非开发者配置。

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/PRDay | ✅ 已推送 |
| GitHub Pages | https://asunnyboy861.github.io/PRDay/ | ✅ 已上线 |
| App Store 元数据 | keytext.md 已生成（15/15 验证通过，保密不入库） | ✅ 已完成 |
| 定价配置 | price.md（订阅 $7.99/月、$49.99/年、7天试用） | ✅ 已完成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据。"Auto-Configured" 与 "Manual Required" 内容已重组到上方 Section 一/二。

### Analysis

基于指南与 us.md 关键词检测：
- "CloudKit (sync + CKShare family sharing)" → iCloud/CloudKit
- "Sunday 7PM push / daily push / red-flag push" → Push Notifications
- "WeatherKit" → WeatherKit 服务
- "HealthKit (optional read-only)" → HealthKit
- "Background remote-notification" → Background Modes
- "Camera for form videos / Location for weather" → usage strings
- "RevenueCat + StoreKit 2" → IAP（实现取 StoreKit 2 原生，零第三方依赖，符合 skill Apple-native-first 标准）

### No Configuration Needed

- App Groups（无扩展）、Apple Watch（指南未要求）、Siri、Sign in with Apple（未要求）

### Verification

- 模拟器构建：BUILD SUCCEEDED
- 真机签名验证（generic/platform=iOS + allowProvisioningUpdates）：PASSED，签名内 entitlements 实测含 aps-environment / healthkit / iCloud 容器（Dev+Prod）
- DEVELOPMENT_TEAM：JP4TN5PTS3（项目级，全部 target 继承）
- PrivacyInfo.xcprivacy：App target 已覆盖
- 签名模式：全自动，无 DEFERRED 状态
