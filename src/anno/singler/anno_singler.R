# Date: 20250908 # Title: run_singler.R # Coder: ydgenomics
# Description: Using SingleR to annotate single-cell RNA-seq data based on a custom reference dataset.
# Input: reference .rds has RNA, query .rds files, and a metadata key for clustering in the reference dataset
# Image: Seurat-R-- /software/miniconda/envs/Seurat/bin/R
# Reference: [使用singleR基于自建数据库来自动化注释单细胞转录组亚群](https://mp.weixin.qq.com/s/GpOxe4WLIrBOjbdH5gfyOQ)

library(Seurat)
library(SingleCellExperiment)
library(scater)
library(SingleR)
library(dplyr)
library(tidyr)  # pivot_wider 需要 tidyr
library(tibble)
library(pheatmap)
library(optparse)
library(ggplot2)

option_list <- list(
    make_option(
        c("-r", "--input_ref_rds"), type = "character", default = "/data/work/Single-Cell-Pipeline/Alignment/test/Os.hr_genes_changed.rds", help = "Path to the reference dataset"),
    make_option(
        c("-k", "--ref_cluster_key"), type = "character", default = "celltypes",help = "Metadata key for clustering in the reference dataset"),
    make_option(
        c("-q", "--input_query_rds"), type = "character", default = "/data/input/Files/yangdong/wdl/Anno-singler/Sv.hr.rds", help = "Path to the query dataset"),
    make_option(
        c("-d", "--query_cluster_key"), type = "character", default = "seurat_clusters",help = "Metadata key for clustering in the query dataset"),
    make_option(
        c("-u", "--umap_name"), type = "character", default = "Xumap_", help = "UMAP reduction name") # `CHOIR_P0_reduction_UMAP`
)
opt <- parse_args(OptionParser(option_list = option_list))
input_ref_rds <- opt$input_ref_rds
ref_cluster_key <- opt$ref_cluster_key
input_query_rds <- opt$input_query_rds
query_cluster_key <- opt$query_cluster_key
umap_name <- opt$umap_name

# Precheck genes 
write_report <- function(..., append = FALSE) {
  con <- file("report.txt", if (append) "at" else "wt")
  sink(con, type = "output")
  sink(con, type = "message")
  eval.parent(substitute(...))
  sink(type = "output")
  sink(type = "message")
  close(con)
}

write_report({
  ref_seu <- readRDS(input_ref_rds)
  cat("Reference dataset loaded successfully.\n")
  print(ref_seu)
  cat("First 10 genes in the reference dataset:\n")
  print(head(rownames(ref_seu), n=10))
  query_seu <- readRDS(input_query_rds)
  cat("\nQuery dataset loaded successfully.\n")
  print(query_seu)
  cat("First 10 genes in the Query dataset:\n")
  print(head(rownames(query_seu), n=10))
  common_genes <- intersect(rownames(ref_seu), rownames(query_seu))
  num_common_genes <- length(common_genes)
  print(paste0("The common gene number of Reference and Query data: ", num_common_genes))
})


# Step 1: Load the reference dataset and create a singleR reference Rdata object
create_ref_singler <- function(input_ref_rds, ref_cluster_key) {
    ref_seu <- readRDS(input_ref_rds);print(ref_seu); print(head(rownames(ref_seu), n=10))
    colnames(ref_seu@meta.data); Idents(ref_seu) <- ref_seu@meta.data[[ref_cluster_key]]
    av <- AggregateExpression(
        ref_seu, group.by = ref_cluster_key, assays = "RNA"
    )
    ref_mat <- av[[1]]
    ref_sce <- SingleCellExperiment(
        assays = list(counts = ref_mat)
    )
    ref_sce <- scater::logNormCounts(ref_sce)
    colData(ref_sce)$Type <- colnames(ref_mat)
    output_ref_rdata <- paste0(sub("\\.rds$", "", basename(input_ref_rds)), "_ref_singler.Rdata")
    save(ref_sce, file = output_ref_rdata)
    return(ref_sce)
}


# Step 2: Load the query dataset and run singleR for annotation
run_singler <- function(query_seu, ref_sce, prefix) {
    # query_seu <- readRDS(input_query_rds); DefaultAssay(query_seu) <- "RNA"
    DefaultAssay(query_seu) <- "RNA"
    # query_seu <- NormalizeData(query_seu, normalization.method = "LogNormalize", scale.factor = 10000)
    query_data <- GetAssayData(query_seu, slot = "data")
    common_genes <- intersect(rownames(query_data), rownames(ref_sce))
    num_common_genes <- length(common_genes)
    print(
        paste0(
            "The common gene number of Reference and Query data: ",
            num_common_genes
        )
    )
    pred <- SingleR(
        test = query_data, ref = ref_sce, labels = ref_sce$Type
    )
    # plot and save pred
    n_label <- length(unique(pred$labels))
    pdf(paste0(prefix, "_pred.pdf"), width = n_label, height = n_label/2)
    plotScoreHeatmap(pred)
    p <- plotDeltaDistribution(pred, ncol = 8, dots.on.top = FALSE); print(p)
    p <- plotScoreDistribution(pred, ncol = 8, dots.on.top = FALSE); print(p)
    dev.off()
    write.csv(pred, paste0(prefix, "_pred.csv"))
    # save to query_seu
    if ("singler" %in% colnames(query_seu@meta.data)) {
        query_seu$singler0 <- query_seu$singler
    }
    query_seu$singler <- pred$labels
    query_seu$singler_pruned <- pred$pruned.labels
    return(query_seu)
}

