# CHANGELOG — src/metaneighbor

> 记录 `metaneighbor.R` 的变更历史。

---

## [v0.2] — 2026-07-09

### 修改内容

- **CSV 输出按 hclust 树顺序重排**：保存的 AUC 矩阵 `*_metaNeighbor.csv` 的行列顺序现在与热图（ComplexHeatmap）一致，方便对照原始数据检查
- 修改前：`write.csv(celltype_NV, ...)` 保存 MetaNeighbor 输出的原始顺序
- 修改后：`celltype_NV[hc$order, hc$order]` 按 `hclust` 的叶子顺序重排后再保存

### 影响范围

- 输出的 `*_metaNeighbor.csv` 文件行列顺序改变（与热图 dendrogram 对齐）
- `*_metaneighbor.rds`、PDF 图、UMAP 等其他输出不受影响

---

## [v0.1] — 初始版本

- MetaNeighbor 分析：输入 RDS → AUC 相似度矩阵 → hclust 聚类 → 统一标签 → 可视化
- 输出：`*_metaNeighbor.csv`（AUC 矩阵）、`*_metaneighbor.rds`、`*_metaNeighbor.pdf`
