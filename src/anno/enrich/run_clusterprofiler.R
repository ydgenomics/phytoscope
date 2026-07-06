# date: 260707

library(clusterProfiler)
library(tidyverse)
library(stringr)
library(KEGGREST)
library(AnnotationForge)
library(dplyr)
library(jsonlite)
library(purrr)
library(RCurl)
library(data.table)
library(readxl)
library(jsonlite)
library(ggplot2)
library(grid)
library(optparse)

# 1. 定义参数列表
option_list <- list(
    make_option(c("-f", "--db_file"), type="character", default="/data/work/Enrich/org.Splumbizincicola.eg.db.tar.gz", help="Path to emapper annotations"),
    make_option(c("-j", "--ko_json"), type="character", default="/data/users/yangdong/yangdong_aad9c0eec3ba48688ac1f8729ce11dba/online/phytoscope/Enrich/ko00001.json", help="Path to ko00001.json"),
    make_option(c("-g", "--genus"), type="character", default="Sedum", help="Genus name"),
    make_option(c("-s", "--species"), type="character", default="plumbizincicola", help="Species name"),
    make_option(c("-t", "--taxid"), type="character", default="1111", help="Taxonomy ID"),
    make_option(c("-c", "--gene_csv"), type="character", default="/data/work/DEAs/FindMarkers/up/combined_markers.csv", help="Path to input gene CSV"),
    make_option(c("-k", "--kegg_info"), type="character", default="/data/work/Enrich/kegg_info.RData", help="Path to kegg_info.RData"),
    make_option(c("-p", "--minp"), type="numeric", default=0.05, help="P-value cutoff") # 💡 已经设为 numeric，避免后续富集报错
)

if (FALSE){
'
db_file="/data/work/Enrich/org.Splumbizincicola.eg.db.tar.gz"
ko_json="/data/users/yangdong/yangdong_aad9c0eec3ba48688ac1f8729ce11dba/online/phytoscope/Enrich/ko00001.json"
genus="Sedum"
species="plumbizincicola"
gene_csv="/data/work/DEAs/conserved_markers_preprocessed_seu.rds.csv"
kegg_info="/data/work/Enrich/kegg_info.RData"
minp=0.05
Rscript /data/work/Enrich/run_clusterprofiler.R \
--db_file $db_file --ko_json $ko_json --genus $genus --species $species \
--gene_csv $gene_csv --kegg_info $kegg_info --minp $minp
'
}

# 2. 解析参数并直接解包到全局环境（极简关键步）
opt <- parse_args(OptionParser(option_list = option_list))
list2env(opt, envir = .GlobalEnv)

# update_kegg
update_kegg <- function(json = 'ko00001.json') {
    pathway2name <- tibble(Pathway = character(), Name = character())
    ko2pathway <- tibble(Ko = character(), Pathway = character())
    kegg <- fromJSON(json)
    for (a in seq_along(kegg[["children"]][["children"]])) {
      A <- kegg[["children"]][["name"]][[a]]
      for (b in seq_along(kegg[["children"]][["children"]][[a]][["children"]])) {
        B <- kegg[["children"]][["children"]][[a]][["name"]][[b]]
        for (c in seq_along(
          kegg[["children"]][["children"]][[a]][["children"]][[b]][["children"]]
        )) {
          pathway_info <- kegg[["children"]][["children"]][[a]][["children"]][[b]][["name"]][[c]]
          pathway_id <- str_match(pathway_info, "ko[0-9]{5}")[1]
          pathway_name <- str_replace(pathway_info, " \\[PATH:ko[0-9]{5}\\]", "") %>%
            str_replace("[0-9]{5} ", "")
          pathway2name <- rbind(
            pathway2name,
            tibble(Pathway = pathway_id, Name = pathway_name)
          )
          kos_info <- kegg[["children"]][["children"]][[a]][["children"]][[b]][["children"]][[c]][["name"]]
          kos <- str_match(kos_info, "K[0-9]*")[, 1]
          ko2pathway <- rbind(
            ko2pathway,
            tibble(Ko = kos, Pathway = rep(pathway_id, length(kos)))
          )
        }
      }
    }
    save(pathway2name, ko2pathway, file = "kegg_info.RData")
    return(ko2pathway)
  }


