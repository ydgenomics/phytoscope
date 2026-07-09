# Phytoscope Report — Jinja2 界面设计计划

> 植物单细胞注释结题报告，单文件自包含 HTML，无需服务器即可在浏览器打开。

---

## 1. 技术选型

| 层面 | 选择 | 理由 |
| ---- | ---- | ---- |
| 模板引擎 | **Jinja2** (Python) | 与 scanpy/Seurat 生态衔接好，条件渲染灵活 |
| CSS 框架 | **Bootstrap 5** (CDN) | 响应式、组件丰富、上手快 |
| 图表 | **Plotly.js** (CDN) | 交互式 UMAP/热图/桑基图/柱状图，一个库全覆盖 |
| 表格 | **DataTables.js** (CDN) | 基因表格需搜索/排序/分页 |
| 图标 | **Font Awesome 6** (CDN) | 模块状态图标 |
| 渲染脚本 | `render_report.py` | 读取各模块输出，注入 JSON 数据到模板，生成 HTML |

---

## 2. 报告页面结构

> **设计原则**：导航栏按项目三层哲学组织 —— Data（数据基础）→ Computation（计算过程）→ Interpretation（生物学解读）。
> 不同于流水线步骤的平铺，三层结构引导读者从"用了什么"到"做了什么"再到"意味着什么"的自然阅读路径。

```text
┌──────────────────────────────────────────────────────────┐
│  NAVBAR:  📦 Data ▼   ⚙️ Computation ▼   🔍 Interpretation │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  ┌─ 📦 Data ────────────────────────────────────────┐   │
│  │  Tab 1: 📊 Overview         项目概览与样本信息      │   │
│  │  Tab 2: 🧬 Markers          标记基因数据库          │   │
│  │  Tab 3: 📈 Reference        参考数据集 & 同源映射    │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌─ ⚙️ Computation ─────────────────────────────────┐   │
│  │  Tab 4: 🔬 Clustering       CHOIR 分群 & UMAP       │   │
│  │  Tab 5: 🔗 MetaNeighbor     批次对齐 & 群合并        │   │
│  │  Tab 6: 🧩 Integration      多方法整合 & scIB 评估   │   │
│  │  Tab 7: 🏷️ Annotation       ScType/SingleR/SAMap   │   │
│  │  Tab 8: 📈 Enrichment       GO/KEGG 富集分析        │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  ┌─ 🔍 Interpretation ──────────────────────────────┐   │
│  │  Tab 9: 🎯 Consensus        多证据统一注释结论       │   │
│  │  Tab 10: 💡 Conclusion      生物学故事 & 讨论        │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### 三层 vs 平铺：设计决策

| 维度 | 平铺式 (旧) | 三层分组 (新) |
| ---- | ----------- | ------------- |
| 导航数量 | 7 个并列 Tab，认知负载高 | 3 个下拉菜单，首屏清爽 |
| 叙事逻辑 | 按流水线执行顺序 | 按 Data → Compute → Interpret |
| 目标读者 | 只有生信人员看得懂 | 生物学家看 Interpretation，生信人员看 Computation |
| 扩展性 | 加模块 = 加 Tab，越来越挤 | 新模块归入对应层即可 |
| 实现复杂度 | 简单 | 需 Bootstrap dropdown + 默认展开当前层 |

### 各层 Tab 详解

#### 📦 Data 层（3 个 Tab）— "我们用了什么"

| Tab | 内容 | 说明 |
| --- | ---- | ---- |
| Overview | 物种/组织/样本卡片、流水线参数、运行状态 | 快速了解实验背景 |
| Markers | 使用的 marker 基因集来源（ScType DB / 文献 curated）、基因数量统计 | 注释的证据基础 |
| Reference | 参考数据集（拟南芥 atlas 等）、同源基因映射结果（diamond blastp 统计） | 跨物种映射的数据基础 |

#### ⚙️ Computation 层（5 个 Tab）— "我们做了什么"

| Tab | 内容 | 说明 |
| --- | ---- | ---- |
| Clustering | CHOIR 聚类参数、交互式 UMAP、cluster 统计 | 细胞分群结果 |
| MetaNeighbor | 批次间 AUC 相似度热图、dendrogram、合并前后对比 | 批次效应处理 |
| Integration | 多方法整合 UMAP 画廊、scIB 雷达图、方法推荐 | 整合质量评估 |
| Annotation | 三方法 UMAP 对比、score 分布、Sankey 一致性图 | 注释中间结果 |
| Enrichment | GO/KEGG 气泡图、通路详情表 | 功能富集结果 |

#### 🔍 Interpretation 层（2 个 Tab）— "这意味着什么"

| Tab | 内容 | 说明 |
| --- | ---- | ---- |
| Consensus | 多证据统一注释表（投票详情 + 置信度）、最终 cell type UMAP | **报告核心结论** |
| Conclusion | 细胞类型图谱总结、关键 marker 基因、与已知生物学知识的印证、讨论与展望 | 可读的生物学故事 |

### 导航栏交互行为

- 点击一级菜单（Data/Computation/Interpretation）展开下拉，显示该层所有 Tab
- 当前所在 Tab 的层级高亮，面包屑导航显示路径（如 `Computation > Annotation`）
- 页面底部提供"上一节 / 下一节"按钮，支持线性阅读
- 移动端：三层折叠为汉堡菜单，展开后显示手风琴式三级结构

---

## 3. 文件结构

```text
src/jinja2/
├── README.md                # 本文件 — 设计计划
├── render_report.py         # 渲染入口脚本：收集数据 → 渲染 Jinja2 → 输出 HTML
├── templates/
│   ├── base.html            # 基础布局：三层 navbar、CDN 引用、footer、面包屑
│   ├── overview.html        # 📦 Data — 项目概览
│   ├── markers.html         # 📦 Data — 标记基因数据库
│   ├── reference.html       # 📦 Data — 参考数据集 & 同源映射
│   ├── cluster.html         # ⚙️ Computation — 聚类
│   ├── metaneighbor.html    # ⚙️ Computation — MetaNeighbor
│   ├── integration.html     # ⚙️ Computation — 整合评估
│   ├── annotation.html      # ⚙️ Computation — 注释中间结果
│   ├── enrichment.html      # ⚙️ Computation — 富集分析
│   ├── consensus.html       # 🔍 Interpretation — 统一注释
│   └── conclusion.html      # 🔍 Interpretation — 生物学结论
├── static/
│   └── (空，所有静态资源走 CDN)
└── example_data/
    └── data_context.json    # 示例 JSON，文档各模块输出字段
