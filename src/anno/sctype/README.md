```
input_rds="/data/work/Integration/out/Sp_BBKNNR_integrated.rds"
markers_csv="/data/work/Feature/marker/NewName_sctype.csv"
cell_type="~{tissue_type}"
cluster_key="metaneighbor"
umap_name="umap"

export PATH="/software/miniconda/envs/Seurat/bin:$PATH"
Rscript ./phytoscope/src/anno/sctype/anno_sctype.R \
--input_query_rds $input_rds --input_marker_csv $markers_csv \
--tissue $cell_type  --cluster_key $cluster_key --umap_name $umap_name --n_circle 5
```