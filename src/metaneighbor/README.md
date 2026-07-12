# MetaNeighbor — 聚类可重复性分析

## 概述

MetaNeighbor 通过计算不同聚类方案间的 **AUROC 相似度矩阵**，评估聚类结果的可重复性和稳定性。

## 原理（Brief）

对每种聚类方案，选取各 cluster 的 top 差异基因构建表达特征。以其中一种聚类方案为训练集（reference），另一种为测试集（query），用 AUROC 衡量 cluster 间的基因表达特征相似度。**高 AUROC 值表示两种聚类方案对同一群细胞的识别高度一致**。

## 数据来源

- 输入：Seurat RDS 对象，包含多个 cluster_key 列（如不同参数下的聚类结果）
- 输出：`*_metaNeighbor.csv`（AUROC 矩阵）和 `*_metaneighbor.rds`（MetaNeighbor 对象）

## 输出

| 文件 | 说明 |
|------|------|
| `*_metaNeighbor.csv` | AUROC 相似度矩阵 |
| `*_metaneighbor.rds` | MetaNeighbor 完整结果对象 |

## 使用方式

```bash
sh metaneighbor.sh
```

## 参考文献

Crow, M., et al. (2018). MetaNeighbor: a method to rapidly assess cell type identity using both functional and random gene sets. *Nature Communications*, 9, 4160.
