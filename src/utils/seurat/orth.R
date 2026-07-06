library(tidyverse)
library(dplyr)
library(Biostrings)
library(Seurat)

# 1. 定义文件路径与工具路径
ref_pep      <- "/Files/User/yangdong/OPEN/shoot.plantcellatlas/at/at.pep"
query_pep    <- "/data/input/Files/User/yangdong/P/p-jintian/assemble2/renamed_transcript_filtered.pep"
input_rds    <- "/data/work/Convert/Sp_ctrl.hr.rds"
diamond_path <- "/software/miniconda/envs/blast/bin/diamond"
cluster_marker="/data/work/DEAs/conserved_markers_Sp_metaneighbor.rds.csv"

# 2. 读取数据并提取目标 ID 列表
df  <- read.csv('/data/work/Feature/marker/jintian-marker.csv', stringsAsFactors = FALSE)
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

# 5. 读取比对结果并进行 1-to-1 过滤
align_res <- read_tsv(align_out, col_names = c("query", "ref", "pident", "length", "mismatch", "gapopen", "qstart", "qend", "sstart", "send", "evalue", "bitscore"), show_col_types = FALSE)

one_to_one_pairs <- align_res %>%
  # 景天端严格 1-to-1
  group_by(query) %>%
  slice_max(order_by = bitscore, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  # 拟南芥端严格 1-to-1
  group_by(ref) %>%
  slice_max(order_by = bitscore, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(query, ref)

pairs_clean <- as.data.frame(one_to_one_pairs)
df_clean    <- as.data.frame(df)
match_idx <- match(df_clean$GeneID, pairs_clean$ref)
df_clean$NewName <- pairs_clean$query[match_idx]
df_annotated <- df_clean[!is.na(df_clean$NewName), ]
df_annotated <- df_annotated[, c("Tissue", "CellType", "GeneID", "NewName", "GeneName", "MarkerType", "References")]
print(head(df_annotated))
message("过滤后剩余 Marker 数量：", nrow(df_annotated))

# 7. 清理所有临时文件
unlink(c(sub_ref_fasta, sub_query_fasta, paste0(diamond_db, ".dmnd"), align_out))

write.csv(df_annotated, "NewName.csv", row.names=FALSE)

# 纯 tidyverse 过滤：只保留 NewName 存在于 df2$gene 中的行
df_annotated2 <- df_annotated %>%
  filter(NewName %in% df2$gene)
# 查看过滤后的前几行
print(head(df_annotated2))
# 查看过滤后还剩下多少个唯一的景天基因，以及总行数
message("过滤后唯一的基因数：", length(unique(df_annotated2$NewName)))
message("过滤后 Marker 总行数：", nrow(df_annotated2))
write.csv(df_annotated2, "NewName_filter.csv", row.names=FALSE)
table(df_annotated2$CellType)
# 纯 tidyverse 转换：不在最后 rename，直接在前面把名字定义好！
df_tissue_cell_raw <- df_annotated2 %>%
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