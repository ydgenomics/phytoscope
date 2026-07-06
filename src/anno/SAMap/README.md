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