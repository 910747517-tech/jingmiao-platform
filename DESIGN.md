---
name: 京淼面诊平台
description: 低压力、可追溯的新客快速面诊工作台
colors:
  brand-default: "#b94537"
  brand-dark: "#843128"
  brand-wash: "#fbf1ed"
  ink: "#292522"
  muted: "#746c66"
  line: "#e8e1da"
  white: "#ffffff"
  paper: "#fffdf9"
  ground: "#f3efe9"
  selected: "#171514"
  risk: "#9b5d20"
  risk-wash: "#fff7e8"
  success: "#346b49"
  success-wash: "#eef7f0"
typography:
  headline:
    fontFamily: "PingFang SC, Hiragino Sans GB, Microsoft YaHei, sans-serif"
    fontSize: "clamp(24px, 5vw, 34px)"
    lineHeight: 1.2
    letterSpacing: "-0.02em"
  body:
    fontFamily: "PingFang SC, Hiragino Sans GB, Microsoft YaHei, sans-serif"
    fontSize: "16px"
    lineHeight: 1.55
  label:
    fontFamily: "PingFang SC, Hiragino Sans GB, Microsoft YaHei, sans-serif"
    fontSize: "13px"
    fontWeight: 700
rounded:
  sm: "9px"
  md: "10px"
  lg: "12px"
  panel: "16px"
  pill: "999px"
spacing:
  xs: "8px"
  sm: "10px"
  md: "14px"
  lg: "24px"
  xl: "28px"
components:
  input:
    backgroundColor: "{colors.white}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    padding: "10px 12px"
    height: "46px"
  choice-selected:
    backgroundColor: "{colors.selected}"
    textColor: "{colors.white}"
    rounded: "{rounded.md}"
    padding: "9px 12px"
    height: "46px"
  submit-primary:
    backgroundColor: "{colors.white}"
    textColor: "{colors.brand-dark}"
    rounded: "{rounded.md}"
    padding: "8px 10px"
    height: "46px"
  dashboard-quick-entry:
    backgroundColor: "{colors.brand-default}"
    textColor: "{colors.white}"
    rounded: "{rounded.sm}"
    padding: "8px 13px"
---

# Design System: 京淼新客快速面诊

## Overview

**Creative North Star: “可信的专业面诊纸”**

这是一个 Operate 模式的门店工作台：暖白纸面、克制线框与京淼红建立专业感，大触控选择、清晰分段和固定行动区保证手机现场可用。界面强调“先听懂、先排风险、只确认第一步”，不使用销售式装饰或效果承诺。

**快速 vs 深度：** 快速面诊用于新客首次到店，目标 5–8 分钟，只覆盖基础资料、核心诉求、安全边界、快速观察、初步判断和第一步共识。复杂问题、仪器检测或长期规划进入深度面诊；快速表单已填内容映射到深度表，避免重复询问。两类记录共用客户档案，但以各自原表只读还原，不把快速记录伪装成完整评估。

**Key Characteristics:**

- 手机优先、六段单向流程，桌面端最大内容宽度为 920px。
- 风险提示先于项目建议；最终只突出一个可执行、可复评的起点。
- 门店主色可由租户配置覆盖；其余暖纸中性色保持稳定。

## Colors

品牌红只承担品牌、进度、当前步骤和关键动作；大面积背景使用暖灰与纸白，降低首次面诊压力。风险使用琥珀色系，安全结果使用绿色系，已选选项使用近黑色以获得明确反馈。

**The One Accent Rule.** 单屏只让京淼红承担主导强调；不要再引入第二套高饱和营销色。

## Typography

统一使用系统中文无衬线字体，确保门店设备加载稳定。标题紧凑有权威感，正文保持 16px 与 1.55 行高；13px 粗体用于字段标签，12–14px 用于辅助说明和状态。

**The Plain-Language Rule.** 标题说明任务，辅助文案解释判断边界；不用医疗诊断口吻，也不用套餐代替方案。

## Layout

页面由吸顶品牌栏、滚动进度、英雄说明、吸顶六步导航、分段表单和固定底部行动区组成。桌面端字段使用 2–3 列网格；720px 以下改为单列，选择组最多两列，观察与照片纵向排列。交互目标在触控设备上至少 44px 高，并为底部安全区预留空间。

档案页顶部并列两个入口：“新客快速面诊”为品牌色主入口，“会员深度面诊”为白底次入口；移动端两列等宽。历史记录标签明确显示“新客快速”或“深度面诊”，并在弹层 iframe 中还原对应原表。

## Elevation & Depth

层级以纸面、边线和少量环境阴影表达。主表单使用柔和大阴影；吸顶顶部栏和固定底栏使用方向性阴影提示层级。表单内部保持平整，风险框和结果提示主要依靠色调分层，不叠加卡片阴影。

## Shapes

表单控件和步骤使用 9–10px 圆角，提示框与照片槽使用 12px，主纸面使用 16px；时长标签使用全圆胶囊。圆角温和但不过度软萌，边框始终细而克制。

## Components

### Workflow Navigation

六步横向导航可滚动且吸顶；当前步骤以品牌浅底、品牌描边和粗体标识。页面滚动进度使用 3px 品牌色细条，不代替步骤名称。

### Fields and Choices

输入框高 46px，聚焦时切换品牌描边并出现轻量焦点环。单选和多选以整块触控卡呈现；选中态为近黑底白字，避免与品牌主动作竞争。风险选项置于独立暖琥珀容器，非“以上均无”选择会展开补充说明。

### Action Bar

底栏使用品牌色承载“客户档案”“转深度面诊”“提交到门店”。提交按钮用白底深红字成为最高层级；自动保存状态持续可见。归档模式隐藏提交、升级与档案跳转，只保留只读内容和“导出 PDF”。

### Quick-to-Deep Handoff

“转深度面诊”保留并映射基础资料、主诉、风险、观察、照片、初步结论和第一步方案，再打开完整表单。升级是流程加深，不是另建客户或清空已有深度草稿。

### Archive Integration

快速提交写入 `form_type: new_customer_quick` 和 `form_version: v1`。客户档案据此选择 `new-client.html` 或深度表 `index.html`，通过同源 `postMessage` 注入历史数据；归档页禁用字段、选项和照片交互，并标注“历史快速面诊 · 只读”。

## Do's and Don'ts

### Do:

- **Do** 保持“主诉 → 风险 → 观察 → 判断 → 第一步”的六段顺序。
- **Do** 在复杂、需仪器检测或长期规划时升级深度面诊，并带入已填数据。
- **Do** 在手机端保留 44px 以上触控目标、单列阅读和固定行动区。

### Don't:

- **Don't** 把完整会员规划字段塞回新客快速流程。
- **Don't** 用营销话术、套餐或无法验证的承诺替代专业判断。
- **Don't** 把快速与深度记录合并成同一张通用归档表，或允许历史记录被误编辑。
