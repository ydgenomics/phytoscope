# Phytoscope TODO

> 植物单细胞注释流水线 — let plant cell annotation more easy!
> 物种：伴矿景天 *Sedum plumbizincicola* | 组织：shoot

---

## 项目概述

**核心流程：** `input_rds → cluster → DEAs → MetaNeighbor → Integration_scib → Anno → Summary (jinja2)`

**两大难点：**

1. **难注释** — 植物（尤其非模式物种）缺少高质量细胞类型 marker 基因，需多证据（marker/enrich/同源）多方法（ScType/SingleR/SAMap）交叉验证
2. **难对齐** — 多样本间细胞类型/状态存在差异，需在对齐批次的同时保留真实生物学差异

**关键变量：** `Genus` `Species` `Rds_path` `Pep_path` `Batch_key` `Cluster_key` `Reduction_key`

---

## 模块状态总览

| 模块 | 路径 | 状态 | 说明 |
| ---- | ---- | :--: | ---- |
| Cluster（CHOIR） | `src/cluster/choir.R` | ✅ | 基于层次聚类的自适应分群 |
| Preprocess | `src/utils/seurat/preprocess.R` | ✅ | Seurat 标准化/HVG/PCA/UMAP |
| DEAs | `src/utils/seurat/allmarkers_conserved.R` | ✅ | FindAllMarkers + FindConservedMarkers |
| Ortholog | `src/utils/seurat/orth.R` | ✅ | diamond blastp 同源基因映射 |
| Blast | `src/utils/align/diamond_blast.sh` | ✅ | 互惠最佳 BLAST (RBH) |
| MetaNeighbor | `src/metaneighbor/` | ✅ | 批次间聚类相似度 + hclust 统一标签 |
| Integration (R) | `src/integration_scib/*_integration.R` | ✅ | BBKNNR / rliger.INMF / SCTransform.CCA / SCTransform.harmony |
| Integration (Py) | `src/integration_scib/*_integration.py` | ✅ | harmony / scVI / unintegrated baseline |
| scIB 评估 | `src/integration_scib/scIB.py` | ✅ | 整合方法基准评测 |
| ScType 注释 | `src/anno/sctype/anno_sctype.R` | ✅ | 基于 marker 基因集的自动注释 |
| SingleR 注释 | `src/anno/singler/anno_singler.R` | ✅ | 基于参考数据集的自动注释 |
| SAMap 跨物种 | `src/anno/SAMap/` | ✅ | 跨物种同源映射注释 |
| Enrich（GO/KEGG） | `src/anno/enrich/run_clusterprofiler.R` | ✅ | clusterProfiler + eggnog 注释 |
| Marker 可视化 | `src/utils/scanpy/plot_marker.py` | ✅ | scanpy 表达可视化 |
| 结果报告（jinja2） | `src/jinja2/` | ⬜ | HTML 报告模板待开发 |
| Convert（rds↔h5ad） | *(待添加)* | ⬜ | sceasy/schard 格式转换 |

---

## TODO

### 🔴 高优先级

- [ ] **jinja2 报告模板** — 编写 HTML 模板，汇总聚类、注释、富集、整合评估结果，生成可交互的结题报告
- [ ] **多注释结果统一** — 设计投票/一致性策略（如 majority vote、confidence score），整合 ScType / SingleR / SAMap 三路注释为统一的 cell type label
- [ ] **注释结果对比可视化** — 绘制 Sankey 图 / alluvial 图展示多方法注释的一致性与分歧（SAMap 已有 sanky_plot.py 可复用）
- [ ] **参数化入口封装** — 提供单一入口脚本/配置文件（YAML/JSON），串联全流程，减少手动逐步骤运行

### 🟡 中优先级

- [ ] **rds ↔ h5ad 格式转换模块** — 将 `Convert` 步骤标准化，封装为独立脚本放入 `src/utils/convert/`
- [ ] **Marker 基因数据库扩展** — 收集更多植物物种/组织的 marker 基因（当前仅有 `NewName_sctype.csv`），结构化存入 `DB/` 目录
- [ ] **参考数据集管理** — 整理拟南芥等模式植物的参考 Seurat 对象（`src/anno/singler/map2rds.R` 已有雏形），建立 ref 版本管理
- [ ] **scIB 结果汇总** — 将各整合方法的 scIB 指标自动汇总成对比表和雷达图
- [ ] **Enrich 自动建库** — `run_clusterprofiler.R` 中 `buildOrgDb_yd()` 需 eggnog 注释文件；提供从 eggnog-mapper 输出到 OrgDb 的一键流程
- [ ] **CHOIR 参数调优指南** — 补充过聚类/欠聚类的调参建议文档（`src/cluster/README.md` 已有部分）

### 🟢 低优先级 / 未来规划

- [ ] **Saturn 跨物种方法调研** — 评估 Saturn 是否适合替代/补充 SAMap（TODO 草稿中有提及但标记为 ×）
- [ ] **多组织支持** — 当前仅 shoot；扩展到 root、leaf 等多组织并行注释
- [ ] **时序/处理对比分析** — 针对对照 vs 处理、时间序列数据的差异分析子流程
- [ ] **Docker/Singularity 镜像** — 环境复现困难（依赖 conda 多环境：Seurat / Alignment / scanpy / r_env），制作容器镜像
- [ ] **Nextflow/WDL 工作流** — 将 shell 脚本串联升级为正式工作流引擎（可参考工作区 `WDL/` 目录）
- [ ] **CI/CD 测试** — 小数据集回归测试，确保各模块更新后流水线仍然可用

### 📝 文档 / 规范

- [ ] 补充各模块脚本顶部的 usage 示例（部分已有，需统一格式）
- [ ] 编写 `doc/` 下的项目整体设计文档（目前只有 `Sp.md` 注释结果）
- [ ] `env_setup.sh` 环境初始化脚本（`src/anno/README.md` 有 export PATH 片段，需整合）

---

## 已完成 ✅

- [x] CHOIR 聚类 (`src/cluster/choir.R`)
- [x] Seurat 预处理 (`src/utils/seurat/preprocess.R`)
- [x] 差异表达分析 - FindAllMarkers + FindConservedMarkers (`src/utils/seurat/allmarkers_conserved.R`)
- [x] 同源基因映射 (`src/utils/seurat/orth.R`)
- [x] Diamond 互惠 BLAST (`src/utils/align/diamond_blast.sh`)
- [x] MetaNeighbor 批次对齐 (`src/metaneighbor/`)
- [x] 多方法整合 - BBKNNR / rliger.INMF / SCTransform.CCA / harmony / scVI (`src/integration_scib/`)
- [x] scIB 整合评测 (`src/integration_scib/scIB.py`)
- [x] ScType 注释 (`src/anno/sctype/anno_sctype.R`)
- [x] SingleR 注释 (`src/anno/singler/anno_singler.R`)
- [x] SAMap 跨物种注释 (`src/anno/SAMap/`)
- [x] GO/KEGG 富集分析 (`src/anno/enrich/run_clusterprofiler.R`)
- [x] Marker 基因表达可视化 (`src/utils/scanpy/plot_marker.py`)
- [x] *S. plumbizincicola* shoot 实际注释 (`doc/Sp.md`)