```

---

## 4. 数据输入规范

`render_report.py` 接收两个输入源：(1) 命令行参数指定项目元信息，(2) `--results_dir` 目录下的各模块 CSV 输出。
渲染脚本负责读取 CSV、校验字段、转为 JSON 数组嵌入模板，生成**单文件自包含** HTML。

### 4.1 命令行参数（项目元信息）

```bash
python render_report.py \
  --results_dir /data/work/results \
  --genus Sedum \
  --species plumbizincicola \
  --tissue shoot \
  --batch_key biosample \
  --cluster_key metaneighbor \
  --output phytoscope_report.html
```

| 参数 | 必需 | 默认值 | 说明 |
| ---- | :--: | ------ | ---- |
| `--results_dir` | ✅ | — | 各模块输出 CSV 所在根目录 |
| `--genus` | ✅ | — | 属名，如 `Sedum` |
| `--species` | ✅ | — | 种名，如 `plumbizincicola` |
| `--tissue` | ✅ | — | 组织，如 `shoot` |
| `--batch_key` | ❌ | `biosample` | 批次列名 |
| `--cluster_key` | ❌ | `metaneighbor` | 聚类列名 |
| `--output` | ❌ | `phytoscope_report.html` | 输出路径 |
| `--top_n_markers` | ❌ | `5` | 每个 cluster 展示 Top N marker |

### 4.2 各模块输入文件规范

`render_report.py` 按以下约定从 `results_dir` 读取 CSV，**列名必须精确匹配**。

---

#### 模块 1: Cluster — `cluster/`

| 文件 | 必需 | 列名 |
| ---- | :--: | ---- |
| `cluster/umap_coords.csv` | ✅ | `cell_id, UMAP_1, UMAP_2, cluster, batch` |
| `cluster/cluster_stats.csv` | ✅ | `cluster, n_cells, pct` |

**`umap_coords.csv`** 示例：

```csv
cell_id,UMAP_1,UMAP_2,cluster,batch
AAACCCAAGATCTGCT-1,-5.23,3.41,0,ctrl_1
AAACCCAGTCGTTGAG-1,4.12,-2.08,3,ctrl_1
AAACGAACAGAGTGCA-1,-4.89,3.15,0,treat_1
```

**`cluster_stats.csv`** 示例：

```csv
cluster,n_cells,pct
0,1200,9.72
1,980,7.94
```

> 来源：CHOIR 聚类后从 Seurat 对象的 `@meta.data` 和 `@reductions$umap` 提取

---

#### 模块 2: Markers — `markers/`

| 文件 | 必需 | 列名 |
| ---- | :--: | ---- |
| `markers/allmarkers.csv` | ✅ | `gene, p_val, avg_log2FC, pct.1, pct.2, p_val_adj, cluster` |
| `markers/conserved_markers.csv` | ❌ | `gene, cluster, avg_log2FC, p_val_adj` + 每个 batch 的 `{batch}_avg_log2FC`, `{batch}_p_val_adj` |
| `markers/orthologs.csv` | ❌ | `query_gene, ref_gene, ref_species, identity, e_value` |

**`allmarkers.csv`** 示例（来自 `FindAllMarkers`）：

```csv
gene,p_val,avg_log2FC,pct.1,pct.2,p_val_adj,cluster
LHCB1.1,0,2.85,0.98,0.12,0,0
RBCS1A,0,2.61,0.95,0.08,0,0
CAB3,1.2e-280,2.33,0.91,0.22,2.7e-276,0
```

**`conserved_markers.csv`** 示例（来自 `FindConservedMarkers`）：

```csv
gene,cluster,avg_log2FC,p_val_adj,ctrl_1_avg_log2FC,ctrl_2_avg_log2FC,treat_1_avg_log2FC,treat_2_avg_log2FC,ctrl_1_p_val_adj,ctrl_2_p_val_adj,treat_1_p_val_adj,treat_2_p_val_adj
LHCB1.1,0,2.71,0,2.83,2.64,2.82,2.55,0,0,0,0
```

**`orthologs.csv`** 示例（来自 `orth.R` + diamond blastp RBH）：

```csv
query_gene,ref_gene,ref_species,identity,e_value
Sp0001234,AT1G29910,Arabidopsis thaliana,92.5,1.2e-180
Sp0005678,ATCG00490,Arabidopsis thaliana,88.3,3.4e-150
```

> 来源：`allmarkers_conserved.R` + `orth.R`；如果未运行同源映射则 `orthologs.csv` 可省略

---

#### 模块 3: Reference — `reference/`

| 文件 | 必需 | 列名 |
| ---- | :--: | ---- |
| `reference/ref_info.csv` | ❌ | `species, tissue, n_cells, n_celltypes, source` |
| `reference/blast_stats.csv` | ❌ | `query_species, ref_species, n_query_genes, n_ref_genes, n_reciprocal_best` |

**`ref_info.csv`** 示例：

```csv
species,tissue,n_cells,n_celltypes,source
Arabidopsis thaliana,shoot,25000,18,PlantCellAtlas v2
Oryza sativa,leaf,18000,14,scPlantDB v1.0
```

**`blast_stats.csv`** 示例：

```csv
query_species,ref_species,n_query_genes,n_ref_genes,n_reciprocal_best
Sedum plumbizincicola,Arabidopsis thaliana,25000,27416,12340
```

> 来源：手动整理或从 `diamond_blast.sh` 输出统计；若未使用参考数据集则可省略

---

#### 模块 4: MetaNeighbor — `metaneighbor/`

| 文件 | 必需 | 列名 |
| ---- | :--: | ---- |
| `metaneighbor/auc_heatmap.csv` | ✅ | 首列为 `batch\|cluster`，其余为各 `batch\|cluster`，值为 AUC |
| `metaneighbor/merged_clusters.csv` | ✅ | `original_cluster, merged_cluster, original_label` |

**`auc_heatmap.csv`** 示例：

```csv
batch_cluster,ctrl_1|0,ctrl_1|1,ctrl_2|0,ctrl_2|1,treat_1|0,treat_1|1
ctrl_1|0,1.00,0.23,0.95,0.19,0.88,0.15
ctrl_1|1,0.23,1.00,0.21,0.93,0.12,0.87
ctrl_2|0,0.95,0.21,1.00,0.22,0.91,0.14
```

**`merged_clusters.csv`** 示例：

```csv
original_cluster,merged_cluster,original_label
ctrl_1|0,M0,0
ctrl_1|1,M1,1
ctrl_2|0,M0,0
ctrl_2|1,M1,1
```

> `original_label` 为 cluster_key 下的原始数值标签
> 来源：`metaneighbor.R` 输出

---

#### 模块 5: Integration — `integration/`

| 文件 | 必需 | 列名 |
| ---- | :--: | ---- |
| `integration/scib_metrics.csv` | ✅ | `method, bio_conservation, batch_correction, total, {子指标}...` |
| `integration/umap_{method}.csv` | ✅ | `cell_id, UMAP_1, UMAP_2, cluster, batch` |

**`scib_metrics.csv`** 示例（来自 `scIB.py` 输出）：

```csv
method,bio_conservation,batch_correction,total,NMI_cluster_lisi,ARI_cluster_lisi,ASW_label,ASW_label_batch,isolated_label_F1,isolated_label_silhouette,PCR_batch,graph_conn, kBET, iLISI, cLISI, silhouette_batch
Unintegrated,0.55,0.40,0.47,0.62,0.48,0.55,0.88,0.45,0.52,0.18,0.72,0.15,0.46,0.54,0.88
Harmony,0.72,0.85,0.78,0.78,0.68,0.63,0.95,0.60,0.64,0.81,0.91,0.87,0.79,0.81,0.95
scVI,0.75,0.82,0.78,0.79,0.71,0.65,0.96,0.63,0.66,0.79,0.93,0.82,0.77,0.83,0.96
rliger.INMF,0.70,0.78,0.74,0.75,0.66,0.61,0.93,0.58,0.62,0.76,0.88,0.80,0.72,0.78,0.93
```

**`umap_{method}.csv`** 命名约定：文件名中的 `{method}` 与 `scib_metrics.csv` 中 method 列对应，如 `umap_Harmony.csv`, `umap_scVI.csv`, `umap_Unintegrated.csv`。结构与 `cluster/umap_coords.csv` 相同。

> 来源：`scIB.py` + 各整合方法（harmony/scVI/rliger/BBKNNR/SCTransform）输出的 UMAP 坐标

---

#### 模块 6: Annotation — `annotation/`

| 文件 | 必需 | 列名 |
| ---- | :--: | ---- |
| `annotation/sctype.csv` | ✅ | `cell_id, cluster, label, score` |
| `annotation/singler.csv` | ❌ | `cell_id, cluster, label, score` |
| `annotation/samap.csv` | ❌ | `cell_id, cluster, label, score` |

**`annotation/sctype.csv`** 示例：

```csv
cell_id,cluster,label,score
AAACCCAAGATCTGCT-1,0,Mesophyll,0.87
AAACCCAGTCGTTGAG-1,3,Progenitor,0.62
AAACGAACAGAGTGCA-1,0,Mesophyll,0.91
```

> - `score` 为 0~1 的置信度分数（ScType 得分 / SingleR delta / SAMap 相似度）
> - 至少需要一个文件；多个文件共存时用于 Sankey 一致性分析和 Consensus 投票
> - `cluster` 列的值应对齐 `cluster_key`
> - 来源：`anno_sctype.R` / `anno_singler.R` / `SAMap.sh`

---

#### 模块 7: Enrichment — `enrichment/`

| 文件 | 必需 | 列名 |
| ---- | :--: | ---- |
| `enrichment/go.csv` | ❌ | `cluster, ID, Description, GeneRatio, BgRatio, pvalue, p.adjust, qvalue, geneID, Count` |
| `enrichment/kegg.csv` | ❌ | 同上 |

**`enrichment/go.csv`** 示例（来自 clusterProfiler）：

```csv
cluster,ID,Description,GeneRatio,BgRatio,pvalue,p.adjust,qvalue,geneID,Count
0,GO:0015979,photosynthesis,85/320,120/8500,1.2e-45,3.6e-42,2.8e-42,LHCB1.1/RBCS1A/CAB3/...,85
0,GO:0009765,photosynthesis light harvesting,42/320,55/8500,5.6e-30,8.4e-28,6.5e-28,LHCB1.1/LHCB2.1/...,42
1,GO:0006952,defense response,63/280,210/8500,2.3e-18,4.6e-16,3.5e-16,PR1/PAD4/EDS1/...,63
```

> 来源：`run_clusterprofiler.R`；GO 和 KEGG 至少有一个

---

### 4.3 数据校验规则

`render_report.py` 在渲染前执行以下校验，失败时写 warning 到报告而非崩溃：

| 校验项 | 处理 |
| ------ | ---- |
| 必需文件缺失 | 对应 Tab 显示 "未运行" 占位 |
| CSV 列名不匹配 | 跳过该文件，报告中标注 ⚠️ |
| `cluster` 列值无法对齐 | 尝试字符串匹配，失败则标注 |
| 空文件 | 等同于缺失 |
| `cell_id` 跨文件不一致 | 以 `umap_coords.csv` 为准，annotation 做 left join |
| score 列含 NA | 替换为 0，标注 ⚠️ |

### 4.4 模板变量总览

以下是 Jinja2 模板可用的**完整变量名**（渲染脚本注入到模板上下文）：

```text
{{ project.genus }}                  # "Sedum"
{{ project.species }}                # "plumbizincicola"
{{ project.tissue }}                 # "shoot"
{{ project.genus_species }}          # "Sedum plumbizincicola" (自动拼接)
{{ project.run_date }}               # "2026-07-09"

