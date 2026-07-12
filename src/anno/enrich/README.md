# Enrichment Analysis — GO/KEGG 富集分析

## 概述

对每个 cluster 的 **cluster-specific 差异表达基因**（marker genes）进行 GO（Gene Ontology）和 KEGG（Kyoto Encyclopedia of Genes and Genomes）富集分析，通过超几何检验推断各 cluster 的生物学功能。

## 原理（Brief）

使用 **clusterProfiler** 对每个 cluster 的差异基因进行 GO（BP/CC/MF）和 KEGG 超几何检验富集。计算每个功能条目/通路的富集显著性（p.adjust < 0.05），结合基因比例（GeneRatio）评估富集程度。**显著富集的通路可以反映该 cluster 的主要生物学功能**。

## 数据来源

- 输入：clusterProfiler `run_clusterprofiler.R` 生成的 `*_enrich_results.txt` 和 `cluster_*_enrich.png`
- 基因列表来源：各 cluster 的 cluster-specific marker genes（conserved markers）

## 输出

| 文件 | 说明 |
|------|------|
| `all_clusters_enrich_results.txt` | 所有 cluster 的富集结果汇总表 |
| `all_subclusters_enrich_results.txt` | 子聚类（更高分辨率）的富集汇总表 |
| `cluster_*_enrich.png` | 各 cluster 的富集气泡图 |

## 参考文献

Wu, T., et al. (2021). clusterProfiler 4.0: A universal enrichment tool for interpreting omics data. *The Innovation*, 2(3), 100141.
