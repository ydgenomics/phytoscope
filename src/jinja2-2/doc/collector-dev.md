# Collector 开发指南

## 概述

Collector 是数据收集层，负责从 `--results_dir` 读取分析输出文件，转换为 Jinja2 模板可用的 Python dict。每个分析模块对应一个 collector。

---

## 快速开始：添加新模块

假设要添加一个 **Violin Plot** 模块。

### Step 1：创建 Collector

```python
# collectors/violin.py

import os
from .utils import image_to_base64, safe_glob, natural_sort_key

def collect_violin(violin_dir):
    """收集 Violin Plot 图片"""
    violin_dir = str(violin_dir)

    # 动态发现所有 violin PNG
    pattern = os.path.join(violin_dir, "*_violin.png")
    pngs = safe_glob(pattern)
    pngs.sort(key=natural_sort_key)

    images = []
    for png in pngs:
        basename = os.path.basename(png)
        gene_name = basename.replace("_violin.png", "")
        b64 = image_to_base64(png)
        if b64:
            images.append({
                "gene": gene_name,
                "b64": b64,
                "filename": basename
            })

    return {
        "has_data": len(images) > 0,
        "images": images
    }
```

### Step 2：创建 Block 模板

```html
<!-- templates/blocks/violin.html -->
<section class="section-container" id="section-violin">
    <h2 class="section-title">🎻 Violin Plots</h2>

    {% if violin.has_data %}
    <div class="tab-buttons">
        {% for img in violin.images %}
        <button class="tab-btn {% if loop.first %}active{% endif %}"
                data-violin-gene="{{ img.gene }}"
                onclick="switchViolinGene('{{ img.gene }}')">
            {{ img.gene }}
        </button>
        {% endfor %}
    </div>

    <div style="text-align:center;">
        <img id="violinViewer" class="display-img"
             src="data:image/png;base64,{{ violin.images[0].b64 }}">
        <br>
        <a id="violinDownload" class="download-btn"
           href="data:image/png;base64,{{ violin.images[0].b64 }}"
           download="{{ violin.images[0].filename }}">📥 下载</a>
    </div>
    {% else %}
    <div class="placeholder-note">⚠️ 未找到 Violin Plot。</div>
    {% endif %}
</section>

{% if violin.has_data %}
<script>
const violinData = {{ violin.images | tojson }};
function switchViolinGene(gene) {
    const item = violinData.find(v => v.gene === gene);
    if (item) {
        document.getElementById('violinViewer').src = 'data:image/png;base64,' + item.b64;
        const dl = document.getElementById('violinDownload');
        dl.href = 'data:image/png;base64,' + item.b64;
        dl.download = item.filename;
    }
    document.querySelectorAll('[data-violin-gene]').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('data-violin-gene') === gene);
    });
}
</script>
{% endif %}
```

### Step 3：注册到主入口

在 `render_full_report.py` 中：

```python
# 1. 导入
from collectors.violin import collect_violin

# 2. 在 context 中收集
context = {
    # ... 其他模块 ...
    "violin": collect_violin(base / "violin"),
}

# 3. 在 base.html 中加入
<!-- base.html 导航栏 -->
<a href="#section-violin">🎻 Violin</a>

<!-- base.html 底部 -->
{% include "blocks/violin.html" %}
```

### Step 4：更新 Interpretation 数据源

在 `interpretation.html` 的 `phytoData` 对象中添加：

```javascript
var phytoData = {
    // ... 其他数据 ...
    violin: {
        has_data: {{ violin.has_data | tojson }},
        gene_count: {{ violin.images | length | tojson }}
    }
};
```

---

## Collector 设计规范

| 规范 | 说明 |
|------|------|
| **返回 dict** | 始终返回 `{"has_data": bool, ...}` |
| **容错** | 文件缺失时 `has_data: False`，不抛异常 |
| **glob 发现** | 用 `safe_glob()` 替代硬编码文件名 |
| **只读文件** | 不修改源文件，只读取和转换 |
| **路径处理** | 使用 `os.path.join()` 确保跨平台 |

---

## 通用工具函数 (`utils.py`)

| 函数 | 用途 |
|------|------|
| `image_to_base64(path)` | PNG → Base64，文件不存在返回 None |
| `read_csv_headers_rows(path, delimiter)` | CSV → (headers, rows) |
| `safe_glob(pattern)` | glob 包装，返回 [] 而非抛异常 |
| `safe_glob_first(pattern)` | 返回第一匹配或 None |
| `natural_sort_key(text)` | 自然排序 key，数字按数值排序 |

---

## 常见数据展示模式

| 数据类型 | 展示方式 | 示例模块 |
|---------|---------|---------|
| **多张 PNG** | Tabs 或导航栏切换 | Cluster, Enrich, Integration |
| **单张 PNG** | 直接嵌入 + 下载 | Dotplot, scIB |
| **矩阵 (CSV)** | Plotly `px.imshow` 热图 | MetaNeighbor, Annotation |
| **表格 (CSV)** | DataTables + CSV 导出 | DEA, Enrich |
| **文本** | Jinja2 直接渲染 | Overview 表单 |