{{ stats.n_cells }}                  # 12345
{{ stats.n_genes }}                  # 25000
{{ stats.n_samples }}                # 4
{{ stats.n_clusters }}               # 15 (来自 cluster_stats.csv 行数)
{{ stats.samples }}                  # ["ctrl_1", "ctrl_2", "treat_1", "treat_2"]
{{ stats.batch_key }}                # "biosample"

{{ modules.choir.status }}           # "ok" | "warning" | "skipped"
{{ modules.choir.n_clusters }}       # 15
{{ modules.choir.params }}           # {random_seed: 42, ...}

# ---- 以下为列表/嵌套结构，模板中通过 for 循环遍历 ----

# cluster 数据
{{ cluster.umap }}                   # [{cell_id, UMAP_1, UMAP_2, cluster, batch}, ...]
{{ cluster.stats }}                  # [{cluster, n_cells, pct}, ...]

# markers 数据
{{ markers.all }}                    # [{gene, p_val, avg_log2FC, pct.1, pct.2, p_val_adj, cluster}, ...]
{{ markers.conserved }}              # [{gene, cluster, avg_log2FC, p_val_adj, ...per_batch}, ...] | null
{{ markers.orthologs }}              # [{query_gene, ref_gene, ref_species, identity, e_value}, ...] | null
{{ markers.top_n }}                  # 5