buildOrgDb_yd <- function(emapper_annotations_xlsx, ko_json, taxid=1111, genus='genus', species='species') {
  # 读取eggnog注释文件，前2行为注释; 若用Galaxy-eggnog则第一行即为列名
  emapper <- tryCatch(
      {
        read_excel(emapper_annotations_xlsx, skip = 2)
      },
      error = function(e) {
        fread(
            emapper_annotations_xlsx, 
            sep = "\t",
            skip = 4,
            header = TRUE,
            fill = TRUE,
            na.strings = "-"
        )
      }
    )
  if (emapper[2, 1] == 'query'){
    emapper <- read_excel(emapper_annotations_xlsx, skip = 2)
  } else {
    colnames(emapper)[1] <- 'query'
  }
  head(emapper)
  emapper <- emapper %>% distinct(query, .keep_all = TRUE)
  options(stringsAsFactors = FALSE)
  emapper[emapper == ""] <- NA

  # gene_info
  gene_info <- emapper %>%
    dplyr::select(GID = query, GENENAME = Preferred_name) %>%
    na.omit()
  head(gene_info)

  # gene2go
  gos <- emapper %>% dplyr::select(query, GOs) %>% na.omit()
  head(gos)
  gene2go <- data.frame(
    GID = character(),
    GO = character(),
    EVIDENCE = character()
  )
  setDT(gos)
  gene2go <- gos[, {
    the_gid <- query
    the_gos <- unlist(str_split(GOs, ","))
    data.table(
      GID = rep(the_gid, length(the_gos)),
      GO = the_gos,
      EVIDENCE = rep("IEA", length(the_gos))
    )
  }, by = seq_len(nrow(gos))]

  gene2go <- gene2go[, c("GID", "GO", "EVIDENCE"), drop = FALSE]
  gene2go$GO[gene2go$GO == "-"] <- NA
  gene2go <- na.omit(gene2go)
  head(gene2go)

  # gene2ko
  gene2ko <- emapper %>%
    dplyr::select(GID = query, Ko = KEGG_ko) %>%
    na.omit()
  gene2ko$Ko <- gsub("ko:", "", gene2ko$Ko)
  head(gene2ko)

  # gene2pathway
  ko2pathway <- update_kegg(ko_json)

  # load(kegg_info_RData) # load(file = "/script/build_orgdb/kegg_info.RData") # stored in the image enrich-R--
  gene2pathway <- gene2ko %>%
    left_join(ko2pathway, by = "Ko") %>%
    dplyr::select(GID, Pathway) %>%
    na.omit()

  # delete duplication
  gene2go <- unique(gene2go)
  gene2go <- gene2go[!duplicated(gene2go), ]
  gene2ko <- gene2ko[!duplicated(gene2ko), ]
  gene2pathway <- gene2pathway[!duplicated(gene2pathway), ]

  # Check the information of species [https://www.ncbi.nlm.nih.gov/taxonomy]
  makeOrgPackage(
    gene_info = gene_info,
    go = gene2go,
    ko = gene2ko,
    pathway = gene2pathway,
    version = "1.0",  # 版本
    maintainer = "yd<2144752653@qq.com>",  # 修改为你的名字和邮箱
    author = "yd<2144752653@qq.com>",  # 修改为你的名字和邮箱
    outputDir = ".",  # 输出文件位置
    tax_id = taxid,
    genus = genus,
    species = species,
    goTable = "go"
  )
  return(list(gene2go = gene2go, gene2ko = gene2ko))
  # install.packages("org.Ahypogaea.eg.db/", repos = NULL, type = "sources")
  # library(org.Ahypogaea.eg.db)
  # print(head(keys(org.Ahypogaea.eg.db, keytype = "GID"), 10))
  # columns(org.Ahypogaea.eg.db)
}

