# Phytoscope Full Report — 使用说明

## 快速开始

```bash
cd jinja2-2/

python render_full_report.py \
    --results_dir /path/to/data/output \
    --species "Sedum plumbizincicola" \
    --tissue "shoot" \
    --background "项目背景描述（可选）" \
    --output phytoscope_full_report.html
```

生成后在浏览器中直接打开 `phytoscope_full_report.html` 即可。

---

## 参数说明

| 参数 | 必需 | 说明 | 示例 |
|------|:--:|------|------|
| `--results_dir` | ✅ | 各分析模块的输出根目录 | `/data/.../phytoscope/data/output` |
| `--species` | ✅ | 物种名 | `"Sedum plumbizincicola"` |
| `--tissue` | ✅ | 组织 | `"shoot"` |
| `--background` | ❌ | 项目背景（可选） | `"超富集植物单细胞测序..."` |
| `--output` | ❌ | 输出文件名 | `phytoscope_full_report.html`（默认） |

---

## 依赖

```bash
pip install jinja2 pandas plotly
```

| 库 | 用途 |
|----|------|
| `jinja2` | HTML 模板渲染 |
| `pandas` | CSV 矩阵读取 |
| `plotly` | 交互式热图生成（MetaNeighbor、Annotation） |

---

## 输入目录结构要求

`--results_dir` 需包含以下子目录和文件（缺失的模块会自动显示占位提示）：

```
results_dir/
├── cluster/
│   └── CHOIR_choir_{condition}_DimPlot.png    ← 聚类 UMAP 图（支持任意数量条件）
├── metaneighbor/
│   └── *metaNeighbor*.csv                     ← AUROC 矩阵
├── integration_scib/
│   ├── png/
│   │   └── {method}_{key}.png                 ← 整合方法 UMAP 图
│   └── scib/
│       └── *.png                              ← scIB 评估图
├── anno/
│   ├── enrich/
│   │   ├── cluster_*_enrich.png               ← 各 cluster 富集图
│   │   └── *enrich_results.txt               ← 富集表格
│   ├── sctype/
│   │   ├── *_sctype.png                       ← sctype UMAP
│   │   └── *_sctype_prob_clusters.csv         ← sctype 概率矩阵
│   ├── singler/
│   │   ├── *_singler.png                      ← singler UMAP
│   │   └── *_singler_prob_clusters.csv        ← singler 概率矩阵
│   └── SAMap_result/
│       ├── DimPlot_*.png                      ← SAMap UMAP
│       └── MappingTable_cross.csv             ← SAMap 映射矩阵
├── utils/
│   ├── seurat/DEA/
│   │   └── allmarkers_*.csv                   ← DEA 差异基因表
│   └── summary/
│       └── dotplot.png                        ← Dotplot 图
```

> **动态发现**：所有文件名通过 glob 模式匹配，不硬编码前缀。比如 `*_sctype.png` 匹配 `Sp_metaneighbor_sctype.png`，更换项目前缀也能自动识别。

---

## 报告内容

生成的单文件 HTML 报告包含以下 9 个模块：

| # | 模块 | 展示方式 |
|:--:|------|---------|
| 1 | **Overview** | 可编辑表单（Python 预填 + 浏览器 localStorage 保存） |
| 2 | **Clustering** | 导航栏切换条件 → UMAP PNG + 下载 |
| 3 | **MetaNeighbor** | Plotly 交互热图（AUROC 矩阵） |
| 4 | **DEA** | DataTables 全量表格 + CSV 导出 |
| 5 | **Enrichment** | Tabs 切换 cluster 富集图 + DataTables 表格 |
| 6 | **Integration** | 方法导航栏 + 维度折叠面板 + scIB 评估图 |
| 7 | **Annotation** | sctype / singler / SAMap Tabs → UMAP + Plotly 热图 |
| 8 | **Dotplot** | PNG 嵌入 + 下载 |
| 9 | **AI Interpretation** | （待接入）前端 API 流式 AI 解读 |

---

## 文件清单

