# > MetaNeighbor计算批次的细胞群间的相似度(AUC)，hclust基于层次聚类进行批次间分群的统一并赋予标签
# 260630
# Rscript /data/work/MetaNeighbor/metaneighbor.R \
# --input_rds /data/work/Anno/cell_type.rds \
# --output_name Sp_anno --batch_key biosample --cluster_key cell_type \
# --new_key metaneighbor2 --cut_value 5

suppressPackageStartupMessages({
    library(MetaNeighbor)
    library(SummarizedExperiment)
    library(Seurat)
    library(dplyr)
    library(SingleCellExperiment)
    library(grid)
    library(ComplexHeatmap)
    library(circlize)
    library(ggplot2)
    library(igraph)
    library(plyr)
    library(RColorBrewer)
    library(optparse)
})

option_list <- list(
  make_option(
    c("-i", "--input_rds"), 
    type = "character", 
    default = "/data/work/Convert/jt_ctrl.hr.rds,/data/work/Convert/jt_stim.hr.rds",
    help = "输入 Seurat 对象的路径，多个文件用逗号(,)隔开 [默认: None]", 
    metavar = "character"
  ),
  make_option(
    c("-o", "--output_name"), 
    type = "character", 
    default = "species",
    help = "输出文件和图表的前缀名 [默认: species]", 
    metavar = "character"
  ),
  make_option(
    c("-b", "--batch_key"), 
    type = "character", 
    default = "biosample",
    help = "Seurat元数据中代表批次/样本的列名 [默认:biosample]", 
    metavar = "character"
  ),
  make_option(
    c("-c", "--cluster_key"), 
    type = "character", 
    default = "leiden_res_0.50",
    help = "Seurat元数据中代表细胞聚类的列名 [默认: leiden_res_0.50]", 
    metavar = "character"
  ),
  make_option(
    c("-n", "--new_key"), 
    type = "character", 
    default = "metaneighbor",
    help = "新的分群的key", 
    metavar = "character"
  ),
  make_option(
    c("-a", "--assay"), 
    type = "character", 
    default = "RNA",
    help = "分析所使用的 Assay 名称 [默认: RNA]", 
    metavar = "character"
  ),
  make_option(
    c("-v", "--cut_value"), 
    type = "numeric",               # 自动处理你前面要求的类型转换逻辑
    default = 6,
    help = "层次聚类剪枝参数。>1 为群组数 k，<=1 为树高度 h [默认: 6]", 
    metavar = "number"
  )
)

# 3. 解析传参
opt_parser <- OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)

# 4. 将解析出的参数赋值给变量，以便后续代码直接使用
input_rds   <- opt$input_rds
output_name <- opt$output_name
batch_key   <- opt$batch_key
cluster_key <- opt$cluster_key
new_key     <- opt$new_key
assay       <- opt$assay
cut_value   <- opt$cut_value

# 5. 打印参数（用于在日志中确认参数是否正确输入）
cat("======= 📊 运行参数确认 =======\n")
cat("Input RDS   :", input_rds, "\n")
cat("Output Name :", output_name, "\n")
cat("Batch Key   :", batch_key, "\n")
cat("Cluster Key :", cluster_key, "\n")
cat("New Key     :", new_key, "\n")
cat("Assay       :", assay, "\n")
cat("Cut Value   :", cut_value, "\n")
cat("===============================\n\n")


# ==========================================
# 后续的多文件读取逻辑示例：
# ==========================================
rds_files <- unlist(strsplit(input_rds, ","))
cat("检测到以下待读取的文件：\n")
print(rds_files)


#' 检查输入Seurat对象路径/用,连接的路径是否有合适的键
check_input <- function(input_file, batch_key, cluter_key){
    message("[check_input] Checking input files...")
    merged_data <- readRDS(input_file[[1]]); DefaultAssay(merged_data) <- "RNA"
    if (batch_key %in% colnames(merged_data@meta.data)) {
        print(paste0("Batch key ", batch_key, " found in metadata."))
    } else {
        prefix <- basename(input_file[[1]])
        merged_data@meta.data[[batch_key]] <- prefix
        print(paste0("Batch key ", batch_key, " not found. Added with value ", prefix, "."))
    }
    if (length(input_file) > 1) {
        message("[check_input] Merging additional input files...")
        for (i in 2:length(input_file)) {
            temp_data <- readRDS(input_file[[i]]); DefaultAssay(temp_data) <- "RNA"
            if (batch_key %in% colnames(temp_data@meta.data)) {
                print(paste0("Batch key ", batch_key, " found in metadata."))
            } else {
                prefix <- basename(input_file[[i]])
                temp_data@meta.data[[batch_key]] <- prefix
                print(paste0("Batch key ", batch_key, " not found. Added with value ", prefix, "."))
            }
            merged_data <- merge(merged_data, temp_data)
        }
    }
    tryCatch({
        print(merged_data$RNA@counts[1:5,1:5])
    }, error = function(e) {
        print(merged_data$RNA$counts[1:5,1:5])
    })
    message("> Printing metadata columns:")
    print(colnames(merged_data@meta.data))
    message("> Printing [batch_key] & [cluster_key]:")
    print(table(merged_data@meta.data[[batch_key]]))
    print(table(merged_data@meta.data[[cluster_key]]))
    return(merged_data)
}


