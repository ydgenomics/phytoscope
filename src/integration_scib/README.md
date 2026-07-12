# Integration & scIB — 整合分析与评估

## 概述

比较多种批次效应校正（integration）方法，使用 **scIB 指标体系** 量化评估各方法的整合质量。

## 原理（Brief）

单细胞数据来自不同批次/样本时，存在技术性批次效应。整合方法在保留生物学变异的前提下消除批次效应：

- **Harmony**：基于迭代软聚类校正 PCA 嵌入
- **scVI**：深度生成模型（VAE）学习批次无关的潜在表示
- **iNMF (rliger)**：非负矩阵分解挖掘共享和批次特异性因子
- **BBKNN**：基于 batch-balanced kNN 图进行批次校正
- **CCA (SCTransform)**：基于典型相关分析的跨批次锚点识别

**scIB** 从批次校正（kBET, ASW_batch）和生物学保守（NMI, ARI, ASW_label, isolated labels）两个维度综合打分。

## 数据来源

- 输入：Seurat RDS / h5ad 对象
- 脚本：`*_integration.R` / `*_integration.py` / `scIB.py`

## 输出

| 文件 | 说明 |
| --- | --- |
| `png/*.png` | 各方法各分组的 UMAP 可视化 |
| `sc/*.csv` | 各方法的 PCA/UMAP 嵌入坐标 |
| `scib/scib_summary_*.csv` | scIB 各指标得分汇总 |
| `scib/scib_plot_*.png` | scIB 综合得分对比图 |

## 使用方式

```shell
cd /phytoscope/src/integration_scib/out
input_rds="/data/work/MetaNeighbor/Sp_metaneighbor.rds"
prefix='Sp'
batch_key='biosample'
key_list='biosample,sample,metaneighbor'
resolution=0.5
cluster_name='celltype'
run_sct="yes"

Rscript /phytoscope/src/integration_scib/BBKNNR_integration.R \
--input_rds $input_rds --prefix $prefix --batch_key $batch_key \
--key_list $key_list --resolution $resolution --cluster_name $cluster_name

Rscript /phytoscope/src/integration_scib/rliger.INMF_integration.R \
--input_rds $input_rds --prefix $prefix --batch_key $batch_key \
--key_list $key_list --resolution $resolution --cluster_name $cluster_name

if [ "$run_sct" == "yes" ]; then
    Rscript /phytoscope/src/integration_scib/SCTransform.CCA_integration.R \
    --input_rds $input_rds --prefix $prefix --batch_key $batch_key \
    --key_list $key_list --resolution $resolution --cluster_name $cluster_name

    Rscript /phytoscope/src/integration_scib/SCTransform.harmony_integration.R \
    --input_rds $input_rds --prefix $prefix --batch_key $batch_key \
    --key_list $key_list --resolution $resolution --cluster_name $cluster_name
fi

python /phytoscope/src/integration_scib/unintegration.py \
$input_h5ad --prefix $prefix --batch_key $batch_key --key_list $key_list \
--cluster_name $cluster_name --resolution $resolution

python /phytoscope/src/integration_scib/harmony_integration.py \
$input_h5ad --prefix $prefix --batch_key $batch_key --key_list $key_list \
--cluster_name $cluster_name --resolution $resolution

python /phytoscope/src/integration_scib/scVI_integration.py \
$input_h5ad --prefix $prefix --batch_key $batch_key --key_list $key_list \
--cluster_name $cluster_name --resolution $resolution

mkdir -p /phytoscope/src/integration_scib/out/scib-metrics && cd /phytoscope/src/integration_scib/out/scib-metrics
python /phytoscope/src/integration_scib/scIB.py \
--unintegrated_h5ad $unintegrated_h5ad --integrated_file $integrated_file \
--tests_file $tests_file --batch_key $batch_key --label_key $label_key \
--n_jobs $n_jobs --prefix $prefix
```

## 参考文献

- Korsunsky, I., et al. (2019). Fast, sensitive and accurate integration of single-cell data with Harmony. *Nature Methods*, 16, 1289-1296.
- Lopez, R., et al. (2018). Deep generative modeling for single-cell transcriptomics. *Nature Methods*, 15, 1053-1058.
- Welch, J. D., et al. (2019). Single-Cell Multi-omic Integration Compares and Contrasts Features of Brain Cell Identity. *Cell*, 177, 1873-1887.
- Luecken, M. D., et al. (2022). Benchmarking atlas-level data integration in single-cell genomics. *Nature Methods*, 19, 41-50.