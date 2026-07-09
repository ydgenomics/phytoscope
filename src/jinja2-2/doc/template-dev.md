# 模板开发指南

## 模板架构

```
templates/
├── base.html          ← 骨架模板（CDN、CSS、导航栏、全局 JS）
└── blocks/            ← 区块模板（每个模块一个文件）
    ├── overview.html
    ├── cluster.html
    ├── ...
    └── interpretation.html
```

`base.html` 通过 `{% include "blocks/xxx.html" %}` 组装所有模块。

---

## 全局 CSS 类参考

| 类名 | 用途 |
|------|------|
| `.section-container` | 模块容器（白色圆角卡片） |
| `.section-title` | 模块标题（蓝色左边框） |
| `.section-subtitle` | 模块副标题（灰色小字） |
| `.method-navbar` | 水平导航栏（flex + 底部边框） |
| `.nav-btn` / `.nav-btn.active` | 导航按钮 / 选中态 |
| `.tab-btn` / `.tab-btn.active` | Tab 按钮 / 选中态 |
| `.tab-content` / `.tab-content.active` | Tab 内容区 / 显示 |
| `.workspace-row` | 左右分栏 flex 布局 |
| `.workspace-left` / `.workspace-right` | 分栏左右区 |
| `.display-img` | 展示图片（max-width + object-fit） |
| `.download-btn` | 绿色下载按钮 |
| `.plotly-container` | Plotly 热图容器 |
| `.placeholder-note` | 无数据占位提示（虚线边框） |
| `.scrollable-cell` | 表格超长单元格（省略号 + title） |

---

## 交互模式参考

### 模式 1：Tabs 切换

用于多张图/表之间切换。参考 `enrich.html`：

```html
<!-- 按钮 -->
<div class="tab-buttons">
    {% for item in data.items %}
    <button class="tab-btn {% if loop.first %}active{% endif %}"
            onclick="switchTab(event, 'tab-{{ loop.index0 }}')">
        {{ item.label }}
    </button>
    {% endfor %}
</div>

<!-- 内容 -->
{% for item in data.items %}
<div id="tab-{{ loop.index0 }}" class="tab-content {% if loop.first %}active{% endif %}">
    <!-- 内容 -->
</div>
{% endfor %}

<script>
function switchTab(evt, tabId) {
    // 隐藏所有
    document.querySelectorAll('#section-xxx .tab-content')
        .forEach(tc => tc.classList.remove('active'));
    document.querySelectorAll('#section-xxx .tab-btn')
        .forEach(btn => btn.classList.remove('active'));
    // 显示目标
    document.getElementById(tabId).classList.add('active');
    evt.currentTarget.classList.add('active');
}
</script>
```

### 模式 2：data-* 属性切换（推荐）

更稳定，不依赖 ID 拼接。参考 `integration.html`、`annotation.html`：

```html
<!-- 按钮用 data-* 标记 -->
<button data-mymodule-key="foo" onclick="switchKey('foo')">Foo</button>

<!-- 内容也用 data-* 标记 -->
<div data-mymodule-key="foo" class="tab-content active">...</div>

<script>
function switchKey(keyId) {
    // 清除所有 active
    document.querySelectorAll('[data-mymodule-key]').forEach(el =>
        el.classList.remove('active'));
    // 激活目标
    document.querySelector('[data-mymodule-key="' + keyId + '"].tab-content')
        .classList.add('active');
    document.querySelector('[data-mymodule-key="' + keyId + '"].tab-btn')
        .classList.add('active');
}
</script>
```

### 模式 3：Plotly 热图渲染

```html
<div id="my-heatmap" class="plotly-container"></div>

<script>
(function() {
    var graphData = {{ data.heatmap_json | safe }};
    if (graphData && graphData.data && graphData.data.length > 0) {
        Plotly.newPlot('my-heatmap', graphData.data, graphData.layout, {
            responsive: true,
            displayModeBar: true
        });
    }
})();
</script>
```

### 模式 4：DataTables 表格

```html
<table id="myTable" class="display cell-border hover stripe">
    <thead><tr>{% for h in headers %}<th>{{ h }}</th>{% endfor %}</tr></thead>
    <tbody>
        {% for row in rows %}
        <tr>{% for cell in row %}<td>{{ cell }}</td>{% endfor %}</tr>
        {% endfor %}
    </tbody>
</table>

<script>
$(document).ready(function() {
    $('#myTable').DataTable({
        pageLength: 15,
        lengthMenu: [10, 15, 30, 50, 100, -1],
        scrollX: true,
        dom: 'Bfrtip',
        buttons: [{ extend: 'csvHtml5', text: '📊 导出 CSV' }],
        language: {
            search: '🔍 搜索:',
            paginate: { previous: '上一页', next: '下一页' }
        }
    });
});
</script>
```

---

## Jinja2 语法速查

| 语法 | 用途 |
|------|------|
| `{% if var %}` | 条件判断 |
| `{% for item in list %}` | 循环 |
| `{% include "blocks/xxx.html" %}` | 引入子模板 |
| `{{ var }}` | 输出变量（自动转义 HTML） |
| `{{ var \| safe }}` | 输出原始 HTML/JS（如 Plotly JSON） |
| `{{ var \| tojson }}` | 转为 JSON（给 JS 使用） |
| `{% if loop.first %}` | 循环第一次 |
| `{% if loop.index0 %}` | 循环索引（0-based） |
| `{{ list \| length }}` | 列表长度 |
| `{{ list \| map(attribute='x') \| list \| tojson }}` | 提取属性为 JSON 数组 |

---

## 常见踩坑

| 问题 | 原因 | 解决 |
|------|------|------|
| `{% macro %}` 在 `{% if %}` 内不工作 | Jinja2 bug | 改用内联 HTML 替代 macro |
| `dict.keys` 冲突 | Jinja2 中 `.keys` 被认作方法 | 用 `key_list` 等其他字段名 |
| Plotly 热图不显示 | JSON 未用 `\| safe` | 加 `\| safe` 过滤器 |
| DataTables 不初始化 | jQuery 或 DataTables JS 未加载 | 检查 CDN 链接 |
| Tab 切换后热图错位 | Plotly 在隐藏容器中初始化 | 在显示后再 `Plotly.relayout` |

---

## 样式自定义

所有样式集中在 `base.html` 的 `<style>` 标签中。CSS 变量：

```css
:root {
    --primary: #2c3e50;    /* 主色调（深蓝灰） */
    --accent: #3498db;     /* 强调色（蓝色） */
    --success: #2ecc71;    /* 成功/下载（绿色） */
    --bg: #f5f7fa;         /* 背景色 */
    --card-bg: #ffffff;    /* 卡片背景 */
    --text: #333333;       /* 文字色 */
    --muted: #95a5a6;      /* 次要文字 */
    --border: #e2e8f0;     /* 边框色 */
}
```

修改这些变量即可全局换肤。