# reference 数据
{{ reference.info }}                 # [{species, tissue, n_cells, n_celltypes, source}, ...] | null
{{ reference.blast_stats }}          # [{query_species, ref_species, ...}, ...] | null

# metaneighbor 数据
{{ metaneighbor.auc_matrix }}        # {labels: [...], rows: [{label, values: [...]}, ...]}
{{ metaneighbor.merged }}            # [{original_cluster, merged_cluster, original_label}, ...]

# integration 数据
{{ integration.scib }}               # [{method, bio_conservation, batch_correction, total, ...}, ...]
{{ integration.umaps }}              # {method_name: [{cell_id, UMAP_1, UMAP_2, cluster, batch}, ...], ...}
{{ integration.best_method }}        # "Harmony" (total 最高者)

# annotation 数据
{{ annotation.sctype }}              # [{cell_id, cluster, label, score}, ...] | null
{{ annotation.singler }}             # [{cell_id, cluster, label, score}, ...] | null
{{ annotation.samap }}               # [{cell_id, cluster, label, score}, ...] | null
{{ annotation.methods_available }}   # ["sctype", "singler"] (实际有数据的列表)
{{ annotation.sankey_links }}        # [{source, target, value}, ...] (render_report.py 自动计算)

# enrichment 数据
{{ enrichment.go }}                  # [{cluster, ID, Description, GeneRatio, BgRatio, pvalue, p.adjust, qvalue, geneID, Count}, ...] | null
{{ enrichment.kegg }}                # 同上 | null
{{ enrichment.has_go }}              # true/false
{{ enrichment.has_kegg }}            # true/false