file_name <- basename(db_file)
# 判断是否包含 ".eg.db"
if (grepl(".eg.db", file_name, fixed = TRUE)) {
    message("文件名包含 .eg.db，执行 OrgDb 相关逻辑...")
    untar(db_file, exdir = ".")
    base_name <- gsub("\\.tar\\.gz$", "", basename(db_file)) # 去掉 .tar.gz 后缀
} else {
    message("文件名不包含 .eg.db，执行 eggNOG-mapper 注释文件解析逻辑...")
    go_ko <- buildOrgDb_yd(db_file, ko_json, taxid, genus, species)
    base_name <- paste0("org.", substr(genus, 1, 1), species,".eg.db")
}

print(base_name)
install.packages(base_name, repos = NULL, type = "sources")

do.call(library, list(base_name))
db <- get(base_name)
columns(db)


checkTargetGeneSet_yd <- function(markers, db, gene_csv) {
    required_cols <- c("gene", "p_val_adj")
    missing_cols <- setdiff(required_cols, colnames(markers))
    if (length(missing_cols) > 0) {
        stop(paste(
            "Error: The following required columns are missing in gene_csv:",
            paste(missing_cols, collapse = ", ")
        ))
    }
    if (!("cluster" %in% colnames(markers))) {
        markers$cluster <- basename(gene_csv)
    }
    head(markers) # gene, cluster, p_val_adj

    # Check
    db_gid <- keys(db, keytype = "GID")
    common_genes <- markers$gene[markers$gene %in% db_gid]
    num_common_genes <- length(common_genes)
    total_genes <- length(markers$gene)
    percentage <- (num_common_genes / total_genes) * 100

    cat("First 10 GIDs in database:\n")
    print(head(db_gid, 10))
    cat("Total number of GIDs in database:", length(db_gid), "\n")
    cat("\nFirst 10 genes in input gene_csv:\n")
    print(head(markers$gene, 10))
    cat("Total number of genes in gene_csv:", total_genes, "\n")
    cat("\nNumber of genes present in database:", num_common_genes, "\n")
    cat("Percentage of input genes matched to database:",
            round(percentage, 2), "%\n")
    return(markers)
}

markers <- read.csv(gene_csv, header = TRUE, stringsAsFactors = FALSE)
markers <- checkTargetGeneSet_yd(markers, db, gene_csv)
# pathway and kegg
pathway2gene <- AnnotationDbi::select(db,keys = keys(db),columns = c("Pathway","Ko")) %>%
  na.omit() %>%
  dplyr::select(Pathway, GID)

load(kegg_info)

# 在循环外初始化一个 List，用于收集所有 Cluster 的富集结果
# 在循环外初始化一个 List，用于收集所有 Cluster 的富集结果
all_clusters_res <- list()
all_subclusters_res <- list()

