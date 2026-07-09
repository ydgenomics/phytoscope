# cluster — CHOIR 聚类

基于 [CHOIR](https://github.com/corceslab/CHOIR) 的细胞聚类脚本，支持跳过已有聚类、分批处理和自动可视化。

## 用法

```bash
Rscript choir.R <input_rds> <cluster_key> <batch_key> [alpha] [random_seed]
```

### 参数

| 参数 | 说明 | 默认值 |
| --- | --- | --- |
| `input_rds` | 输入 Seurat RDS 对象路径 | 必填 |
| `cluster_key` | 聚类结果存入的列名；已存在则跳过 CHOIR；传 `"NULL"` 强制运行 | 必填 |
| `batch_key` | 分批列名；`unique(batch) > 1` 时分批运行；传 `"NULL"` 不分批 | 必填 |
| `alpha` | CHOIR 显著性阈值 | `0.05` |
| `random_seed` | 随机种子 | `42` |

### 示例

```bash
input_rds="/data/work/Convert/jt_ctrl.hr.rds"
random_seed="42"

# 检查 cluster_key="metaneighbor"，按 biosample 分批
Rscript choir.R $input_rds metaneighbor biosample 0.05 $random_seed

# 强制运行 CHOIR，不分批
Rscript choir.R $input_rds NULL NULL 0.05 $random_seed

# 强制运行 CHOIR，按 biosample 分批
Rscript choir.R $input_rds NULL biosample 0.05 $random_seed
```

## 输出

| 文件 | 说明 |
| --- | --- |
| `<input_rds>` | 含 CHOIR 聚类列及 `cluster_key` 列的 Seurat 对象 |
| `CHOIR_<cluster_key>_DimPlot.png` | DimPlot 可视化（`CHOIR_P0_reduction`） |
| `CHOIR_<cluster_key>_<batch>_DimPlot.png` | 多批次模式下各批次的独立可视化 |

## 调参建议

- **过聚类**：提高 `min_accuracy`（如 0.55~0.6）或降低 `alpha`（如 0.01）
- **欠聚类**：使用默认 `min_accuracy = 0.5`，或改用 `p_adjust = "fdr"`
- **内存不足**：保持 `distance_approx = TRUE`，调小 `downsampling_rate`
