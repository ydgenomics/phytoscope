# Date: 260707
# Image: plantphone-R-02
### rds必须包括标准化处理的layer: data
### FindAllMarkers适用于分群后找各个群的marker基因，该群区别于其它群特异的基因(pos/neg) `assay` `group.by` `only.pos = TRUE`
library(Seurat)
library(dplyr)
library(optparse)


if(FALSE){'
input_rds="/data/work/MetaNeighbor/jt_metaneighbor.rds"
batch_key="biosample"
cluster_key="metaneighbor_10"
Rscript ./phytoscope/src/utils/seurat/allmarkers_conserved.R \
--rds $input_rds --assay RNA \
--batch_key $batch_key --cluster_key $cluster_key --only_pos yes
'}

option_list <- list(
    make_option(c("-r", "--rds"), type = "character", default = "/data/work/Single-Cell-Pipeline/output/dataget/peanut_merge/test_merge.rds", help = "Path to RDS file"),
    make_option(c("-a", "--assay"), type = "character", default = "RNA", help = "Assay to use"),
    make_option(c("-b", "--batch_key"), type = "character", default = "biosample", help = "Batch variable"),
    make_option(c("-g", "--cluster_key"), type = "character", default = "leiden_res_0.50", help = "Group variable"),
    make_option(c("-o", "--only_pos"), type = "character", default = "yes", help = "Whether is only focusing positive genes"),
    make_option(c("-p", "--p_threshold"), type = "numeric", default = 1e-10, help = "P value of maxiusm")
)
opt <- parse_args(OptionParser(option_list = option_list))
rds <- opt$rds
assay <- opt$assay
batch_key <- opt$batch_key
cluster_key <- opt$cluster_key
only_pos <- opt$only_pos
p_threshold <- opt$p_threshold

only_pos <- only_pos == "yes"
seu <- readRDS(rds); print(seu)
DefaultAssay(seu) <- assay
celltypes <- unique(seu@meta.data[[cluster_key]])

# if (assay == "RNA") {
#     seu <- NormalizeData(seu)
# }

# 记录脚本起始时间
start_time <- proc.time()

name <- basename(rds)

# FindAllMarkers 
# "p_val" "avg_log2FC" "pct.1" "pct.2" "p_val_adj" "cluster" "gene"
Idents(seu) <- seu@meta.data[[cluster_key]]
allmarkers <- FindAllMarkers(seu, assay = assay, group.by = cluster_key, only.pos = only_pos) # nolint
allmarkers <- allmarkers %>% filter(p_val_adj < p_threshold)
print(head(allmarkers))
write.csv(allmarkers, paste0("allmarkers_", name, ".csv"), row.names = FALSE)


# FindConservedMarkers
# "WT_p_val" "WT_avg_log2FC" "WT_pct.1" "WT_pct.2" "WT_p_val_adj" "Mut_p_val" "Mut_avg_log2FC" "Mut_pct.1" "Mut_pct.2" "Mut_p_val_adj" "max_pval" "minimump_p_val" "cluster" "gene" "avg_log2FC" "p_val_adj"
if (batch_key %in% colnames(seu@meta.data)) {
    conserved_markers <- list()
    for (cell_type in celltypes) {
        Idents(seu) <- seu@meta.data[[cluster_key]]
        markers <- FindConservedMarkers(seu, ident.1 = cell_type, grouping.var = batch_key, only.pos = only_pos, assay = assay) # nolint
        # `assay` `ident.1` `grouping.var` `only.pos = TRUE`
        avg_log2FC_columns <- grep("_avg_log2FC$", names(markers), value = TRUE)
        if (length(avg_log2FC_columns) == 1) {
            markers$avg_log2FC <- markers[[avg_log2FC_columns]]
        } else {
            markers$avg_log2FC <- rowMeans(markers[, avg_log2FC_columns], na.rm = TRUE)
        }
        p_val_adj_columns <- grep("_p_val_adj$", names(markers), value = TRUE)
        if (length(avg_log2FC_columns) == 1) {
            markers$p_val_adj <- markers[[p_val_adj_columns]]
        } else {
            markers$p_val_adj <- rowMeans(markers[, p_val_adj_columns], na.rm = TRUE)
        }
        markers$cluster <- cell_type
        markers$gene <- rownames(markers)
        conserved_markers[[cell_type]] <- markers
    }
    conserved_markers <- bind_rows(conserved_markers)
    conserved_markers <- conserved_markers %>% filter(p_val_adj < p_threshold)
    print(head(conserved_markers))
    write.csv(conserved_markers, paste0("conserved_markers_", name, ".csv"), row.names = FALSE) # nolint
}

elapsed <- (proc.time() - start_time)[3] / 3600
cat("[TIME] 总运行时间:", round(elapsed, 3), "h\n")