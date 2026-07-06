Rscript ./phytoscope/src/metaneighbor/metaneighbor.R \
--input_rds /data/work/Anno/cell_type.rds \
--output_name Sp_anno --batch_key biosample --cluster_key cell_type \
--new_key metaneighbor2 --cut_value 5