# CHANGELOG — src/anno/singler

> 记录 `anno_singler.R` 的变更历史。

---

## [v0.2] — 2026-07-09

### 变更内容

新增基于 `pred$pruned.labels` 的 cluster-level identity 投票机制（**Scheme A 百分比阈值投票**），输出按 cluster 归一化为 100% 的 cell_type × cluster 百分比矩阵。

### 新增功能

- **`singler_pruned` 元数据**：将 `pred$pruned.labels` 写入 Seurat 对象，NA 替换为 "Unknown"
- **百分比矩阵**：`count_matrix` 按列归一化为百分比（每列和 = 100%），替代原 softmax，输出 `*_singler_prob_clusters.csv`
- **阈值投票（Scheme A）**：占比 > 50%（多数原则）才保留标签，否则标记为 `"Mixed"`
- **`purity_check` 列**：记录每个 cluster 是否通过纯度检查（pass/fail），输出 `*_singler_cluster_identity.csv`
- **低纯度警告**：自动打印哪些 cluster 被标记为 Mixed，并建议重新聚类
- **`seu$singler` 重定义**：由 per-cell label 改为 cluster-level 标签（同 cluster 所有细胞同一标签）

### 代码精简

- **热图复用 prob_matrix**：component heatmap 直接使用 `prob_matrix` 绘制，消除重复的计数 → pivot_wider → 百分比计算逻辑，减少 6 行冗余代码

### 输出文件变更

| 版本 | 输出文件 | 说明 |
| :--- | :--- | :--- |
| v0.1 | `*_pred.csv` | SingleR 原始预测 |
| v0.1 | `*_singler.pdf` | per-cell labels UMAP |
| **v0.2** | `*_singler_prob_clusters.csv` | **[新增]** Cluster 百分比矩阵（每列和 = 100%） |
| **v0.2** | `*_singler_cluster_identity.csv` | **[新增]** Cluster 身份（含 purity_check） |
| **v0.2** | `*_singler.pdf` | cluster-level labels UMAP（重定义） |
| **v0.2** | `*_component.pdf` | 使用 `singler_pruned` 绘制（含 Unknown） |

---

## [v0.1] — 初始版本

- 基础 SingleR 注释流程：构建参考 → 运行 SingleR → 保存 per-cell 标签
- 参数：`input_ref_rds`, `ref_cluster_key`, `input_query_rds`, `query_cluster_key`, `umap_name`
