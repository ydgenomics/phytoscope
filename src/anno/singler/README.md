# SingleR 自动注释

## 概述

SingleR (Single-Cell Recognition) 是一种基于**参考数据集表达谱相关性**的细胞类型自动注释方法。它利用同物种（或跨物种同源基因替换后）的参考 RDS 数据集，对 query 中的每个细胞进行类型鉴定。

与 ScType 的核心区别：

| 特性 | SingleR | ScType |
| :--- | :--- | :--- |
| 依据 | 与参考数据的**表达谱相关性** | 标记基因的**加权打分** |
| 是否需要参考 | **需要**完整参考 RDS | 仅需标记基因 CSV |
| 打分方式 | Spearman 相关系数 | 正负标记基因联合打分 |
| 注释粒度 | 每个细胞独立注释 | 按 cluster 汇总注释 |
| 跨物种 | 天然支持（同源基因替换后） | 需手动构建同源标记基因 |

---

## SingleR 注释原理

### 核心思想

> 对 query 中每个细胞，计算其表达谱与参考数据集中各细胞类型平均表达谱的 **Spearman 相关系数**，得分最高的类型即为注释结果。

### 流程详解

#### Step 1 — 参考数据集构建（`create_ref_singler`）

```r
create_ref_singler <- function(input_ref_rds, ref_cluster_key) {
    ref_seu <- readRDS(input_ref_rds)
    Idents(ref_seu) <- ref_seu@meta.data[[ref_cluster_key]]
    
    # 按细胞类型聚合，得到平均表达矩阵
    av <- AggregateExpression(ref_seu, group.by = ref_cluster_key, assays = "RNA")
    ref_mat <- av[[1]]  # 基因 × 细胞类型
    
    # 转为 SingleCellExperiment 并 log-normalize
    ref_sce <- SingleCellExperiment(assays = list(counts = ref_mat))
    ref_sce <- scater::logNormCounts(ref_sce)
    colData(ref_sce)$Type <- colnames(ref_mat)
    return(ref_sce)
}
```

构建的参考数据格式：

```text
          Mesophyll  Epidermis  Bundle_Sheath  ...
gene_A      5.2        0.1         4.8         ...
gene_B      0.3        6.7         0.2         ...
gene_C      4.1        0.5         5.3         ...
```

- **每列** = 一种细胞类型的平均表达谱（log-normalized）
- **每行** = 一个基因

#### Step 2 — Spearman 相关性计算

对 query 中**每个细胞**，计算其表达谱与参考中**每种细胞类型**平均表达谱的 Spearman 相关系数：

$$
r_{ij} = \frac{\text{cov}(q_i, r_j)}{\sigma_{q_i} \cdot \sigma_{r_j}}
$$

- $q_i$ = query 第 $i$ 个细胞的表达向量
- $r_j$ = 参考第 $j$ 种细胞类型的平均表达向量
- 结果矩阵：`n_cells × n_cell_types`

> Spearman 使用**秩次**而非原始值，对基因表达量的分布不敏感，更适合跨数据集比较。

#### Step 3 — 精细注释（fine-tuning）

SingleR 的独特之处在于它会进行**迭代筛选**：

```text
Round 1: 在所有细胞类型中找相关性最高的类型 → 保留 top 子集
Round 2: 在 top 子集中再找 → 继续缩小范围
...
直到只剩一种细胞类型
```

#### Step 4 — 置信度修剪（pruning）

`SingleR` 返回的 `pred` 对象包含：

| 列 | 说明 |
| :--- | :--- |
| `scores` | 每种细胞类型的相关性得分矩阵 |
| `labels` | 直接注释结果，每个细胞都有标签 |
| `pruned.labels` | **经置信度修剪**：低分细胞被设为 `NA` |

`pruneScores()` 修剪规则：

1. 计算每个细胞的 **Delta** = 最高分 - 次高分
2. 若 Delta 低于阈值 → 该细胞注释置信度低 → `pruned.labels` 设为 `NA`

---

## Cluster-level 身份投票

### 为什么要做 cluster-level 注释？

SingleR 是**单个细胞级别**的注释，但生物学的分析单元通常是 **cluster**。使用 majority voting 可以让注释落到 cluster 层面。

### 流程

