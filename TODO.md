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