# 常见问题 (FAQ)

## 报告生成

### Q: 报告太大（~35MB），如何缩小？

35MB 是正常的（主要来自 Base64 图片）。减小方案：

1. **降低 PNG 分辨率** — 在生成分析结果时控制图片尺寸
2. **使用 JPEG 替代 PNG** — 修改 `image_to_base64` 为 JPEG 编码
3. **外部引用图片** — 不嵌入 Base64，改为 `<img src="file:///...">`（但失去便携性）

### Q: 某模块数据缺失，报告会报错吗？

不会。每个 collector 检查文件是否存在，缺失时返回 `has_data: False`，模板显示占位提示而不渲染内容。

### Q: 如何只生成部分模块？

修改 `base.html`，注释掉不需要的 `{% include "blocks/xxx.html" %}` 行。

### Q: 能否批量生成多个项目的报告？

```bash
# 写个 shell 脚本
for dir in /data/project_*/output; do
    species=$(basename $(dirname $dir))
    python render_full_report.py \
        --results_dir "$dir" \
        --species "$species" \
        --tissue "shoot" \
        --output "report_${species}.html"
done
```

---

## 模板

### Q: 为什么不用 Extends/Block 模式？

原版 `jinja2/` 用 `{% extends "base.html" %}` + `{% block %}` 的 Bootstrap Tab 切换。但 `jinja2-2` 改为锚点滚动 + 单页布局，`{% include %}` 更简单，每个 block 完全独立。

### Q: 如何自定义 Bootstrap 主题？

修改 `base.html` 中的 Bootstrap CDN 链接，或在内嵌 `<style>` 中覆盖变量。例如换用 Bootswatch 主题：

```html
<link href="https://cdn.jsdelivr.net/npm/bootswatch@5.3.3/dist/flatly/bootstrap.min.css" rel="stylesheet">
```

---

## API / AI 解读

### Q: 是否支持其他 AI 提供商？

当前只实现 Kimi (Moonshot)。切换到其他 API 需要：

1. 修改 `callKimiAPI()` 中的 endpoint URL
2. 调整请求体格式（不同 API 的 messages 结构不同）
3. 调整 SSE 解析逻辑（data 字段名可能不同）

OpenAI 兼容的 API（如 DeepSeek、通义千问）通常只需改 URL 和 model 名。

### Q: API Key 存储在哪里？

浏览器 `localStorage`，key 名为 `phytoscope-api-key`。清除浏览器数据会丢失。

### Q: 解读结果不符合预期？

1. 编辑 System Prompt，加入组织特异性知识
2. 确保 Overview 表单填写了详细的背景信息
3. 尝试 `moonshot-v1-32k` 模型（更大上下文窗口）

---

## 开发

### Q: 如何调试单个 collector？

```python
# 在 Python 中直接测试
import sys; sys.path.insert(0, '.')
from collectors.enrich import collect_enrich
import json
result = collect_enrich('/path/to/anno/enrich')
print(json.dumps(result, indent=2, ensure_ascii=False)[:500])
```

### Q: glob 匹配不到文件？

检查 `safe_glob()` 中的模式是否正确：

```python
from collectors.utils import safe_glob
# 在项目目录下运行
print(safe_glob('../../data/output/cluster/CHOIR_*_DimPlot.png'))
```

### Q: Plotly 热图在标签页中不显示？

Plotly 在 `display: none` 容器中初始化时尺寸为 0。解决方案：

1. 确保初始显示的 tab 的 content 有 `active` 类（`display: block`）
2. 切换后再调用 `Plotly.relayout(divId, {})` 触发重绘
3. 或使用 `Plotly.Plots.resize(divId)`

### Q: DataTables 表格报错 "Cannot reinitialize"？

同一个 table ID 被初始化两次。检查是否有重复的 `$(document).ready()` 调用。

---

## 部署与分发

### Q: 能否部署到 Web 服务器？

直接上传 `.html` 文件到任意静态服务器（Nginx、Apache、GitHub Pages）即可。所有资源 CDN 加载，无需后端。

### Q: 内网环境如何使用？

1. 在内网部署 CDN 镜像（或下载所有 JS/CSS 到本地）
2. 修改 `base.html` 中的 CDN 链接指向内网地址
3. 或将所有 JS/CSS 内联到 HTML 中

### Q: 兼容哪些浏览器？

| 浏览器 | 最低版本 | 备注 |
|--------|:--:|------|
| Chrome | 90+ | 完全支持 |
| Edge | 90+ | 完全支持 |
| Firefox | 90+ | 完全支持 |
| Safari | 14+ | 部分 CSS 效果略有差异 |
| IE | ❌ | 不支持 |
