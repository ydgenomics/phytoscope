- 前处理，确定基本的slot都有（适配下游的sctype，singler任务）
- 找细胞群marker基因


```shell
input_rds="/data/work/MetaNeighbor/Sp_choir_metaneighbor.rds"
umap_name="umap"
Rscript preprocess.R $input_rds $umap_name


input_rds="/data/work/seurat/preprocessed_seu.rds"
batch_key="biosample"
cluster_key="metaneighbor"
Rscript /data/work/DEAs/allmarkers_conserved.R \
--rds $input_rds --assay RNA --batch_key $batch_key \
--cluster_key $cluster_key --only_pos yes
```

- 可视化细胞类型特异marker基因
- 可视化目标基因的表达
- 可视化umap

```
$ head -n 1 /data/work/Feature/marker/jintian-marker.csv
Tissue,CellType,GeneID,GeneName,MarkerType,References
```