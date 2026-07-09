我当前处于 Plan 模式，无法直接编辑工作区文件。但我会把完整计划保存到会话记忆中，同时输出 Markdown 内容供你复制到 TODO.md。

Created memory file [](file:///c%3A/Users/%E4%BA%BA/AppData/Roaming/Code/User/workspaceStorage/98c11c1dfef667ca4918063440b1f531/GitHub.copilot-chat/memory-tool/memories/NGY2Y2VkMjQtZWE1Mi00OWEzLWE0NTktMGZkNmUxYjQ3Mjc4/plan.md)

计划已保存到会话记忆中。以下是可以直接复制到 TODO.md 的完整内容：

---

```markdown
# Phytoscope 整合报告 — 实现计划

## 一、整体架构

```
render_full_report.py          ← 主入口
    │
    ├─ collectors/              ← 数据收集层（8个模块）
    │   ├── utils.py           通用函数
    │   ├── overview.py        Data: 项目元信息
    │   ├── cluster.py         Computation: 聚类 UMAP
    │   ├── metaneighbor.py    Computation: MetaNeighbor 热图
    │   ├── dea.py             Computation: DEA 表格
    │   ├── enrich.py          Computation: 富集
    │   ├── integration.py     Computation: 整合评估
    │   ├── annotation.py      Computation: 注释
    │   └── dotplot.py         Computation: Dotplot
    │
    ├─ templates/
    │   ├── base.html          骨架 + 全局 CSS/JS + 粘性导航栏
    │   └── blocks/
    │       ├── overview.html
    │       ├── cluster.html
    │       ├── metaneighbor.html
    │       ├── dea.html
    │       ├── enrich.html
    │       ├── integration.html
    │       ├── annotation.html
    │       ├── dotplot.html
    │       └── interpretation.html
    │
    └─ phytoscope_full_report.html  ← 最终输出
```

## 二、各模块数据源与动态发现

| # | 模块 | glob 模式 | 展示方式 |
|:--:|------|---------|---------|
| 1 | **Overview** | (命令行参数) | 混合模式表单：Python预填 + 用户编辑 + localStorage |
| 2 | **Cluster** | `cluster/CHOIR_*_DimPlot.png` | 导航栏切换条件（ctrl/stim/...任意数量），可下载PNG |
| 3 | **MetaNeighbor** | `metaneighbor/*metaNeighbor*.csv` | Plotly 热图 (RdBu_r, zmin=0.2) |
| 4 | **DEA** | `utils/seurat/DEA/allmarkers_*.csv` | DataTables 全量列 + CSV导出（仅allmarkers） |
| 5 | **Enrich** | `anno/enrich/cluster_*_enrich.png` + `*_enrich_results.txt` | Tabs切换各cluster + DataTables表格 |
| 6 | **Integration** | `integration_scib/png/*.png` | 导航栏（方法）+ 折叠面板（key），缺失显示占位 |
| 7 | **scIB** | `integration_scib/scib/*.png` | 嵌入 + 下载PNG |
| 8 | **sctype** | `anno/sctype/*_sctype.png` + `*_sctype_prob_clusters.csv` | 左侧UMAP + 右侧Plotly热图 |
| 9 | **singler** | `anno/singler/*_singler.png` + `*_singler_prob_clusters.csv` | 同上 |
| 10 | **SAMap** | `anno/SAMap_result/DimPlot_*.png` + `MappingTable_cross.csv` | 同上 |
| 11 | **Dotplot** | `utils/summary/dotplot.png` | 嵌入 + 下载PNG |
| 12 | **Interpretation** | 前端API调用 | 流式输出AI解读 |

## 三、动态文件发现策略（无硬编码）

- 所有文件名通过 `glob` 模式匹配，不写死具体前缀（如 `Sp_`）
- Cluster: `glob("cluster/CHOIR_*_DimPlot.png")`，从文件名提取条件名
- MetaNeighbor: `glob("metaneighbor/*metaNeighbor*.csv")`
- DEA: `glob("utils/seurat/DEA/allmarkers_*.csv")`，只取allmarkers
- Enrich 图: `glob("anno/enrich/cluster_*_enrich.png")`，自然排序
- Enrich 表: `glob("anno/enrich/*_enrich_results.txt")`，取all_subclusters那个
- Integration png: `glob("integration_scib/png/*.png")`，`rsplit("_", 1)` 解析 method/key
- scIB: `glob("integration_scib/scib/*.png")[0]`
- sctype UMAP: `glob("anno/sctype/*_sctype.png")`
- sctype 热图: `glob("anno/sctype/*_sctype_prob_clusters.csv")`
- singler UMAP: `glob("anno/singler/*_singler.png")`
- singler 热图: `glob("anno/singler/*_singler_prob_clusters.csv")`
- SAMap UMAP: `glob("anno/SAMap_result/DimPlot_*.png")`
- SAMap 热图: `anno/SAMap_result/MappingTable_cross.csv`
- Dotplot: `utils/summary/dotplot.png`

## 四、Annotation 子方法布局

每个子方法（sctype/singler/SAMap）用 Tabs 切换，布局为左右分栏：

```
┌─────────────────────────────────────────┐
│  Tabs: [sctype] [singler] [SAMap]       │
├─────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────────┐ │
│  │  UMAP PNG    │  │  Plotly 热图      │ │
│  │  (flex:1)    │  │  (flex:1)         │ │
│  │  行=细胞类型  │  │  行=细胞类型      │ │
│  │  + 下载按钮  │  │  列=cluster       │ │
│  └──────────────┘  └──────────────────┘ │
└─────────────────────────────────────────┘
```

热图用 `px.imshow`，`pio.to_json()` 序列化，前端 CDN Plotly.js 渲染。

## 五、技术选型

| 层面 | 选择 |
|------|------|
| 模板引擎 | Jinja2 `{% include %}` |
| CSS 框架 | Bootstrap 5.3 CDN |
| 表格 | DataTables CDN (搜索/排序/分页/CSV导出) |
| 热图 | Plotly.js 2.35 CDN + `pio.to_json()` |
| 图片 | Base64 嵌入 |
| AI 解读 | 前端 fetch → API 流式输出 |
| 数据持久化 | localStorage |

## 六、实现阶段

| Phase | 内容 |
|:--:|------|
| 1 | 骨架搭建：`collectors/utils.py` + `templates/base.html` + `render_full_report.py` |
| 2 | 迁移已有模块：Enrich / Integration / MetaNeighbor → collectors/ + blocks/ |
| 3 | 新增 Cluster（动态条件导航栏，适配任意数量） |
| 4 | 新增 DEA（DataTables 单表 allmarkers） |
| 5 | 新增 Annotation（sctype/singler/SAMap 三合一 Plotly 热图） |
| 6 | 新增 Dotplot + Overview 表单 |
| 7 | Interpretation 前端 API |
| 8 | 边界条件（文件缺失/CSV为空/glob无匹配 → 占位提示） |

## 七、边界条件

| 场景 | 处理 |
|------|------|
| 文件/目录不存在 | `os.path.exists` → 空dict → `{% if %}` 占位 |
| CSV为空 | `{headers:[], rows:[]}` → 不渲染表格 |
| glob无匹配 | 返回空列表 → 模板显示"无数据" |
| 某方法无某key | Integration折叠面板显示"该维度无数据" |
| Plotly JSON为空 | 前端判断不渲染 |

## 八、最终文件清单

```
jinja2-2/
├── render_full_report.py          ← 新建
├── collectors/                    ← 新建
│   ├── __init__.py
│   ├── utils.py
│   ├── overview.py
│   ├── cluster.py
│   ├── metaneighbor.py            ← 重构自 metaneighbor.py
│   ├── dea.py
│   ├── enrich.py                  ← 重构自 enrich.py
│   ├── integration.py             ← 重构自 integration_scib.py
│   ├── annotation.py
│   └── dotplot.py
├── templates/                     ← 新建
│   ├── base.html
│   └── blocks/
│       ├── overview.html
│       ├── cluster.html
│       ├── metaneighbor.html
│       ├── dea.html
│       ├── enrich.html
│       ├── integration.html
│       ├── annotation.html
│       ├── dotplot.html
│       └── interpretation.html
├── phytoscope_full_report.html    ← 输出
├── enrich.py                      ← 保留不动
├── integration_scib.py            ← 保留不动
└── metaneighbor.py                ← 保留不动
```
```

---

请将以上内容复制到 TODO.md 中。计划就绪后告诉我，就可以开始 Phase 1 实现了。