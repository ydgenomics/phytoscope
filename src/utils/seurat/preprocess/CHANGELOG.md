# CHANGELOG — src/utils/seurat/preprocess

> 记录 `preprocess.R` 的变更历史。

---

## [v0.2] — 2026-07-09

### 变更内容

新增对外部 PCA 嵌入 CSV（如 harmony 校正矩阵）的支持，并提升其优先级：传入 CSV 时始终使用外部嵌入计算 FindNeighbors 和 UMAP，跳过内部 PCA。

### 新增功能

- **外部 PCA CSV 支持**：通过第 3 个参数传入嵌入 CSV（如 harmony 输出），`read.csv()` 读取后通过 `CreateDimReducObject()` 创建自定义降维，替代 `RunPCA()`
- **细胞自动对齐**：取 CSV 行名与 Seurat 对象 `colnames` 的交集，确保细胞顺序一致
- **优先级逻辑**：`pca_csv` 提供时始终执行外部嵌入流程；否则若 UMAP 不存在则运行标准 PCA 流程；若 UMAP 已存在则跳过

### 参数变更

| 版本 | 参数签名 | 说明 |
| :--- | :--- | :--- |
| v0.1 | `preprocess.R <input_rds> <umap_name>` | 旧版，2 个位置参数 |
| **v0.2** | `preprocess.R <input_rds> <umap_name> [pca_csv]` | 新版，3 个参数，第 3 个可选 |

### 用法示例

```bash
# 无外部 CSV：走标准 PCA → FindNeighbors → UMAP
Rscript preprocess.R input.rds umap

# 有外部 CSV（如 harmony 嵌入）：跳过 PCA，直接 FindNeighbors → UMAP
Rscript preprocess.R input.rds umap /path/to/harmony_embeddings.csv

# 即使 UMAP 已存在，传入 CSV 也会强制重新计算
```

---

## [v0.1] — 初始版本

- 基础预处理：检查/补充 NormalizeData、FindVariableFeatures、ScaleData
- 标准降维流程：RunPCA → FindNeighbors → RunUMAP
- 参数：`input_rds`, `umap_name`
