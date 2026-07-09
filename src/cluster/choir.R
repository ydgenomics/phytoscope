# ref: https://tomsing1.github.io/blog/posts/choir/
# https://www.choirclustering.com/articles/CHOIR.html
# https://github.com/corceslab/CHOIR/issues/29
# image: CHOIR+singleR /home/stereonote/miniconda3/envs/r_env/bin/Rscript

# 如果运行太慢/内存不足：保持 distance_approx = TRUE，核对 n_cores 是否匹配你的机器，并可尝试调小 downsampling_rate（如指定为较小的数值）。

# 如果觉得分出的细胞亚群太多（过聚类）：可以提高 min_accuracy（如 0.55 或 0.6）或者降低 alpha 值（如 0.01）。

# 如果觉得分出的亚群太少（欠聚类）：可以使用默认的 min_accuracy = 0.5，或考虑改用稍微宽松一点的 P 值校正方法 p_adjust = "fdr"。 

suppressPackageStartupMessages({
  library(CHOIR)
  library(ggnewscale)
  library(ragg)
  library(scRNAseq)
  library(Seurat)
  library(dplyr)
  library(ggplot2)
})

# setwd('/data/work/CHOIR')

args <- commandArgs(trailingOnly = TRUE)
print(args)
if(length(args) < 3 || length(args) > 5){stop('
### Usage
Rscript choir.R <input_rds> <cluster_key> <batch_key> [alpha] [random_seed]

### Arguments
  input_rds     输入 Seurat RDS 对象路径
  cluster_key   Seurat meta.data 中的聚类列名。
                若该列已存在则跳过 CHOIR；
                若不存在则执行 CHOIR 聚类。
                传递 "NULL" 表示强制运行 CHOIR（不检查）。
  batch_key     Seurat meta.data 中的批次列名。
                若 unique(batch) > 1 则按 batch split 后分别跑 CHOIR 再 merge。
                若 unique(batch) <= 1 则直接跑 CHOIR。
                传递 "NULL" 表示不分批。
  alpha         (可选) CHOIR 显著性阈值，默认 0.05
  random_seed   (可选) 随机种子，默认 42

### Examples
# 检查 cluster_key="metaneighbor"；batch_key="biosample"
Rscript choir.R input.rds metaneighbor biosample 0.05 42

# 强制运行 CHOIR，不分批
Rscript choir.R input.rds NULL NULL 0.05 42

# 强制运行 CHOIR，按 batch split
Rscript choir.R input.rds NULL biosample 0.05 42
')}

input_rds    <- args[1]
cluster_key  <- args[2]
batch_key    <- args[3]
alpha        <- ifelse(length(args) >= 4, args[4], "0.05")
random_seed  <- ifelse(length(args) >= 5, args[5], "42")

# 记录脚本起始时间
start_time <- proc.time()

# ---------------------------------------------------------------------------
# 1. 读取数据
# ---------------------------------------------------------------------------
cat("[INFO] 读取 RDS:", input_rds, "\n")
object <- readRDS(input_rds)
cat("[INFO] 输入对象:", nrow(object), "genes x", ncol(object), "cells\n")

# ---------------------------------------------------------------------------
# 2. 检查 cluster_key 是否已存在
# ---------------------------------------------------------------------------
skip_choir <- FALSE
if (tolower(cluster_key) != "null" && cluster_key %in% colnames(object@meta.data)) {
  cat("[INFO] cluster_key '", cluster_key, "' 已存在于 meta.data，跳过 CHOIR\n", sep = "")
  skip_choir <- TRUE
} else {
  if (tolower(cluster_key) != "null") {
    cat("[INFO] cluster_key '", cluster_key, "' 不存在，将运行 CHOIR 聚类\n", sep = "")
  } else {
    cat("[INFO] cluster_key 为 NULL，强制运行 CHOIR\n")
  }
}

# ---------------------------------------------------------------------------
# 3. 确定是否需要按 batch split
# ---------------------------------------------------------------------------
do_split <- FALSE
batch_values <- NULL
if (!skip_choir && tolower(batch_key) != "null" && batch_key %in% colnames(object@meta.data)) {
  batch_values <- unique(object@meta.data[[batch_key]])
  n_batch <- length(batch_values)
  cat("[INFO] batch_key '", batch_key, "' 共有", n_batch, "个批次\n")
  if (n_batch > 1) {
    do_split <- TRUE
    cat("[INFO] 批次 > 1，按 batch split 后分别跑 CHOIR\n")
  } else {
    cat("[INFO] 仅有 1 个批次，直接跑 CHOIR\n")
  }
} else if (!skip_choir) {
  cat("[INFO] batch_key 为 NULL 或不存在于 meta.data，直接跑 CHOIR\n")
}

# ---------------------------------------------------------------------------
# 4. 执行 CHOIR 聚类
# ---------------------------------------------------------------------------
run_choir_on_object <- function(obj, cluster_key, suffix = "") {
  obj <- NormalizeData(obj, verbose = FALSE)
  n_cores <- min(8, parallel::detectCores())
  cat("[INFO] 运行 CHOIR (alpha=", alpha, ", n_cores=", n_cores, ", seed=", random_seed, ")\n")
  
  obj <- CHOIR(
    obj,
    n_cores = n_cores,
    alpha = as.numeric(alpha),
    random_seed = as.integer(random_seed)
  )
  
  # 给 CHOIR 添加的聚类列加上 suffix 以区分不同批次
  if (suffix != "") {
    choir_cols <- grep("^CHOIR_", colnames(obj@meta.data), value = TRUE)
    for (col in choir_cols) {
      colnames(obj@meta.data)[colnames(obj@meta.data) == col] <- paste0(col, suffix)
    }
  }
  
  # 将 CHOIR 聚类结果赋值给 cluster_key
  choir_cluster_col <- grep("^CHOIR_clusters$", colnames(obj@meta.data), value = TRUE)
  if (length(choir_cluster_col) == 0) {
    choir_cluster_col <- grep("^CHOIR_", colnames(obj@meta.data), value = TRUE)[1]
  }
  if (length(choir_cluster_col) > 0) {
    obj@meta.data[[cluster_key]] <- obj@meta.data[[choir_cluster_col]]
    cat("[INFO] CHOIR 聚类结果已赋值至:", cluster_key, "(来源列:", choir_cluster_col, ")\n")
  } else {
    cat("[WARN] 未找到 CHOIR 聚类列，无法赋值给:", cluster_key, "\n")
  }
  
  # 保存 DimPlot PNG（分批时带 suffix 防覆盖）
  if ("CHOIR_P0_reduction" %in% names(obj@reductions)) {
    png_suffix <- if (suffix != "") paste0("_", suffix) else ""
    png_file <- paste0("CHOIR_", cluster_key, png_suffix, "_DimPlot.png")
    obj <- runCHOIRumap(obj, reduction = "P0_reduction")
    p <- DimPlot(obj, reduction = "CHOIR_P0_reduction_UMAP", group.by = cluster_key, 
                 shuffle = TRUE, label = TRUE) + NoLegend()
    ggsave(png_file, p, width = 10, height = 8, dpi = 300)
    cat("[INFO] DimPlot 已保存至:", png_file, "\n")
  } else {
    cat("[WARN] 未找到 CHOIR_P0_reduction，跳过 DimPlot\n")
  }
  
  return(obj)
}

if (skip_choir) {
  # cluster_key 已存在，直接保存
  saveRDS(object, basename(input_rds))
  elapsed <- (proc.time() - start_time)[3] / 3600
  cat("[INFO] 已跳过 CHOIR，原对象保存至:", basename(input_rds), "\n")
  cat("[TIME] 总运行时间:", round(elapsed, 3), "h\n")
  quit(save = "no")
}

if (do_split) {
  # 按 batch split -> 分别跑 CHOIR -> merge
  cat("[INFO] 按", batch_key, "拆分对象...\n")
  split_list <- SplitObject(object, split.by = batch_key)
  
  choir_list <- list()
  for (b in names(split_list)) {
    cat("[INFO] 处理批次:", b, "-", ncol(split_list[[b]]), "cells\n")
    choir_list[[b]] <- run_choir_on_object(split_list[[b]], cluster_key, suffix = b)
    # choir_list[[b]] <- run_choir_on_object(split_list[[b]], cluster_key, suffix = paste0(".", b))
  }
  
  cat("[INFO] 合并各批次结果...\n")
  object_merged <- merge(choir_list[[1]], choir_list[-1])
  
  # 确保 CHOIR 列已合并（merge 会保留 meta.data）
  cat("[INFO] 保存合并后的对象至:", basename(input_rds), "\n")
  saveRDS(object_merged, basename(input_rds))
  
  # 打印合并后的 CHOIR 聚类统计
  choir_cols <- grep("^CHOIR_", colnames(object_merged@meta.data), value = TRUE)
  cat("[INFO] CHOIR 聚类列:", paste(choir_cols, collapse = ", "), "\n")
  
  elapsed <- (proc.time() - start_time)[3] / 3600
  cat("[TIME] 总运行时间:", round(elapsed, 3), "h\n")
  
} else {
  # 单个批次，直接跑 CHOIR
  object_out <- run_choir_on_object(object, cluster_key)
  saveRDS(object_out, basename(input_rds))
  cat("[INFO] 保存 CHOIR 结果至:", basename(input_rds), "\n")
  elapsed <- (proc.time() - start_time)[3] / 3600
  cat("[TIME] 总运行时间:", round(elapsed, 3), "h\n")
}