# consensus 数据 (render_report.py 自动计算)
{{ consensus.labels }}               # [{cell_id, cluster, final_label, n_agree, methods_agreed, confidence}, ...]
{{ consensus.summary }}              # [{cluster, final_label, n_cells, confidence_level, sctype_label, singler_label, samap_label}, ...]
```

---

## 5. 各 Tab 详细 UI 设计

### 📦 Data 层

#### 5.1 Overview（项目概览）

```text
┌──────────────────────────────────────────────────┐
│  🌿 Sedum plumbizincicola — Shoot                 │
│  Report generated: 2026-07-09                     │
├────────────────┬────────────────┬─────────────────┤
│  📦 12,345      │  🧬 25,000      │  🧪 4 samples    │
│  cells          │  genes          │  (ctrl_1, ...)   │
├────────────────┴────────────────┴─────────────────┤
│  数据来源 & 参考数据集一览                           │
│  Marker DB: scplantdb v1.0 | Ref: Arabidopsis atlas │
└──────────────────────────────────────────────────┘
```

- 4 个统计卡片（cells / genes / samples / clusters）
- 数据来源与参考数据集信息卡片
- 参数摘要折叠面板（点击展开）

#### 5.2 Markers（标记基因数据库）

- 使用的 marker 基因集来源及版本
- 各细胞类型 marker 基因数量柱状图
- marker 基因集覆盖度评估（数据库中多少基因在数据中有表达）

#### 5.3 Reference（参考数据集 & 同源映射）

- 参考数据集信息卡片（物种、组织、细胞类型数）
- diamond blastp 互惠最佳匹配统计
- 同源基因映射结果表（DataTables）

### ⚙️ Computation 层

#### 5.4 Clustering（聚类）

- **主图**: Plotly 交互式 UMAP — 缩放/悬停显示 cell barcode 和 cluster
- **侧栏**: cluster 细胞数柱状图 + 批次着色 UMAP (双图切换按钮)
- **表格**: cluster 统计表 (细胞数 / 占总比)

#### 5.5 MetaNeighbor（批次对齐）

- **热图**: Plotly heatmap，横纵轴为 `batch|cluster`，值为 AUC 相似度
- **树图**: 层次聚类 dendrogram，标注 cut 线
- **对比卡片**: 合并前 15 群 → 合并后 10 群

#### 5.6 Integration（整合评估）

- **概览表**: DataTables — 方法名列 + 各指标列，推荐方法高亮
- **雷达图**: Plotly polar chart，每个方法一个多边形
- **UMAP 画廊**: 2×3 grid，各整合方法 UMAP 子图，统一坐标轴
- **下载按钮**: 导出 scIB 指标 CSV

#### 5.7 Annotation（细胞注释 — 中间结果）

- **总览表**: 每个 cluster 在三方法下的 label + confidence score
- **Sankey 图**: Plotly Sankey — 左 ScType → 中 SingleR → 右 SAMap
- **三连 UMAP**: ScType / SingleR / SAMap 着色对比
- （Consensus 结论移至 Interpretation 层）

#### 5.8 Enrichment（富集分析）

- **气泡图**: Plotly scatter — x=GeneRatio, y=Description, size=Count, color=p.adjust
- **GO/KEGG 切换标签**
- **详情表**: DataTables — 点击气泡跳转到对应行

### 🔍 Interpretation 层

#### 5.9 Consensus（多证据统一注释）

- **最终注释 UMAP** — 全报告最重要的图，颜色按统一后的 cell type
- **投票详情表**: 每个 cluster 三种方法的 label + 一致性评分
- **注释置信度分布**: 柱状图展示 high/medium/low confidence 比例
- **Marker-Enrich 交叉验证卡片**: 标注哪些 cluster 的 marker 与富集结果互相印证

#### 5.10 Conclusion（生物学结论 & 讨论）

- **细胞图谱摘要**: 文字描述 + 缩略 UMAP
- **关键发现**: 每类细胞的 marker 基因 + 富集通路 + 生物学意义
- **与已知知识对比**: 与拟南芥等模式植物的异同
- **局限性 & 展望**: 方法局限、未解决问题、后续实验建议
- **方法汇总表**: 使用的软件/版本/参数一览

---

## 6. 交互设计要点

| 特性 | 实现 |
| ---- | ---- |
| 响应式布局 | Bootstrap 5 grid，移动端友好 |
| 图表联动 | 点击 UMAP 的 cluster → 筛选 marker 表 / 富集表 |
| 深色模式 | Bootstrap 5 原生 `data-bs-theme="dark"` 切换按钮 |
| 导出 | 表格导出 CSV/Excel (DataTables buttons)，截图按钮 (Plotly) |
| 搜索 | DataTables 全局搜索 + 列筛选 |
| 打印 | `@media print` 隐藏导航，保留图表 |

---

## 7. render_report.py 伪代码

```python
#!/usr/bin/env python3
"""Phytoscope Report Renderer — 收集流水线输出，渲染单文件 HTML 报告。"""

