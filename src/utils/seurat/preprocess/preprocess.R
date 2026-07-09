# CHOIR+singleR

library(Seurat)

args <- commandArgs(trailingOnly = TRUE)
if(length(args) != 2){stop('
### Example
cd /data/output
input_rds="/data/work/Convert/at.hr.rds"
umap_name="umap"
Rscript /data/work/seurat/preprocess.R $input_rds $umap_name
Rscript preprocess.R $input_rds $umap_name
')}
input_rds <- args[1]
umap_name <- args[2]

# 记录脚本起始时间
start_time <- proc.time()

seu <- readRDS(input_rds)
seu <- UpdateSeuratObject(seu)
print(seu)


# 检查seu是否RNA的结果完整，包含标准化好的表达矩阵、高变基因，scale.data
# 1. 检查是否存在 RNA assay
if (!"RNA" %in% names(seu@assays)) {
    stop("[info] The Seurat object does not contain an RNA assay.")
}

# 2. 检查并处理标准化数据 (data layer)
if (!"data" %in% Layers(seu, assay = "RNA")) {
    message("[info] The RNA assay does not contain a 'data' layer. Normalizing...")
    seu <- NormalizeData(seu, normalization.method = "LogNormalize", scale.factor = 10000)
} else if (any(is.na(LayerData(seu, assay = "RNA", layer = "data")))) {
    message("[info] The 'data' layer contains NA values. Re-normalizing...")
    seu <- NormalizeData(seu, normalization.method = "LogNormalize", scale.factor = 10000)
}

print(LayerData(seu, assay = "RNA", layer = "data")[1:10, 1:10])

# 3. 检查并处理高变基因 (Variable Features)
if (length(VariableFeatures(seu)) == 0) {
    message("[info] No variable features found. Finding variable features...")
    seu <- FindVariableFeatures(seu, selection.method = "vst", nfeatures = 2000)
}

# 4. 检查并处理缩放数据 (scale.data layer)
if (!"scale.data" %in% Layers(seu, assay = "RNA")) {
    message("[info] The RNA assay does not contain a 'scale.data' layer. Scaling...")
    seu <- ScaleData(seu, features = VariableFeatures(seu))
} else if (any(is.na(LayerData(seu, assay = "RNA", layer = "scale.data")))) {
    message("[info] The 'scale.data' layer contains NA values. Re-scaling...")
    seu <- ScaleData(seu, features = VariableFeatures(seu))
}

if (!umap_name %in% names(seu@reductions)) {
    message("[info] The Seurat object does not contain a UMAP reduction. Running PCA, FindNeighbors, and UMAP...")
    seu <- RunPCA(seu, features = VariableFeatures(seu), npcs = 40, verbose = FALSE)
    seu <- FindNeighbors(seu, dims = 1:30, verbose = FALSE)
    seu <- RunUMAP(seu, dims = 1:30, reduction.name = umap_name, verbose = FALSE)
} else {
    message("[info] The Seurat object already contains a UMAP reduction. Skipping PCA, FindNeighbors, and UMAP.")
}

print(seu)
saveRDS(seu, basename(input_rds))

message("[info] Check complete! RNA assay is ready.")

elapsed <- (proc.time() - start_time)[3] / 3600
cat("[TIME] 总运行时间:", round(elapsed, 3), "h\n")