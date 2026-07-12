# DEA — 差异表达分析

## 概述

对每个 cluster 进行差异表达分析（Differential Expression Analysis），识别 cluster 间显著差异表达的基因（marker genes）。

## 原理（Brief）

使用 **Wilcoxon 秩和检验** 比较每个基因在目标 cluster 与其他所有 cluster 中的表达差异。对于每个 cluster，计算：
- **All Markers**：使用全部样本中所有细胞的表达数据
- **Conserved Markers**：在不同批次/条件下保守表达的 marker 基因

通过 logFC（log fold change）和调整后 p 值排序，识别 cluster-specific 的 top marker 基因。

## 数据来源

- 输入：`preprocessed_seu.rds`（Seurat 对象）
- 脚本：`allmarkers_conserved.R`

## 输出

| 文件 | 说明 |
|------|------|
| `allmarkers_*.csv` | 各 cluster 的完整差异基因列表 |
| `conserved_markers_*.csv` | 跨批次保守的 marker 基因 |

## 使用方式

```bash
Rscript allmarkers_conserved.R --rds <input> --batch_key <batch> --cluster_key <cluster>
```

## 参考文献

Satija, R., et al. (2015). Spatial reconstruction of single-cell gene expression data. *Nature Biotechnology*, 33, 495-502.
