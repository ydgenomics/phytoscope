### Date: 260703 SCTransform.CCA_integration.R
### Image: integration-R-- /opt/conda/bin/R
### Coder: ydgenomics
### Ref: https://satijalab.org/seurat/archive/v4.3/sctransform_v2_vignette

library(Seurat) # make sure you are running SeuratV5
options(Seurat.object.assay.version = 'v5')
library(SeuratData)
library(patchwork)
library(optparse)
library(ggplot2)
library(magrittr)

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

out_rds <- paste0(prefix, '_SCTransform.CCA_integrated.rds')
out_UMAP <- paste0(prefix, '_SCTransform.CCA_integrated.pdf')

#pre-processs
obj <- readRDS(input_rds)
obj.list <- SplitObject(obj, split.by = batch_key)
obj.list.transformed <- list()
batch_keys <- unique(obj@meta.data[[batch_key]])
for (i in batch_keys) {
  current.obj <- obj.list[[i]]
  transformed.obj <- SCTransform(current.obj, vst.flavor = "v2", verbose = FALSE) %>% RunPCA(npcs = 30, verbose = FALSE)
  obj.list.transformed[[i]] <- transformed.obj
}
obj.list <- obj.list.transformed
obj.list


#Perform integration 
#features <- SelectIntegrationFeatures(object.list = obj.list, nfeatures = 3000)
features <- SelectIntegrationFeatures(object.list = obj.list)
obj.list <- PrepSCTIntegration(object.list = obj.list, anchor.features = features)
#method=cca
obj.anchors <- FindIntegrationAnchors(object.list = obj.list, normalization.method = "SCT", anchor.features = features, reduction = "cca")
obj <- IntegrateData(anchorset = obj.anchors, normalization.method = "SCT")


#Perform an integrated analysis
obj <- RunPCA(obj, verbose = FALSE)
obj <- RunUMAP(obj, reduction = "pca", dims = 1:30, verbose = FALSE)
obj <- FindNeighbors(obj, reduction = "pca", dims = 1:30)
obj <- FindClusters(obj, resolution = resolution, cluster.name = cluster_name)

#save rds
saveRDS(obj, file = out_rds)

key_list <- c(key_list, cluster_name)

pdf(out_UMAP)
for (i in c(batch_key, key_list)){
    p <- DimPlot(obj, reduction = "umap", group.by = i, shuffle = TRUE, label = TRUE) + NoLegend()
    print(p)
}
dev.off()

# 保存各分组的 UMAP 为 PNG
method_tag <- gsub(paste0("^", prefix, "_(.+)_integrated\\.rds$"), "\\1", out_rds)
for (i in c(batch_key, key_list)) {
    p <- DimPlot(obj, reduction = "umap", group.by = i, shuffle = TRUE, label = TRUE) + NoLegend()
    ggsave(paste0(method_tag, "_", i, ".png"), plot = p, width = 10, height = 8, dpi = 300)
}

reduc_names <- c("pca")

for (red_name in reduc_names) {
    reduc <- obj[[red_name]]
    emb <- as.data.frame(Embeddings(reduc))
    emb <- cbind(cell_id = rownames(emb), emb)
    # CSV 不压缩
    red_file <- paste0(red_name, "_SCTransform.CCA_integrated.csv")
    write.csv(emb, red_file, row.names = FALSE)
}

elapsed <- (proc.time() - start_time)[3] / 3600
cat("[TIME] 总运行时间:", round(elapsed, 3), "h\n")