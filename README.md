# 🌱 Phytoscope

> **植物单细胞自动化注释流水线** — Let plant cell annotation more easy!

端到端方案：从聚类、多方法注释、批次整合评估，到交互式 HTML 报告 + AI 解读。

---

## 快速开始

```bash
# 1. 安装依赖
pip install jinja2 pandas plotly

# 2. 生成报告
cd src/jinja2-2/
python render_full_report.py \
    --results_dir ../../data/output \
    --species "Sedum plumbizincicola" \
    --tissue "shoot" \
    --output phytoscope_full_report.html

# 3. 浏览器打开 phytoscope_full_report.html
```

详细参数见 `src/jinja2-2/README.md`。

---

## 项目结构

```
phytoscope/
├── src/                          ← 分析脚本
│   ├── cluster/                  ← CHOIR 聚类
│   ├── anno/                     ← 注释 (ScType / SingleR / SAMap) + 富集
│   ├── integration_scib/         ← 多方法整合 + scIB 评估
│   ├── metaneighbor/             ← MetaNeighbor 可重复性
│   ├── utils/                    ← 工具 (格式转换 / 预处理 / DEA)
│   └── jinja2-2/                 ← 🎯 报告生成器 (整合所有结果 → 单文件 HTML)
│       ├── render_full_report.py ← 主入口
│       ├── collectors/           ← 数据收集层
│       ├── templates/            ← Jinja2 模板
│       └── doc/                  ← 使用与开发文档
├── data/
│   ├── input/                    ← 输入数据
│   └── output/                   ← 各模块输出 (--results_dir 指向这里)
└── doc/                          ← 项目设计文档
```

---

## 流水线概览

```
┌─────────────┐    ┌──────────────────────────────┐    ┌──────────────────┐
│  📦 Data     │ →  │  ⚙️ Computation              │ →  │  🔍 Interpretation │
│  项目信息     │    │                              │    │                    │
│  参考数据     │    │  ① CHOIR 聚类                │    │  Jinja2 单文件报告  │
│  Marker基因  │    │  ② Preprocess + AllMarkers   │    │  • 9 个交互模块    │
└─────────────┘    │  ③ GO/KEGG 富集              │    │  • Plotly 热图     │
                   │  ④ MetaNeighbor 对齐          │    │  • DataTables 表格  │
                   │  ⑤ Integration + scIB 评估    │    │  • 图片下载         │
                   │  ⑥ ScType/SingleR/SAMap 注释  │    │  • Kimi AI 解读    │
                   └──────────────────────────────┘    └──────────────────┘
```

---

## 报告模块

| # | 模块 | 内容 |
|:--:|------|------|
| 1 | **Overview** | 可编辑表单（物种/组织/背景） |
| 2 | **Clustering** | CHOIR UMAP（动态条件导航） |
| 3 | **MetaNeighbor** | AUROC 交互热图 |
| 4 | **DEA** | All Markers 差异基因表 |
| 5 | **Enrichment** | GO/KEGG 富集图 + 表格 |
| 6 | **Integration** | 多方法 UMAP + scIB 评估 |
| 7 | **Annotation** | ScType / SingleR / SAMap 热图 |
| 8 | **Dotplot** | Marker 表达点图 |
| 9 | **AI Interpretation** | Kimi API 流式解读 |

---

## 关键特性

- **零文件依赖** — 所有图片 Base64 嵌入，单文件即可分享
- **动态发现** — glob 模式匹配文件，换项目无需改代码
- **多证据交叉验证** — 三种注释方法 + MetaNeighbor 对齐
- **AI 辅助解读** — Kimi API 流式生成生物学结论
- **离线可用** — CDN 资源加载后无需服务器

---

## 文档

| 文档 | 说明 |
|------|------|
| `src/jinja2-2/README.md` | 报告生成器使用说明 |
| `src/jinja2-2/doc/architecture.md` | 架构设计 |
| `src/jinja2-2/doc/collector-dev.md` | 如何新增模块 |
| `src/jinja2-2/doc/template-dev.md` | 模板开发指南 |
| `src/jinja2-2/doc/interpretation-guide.md` | AI 解读使用指南 |
| `src/jinja2-2/doc/faq.md` | 常见问题 |
| `PROJECT.md` | 完整项目设计文档 |

