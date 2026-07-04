# ref: https://tomsing1.github.io/blog/posts/choir/
# https://www.choirclustering.com/articles/CHOIR.html
# https://github.com/corceslab/CHOIR/issues/29

# 如果运行太慢/内存不足：保持 distance_approx = TRUE，核对 n_cores 是否匹配你的机器，并可尝试调小 downsampling_rate（如指定为较小的数值）。

# 如果觉得分出的细胞亚群太多（过聚类）：可以提高 min_accuracy（如 0.55 或 0.6）或者降低 alpha 值（如 0.01）。

# 如果觉得分出的亚群太少（欠聚类）：可以使用默认的 min_accuracy = 0.5，或考虑改用稍微宽松一点的 P 值校正方法 p_adjust = "fdr"。 

suppressPackageStartupMessages({
  library(CHOIR)
  # library(countsplit)
  library(ggnewscale)
  library(ragg)
  library(scRNAseq)
  library(Seurat)
  # library(tictoc)
})

setwd('/data/work/CHOIR')

args <- commandArgs(trailingOnly = TRUE)
print(args)
if(length(args) != 2){stop('
### Example
input_rds="/data/work/Convert/jt_ctrl.hr.rds"
random_seed="42"
/home/stereonote/miniconda3/envs/r_env/bin/Rscript \
/data/work/CHOIR/choir.R $input_rds $random_seed
')}
input_rds <- args[1]
random_seed <- args[2]

object <- readRDS(input_rds)
object

# # 计算要抽取的细胞数量（10%）
# n_cells <- ncol(object) * 0.1
# # 随机抽取细胞条码
# set.seed(123)  # 设置随机种子，确保结果可重复
# cells_to_keep <- sample(colnames(object), size = n_cells, replace = FALSE)
# # 使用 subset 提取子集
# object <- subset(object, cells = cells_to_keep)
# # 查看结果
# object

object <- NormalizeData(object)

# options(future.globals.maxSize = 2.0 * 1e9)
n_cores = 8

object <- CHOIR(object, n_cores = n_cores, random_seed = as.integer(random_seed))

# object <- object |>
#   buildTree(n_cores = n_cores) |>
#   pruneTree(n_cores = n_cores)
# object

saveRDS(object, basename(input_rds))