export PATH="/opt/software/miniconda3/envs/Seurat/bin:$PATH"


export PATH="/opt/software/miniconda3/envs/alignment/bin:$PATH"

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

```shell
h5ad_list=~{sep="," h5ad_list}
pep_list=~{sep="," h5ad_list}
species_list=~{species_list}
cluster_list=~{cluster_list}
subset_list=~{subset_list}
do_rename_list=~{do_rename_list}
do_process_list=~{do_process_list}
do_harmonization_list=~{do_harmonization_list}

sh ./SAMap/SAMap.sh "$h5ad_list" "$pep_list" \
"$species_list" "$cluster_list" "$subset_list" \
"$do_rename_list" "$do_process_list" "$do_harmonization_list"
```