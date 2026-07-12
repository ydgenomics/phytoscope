# ScType 自动注释

## 概述

ScType (Single Cell Type) 是一种基于**标记基因权重打分**的自动细胞类型注释方法。它利用用户提供的标记基因 CSV 文件，对 Seurat 对象的每个 cluster 进行细胞类型鉴定。

---

## ScType 注释原理

### 核心思想

> 对每个细胞类型，计算其 positive marker（正标记）和 negative marker（负标记）的综合加权得分，**得分最高的类型**即为该 cluster 的注释结果。

两个关键设计：

1. **标记基因敏感度加权**：标记基因越"专一"（被越少的细胞类型共享），权重越高
2. **正负标记联合打分**：`positive markers` 加分，`negative markers` 扣分

### 流程详解

#### 1. 基因集准备 (`gene_sets_prepare`)

从 CSV 读取标记基因，按组织类型（`tissueType`）筛选，拆分为两组：

- **`geneSymbolmore1` → `gs_positive`**：该类型应**高表达**的基因
- **`geneSymbolmore2` → `gs_negative`**：该类型应**低表达**的基因

#### 2. 打分函数 (`sctype_score`)

##### Step A — 标记基因敏感度计算

```r
marker_stat = sort(table(unlist(gs)), decreasing = T)
marker_sensitivity = data.frame(
  score_marker_sensitivity = scales::rescale(
    as.numeric(marker_stat), to = c(0,1), from = c(length(gs), 1)),
  gene_ = names(marker_stat))
```

- 统计每个基因出现在多少种细胞类型的 positive marker 中
- 映射到 [0,1] 区间：**基因出现在越少的类型中，权重越高**
- 例如：`RBCS` 只出现在 1 种类型 → 权重≈1.0；`PIR` 出现在 10 种类型 → 权重≈0.2

##### Step B — 基因子集筛选

只保留输入数据中**实际存在**的标记基因，不存在的基因自动过滤并输出报告。

##### Step C — 加权表达矩阵

```r
Z[gene, ] = Z[gene, ] * score_marker_sensitivity
```

- 将表达矩阵中每个标记基因的值 × 其敏感度权重
- **特异基因的表达被放大，通用基因的表达被压缩**

##### Step D — 正负标记联合打分

$$
\text{score} = \frac{\sum \text{positive\_z}}{\sqrt{n_{pos}}} + \frac{\sum (-\text{negative\_z})}{\sqrt{n_{neg}}}
$$

- `sum_t1` = positive marker 表达之和 ÷ √(基因数) → **正贡献**
- `sum_t2` = negative marker 表达之和 × (-1) ÷ √(基因数) → **负贡献**
- 最终得分 = sum_t1 + sum_t2

> 除以 √(基因数) 是对标记基因集合大小的归一化，避免基因多的类型天然得分高。

#### 3. 按 Cluster 汇总

```r
cL_resutls <- do.call("rbind", lapply(unique(cluster_key), function(cl){
  es.max.cl = sort(rowSums(es.max[, cells_in_cluster]), decreasing = TRUE)
  head(data.frame(cluster, type, scores, ncells), n = n_circle)
}))
```

- 每个 cluster 内所有细胞的得分相加 (`rowSums`)
- 取得分最高的 `n_circle`（默认 5）个候选类型

#### 4. 确定最终注释

```r
sctype_scores <- cL_resutls %>% group_by(cluster) %>% top_n(n = 1, wt = scores)
```

- 每个 cluster 取**最高分**类型作为注释
- 如果最高分 < ncells/4，设为 **"Unknown"**（低置信度过滤）

#### 5. Circle Packing 可视化

使用 `ggraph` 绘制嵌套圆图：

```text
Cluster 1 (大圆, 灰色, 面积 = 细胞数)
├── Mesophyll (小圆, 面积 = 得分占比 × 细胞数)
├── Epidermis (小圆)
└── ...
```

- **外层大圆**：每个 cluster，面积 ∝ 细胞总数
- **内层小圆**：候选细胞类型，面积 ∝ 该类型在 cluster 中的置信度占比

---

## 输入参数