ref_sce <- create_ref_singler(input_ref_rds, ref_cluster_key)
prefix <- sub("\\.rds$", "", basename(input_query_rds))
seu <- run_singler(query_seu, ref_sce, prefix)

# === Cluster-level identity by majority voting ===
# Replace NA in pruned.labels with "Unknown"
seu$singler_pruned[is.na(seu$singler_pruned)] <- "Unknown"

# Build count matrix (cell_type × cluster)
vote_df <- data.frame(
  cluster  = seu@meta.data[[query_cluster_key]],
  celltype = seu$singler_pruned,
  stringsAsFactors = FALSE
)

count_matrix <- vote_df %>%
  dplyr::count(cluster, celltype) %>%
  pivot_wider(names_from = cluster, values_from = n, values_fill = 0) %>%
  column_to_rownames("celltype") %>%
  as.matrix()

# Percentage per cluster (each cluster sums to 100%)
prob_matrix <- sweep(count_matrix, 2, colSums(count_matrix), `/`) * 100
rownames(prob_matrix) <- rownames(count_matrix)

# Save probability matrix
write.csv(prob_matrix,
  paste0(prefix, "_singler_prob_clusters.csv"),
  row.names = TRUE)

# Determine cluster identity with purity threshold (Scheme A)
purity_threshold <- 30
cluster_identity <- data.frame(
  cluster = colnames(prob_matrix),
  singler = rownames(prob_matrix)[apply(prob_matrix, 2, which.max)],
  prob    = apply(prob_matrix, 2, max),
  purity_check = "pass",
  stringsAsFactors = FALSE
)
rownames(cluster_identity) <- NULL

# Apply purity threshold
for (i in 1:nrow(cluster_identity)) {
  cl <- cluster_identity$cluster[i]
  top_prob <- cluster_identity$prob[i]

  if (top_prob > purity_threshold) {
    # High confidence (>50%): keep the label
    cluster_identity$purity_check[i] <- "pass"
  } else {
    # Low confidence: mark as "Unknown"
    cluster_identity$singler[i] <- "Unknown"
    cluster_identity$prob[i] <- NA
    cluster_identity$purity_check[i] <- "fail"
  }
}

# Write cluster-level identity to Seurat metadata
seu$singler <- NA_character_
for (i in 1:nrow(cluster_identity)) {
  cl <- cluster_identity$cluster[i]
  ct <- cluster_identity$singler[i]
  seu$singler[seu@meta.data[[query_cluster_key]] == cl] <- ct
}

# Print and warn about low-confidence clusters
print(cluster_identity)
low_confidence <- cluster_identity[cluster_identity$purity_check == "fail", ]
if (nrow(low_confidence) > 0) {
  message(sprintf(
    "[warning] %d clusters have no majority (> %.0f%%), marked as 'Unknown':",
    nrow(low_confidence), purity_threshold))
  print(low_confidence[, c("cluster", "singler")])
  message("[suggestion] Consider sub-clustering these clusters for better resolution.")
}

write.csv(cluster_identity,
  paste0(prefix, "_singler_cluster_identity.csv"),
  row.names = FALSE)


pdf(paste0(prefix, "_singler.pdf"))
DimPlot(seu, reduction = umap_name, group.by = 'singler', shuffle = TRUE, label = TRUE) + NoLegend()
dev.off()

ggsave(paste0(prefix, "_singler.png"),
       plot = DimPlot(seu, reduction = umap_name, group.by = 'singler', shuffle = TRUE, label = TRUE) + NoLegend(),
       dpi = 300)

# === Component heatmap (from prob_matrix) ===
n_types <- nrow(prob_matrix)
pdf(paste0(prefix, "_component.pdf"), width = n_types / 2, height = n_types / 2)
pheatmap(prob_matrix,
         cluster_rows = TRUE,
         cluster_cols = TRUE,
         display_numbers = TRUE,
         number_format = "%.1f",
         number_color = "black",
         color = colorRampPalette(c("white", "yellow", "red"))(100),
         main = "Cluster Component Heatmap (pruned)")
dev.off()
              
# Save the annotated query dataset
output_query_rds <- paste0(prefix, "_singler.rds")
saveRDS(seu, file = output_query_rds)