for(i in unique(markers$cluster)){
    marker_subset <- filter(markers, cluster == i)
    gene_list <- marker_subset %>% filter(p_val_adj < minp) %>% pull(gene)
    
    # 如果该 Cluster 筛选后没有基因，跳过防止报错
    if (length(gene_list) == 0) {
        print(paste0("Cluster ", i, " has no significant genes. Skipping."))
        next
    }
    
    # 1. 运行富集分析
    go_data <- enrichGO(gene = gene_list, OrgDb = db, keyType = 'GID', ont = 'ALL', qvalueCutoff = 0.05, pvalueCutoff = minp)
    go_data <- as.data.frame(go_data)
    
    kegg_result <- enricher(gene_list, TERM2GENE = pathway2gene, TERM2NAME = pathway2name, pvalueCutoff = 0.05, qvalueCutoff = minp)
    kegg_data <- as.data.frame(kegg_result)
    
    # 2. 合并 GO 和 KEGG 并规范化格式
    if (nrow(go_data) > 0 && nrow(kegg_data) > 0) {
        kegg_data$ONTOLOGY <- "KEGG"
        # 调整列顺序，使 KEGG 的 ONTOLOGY 排在第一列与 GO 对齐
        kegg_data <- kegg_data[, c("ONTOLOGY", setdiff(names(kegg_data), "ONTOLOGY"))]
        cluster_data <- rbind(go_data, kegg_data)
    } else if (nrow(go_data) > 0) {
        cluster_data <- go_data
        print(paste0(i, " lacked enrichment kegg information"))
    } else if (nrow(kegg_data) > 0) {
        kegg_data$ONTOLOGY <- "KEGG"
        cluster_data <- kegg_data[, c("ONTOLOGY", setdiff(names(kegg_data), "ONTOLOGY"))]
        print(paste0(i, " lacked enrichment go information"))
    } else {
        print(paste0("Data is empty for cluster ", i, ". Skipping."))
        next
    }
    
    # 3. 添加 Cluster 标记并收集数据
    cluster_data$cluster <- i
    all_clusters_res[[as.character(i)]] <- cluster_data
    
    # 4. 可视化：只取整个 Cluster 里面最显著的 Top 20 条目
    data_subset <- cluster_data %>%
        arrange(p.adjust) %>%
        slice_head(n = 10)
    
    all_subclusters_res[[as.character(i)]] <- data_subset
    
    if (nrow(data_subset) > 0) {
        print(paste0("Plotting Top 10 for Cluster ", i))

        # ========== 固定参数 ==========
        bar_length <- 4          # bar 的固定长度（英寸）
        y_text_size <- 16        # Y 轴文字大小（必须和 theme 里一致）
        base_extra <- 1.5        # 其他固定宽度：边距、分面标签、X 轴标题等

        # ========== 动态计算 Y 轴标签宽度 ==========
        # 获取最长字符串
        max_desc <- as.character(data_subset$Description)[which.max(nchar(as.character(data_subset$Description)))]

        # 计算该字符串在指定字体大小下的实际渲染宽度（英寸）
        y_label_width <- convertWidth(
            grobWidth(textGrob(max_desc, gp = gpar(fontsize = y_text_size, fontface = "bold"))),
            unitTo = "inches", valueOnly = TRUE
        )

        # ========== 总宽度 ==========
        plot_width <- bar_length + y_label_width + base_extra

        # ========== 高度保持原有逻辑 ==========
        plot_height <- 2 + 0.25 * nrow(data_subset)

        # # ========== 设置画布 ==========
        # options(repr.plot.width = plot_width, repr.plot.height = plot_height)

        # ========== 绘图 ==========
        plot1 <- ggplot(data_subset, aes(x = -log10(p.adjust), y = reorder(Description, -p.adjust))) + 
            geom_bar(stat = "identity", aes(fill = p.adjust), width = 0.7) +  
            scale_fill_gradient(low = "red", high = "blue") +  
            facet_grid(ONTOLOGY ~ ., scales = "free_y", space = "free_y") + 
            labs(title = paste0("Group: ", i), x = "-log10(p.adjust)", y = "") +
            theme_bw() + 
            theme(
                plot.title = element_text(hjust = 0.5, face = "bold", size = 12),
                axis.text.x = element_text(size = 8), 
                axis.text.y = element_text(size = y_text_size, face = "bold"),  # 和计算时一致
                strip.text.y = element_text(angle = 0, face = "bold", size = 12)
            ) +
            guides(fill = "none")
        
        # print(plot1)
        ggsave(
            filename = paste0(i, "_enrich.png"), 
            plot = plot1, 
            width = plot_width, 
            height = plot_height, 
            dpi = 150, 
            limitsize = FALSE
        )
    }
}

# 5. 循环结束后，合并所有数据并保存为一个总的 txt 文件
if (length(all_clusters_res) > 0) {
    final_combined_data <- bind_rows(all_clusters_res)
    # 调一下列顺序，把 Cluster 放最前面方便查看
    final_combined_data <- final_combined_data[, c("cluster", setdiff(names(final_combined_data), "cluster"))]
    
    write.table(final_combined_data, file = "all_clusters_enrich_results.txt", 
                sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
    print("All cluster results saved to 'all_clusters_enrich_results.txt'.")
    final_subcombined_data <- bind_rows(all_subclusters_res)
    # 调一下列顺序，把 Cluster 放最前面方便查看
    final_subcombined_data <- final_subcombined_data[, c("cluster", setdiff(names(final_subcombined_data), "cluster"))]
    
    write.table(final_subcombined_data, file = "all_subclusters_enrich_results.txt", 
                sep = "\t", row.names = FALSE, col.names = TRUE, quote = FALSE)
} else {
    print("No enrichment data found across all clusters.")
}