| 参数 | 类型 | 默认值 | 说明 |
| :--- | :--- | :--- | :--- |
| `--input_marker_csv` | string | - | 标记基因 CSV 文件路径 |
| `--tissue` | string | leaf | 组织类型（leaf, root 等） |
| `--input_query_rds` | string | - | 输入 Seurat RDS 文件 |
| `--assay_key` | string | RNA | Assay 名称（RNA / SCT / integrated） |
| `--cluster_key` | string | CHOIR_clusters_0.05 | metadata 中的 cluster 列名 |
| `--umap_name` | string | CHOIR_P0_reduction_UMAP | UMAP 降维名称 |
| `--n_circle` | integer | 5 | 每个 cluster 显示的小圆数量 |

## 输出文件

| 文件 | 说明 |
| :--- | :--- |
| `*_sctype.rds` | 添加了 `sctype` 注释的 Seurat 对象 |
| `*_sctype_umap.pdf` | Circle Packing + UMAP 可视化（PDF） |
| `*_sctype_umap.png` | Circle Packing + UMAP 可视化（PNG，300 dpi） |
| `*_sctype.pdf` | sctype 注释 UMAP（PDF） |
| `*_sctype.png` | sctype 注释 UMAP（PNG，300 dpi） |
| `*_sctype_scores_sorted.csv` | 每个 cluster 的最佳注释及得分 |
| `*_nodes.csv` | Circle Packing 图的节点数据 |
| `*_sctype_prob_clusters.csv` | Min-Max 归一化的 cell_type × cluster 得分矩阵 |
| `report.txt` | 缺失标记基因的报告 |

---

## 新增：概率矩阵输出

在 `cL_resutls` 汇总之前，新增了**归一化得分矩阵**的保存功能：

### 构建过程

```r
# 1. 构建 cell_type × cluster 原始得分矩阵
sctype_cluster_matrix <- do.call("rbind", lapply(
  unique(seu@meta.data[[cluster_key]]),
  function(cl) {
    cells <- rownames(seu@meta.data[seu@meta.data[[cluster_key]] == cl, ])
    rowSums(es.max[, cells, drop = FALSE])
  }
))
sctype_cluster_matrix <- t(sctype_cluster_matrix)

# 2. Min-Max 归一化（per cluster）→ [0,1]，线性保留相对差异，可正确处理负得分
minmax <- function(x) (x - min(x)) / (max(x) - min(x))
sctype_prob <- apply(sctype_cluster_matrix, 2, minmax)

# 3. 保存 CSV
write.csv(sctype_prob, "*_sctype_prob_clusters.csv", row.names = TRUE)
```

### 矩阵格式

| cell_type | cluster_1 | cluster_2 | cluster_3 | ... |
| :--- | :--- | :--- | :--- | :--- |
| Mesophyll | **0.85** | 0.02 | 0.01 | ... |
| Epidermis | 0.05 | **0.78** | 0.03 | ... |
| Bundle_Sheath | 0.01 | 0.04 | **0.82** | ... |
| ... | ... | ... | ... | ... |

- **每行** = 一种候选细胞类型
- **每列** = 一个 cluster
- **每个值 ∈ [0,1]**，线性保留得分间的相对差异（Min-Max 归一化）
- 可直接用于 `pheatmap`、`ComplexHeatmap` 等工具绘制热图

### 使用示例（R 中绘制热图）

```r
library(pheatmap)

prob_mat <- read.csv("*_sctype_prob_clusters.csv", row.names = 1)

pheatmap(prob_mat,
  cluster_rows = TRUE,
  cluster_cols = TRUE,
  main = "ScType Annotation Probability",
  fontsize_row = 8,
  fontsize_col = 10,
  color = colorRampPalette(c("white", "yellow", "red"))(100))
```

---

## 用法示例

```bash
Rscript anno_sctype.R \
  --input_query_rds /path/to/seurat.rds \
  --input_marker_csv /path/to/markers.csv \
  --tissue leaf \
  --cluster_key CHOIR_clusters_0.05 \
  --umap_name CHOIR_P0_reduction_UMAP \
  --n_circle 5
```

---

## 参考

- [单细胞全自动注释篇(四)——ScType](https://mp.weixin.qq.com/s/hKBiZCHwDdoJOk0YChbtMA)
- [ScType GitHub](https://github.com/IanevskiAleksandr/sc-type)
