### Date: 260309 SCTransform.harmony_integration.R
### Image: integration-R-- /opt/conda/bin/R
### Coder: ydgenomics
### Ref: https://satijalab.org/seurat/articles/seurat5_integration
# Interesting thing is written for V5.20 'split()' and 'IntegrateLayers'

library(Seurat) # make sure you are running SeuratV5
options(Seurat.object.assay.version = 'v5')
library(SeuratData)
library(patchwork)
library(optparse)
library(ggplot2)

option_list <- list(
  make_option(c("-i", "--input_rds"),
    type = "character", default = NULL,
    help = "Path to input preprocessed rds file"
  ),
  make_option(c("-o", "--prefix"),
    type = "character", default = NULL,
    help = "Prefix of output file"
  ),
  make_option(c("-b", "--batch_key"),
    type = "character", default = NULL,
    help = "Batch key identifier to integrate"
  ),
  make_option(c("-k", "--key_list"),
    type = "character", default = "biosample,sample",
    help = "Sample key identifier"
  ),
  make_option(c("-r", "--resolution"),
    type = "double", default = 0.5,
    help = "Set the resolution for clustering"
  ),
  make_option(c("-c", "--cluster_name"),
    type = "character", default = "celltype",
    help = "New cluster new"
  )
)

# parse input
opt <- parse_args(OptionParser(option_list = option_list))
input_rds <- opt$input_rds
prefix <- opt$prefix
batch_key <- opt$batch_key
key_list <- strsplit(opt$key_list, ",")[[1]]
resolution <- opt$resolution
cluster_name <- opt$cluster_name

# 记录脚本起始时间
start_time <- proc.time()

out_rds <- paste0(prefix, '_SCTransform.harmony_integrated.rds')
out_UMAP <- paste0(prefix, '_SCTransform.harmony_integrated.pdf')

obj <- readRDS(input_rds)
#obj <- subset(obj, nFeature_RNA > 1000)

obj[["RNA"]] <- split(obj[["RNA"]], f = obj@meta.data[[batch_key]])

# run sctransform
obj <- SCTransform(obj, vst.flavor = "v2")
obj <- RunPCA(obj, npcs = 30, verbose = FALSE)

# one-liner to run Integration
obj <- IntegrateLayers(object = obj, method = HarmonyIntegration,
                       orig.reduction = "pca", new.reduction = 'harmony',
                       assay = "SCT", verbose = FALSE)
obj <- FindNeighbors(obj, reduction = "harmony", dims = 1:30)
# obj <- FindClusters(obj, resolution = 2, cluster.name = "harmony_clusters")
obj <- FindClusters(obj, resolution = resolution, cluster.name = cluster_name)

#colnames(obj@meta.data)[colnames(obj@meta.data) == "_index"] <- "X_index"
#
obj <- RunUMAP(obj, reduction = "harmony", dims = 1:30, reduction.name = "umap")

DefaultAssay(obj) <- "RNA"
#obj <- JoinLayers(obj)
obj [["RNA"]] <- JoinLayers(obj [["RNA"]])

# Assay RNA changing from Assay5 to Assay
tryCatch({
    obj[["RNA"]] <- as(obj[["RNA"]], "Assay")
}, error = function(e) {
    message("Error Convert Assay5 to Assay: ", e$message)
})
    
saveRDS(obj, file = out_rds)

key_list <- c(key_list, cluster_name)

pdf(out_UMAP)
DimPlot(obj, reduction = "umap", group.by = batch_key)
for (i in key_list){
    p <- DimPlot(obj, reduction = "umap", group.by = i, shuffle = TRUE, label = TRUE)
    print(p)
}
dev.off()

# 处理所有 Reductions -> reduction/（不压缩）
reduc_names <- c('harmony')

for (red_name in reduc_names) {
    reduc <- obj[[red_name]]
    emb <- as.data.frame(Embeddings(reduc))
    emb <- cbind(cell_id = rownames(emb), emb)
    # CSV 不压缩
    red_file <- paste0(red_name, "_SCTransform.harmony_integrated.csv")
    write.csv(emb, red_file, row.names = FALSE)
}

elapsed <- (proc.time() - start_time)[3] / 3600
cat("[TIME] 总运行时间:", round(elapsed, 3), "h\n")