```
jinja2-2/
├── render_full_report.py          ← 主入口
├── collectors/                    ← 数据收集层（8 个模块）
│   ├── __init__.py
│   ├── utils.py                   ← 通用：image_to_base64 / glob / CSV 读取
│   ├── overview.py                ← 项目元信息
│   ├── cluster.py                 ← 聚类 UMAP
│   ├── metaneighbor.py            ← MetaNeighbor 热图
│   ├── dea.py                     ← DEA 表格
│   ├── enrich.py                  ← 富集分析
│   ├── integration.py             ← 整合评估
│   ├── annotation.py              ← sctype/singler/SAMap
│   └── dotplot.py                 ← Dotplot
├── templates/                     ← Jinja2 模板
│   ├── base.html                  ← 骨架 + 全局 CSS/JS
│   └── blocks/
│       ├── overview.html
│       ├── cluster.html
│       ├── metaneighbor.html
│       ├── dea.html
│       ├── enrich.html
│       ├── integration.html
│       ├── annotation.html
│       ├── dotplot.html
│       └── interpretation.html
├── phytoscope_full_report.html    ← 输出（示例）
├── enrich.py                      ← 旧版独立脚本（保留）
├── integration_scib.py            ← 旧版独立脚本（保留）
└── metaneighbor.py                ← 旧版独立脚本（保留）
```

---

## 报告html的架构

- Data
  - background info (填写物种，组织信息，项目背景)
- Computation
  - Cluster (umap)
  - Metaneighbor (umap + heatmap)
  - DEA (table)
  - Enrich (png, table)
  - Integration_scIB (png)
  - Anno
    - sctype (umap + heatmap)
    - singler (umap + heatmap)
    - SAMap (umap + heatmap)
    - summary table
  - Dotplot (png?)
    - 备注：去掉死板的固定 width 或 height（比如限制死的 height: 700px），改用 CSS 的弹性自适应布局（max-width, object-fit: contain）
- Intepretation


添加可下载按钮，表格可下载为csv，图片可以下载为png