#' 计算不同批次各自群之间的相似度即AUC值
run_metaneighbor <- function(merged_data, batch_key, cluster_key, output_name, assay = "RNA"){
    message("[run_metaneighbor] Running MetaNeighbor analysis...")
    sdata <- as.SingleCellExperiment(merged_data, assay = assay, slot = "counts")
    var_genes = variableGenes(dat = sdata, exp_labels = sdata@colData[[batch_key]])
    celltype_NV = MetaNeighborUS(var_genes = var_genes,
                                dat = sdata,
                                study_id = sdata@colData[[batch_key]],
                                cell_type = sdata@colData[[cluster_key]],
                                fast_version = TRUE)
    return(celltype_NV)
}


#' 自动化层次聚类与动态剪枝函数
#'
#' @param auc_matrix 输入的AUC/AUROC值矩阵（群与群之间的相似性矩阵）
#' @param method hclust的聚类方法，默认使用 "complete"
#' @param cut_value 剪枝参数。可以是大于1的整数（代表聚类数k），或0-1之间的浮点数（代表树高度h）
#'
#' @return 返回一个包含原始群名和新聚类标签的数据框 (data.frame)
get_meta_clusters <- function(auc_matrix, method = "complete", cut_value = 6) {
  
  # 1. 安全检查与类型转换
  if (missing(cut_value)) {
    stop("错误：必须提供 cut_value 参数（可以是一个整数 k 或浮点数 h）。")
  }
  
  # 强制转换为浮点数
  cut_value <- as.numeric(cut_value)
  if (is.na(cut_value)) {
    stop("错误：输入的 cut_value 无法转换为有效的数字。")
  }
  
  # 2. 计算距离矩阵并运行 hclust
  # MetaNeighbor 的距离通常定义为 1 - AUC
  dist_matrix <- as.dist(1 - auc_matrix)
  hc <- hclust(dist_matrix, method = method)
  
  # 3. 核心核心判断：基于输入值大小决定剪枝策略
  if (cut_value > 1) {
    # 如果大于1，判定为期望的聚类个数 k
    k_val <- as.integer(cut_value) # 确保是整数
    cat(paste0("[get_meta_clusters] 检测到 cut_value > 1，正在基于【聚类数量 k = ", k_val, "】进行剪枝...\n"))
    meta_clusters <- cutree(hc, k = k_val)
    
  } else {
    # 如果小于等于1，判定为树的高度不相似度阈值 h
    cat(paste0("[get_meta_clusters] 检测到 cut_value <= 1，正在基于【树干高度 h = ", cut_value, "】进行剪枝...\n"))
    meta_clusters <- cutree(hc, h = cut_value)
  }
  
  # 4. 构建并格式化输出的 data.frame
  dendro_cluster_df <- data.frame(
    group = names(meta_clusters),
    dendrogram_cluster = paste0("cluster_", meta_clusters), # 直接在这里拼接前缀
    stringsAsFactors = FALSE
  )
  
  cat("[get_meta_clusters] 打印 dendro_cluster_df 前几行\n")
  print(head(dendro_cluster_df))
  
  list(dendro_cluster_df = dendro_cluster_df, hc = hc) # 同时返回聚类结果和 hclust 对象以供后续使用
}

seu <- check_input(rds_files, batch_key, cluster_key)
celltype_NV <- run_metaneighbor(seu, batch_key, cluster_key, output_name, assay)
result <- get_meta_clusters(celltype_NV, method = "complete", cut_value = cut_value)
dendro_cluster_df <- result$dendro_cluster_df
hc <- result$hc

# 将新的聚类标签添加到 Seurat 对象的元数据中
combined_key <- paste0(batch_key, "|", cluster_key)
seu@meta.data[[combined_key]] <- paste(
    seu@meta.data[[batch_key]], 
    seu@meta.data[[cluster_key]], 
    sep = "|"
)
group2dendro <- setNames(
  dendro_cluster_df$dendrogram_cluster, 
  dendro_cluster_df$group
)

seu@meta.data[[new_key]] <- unname(group2dendro[match(seu@meta.data[[combined_key]], names(group2dendro))])

name <- paste0("auc_hclust_", as.character(cut_value))
seu@meta.data[[name]] <- seu@meta.data[[new_key]]

