|task|env|description|
|-|-|-|
|Seurat|plantphone|数据预处理，描述性统计，降维可视化，分群的特异基因|
|Blast|optdntra|处理同源基因|
|Enrich||富集分析|
|Convert|sceasy-schard|转rds为h5ad|
|Sctype|||
|Singler|||
|SAMap|||
|jinja2||结果整理|

物种拉丁名 伴矿景天（学名：Sedum plumbizincicola）
组织：shoot


source /opt/software/miniconda3/bin/conda/bin/activate

- Genus
- Species
- Rds_path
- Pep_path
- Batch_key
- Cluster_key
- Reduction_key

- metaneighbor
- anno
  - Markers
    - cell-specific genes
      - private
      - ortho(blastp)
    - cluster_specific genes
      - FindConservedMarkers
      - FindAllMarkers
    - sctype
  - Enrich
    - .db file
    - eggnog annotation file
  - Ref
    - same gene names
    - distinguish gene names (blastp)
  - Cross-species
    - SAMap
    - Saturn(x)
- integration_scib
  - integration
  - scib
- hclust -> 


输入一个rds文件，即某植物某组织的单细胞转录组表达矩阵，多样本数据涉及对照处理或时序数据
解决两个难点，一是难注释，植物缺少高质量的细胞类型marker基因，对于非模式物种就更稀缺了，高置信度的注释需要多证据支持，多证据多方法的注释如何统一也是一个问题；二是难对齐，不同的实验、样品可能细胞类型/状态存在差异，如何把共有的注释出来并保留真实的生物学差异。
scanpy做marker的可视化；seurat做找群特异marker;
