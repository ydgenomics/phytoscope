# phytoscope
let plant cell annotation more easy!

---

细胞分群与细胞类别
分群影响注释，证据的对齐
现在问题是scplantdb的细胞类型marker基因为什么这么多？


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
- 测试效果
  - 非模式物种景天shoot的镉对照处理的注释
- 效率提升
  - 传统
  - 流程运行时间
- 总结展望

植物单细胞自动化注释
模板html的Data模块，填写相关的单细胞项目信息，包括但不限于，物种信息（种名），组织，项目背景（optional），提供系统提示词：总结分析项目背景，整理其解剖学信息，应该注释成那些细胞类型，关注的科学问题，可用的资源

填写数据和运行流程的参数，(这部分学习src脚本的要求参数完善)
input_rds, marker_csv, query_pep, ref_rds, ref_pep,等文件
batch_key, sample_key等参数
填好了之后可以导出为csv

计算部分，输入的rds先读入choir如果给的cluster_key存在则不跑，不存在再看unique(seu$batch_key)的数量是不是大于1，大于1的话要split之后分别跑CHOIR,然后再merge为一个rds保存。跑了CHOIR之后输出的rds或判断直接保留原文件的rds，经过utils/seurat/preprocess.R处理rds，处理好的rds跑src\utils\seurat\allmarkers_conserved.R拿到cluster 特异marker基因列表，后续用于运行src/anno/enrich，处理好的rds将rds作为输入跑metaneighbor，rds可以通过utils/convert转rds为h5ad跑相应的python脚本。metaneighbor输出的rds作为integration_scib的输入，其metaneighbor添加的注释键作为label_key。metaneighbor输出的rds和转好的h5ad文件用于跑src/anno。其需要的文件需要在data部分准备好，设置好。

输入的细胞类型特异基因要有这些column，像D:\APP_cs\YD_learn\github\phytoscope\data\jintian-marker2.csv一样，这个是同源注释所以要跑一下src\utils\seurat\orth.R拿到转换好的*_sctype.csv，这个文件将用于anno_sctype的运行和后续marker基因的可视化。


解读部分，基于data部分总结的背景和公共数据，从不同的方法证据和marker证据，得出最终的注释信息，metaneighbor分群对应的细胞类型，说明原因和不足。这些都要内嵌系统提示词。

整个jinja2的纯前端设计要能嵌入这些内容，同时也要能支持接入api，实现对文字和图像的解读。
