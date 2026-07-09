# CHANGELOG — src/cluster

> 记录 `choir.R` 的变更历史。

---

## [v0.3] — 2026-07-10

### 变更内容

CHOIR 聚类完成后自动将结果赋值给 `cluster_key`，并输出 DimPlot 可视化 PNG。

### 新增功能

- **聚类结果映射**：运行 CHOIR 后，自动将 `CHOIR_clusters` 列的值赋给 `obj@meta.data[[cluster_key]]`，使下游流程可直接按用户指定的列名使用聚类结果
- **DimPlot 自动输出**：使用 `CHOIR_P0_reduction` 降维结果，按 `cluster_key` 分组生成 DimPlot 并保存为 PNG（`ggsave`，10×8，150 dpi）
- **分批 PNG 防覆盖**：多 batch 模式下，每个批次的 PNG 文件名带 `_<batch>` 后缀，避免互相覆盖

### 文件输出

| 输出文件 | 说明 |
| --- | --- |
| `<input_rds>` | 含 CHOIR 聚类结果及 `cluster_key` 列的 Seurat RDS |
| `CHOIR_<cluster_key>_DimPlot.png` | 单批次 / 合并后的 DimPlot |
| `CHOIR_<cluster_key>_<batch>_DimPlot.png` | 多批次模式下各批次的独立 DimPlot |

---

## [v0.2] — 2026-07-09

### 变更内容

根据流水线设计（`PROJECT.md` #4.2 Stage 1）重构 `choir.R`，新增`cluster_key`和`batch_key`参数支持智能跳过分群和分批处理。

### 新增功能

- **`cluster_key` 检查**：若指定列已存在于 `seu@meta.data`，则跳过 CHOIR 直接保存 RDS；若不存在或传 `"NULL"`，则运行 CHOIR 聚类
- **`batch_key` 分批处理**：若 `unique(seu$batch_key) > 1`，按 batch 拆分后分别跑 CHOIR，再 merge 为一个 RDS；若 ≤ 1 则直接跑 CHOIR
- **批次后缀标记**：分批跑 CHOIR 后，聚类列名自动添加 `.{batch_name}` 后缀以区分不同批次的独立聚类结果
- **运行计时**：脚本启动时用 `proc.time()` 记录起始时间，三个出口（skip/split/single）均打印总运行时间（单位：h）

### 参数变更

| 版本 | 参数签名 | 说明 |
| --- | --- | --- |
| v0.1 | `choir.R <input_rds> <alpha> <random_seed>` | 旧版，3 个位置参数 |
| **v0.2** | `choir.R <input_rds> <cluster_key> <batch_key> [alpha] [random_seed]` | 新版，5 个参数，后 2 个可选 |

### 用法示例

```bash
# 检查 cluster_key="metaneighbor"，按 biosample 分批
Rscript choir.R input.rds metaneighbor biosample 0.05 42

# 强制运行 CHOIR（不分批）
Rscript choir.R input.rds NULL NULL 0.05 42

# 强制运行 CHOIR（按 biosample 分批）
Rscript choir.R input.rds NULL biosample 0.05 42
```

---

## [v0.1] — 初始版本

- 基础 CHOIR 聚类：输入 RDS → 运行 CHOIR → 保存结果
- 参数：`input_rds`, `alpha`, `random_seed`