write.csv(celltype_NV, file = paste0(output_name, "_metaNeighbor.csv"), quote = FALSE, row.names = TRUE)
saveRDS(seu, file = paste0(output_name, "_metaneighbor.rds"))

# plot
pdf(paste0(output_name,"_metaNeighbor.pdf"), width=7+0.1*length(rownames(celltype_NV)), height=5+0.1*length(rownames(celltype_NV)))
cols = rev(colorRampPalette(RColorBrewer::brewer.pal(11,"RdYlBu"))(100))
breaks = seq(0, 1, length=101)
gplots::heatmap.2(celltype_NV,
                  col = cols,
                  breaks = breaks,
                  key.xlab = "AUROC",
                  margins = c(8, 8),
                  trace = "none",
                  density.info = "none",
                  offsetRow=0.1,
                  offsetCol=0.1,
                  cexRow = 0.7,
                  cexCol = 0.7)

mat <- as.matrix(celltype_NV)

# 2. 创建注释数据框（行名必须与矩阵的行列名完全一致）
# 假设 dendro_cluster_df 的第一列是 group（样本/群名），第二列是新分群
rownames(dendro_cluster_df) <- dendro_cluster_df$group

# 提取出分类信息，并转换为因子（Factor）以方便分配颜色
annotation_df <- data.frame(
  New_Cluster = as.factor(dendro_cluster_df[rownames(mat), "dendrogram_cluster"])
)
rownames(annotation_df) <- rownames(mat)

# 3. 为你的新分群自动生成一套颜色（比如 40 个群就生成 40 种颜色）
num_clusters <- length(unique(annotation_df$New_Cluster))
cluster_colors <- rainbow(num_clusters) 
names(cluster_colors) <- levels(annotation_df$New_Cluster)

# 4. 创建热图的侧边注释条
row_ann <- rowAnnotation(
  Cluster = annotation_df$New_Cluster,
  col = list(Cluster = cluster_colors)
)

col_ann <- HeatmapAnnotation(
  Cluster = annotation_df$New_Cluster,
  col = list(Cluster = cluster_colors),
  show_legend = FALSE # 顶部的图例和侧边一样，可以隐藏一个
)

# 5. 绘制热图
# 注意：cluster_rows 和 cluster_columns 可以直接传入你之前算好的 hclust 对象 hc
Heatmap(
  mat,
  name = "AUROC",
  cluster_rows = hc,          # 使用你之前算好的 hclust 树结构
  cluster_columns = hc,       # 保持行列树状图一致
  left_annotation = row_ann,  # 左侧加上分群彩色条
  top_annotation = col_ann,   # 顶部加上分群彩色条
  show_row_names = TRUE,      # 是否显示原有的群名
  show_column_names = TRUE
)

# 如果你想把所有的图保存到一个 PDF 中，请取消下面这行的注释（并指定路径）
# pdf("my_cluster_analysis_plots.pdf", width = 10, height = 7)

if ("umap" %in% names(seu@reductions)) {
    p <- DimPlot(
        object = seu, 
        reduction = "umap",              # 指定使用 UMAP 降维结果
        group.by = new_key,              # 分群键设置为 metaneighbor
        cols = cluster_colors,           # 按你定义的变量分配颜色
        label = TRUE,                    # 在图上给每个群中心点加上标签
        label.size = 5,                  # 标签字体大小
        repel = TRUE                     # 防止标签重叠
        ) + 
        labs(title = "UMAP Colored by MetaNeighbor Clusters") + 
        theme_minimal() +                # 使用一个干净的主题风格
        theme(plot.title = element_text(hjust = 0.5, face = "bold")) # 标题居中加粗
    print(p)
    
    p1 <- DimPlot(seu, reduction = "umap", group.by = batch_key)
    print(p1)
    
    p2 <- DimPlot(seu, reduction = "umap", group.by = combined_key)
    print(p2)
} else {
    message("UMAP reduction not found in Seurat object. Skipping UMAP plot.")
}

# 1. 提取元数据并计算频数
df <- seu@meta.data %>%
  group_by(!!sym(batch_key), !!sym(new_key)) %>%
  dplyr::tally() %>%
  ungroup() %>% 
  group_by(!!sym(batch_key)) %>% 
  dplyr::mutate(Percentage = n / sum(n) * 100) %>%
  ungroup()

print(df)
# 2. 绘制百分比堆叠条形图
p_bar <- ggplot(df, aes(x = .data[[batch_key]], y = Percentage, fill = .data[[new_key]])) +
  geom_bar(stat = "identity", position = "stack", width = 0.8) + 
  scale_fill_manual(values = cluster_colors) + 
  theme_minimal(base_size = 16) +
  labs(
    x = batch_key,
    y = "Percentage (%)",
    fill = new_key
  ) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_line(color = "black"), # 加上坐标轴线，让图表看起来更有学术感
    legend.position = "right"
  )

print(p_bar)
dev.off()