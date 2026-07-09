# SAMap 跨物种注释

## 概述

SAMap (Species-Aware Mapping) 是一种**跨物种单细胞映射**方法，基于**基因同源性**（orthologs）将不同物种的细胞类型进行比对，推断跨物种的细胞类型对应关系。

在 phytoscope 中，SAMap 与 ScType / SingleR 并列为三种注释方法之一，共同提供多证据交叉验证。

---

## 文件结构

```text
src/anno/SAMap/
├── SAMap.sh                         # 主入口脚本，串联全流程
├── SAMap_result/
│   ├── README.md                    # 本文件
│   └── SAMap_integration.py         # 核心集成 + MappingTable 解析
└── tmp/
    ├── pairwise_blastp.sh           # 互惠 blastp（建库 + 双向比对）
    ├── SAMap_prepare.py             # h5ad → SAM .pkl 预处理
    └── sanky_plot.py               # MappingTable → 交互式 Sankey 图
```

---

## 运行方式

```bash
sh SAMap.sh \
  "/data/work/anndata/At_stem.h5ad,/data/work/anndata/Sp_stem.h5ad" \
  "/data/work/processed/At.pep,/data/work/processed/Sp.pep" \
  "At,Sp" \
  "celltype,metaneighbor" \
  "1000,1000" \
  "no,no" \
  "yes,yes" \
  "no,biosample"
```

| 参数序号 | 参数名 | 默认值示例 | 说明 |
| :--: | ------ | ---------- | ---- |
| 1 | `h5ad_list` | `At.h5ad,Sp.h5ad` | 各物种 h5ad，逗号分隔 |
| 2 | `pep_list` | `At.pep,Sp.pep` | 各物种蛋白序列 fasta |
| 3 | `species_list` | `At,Sp` | 物种缩写，对应文件名前缀 |
| 4 | `cluster_list` | `celltype,metaneighbor` | 各物种 Seurat 中的 cluster 列名 |
| 5 | `subset_list` | `1000,1000` | 各物种采样细胞数（`int` 为数量，`float` 为比例） |
| 6 | `do_rename_list` | `no,no` | 是否将基因名中的 `.` 替换为 `_` |
| 7 | `do_process_list` | `yes,yes` | 是否运行 SAM 预处理（首次运行需 `yes`） |
| 8 | `do_harmonization_list` | `no,biosample` | 是否运行批次校正（`no` 或批次列名） |

---

## 流程详解

```text
┌──────────────────────────────────────────────────────┐
│  Step 1: pairwise_blastp.sh                          │
│  ├─ makeblastdb 建库（每个物种 .pep）                  │
│  ├─ blastp 双向比对（At→Sp, Sp→At）                   │
│  └─ 输出: tmp/maps/{At}{Sp}/ 目录下的比对结果           │
├──────────────────────────────────────────────────────┤
│  Step 2: SAMap_prepare.py                            │
│  ├─ h5ad → SAM 对象（.pkl）                           │
│  ├─ 可选：基因名规范化（. → _）                        │
│  ├─ 可选：harmonization 去批次                         │
│  └─ 输出: tmp/{species}.pkl                          │
├──────────────────────────────────────────────────────┤
│  Step 3: SAMap_integration.py                        │
│  ├─ 加载各物种 .pkl                                   │
│  ├─ SAMAP pairwise 跨物种映射                         │
│  ├─ 联合 wPCA/UMAP 降维                               │
│  ├─ MappingTable 解析（见下方）                        │
│  └─ 输出: SAMap_result/ 下所有文件                     │
├──────────────────────────────────────────────────────┤
│  Step 4: sanky_plot.py                               │
│  ├─ 读取 MappingTable.csv                            │
│  ├─ 过滤低分连接（--slimit，默认 0.6）                 │
│  └─ 输出: 交互式 Sankey HTML                          │
└──────────────────────────────────────────────────────┘
```

---

## MappingTable 解析逻辑

