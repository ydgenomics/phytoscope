# AI 结果解读 — 使用指南

## 概述

`phytoscope_full_report.html` 底部的 **💡 AI Interpretation** 模块，通过调用 **Kimi (Moonshot) API**，自动综合报告中所有分析模块的数据，生成结构化的生物学解读报告。

---

## 前置条件

| 必要条件 | 说明 |
|---------|------|
| **网络连接** | 需要访问 `api.moonshot.cn` |
| **Kimi API Key** | 在 [Moonshot 平台](https://platform.moonshot.cn) 注册获取 |
| **浏览器** | Chrome / Edge / Firefox 现代版本 |

> API Key 存储在浏览器 `localStorage` 中，不会上传到第三方服务器。

---

## 使用步骤

1. 用浏览器打开 `phytoscope_full_report.html`
2. 在顶部导航栏填写 **Overview** 表单（物种、组织、项目背景）
3. 滚动到底部 **💡 AI Interpretation** 区域
4. 在左侧 **API 设置** 卡片中输入 Kimi API Key（格式：`sk-...`）
5. （可选）点击「✏️ 编辑」展开系统提示词面板，根据需要调整
6. 点击 **🤖 生成 AI 解读** 按钮
7. 等待流式输出完成（约 20-60 秒）

---

## 数据来源

AI 解读的 User Prompt 由前端 JavaScript 自动构建，整合以下模块信息：

| 数据源 | 收集内容 |
|--------|---------|
| **Overview 表单** | 物种名、组织、项目背景 |
| **Clustering** | 聚类方法（CHOIR）、实验条件 |
| **Integration** | 所有整合方法名、评估维度 |
| **MetaNeighbor** | 是否完成可重复性分析 |
| **DEA** | All Markers 表格的列名结构 |
| **Enrichment** | Cluster 数量、表格列名、前 5 行数据 |
| **Annotation** | 可用注释方法（ScType / SingleR / SAMap） |

---

## 系统提示词（System Prompt）

内嵌于 HTML 报告中，用户可编辑。默认提示词定义了：

- **角色**：植物单细胞转录组学专家
- **输出格式**：Markdown，6 段结构化报告
- **分析任务**：
  1. 细胞类型图谱与 Marker 基因
  2. 注释方法比较（ScType vs SingleR vs SAMap）
  3. 整合方法评估与推荐
  4. GO/KEGG 通路生物学意义
  5. 结论与实验验证建议

---

## 技术实现

| 层级 | 技术 |
|------|------|
| **API 端点** | `https://api.moonshot.cn/v1/chat/completions` |
| **模型** | `moonshot-v1-8k`（默认） |
| **认证** | `Authorization: Bearer {api_key}` |
| **传输** | Server-Sent Events (SSE) 流式 |
| **渲染** | 纯文本逐字追加到 `<div>` |
| **持久化** | API Key 存 `localStorage` |

```javascript
// 核心调用流程
async function runAIInterpretation() {
    const systemPrompt = document.getElementById('ai-system-prompt').value;
    const userPrompt = buildUserPrompt();  // 自动拼接所有模块数据

    await callKimiAPI(systemPrompt, userPrompt,
        onChunk,  // 流式更新 UI
        onDone,   // 完成回调
        onError   // 错误处理
    );
}
```

---

## 故障排查

| 症状 | 可能原因 | 解决 |
|------|---------|------|
| `API error (401)` | API Key 无效或过期 | 检查 Key 格式 `sk-...` |
| `API error (429)` | 调用频率超限 | 等待 1 分钟后重试 |
| `Network error` | 网络不通 | 检查是否能访问 `api.moonshot.cn` |
| 输出内容不相关 | 提示词泛化 | 点击「编辑」调整 System Prompt |
| 页面无响应 | CDN 资源加载失败 | 检查网络，刷新页面 |

---

## 与独立 API 工具的关系

`jinja2-2/api/` 目录下有一个独立的 **Plant-scOmics Narrator** 工具（`api.html`），它是一个植物文献综述智能体，与本报告的 Interpretation 模块共享相同的 Kimi API 调用模式，但用途不同：

| 特性 | Interpretation (报告中) | api.html (独立工具) |
|------|:--:|:--:|
| 用途 | 解读分析结果 | 文献综述生成 |
| 数据来源 | 报告内各模块 | 用户手动输入物种/组织 |
| 模型 | moonshot-v1-8k | moonshot-v1-auto (联网) |
| 输出 | 流式逐字 | 一次性返回 |
| 运行方式 | 直接打开 HTML | `start.bat` 启动本地服务器 |
