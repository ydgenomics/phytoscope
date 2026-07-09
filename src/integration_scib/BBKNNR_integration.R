### Date: 260703
### Ref: https://mp.weixin.qq.com/s/ZkY8R3yZEEsIuV8lDIAdlA

library(bbknnR)
library(Seurat)
library(ggplot2)
library(dplyr)
library(SeuratData)
library(patchwork)
library(optparse)
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

out_rds <- paste0(prefix, '_BBKNNR_integrated.rds')
out_UMAP <- paste0(prefix, '_BBKNNR_integrated.pdf')

#### 1.load dataset
obj <- readRDS(input_rds)
#obj[["RNA"]] <- split(obj[["RNA"]], f = obj$biosample)
#### 2.normalize/HVG/scale/pca
#obj <- NormalizeData(obj) 
#obj <- FindVariableFeatures(obj, selection.method = "vst")
#obj <- ScaleData(obj)
#obj <- RunPCA(obj, npcs = 50, verbose = FALSE)
obj <- NormalizeData(obj) %>% FindVariableFeatures(selection.method = "vst") %>% ScaleData() %>% RunPCA(npcs = 50, verbose = FALSE)

#### 3. bbknn
obj <- RunBBKNN(obj, reduction = "pca", run_TSNE = FALSE, batch_key = batch_key)
#obj[["RNA"]] <- JoinLayers(obj[["RNA"]])
#obj <- FindNeighbors(obj, reduction = "pca", k.param = 10, dims = 1:30) 
#obj <- FindClusters(obj, resolution = resolution_set, cluster.name = "integrated_cluster", algorithm = 1, graph.name="bbknn")
#obj <- FindClusters(obj, resolution = resolution_set, cluster.name = "integrated_cluster")

obj <- FindNeighbors(obj, reduction = "pca", k.param = 10, dims = 1:30) %>%
  FindClusters(resolution = resolution, algorithm = 1, graph.name = "bbknn", cluster.name = cluster_name) %>%
  identity()
unique(obj@meta.data[[cluster_name]])
obj
#
#obj <- RunUMAP(obj, reduction = "pca", dims = 1:30, reduction.name = "umap")
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

elapsed <- (proc.time() - start_time)[3] / 3600
cat("[TIME] 总运行时间:", round(elapsed, 3), "h\n")