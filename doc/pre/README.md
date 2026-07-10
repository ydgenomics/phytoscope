PlantAnnotator —— 基于LLM Agent的植物单细胞全自动智能注释平台

- 项目背景
  - 单细胞测序技术的发展，越来越多的研究人员利用单细胞技术做EvoDvo研究
  - 植物三大图谱，拟南芥，水稻，大豆，泛维管植物示例
  - 细胞注释的重要性，是后面研究的基础
- 项目意义
  - 植物单细胞注释的难点
    - 缺少高质量的细胞类型marker基因
    - 非模式物种研究的困境
    - 细胞类型marker基因收集费时费力
    - 自动化注释软件结果的整合
    - 多分组数据去批次和注释对齐
  - 项目解决方案
    - 整合多个软件方法
    - 从项目背景、计算、解释的端到端解决方案
- 项目设计
  - Data
    - knowledge data
    - public data
    - studied data
  - Compution
    - cluster with leiden and CHOIR
    - annotation with multi-methods
    - align with metaneighbor, integration, and scib-metrices
  - Interpretation
    - display: jinja2
    - api: kimi
- 项目进展
- 项目效果
  - 非模式物种景天shoot的镉对照处理的注释
  - 传统
  - 流程运行时间
- 总结展望
  - 不足
    - 自动化不强，只是在结果部分和解读部分引用了大模型
    - 计算依赖软件多，环境管理复杂，外部迁移部署难
  - 后续工作
    - 完善本地(DCS)数据库，包括标记基因、表达矩阵、物种蛋白序列和功能注释
    - 构建本地(DCS)知识库，文献知识(分类学、解剖学、植物生理、分子生物学)
    - 测试已发表数据，做benchmarking，提高准确性和效率

  - 当前局限
    - ⚠️ LLM仅用于结果解读层，未深度嵌入计算层做智能决策
        → 聚类参数选择、注释结果冲突裁决目前仍靠人工经验
    - ⚠️ 依赖 R/Python/conda 多环境，部署迁移成本高
        → R(Seurat/CHOIR/SingleR) + Python(scanpy/scIB/jinja2) + shell(BLAST) 三套环境
    - ⚠️ 流程需手动分步执行，缺乏统一调度入口
        → 各模块独立脚本，参数传递靠约定，容错和断点续跑未支持
  - 后续工作
    - 🔲 构建本地知识库 (DCS Data + Knowledge Base)
       ├─ 数据库：marker基因库 / 多物种表达矩阵 / 蛋白序列 / 功能注释
       └─ 知识库：分类学 / 解剖学 / 植物生理 / 分子生物学文献知识图谱
    - 🔲 深化LLM Agent集成
       ├─ 计算层：LLM辅助聚类参数调优、注释冲突智能裁决
       └─ 数据层：LLM自动文献挖掘补充marker基因、跨物种知识迁移
    - 🔲 Benchmarking 与验证
       ├─ 收集已发表植物单细胞数据集，建立金标准测试集
       └─ 对比现有工具(scType/SingleR/SAMap单独使用)的准确率与效率
    - 🔲 工程化完善
       ├─ Docker/Singularity 容器化 → 一键部署
       ├─ Nextflow/WDL 工作流引擎 → 参数化调度+断点续跑
       └─ CI/CD 回归测试 → 小数据集自动化验证