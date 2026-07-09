library(tidyverse)
library(dplyr)
library(Biostrings)
library(Seurat)

# 1. 命令行参数解析
args <- commandArgs(trailingOnly = TRUE)
print(args)
if(length(args) < 6){stop('
### Usage
Rscript orth.R [ref_pep] [query_pep] [input_rds] [diamond_path] [cluster_marker] [marker_csv] [add_info]
### Example
ref_pep="/Files/User/yangdong/OPEN/shoot.plantcellatlas/at/at.pep"
query_pep="/data/input/Files/User/yangdong/P/p-jintian/assemble2/renamed_transcript_filtered.pep"
input_rds="/data/work/Integration/cell_type.rds"
diamond_path="/software/miniconda/envs/blast/bin/diamond"
cluster_marker="/data/work/DEAs/conserved_markers_cell_type.rds.csv"
marker_csv="/data/work/Feature/marker/At/arabidopsis_thaliana.marker_fd.csv"
add_info="yes"
Rscript ../orth.R $ref_pep $query_pep $input_rds $diamond_path $cluster_marker $marker_csv $add_info
')}
ref_pep <- args[1]
query_pep <- args[2]
input_rds <- args[3]
diamond_path <- args[4]
cluster_marker <- args[5]
marker_csv <- args[6]
add_info <- ifelse(length(args) >= 7, args[7], "no")

# 2. 读取数据并提取目标 ID 列表
df  <- read.csv(marker_csv, stringsAsFactors = FALSE)
df <- df %>%
  distinct(GeneID, .keep_all = TRUE)
df2 <- read.csv(cluster_marker)
seu <- readRDS(input_rds)

ref_   <- unique(df$GeneID)   # 拟南芥 Marker 基因 ID 列表
query_ <- rownames(seu)       # 景天单细胞对象中的基因 ID 列表

# 3. 对 pep 文件进行 Subset 并写出临时 Fasta
message("正在读取并筛选 Pep 序列文件...")
ref_seq   <- readAAStringSet(ref_pep)
query_seq <- readAAStringSet(query_pep)

# 清理 Fasta Header 中的空格及后续注释信息，仅保留前缀 ID
names(ref_seq)   <- str_split_fixed(names(ref_seq), " ", 2)[, 1]
names(query_seq) <- str_split_fixed(names(query_seq), " ", 2)[, 1]

# 根据 ID 列表进行子集筛选
ref_seq_sub   <- ref_seq[names(ref_seq) %in% ref_]
query_seq_sub <- query_seq[names(query_seq) %in% query_]

# 定义临时子集文件路径
sub_ref_fasta   <- tempfile(fileext = "_ref_sub.fa")
sub_query_fasta <- tempfile(fileext = "_query_sub.fa")

# 写出筛选后的 Fasta 文件
writeXStringSet(ref_seq_sub, sub_ref_fasta)
writeXStringSet(query_seq_sub, sub_query_fasta)

message(paste("筛选后ref序列数:", length(ref_seq_sub)))
message(paste("筛选后query序列数:", length(query_seq_sub)))

# 4. 运行 DIAMOND 比对 (使用 Subset 后的文件)
diamond_db <- tempfile(fileext = ".dmnd")
align_out  <- tempfile(fileext = ".tsv")

message("正在构建临时 DIAMOND 数据库...")
system2(diamond_path, args = c("makedb", "--in", sub_ref_fasta, "-d", diamond_db))

message("正在进行 DIAMOND 比对...")
system2(diamond_path, args = c("blastp", "-d", diamond_db, "-q", sub_query_fasta, "-o", align_out, 
                               "--outfmt", "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore", 
                               "--max-target-seqs", "1", "--quiet"))


message("正在构建临时 DIAMOND 数据库...")
system2(diamond_path, args = c("makedb", "--in", sub_ref_fasta, "-d", diamond_db))

message("正在进行 DIAMOND 比对...")
system2(diamond_path, args = c("blastp", 
                               "-d", diamond_db, 
                               "-q", sub_query_fasta, 
                               "-o", align_out, 
                               "--outfmt", "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore", 
                               "--max-target-seqs", "5",     # 输出多个匹配（如5个）
                               "--evalue", "1e-6",           # 添加 evalue 阈值过滤
                               "--quiet"))

# 5. 读取比对结果并进行 1-to-1 过滤
align_res <- read_tsv(align_out, 
                      col_names = c("query", "ref", "pident", "length", "mismatch", 
                                   "gapopen", "qstart", "qend", "sstart", "send", 
                                   "evalue", "bitscore"), 
                      show_col_types = FALSE)

message("过滤后比对记录数: ", nrow(align_res))

# 方法1：Reciprocal Best Hit (RBH) - 推荐
rbh_pairs <- align_res %>%
  # 第一步：每个 query 的最佳 hit
  group_by(query) %>%
  slice_max(order_by = bitscore, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(query, ref, bitscore) %>%
  # 第二步：检查是否是相互最佳
  inner_join(
    align_res %>%
      group_by(ref) %>%
      slice_max(order_by = bitscore, n = 1, with_ties = FALSE) %>%
      ungroup() %>%
      select(query, ref, bitscore),
    by = c("query", "ref"),
    suffix = c("_q", "_r")
  ) %>%
  select(query, ref)

message("RBH 配对数: ", nrow(rbh_pairs))

if (add_info == "yes"){
    # 基于 rbh_pairs 将 df 的 GeneID(ref)、Description、Tissue、CellType 传给 df2
    rbh_info <- rbh_pairs %>% 
      left_join(df %>% distinct(GeneID, Description, Tissue, CellType), by = c("ref" = "GeneID")) %>%
      select(query, ref, Description, Tissue, CellType)

    df2 <- df2 %>%
      left_join(rbh_info, by = c("gene" = "query")) %>%
      mutate(NewName = ref) %>%
      select(-ref)

    write.csv(df2, "df2_NewName.csv", row.names = FALSE)
    message("已保存 df2_NewName.csv")

    # 过滤出 Description、Tissue、CellType 均不为空的行，按 cluster 取 head 5
    df2_head5 <- df2 %>%
      filter(!is.na(Description) & Description != "",
            !is.na(Tissue) & Tissue != "",
            !is.na(CellType) & CellType != "") %>%
      group_by(cluster) %>%
      slice_head(n = 5) %>%
      ungroup()

    write.csv(df2_head5, "df2_NewName_head5.csv", row.names = FALSE)
    message("已保存 df2_NewName_head5.csv")

    # 构建 sctype 格式：tissueType 固定为 At
    df2_sctype <- df2_head5 %>%
      group_by(CellType) %>%
      summarise(
        geneSymbolmore1 = paste(unique(gene), collapse = ","),
        geneSymbolmore2 = "",
        .groups = "drop"
      ) %>%
      mutate(
        tissueType = "At",
        cellName = CellType,
        shortName = CellType
      ) %>%
      select(tissueType, cellName, geneSymbolmore1, geneSymbolmore2, shortName)

    write.csv(df2_sctype, "df2_NewName_head5_sctype.csv", row.names = FALSE)
    message("已保存 df2_NewName_head5_sctype.csv")
}

# 旧代码：基于 rbh_pairs 给 df 添加 NewName 并过滤
pairs_clean <- as.data.frame(rbh_pairs)
df_clean    <- as.data.frame(df)
match_idx <- match(df_clean$GeneID, pairs_clean$ref)
df_clean$NewName <- pairs_clean$query[match_idx]
df_annotated <- df_clean[!is.na(df_clean$NewName), ]
remaining_cols <- setdiff(names(df_annotated), c("Tissue", "CellType"))
df_annotated <- df_annotated[, c("Tissue", "CellType", remaining_cols)]
print(head(df_annotated))
message("过滤后剩余 Marker 数量：", nrow(df_annotated))

write.csv(df_annotated, "NewName.csv", row.names=FALSE)

if (add_info == "yes") {
    # 纯 tidyverse 过滤：只保留 NewName 存在于 df2$gene 中的行
    df_annotated <- df_annotated %>% filter(NewName %in% df2$gene)
    print(head(df_annotated))
    message("过滤后唯一的基因数：", length(unique(df_annotated$NewName)))
    message("过滤后 Marker 总行数：", nrow(df_annotated))
}

write.csv(df_annotated, "NewName_filter.csv", row.names=FALSE)
table(df_annotated$CellType)

# 纯 tidyverse 转换
df_tissue_cell_raw <- df_annotated %>%
  group_by(across(c(1, 2))) %>%
  summarise(
    geneSymbolmore1 = paste(unique(NewName), collapse = ","),
    geneSymbolmore2 = "",
    .groups = "drop"
  ) %>%
  setNames(c("tissueType", "cellName", "geneSymbolmore1", "geneSymbolmore2"))

print(head(df_tissue_cell_raw))
df_tissue_cell_raw$shortName <- df_tissue_cell_raw$cellName
write.csv(df_tissue_cell_raw, "NewName_sctype.csv", row.names=FALSE)

# 清理所有临时文件
unlink(c(sub_ref_fasta, sub_query_fasta, paste0(diamond_db, ".dmnd"), align_out))