$ tree /data/users/yangdong/yangdong_aad9c0eec3ba48688ac1f8729ce11dba/online/phytoscope/data/output
/data/users/yangdong/yangdong_aad9c0eec3ba48688ac1f8729ce11dba/online/phytoscope/data/output
├── anno
│   ├── enrich
│   │   ├── all_clusters_enrich_results.txt
│   │   ├── all_subclusters_enrich_results.txt
│   │   ├── cluster_1_enrich.png
│   │   ├── cluster_2_enrich.png
│   │   ├── cluster_3_enrich.png
│   │   ├── cluster_4_enrich.png
│   │   ├── cluster_5_enrich.png
│   │   ├── cluster_6_enrich.png
│   │   ├── cluster_7_enrich.png
│   │   ├── cluster_8_enrich.png
│   │   ├── kegg_info.RData
│   │   ├── org.Splumbizincicola.eg.db
│   │   │   ├── DESCRIPTION
│   │   │   ├── inst
│   │   │   │   └── extdata
│   │   │   │       └── org.Splumbizincicola.eg.sqlite
│   │   │   ├── man
│   │   │   │   ├── org.Splumbizincicola.egBASE.Rd
│   │   │   │   ├── org.Splumbizincicola.eg_dbconn.Rd
│   │   │   │   └── org.Splumbizincicola.egORGANISM.Rd
│   │   │   ├── NAMESPACE
│   │   │   └── R
│   │   │       └── zzz.R
│   │   └── Rplots.pdf
│   ├── SAMap_result
│   │   ├── all.h5ad
│   │   ├── DimPlot_SAMap.png
│   │   ├── gene_pairs.csv
│   │   ├── MappingTable_cluster_identity.csv
│   │   ├── MappingTable_cross.csv
│   │   ├── MappingTable.csv
│   │   ├── MappingTable.csv_sanky.html
│   │   ├── Merge_UMAP.pdf
│   │   ├── SAMap_integration.py
│   │   └── umap_species_celltype.pdf
│   ├── sctype
│   │   ├── report.txt
│   │   ├── Sp_metaneighbor_nodes.csv
│   │   ├── Sp_metaneighbor_sctype.pdf
│   │   ├── Sp_metaneighbor_sctype.png
│   │   ├── Sp_metaneighbor_sctype_prob_clusters.csv
│   │   ├── Sp_metaneighbor_sctype.rds
│   │   ├── Sp_metaneighbor_sctype_scores_sorted.csv
│   │   └── Sp_metaneighbor_sctype_umap.pdf
│   └── singler
│       ├── at_genes_changed.rds
│       ├── at_genes_changed_ref_singler.Rdata
│       ├── at.pep.dmnd
│       ├── reciprocal_best.txt
│       ├── renamed_transcript_filtered.pep.dmnd
│       ├── report.txt
│       ├── result
│       │   ├── blastp_at.pep_vs_renamed_transcript_filtered.pep.txt
│       │   └── blastp_renamed_transcript_filtered.pep_vs_at.pep.txt
│       ├── Sp_metaneighbor_component.pdf
│       ├── Sp_metaneighbor_pred.csv
│       ├── Sp_metaneighbor_pred.pdf
│       ├── Sp_metaneighbor_singler_cluster_identity.csv
│       ├── Sp_metaneighbor_singler.pdf
│       ├── Sp_metaneighbor_singler.png
│       ├── Sp_metaneighbor_singler_prob_clusters.csv
│       └── Sp_metaneighbor_singler.rds
├── cluster
│   ├── CHOIR_choir_ctrl_DimPlot.png
│   ├── CHOIR_choir_stim_DimPlot.png
│   └── Sp_0.05.rds
├── integration_scib
│   ├── pdf
│   │   ├── Sp_BBKNNR_integrated.pdf
│   │   ├── Sp_harmony_integrated.pdf
│   │   ├── Sp_rliger.INMF_integrated.pdf
│   │   ├── Sp_SCTransform.CCA_integrated.pdf
│   │   ├── Sp_SCTransform.harmony_integrated.pdf
│   │   └── Sp_unintegrated.pdf
│   ├── png
│   │   ├── BBKNNR_biosample.png
│   │   ├── BBKNNR_celltype.png
│   │   ├── BBKNNR_metaneighbor.png
│   │   ├── BBKNNR_sample.png
│   │   ├── harmony_biosample.png
│   │   ├── harmony_celltype.png
│   │   ├── harmony_metaneighbor.png
│   │   ├── harmony_sample.png
│   │   ├── rliger.INMF_biosample.png
│   │   ├── rliger.INMF_celltype.png
│   │   ├── rliger.INMF_metaneighbor.png
│   │   ├── rliger.INMF_sample.png
│   │   ├── SCTransform.CCA_biosample.png
│   │   ├── SCTransform.CCA_celltype.png
│   │   ├── SCTransform.CCA_metaneighbor.png
│   │   ├── SCTransform.CCA_sample.png
│   │   ├── SCTransform.harmony_biosample.png
│   │   ├── SCTransform.harmony_celltype.png
│   │   ├── SCTransform.harmony_metaneighbor.png
│   │   ├── SCTransform.harmony_sample.png
│   │   ├── unintegrated_biosample.png
│   │   ├── unintegrated_metaneighbor.png
│   │   └── unintegrated_sample.png
│   ├── sc
│   │   ├── harmony_SCTransform.harmony_integrated.csv
│   │   ├── iNMF_rliger.INMF_integrated.csv
│   │   ├── pca_SCTransform.CCA_integrated.csv
│   │   ├── Sp_BBKNNR_integrated.rds
│   │   ├── Sp_harmony_integrated.h5ad
│   │   ├── Sp_rliger.INMF_integrated.rds
│   │   ├── Sp_SCTransform.CCA_integrated.rds
│   │   ├── Sp_SCTransform.harmony_integrated.rds
│   │   ├── Sp_unintegrated.h5ad
│   │   └── X_pca_harmony_harmony_integrated.csv
│   └── scib
│       ├── harmony_SCTransform.harmony_integrated.csv
│       ├── Sp_scIB.csv
│       ├── Sp_scIB.h5ad
│       ├── Sp_scIB.pdf
│       └── Sp_scIB.png
├── metaneighbor
│   ├── Sp_0.05.rds
│   ├── Sp_metaNeighbor.csv
│   ├── Sp_metaNeighbor.pdf
│   └── Sp_metaneighbor.rds
└── utils
    ├── convert
    │   └── Sp_metaneighbor.rh.h5ad
    ├── seurat
    │   ├── DEA
    │   │   ├── allmarkers_Sp_metaneighbor.rds.csv
    │   │   └── conserved_markers_Sp_metaneighbor.rds.csv
    │   ├── preprocess
    │   │   └── Sp_metaneighbor.rds
    │   └── preprocess_marker
    │       ├── NewName.csv
    │       ├── NewName_filter.csv
    │       └── NewName_sctype.csv
    └── summary
        └── dotplot.png

26 directories, 112 files