import json, argparse, csv
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

def collect_data(results_dir: Path, metadata: dict) -> dict:
    """遍历 results_dir 收集各模块输出，组装 data_context。"""
    ctx = {"project": metadata, "stats": {}, "modules": {}}
    # cluster/
    #   - umap_coords.csv
    #   - cluster_counts.csv
    # metaneighbor/
    #   - auc_heatmap.csv
    #   - merged_clusters.csv
    # integration/
    #   - scib_metrics.csv
    #   - umap_*.csv
    # anno/
    #   - sctype_labels.csv
    #   - singler_labels.csv
    #   - samap_labels.csv
    #   - consensus_labels.csv
    # markers/
    #   - allmarkers.csv
    #   - conserved_markers.csv
    #   - orthologs.csv
    # enrich/
    #   - go_enrich.csv
    #   - kegg_enrich.csv
    return ctx

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--results_dir", required=True)
    parser.add_argument("--output", default="phytoscope_report.html")
    parser.add_argument("--genus", default="Sedum")
    parser.add_argument("--species", default="plumbizincicola")
    parser.add_argument("--tissue", default="shoot")
    args = parser.parse_args()

    ctx = collect_data(Path(args.results_dir), vars(args))
    env = Environment(loader=FileSystemLoader("templates"))
    template = env.get_template("base.html")
    html = template.render(**ctx)

    Path(args.output).write_text(html, encoding="utf-8")
    print(f"✅ Report saved to {args.output}")

