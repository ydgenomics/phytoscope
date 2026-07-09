# API 配置与使用指南

> 本文档面向 jinja2-2 项目中的 API 集成（Kimi Moonshot）。

---

## 1. 获取 API Key

1. 访问 [Moonshot AI 开放平台](https://platform.moonshot.cn)
2. 注册/登录账号
3. 进入「API Keys」页面
4. 创建新 Key，复制 `sk-...` 开头的字符串
5. **妥善保管**，不要提交到 Git

---

## 2. 在报告中使用

打开 `phytoscope_full_report.html`，滚动到底部：

```
┌──────────────────────────────────────────────────────┐
│ 🔑 API 设置                                          │
│ ┌──────────────────────────────────────────────────┐ │
│ │ Kimi API Key:  [sk-xxxxxxxxxxxxxxxxxxxxx]        │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
│ 🤖 系统提示词                          [✏️ 编辑]     │
│ ┌──────────────────────────────────────────────────┐ │
│ │ 你是一位植物单细胞转录组学专家...                  │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
│ [      🤖 生成 AI 解读       ]                       │
└──────────────────────────────────────────────────────┘
```

API Key 输入后自动保存到浏览器 localStorage，下次打开无需重新输入。

---

## 3. API 调用参数

| 参数 | 值 | 说明 |
|------|-----|------|
| **端点** | `https://api.moonshot.cn/v1/chat/completions` | Kimi 官方 API |
| **模型** | `moonshot-v1-8k` | 8K 上下文，适合 3-5 页分析报告 |
| **认证头** | `Authorization: Bearer {key}` | Bearer Token |
| **stream** | `true` | SSE 流式返回 |
| **temperature** | `0.7` | 适中创造性 |

---

## 4. 流式输出解析

```javascript
const reader = response.body.getReader();
const decoder = new TextDecoder();
let buffer = '';

while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    // 按行分割 SSE 事件
    const lines = buffer.split('\n');
    buffer = lines.pop();
    for (const line of lines) {
        if (line.startsWith('data: ')) {
            const data = line.slice(6).trim();
            if (data === '[DONE]') continue;
            const parsed = JSON.parse(data);
            const chunk = parsed.choices?.[0]?.delta?.content;
            // 累积到 UI
        }
    }
}
```

---

## 5. 错误码参考

| HTTP 状态码 | 含义 | 处理 |
|:--:|------|------|
| **200** | 成功 | — |
| **401** | API Key 无效 | 检查 Key 格式，重新生成 |
| **429** | 速率限制 | 降低调用频率 |
| **500** | 服务器错误 | 重试，联系 Moonshot |
| **503** | 服务过载 | 等待后重试 |

---

## 6. 费用估算

| 模型 | 输入价格 | 输出价格 | 单次解读估算 |
|------|---------|---------|:--:|
| `moonshot-v1-8k` | ¥0.024/1K tokens | ¥0.024/1K tokens | ~¥0.05-0.15 |
| `moonshot-v1-32k` | ¥0.024/1K tokens | ¥0.024/1K tokens | ~¥0.10-0.30 |

> 单次解读约消耗 2000-6000 tokens（含 System Prompt + User Prompt + 输出）。

---

## 7. 切换到其他模型

修改 `localStorage` 中的模型名：

```javascript
// 在浏览器控制台执行
localStorage.setItem('phytoscope-api-model', 'moonshot-v1-32k');
```

然后刷新页面即可使用新模型。