```text
pred$pruned.labels
        ↓
NA → "Unknown"           ← 低置信度细胞标记为 Unknown
        ↓
按 cluster 统计各类型细胞数   ← count_matrix
        ↓
百分比归一化 (每列和 = 100%)  ← prob_matrix
        ↓
阈值投票 (Scheme A)       ← 占比 > 50% 才保留标签
        ↓
写入 seu$singler          ← cluster-level 标签
```

### 阈值规则

| 条件 | 标签 | 说明 |
| :--- | :--- | :--- |
| 占比 > 50% | 保留原类型 | 该类型占多数，可信 |
| 占比 ≤ 50% | **Mixed** | 无绝对多数，建议重新聚类 |

### 输出的百分比矩阵格式

`*_singler_prob_clusters.csv`：

| celltype | 0 | 1 | 2 | 3 |
| :--- | :--- | :--- | :--- | :--- |
| Mesophyll | **85.3** | 5.1 | 15.2 | 1.2 |
| Epidermis | 5.1 | **90.7** | 3.8 | 2.5 |
| Bundle_Sheath | 3.2 | 1.5 | **78.2** | 3.1 |
| Unknown | 6.4 | 2.7 | 2.8 | **93.2** |

- **每列和 = 100%**，直接反映各类型在 cluster 中的实际占比
- 数值为实际百分比（%），与 component heatmap 数值一致

### 输出的 cluster identity CSV

`*_singler_cluster_identity.csv`：

| cluster | singler | prob | purity_check |
| :--- | :--- | :--- | :--- |
| 0 | Mesophyll | 85.3 | pass |
| 1 | Epidermis | 90.7 | pass |
| 2 | **Mixed** | NA | **fail** |
| 3 | Bundle_Sheath | 78.2 | pass |
| 4 | **Mixed** | NA | **fail** |

- **`purity_check = pass`**：占比 > 50%，该类型占多数
- **`purity_check = fail`**：占比 ≤ 50%，无绝对多数，标记为 Mixed

运行时还会打印警告：

```text
[warning] 2 clusters have no majority (> 50%), marked as 'Mixed':
  cluster singler
2      2   Mixed
4      4   Mixed
[suggestion] Consider sub-clustering these clusters for better resolution.
```

---

## 输入参数

| 参数 | 缩写 | 类型 | 默认值 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| `--input_ref_rds` | `-r` | string | - | 参考数据集 RDS 路径 |
| `--ref_cluster_key` | `-k` | string | celltypes | 参考数据中的细胞类型列名 |
| `--input_query_rds` | `-q` | string | - | 待注释 query 的 RDS 路径 |
| `--query_cluster_key` | `-d` | string | seurat_clusters | query 数据的 cluster 列名 |
| `--umap_name` | `-u` | string | Xumap_ | UMAP 降维名称 |

## 输出文件

| 文件 | 说明 |
| :--- | :--- |
| `*_ref_singler.Rdata` | 处理后的参考数据集（SingleCellExperiment 格式） |
| `*_pred.pdf` | SingleR 预测结果可视化（score heatmap + delta distribution + score distribution） |
| `*_pred.csv` | SingleR 原始预测结果（每个细胞） |
| `*_singler.pdf` | Cluster-level 注释 UMAP 图 |
| `*_singler_cluster_identity.csv` | 每个 cluster 的身份和置信度概率 |
| `*_singler_prob_clusters.csv` | Softmax 归一化的 cell_type × cluster 概率矩阵 |
| `*_component.pdf` | Cluster 组成百分比热图 |
| `*_singler.rds` | 添加了注释的 Seurat 对象 |
| `report.txt` | 参考与 query 的共同基因数量报告 |

## 用法示例

```bash
# 基本用法
Rscript anno_singler.R \
  -r /path/to/reference.rds \
  -k celltypes \
  -q /path/to/query.rds \
  -d seurat_clusters \
  -u umap

# 跨物种注释（需先做同源基因替换）
Rscript anno_singler.R \
  -r /path/to/Os.hr_genes_changed.rds \
  -k celltypes \
  -q /path/to/Sv.hr.rds \
  -d seurat_clusters \
  -u Xumap_
```

## 参考

- [使用 singleR 基于自建数据库来自动化注释单细胞转录组亚群](https://mp.weixin.qq.com/s/GpOxe4WLIrBOjbdH5gfyOQ)
- [SingleR GitHub](https://github.com/LTLA/SingleR)