if __name__ == "__main__":
    main()
```

---

## 8. 实施计划

| 步骤 | 层级 | 内容 | 预计产出 |
| :--: | :--: | ---- | -------- |
| 1 | — | 创建 `templates/base.html` 骨架（三层 navbar + tab 框架） | 可打开的空报告页面 |
| 2 | — | 实现 `render_report.py` 数据收集 + 渲染逻辑 | 命令行生成 HTML |
| 3 | 📦 | Overview — 统计卡片 + 数据来源 | 概览页可用 |
| 4 | 📦 | Markers + Reference — marker 库 + 同源映射 | Data 层完整 |
| 5 | ⚙️ | Clustering — UMAP 散点图 + 统计 | 聚类可视化 |
| 6 | ⚙️ | Annotation — 三方法 UMAP + Sankey | 注释中间结果 |
| 7 | ⚙️ | Integration — scIB 表格 + 雷达图 + UMAP 画廊 | 整合评估 |
| 8 | ⚙️ | MetaNeighbor + Enrichment — 热图/气泡图 | Computation 层完整 |
| 9 | 🔍 | Consensus — 统一注释 + 置信度 | **核心结论可视化** |
| 10 | 🔍 | Conclusion — 生物学故事 + 讨论 | Interpretation 层完整 |
| 11 | — | 整体打磨：深色模式、导出、响应式、面包屑导航 | 生产可用 |

---

## 9. 注意事项

- 所有图表数据嵌入 HTML（`<script>` 标签内联 JSON），**不依赖外部数据文件**
- CDN 资源（Bootstrap/Plotly/DataTables/FontAwesome）需设计 fallback 或考虑内联关键 CSS
- 首次实现先针对 *S. plumbizincicola* shoot 数据硬编码字段名，后续通过 `data_context.json` schema 泛化
- `plot_marker.py`（`src/utils/scanpy/`）当前为空，需在 Markers tab 设计时同步开发
