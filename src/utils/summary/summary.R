library(Seurat)
library(ggplot2)

# 从命令行参数获取输入文件路径
args <- commandArgs(trailingOnly = TRUE)
seurat_path <- args[1]
mapping_path <- args[2]

# 读取Seurat对象
seu <- readRDS(seurat_path)

# 读取SAMap映射结果
mapping <- read.csv(mapping_path)

# 创建cluster到SAMap的映射
cluster_to_samap <- setNames(mapping$SAMap, mapping$cluster)

# 方法1：使用unname()去除名字
seu$SAMap <- unname(cluster_to_samap[seu$metaneighbor])

# 或者方法2：使用as.character()转换
# seu$SAMap <- as.character(cluster_to_samap[seu$metaneighbor])

# 检查映射结果
print(table(seu$SAMap))

# 查看可用的reduction名称
print(names(seu@reductions))

# 使用umap reduction绘图
umap_name <- "umap"

# 绘制DimPlot
p <- DimPlot(seu, reduction = umap_name, group.by = 'SAMap', shuffle = TRUE, label = TRUE) + NoLegend()

# 保存图片
ggsave("DimPlot_SAMap.png", plot = p, dpi = 300)