### 2 物种模式（`len(species) == 2`）

当恰好两个物种时，SAMap 自动推断参考物种和查询物种的对应关系：

```python
# 物种 A (species[0]) = 参考物种，物种 B (species[1]) = 查询物种
# 行 = 物种 A 的 cluster（去除 At_ 前缀）
# 列 = 物种 B 的 cluster（去除 Sp_ 前缀）
```

**原始 MappingTable**：

```text
            At_Mesophyll  At_Cambium  ...  Sp_0  Sp_1  Sp_2  ...
At_Mesophyll    0.00         0.00     ...  0.85  0.12  0.03  ...
At_Cambium      0.00         0.00     ...  0.10  0.91  0.05  ...
Sp_0            0.85         0.10     ...  0.00  0.00  0.00  ...
Sp_1            0.12         0.91     ...  0.00  0.00  0.00  ...
```

**处理后 `MappingTable_cross.csv`**（仅保留跨物种块）：

```text
              Sp_0   Sp_1   Sp_2
Mesophyll     0.85   0.12   0.03
Cambium       0.10   0.91   0.05
```

**`MappingTable_cluster_identity.csv`**：

| cluster | SAMap | score | purity_check |
| :------ | :---- | :---- | :----------- |
| Sp_0 | Mesophyll | 0.85 | pass |
| Sp_1 | Cambium | 0.91 | pass |
| Sp_2 | Unknown | NA | fail |

- `score > 0.5` → `purity_check = pass`，取最佳匹配细胞类型
- `score ≤ 0.5` → `purity_check = fail`，标记 `Unknown`

### 多物种模式（`len(species) > 2`）

跳过 MappingTable 解析，仅输出原始 `MappingTable.csv` 和联合 UMAP，打印提示信息：

```text
[info] 3 species detected, skipping cross-species cluster identity parsing.
```

---

## 输出文件一览

| 文件 | 生成条件 | 说明 |
| :--- | :--- | :--- |
| `MappingTable.csv` | 始终 | 原始全量映射分数矩阵 |
| `MappingTable_cross.csv` | 2 物种 | 过滤后的跨物种映射矩阵（去前缀） |
| `MappingTable_cluster_identity.csv` | 2 物种 | 每个查询物种 cluster 的最佳匹配 |
| `Merge_UMAP.pdf` | 始终 | 跨物种联合 UMAP 散点图 |
| `gene_pairs.csv` | 始终 | 跨物种共表达同源基因对 |
| `all.h5ad` | 始终 | 联合 AnnData（含 wPCA 和 celltype 标注） |
| `umap_species_celltype.pdf` | 始终 | 按物种 + 按细胞类型着色的双面板 UMAP |
| `*_sanky.html` | 始终 | 交互式 Sankey 图（Plotly） |

---

## 与其他注释方法的对比

| 维度 | ScType | SingleR | **SAMap** |
| :--- | :--- | :--- | :--- |
| 方法 | 标记基因加权打分 | 参考表达谱相关性 | **同源基因跨物种映射** |
| 输入 | marker CSV | 同物种参考 RDS | 另一个物种的单细胞数据 |
| 跨物种 | ❌ 需手动构建 | ⚠️ 需替换同源基因 | ✅ **原生支持** |
| 适用场景 | 有高质量 marker 集 | 有同组织参考数据 | 非模式物种、无参考数据 |

---

## 依赖环境

- Python: `samap`, `samalg`, `scanpy`, `pandas`, `numpy`, `matplotlib`, `plotly`
- Shell: `blastp` / `makeblastdb`（BLAST+ 套件）
- 镜像建议: `SAMap` 专用 conda 环境
| **输出** | cell_type × cluster 概率 | per-cell + cluster 身份 | 跨物种 cell type 对应表 |
| **归一化** | Softmax | 百分比 | 原始映射分数 |

## 用法

```bash
python SAMap_integration.py "At,Sp" "celltypes,celltypes"
```
