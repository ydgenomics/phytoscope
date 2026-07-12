"""
Enrich 数据收集：富集分析 PNG + 表格数据。
"""
import os
import re
from .utils import image_to_base64, read_csv_headers_rows, safe_glob, natural_sort_key


def collect_enrich(enrich_dir):
    enrich_dir = str(enrich_dir)

    # 扫描 cluster 富集图
    img_pattern = os.path.join(enrich_dir, "cluster_*_enrich.png")
    img_files = safe_glob(img_pattern)
    img_files.sort(key=lambda x: natural_sort_key(os.path.basename(x)))

    cluster_images = []
    for img in img_files:
        basename = os.path.basename(img)
        cluster_name = basename.replace("_enrich.png", "").replace("_", " ").title()
        b64 = image_to_base64(img)
        if b64:
            cluster_images.append({
                "name": cluster_name,
                "filename": basename,
                "b64_data": b64
            })

    # 解析富集表格（优先取 all_subclusters 版本）
    txt_pattern = os.path.join(enrich_dir, "*_enrich_results.txt")
    txt_files = safe_glob(txt_pattern)
    # 优先 all_subclusters，否则取第一个
    txt_path = None
    for tf in txt_files:
        if "all_subclusters" in os.path.basename(tf):
            txt_path = tf
            break
    if not txt_path and txt_files:
        txt_path = txt_files[0]

    headers, rows = [], []
    if txt_path:
        headers, rows = read_csv_headers_rows(txt_path, delimiter='\t')

    # 按 cluster 分组构建富集摘要（用于 AI 解读 prompt）
    cluster_names = []
    cluster_summaries = {}
    cluster_idx = 0  # "cluster" 列在表头中的索引
    # 查找 cluster 列的索引
    for i, h in enumerate(headers):
        if h.strip().lower() == "cluster":
            cluster_idx = i
            break
    for row in rows:
        if len(row) <= cluster_idx:
            continue
        cn = row[cluster_idx].strip()
        if not cn:
            continue
        if cn not in cluster_summaries:
            cluster_summaries[cn] = []
            cluster_names.append(cn)
        # 收集关键字段：ONTOLOGY, Description, p.adjust
        ontology = row[1] if len(row) > 1 else ""
        desc = row[3] if len(row) > 3 else ""
        p_adj = row[7] if len(row) > 7 else "NA"
        cluster_summaries[cn].append({
            "ontology": ontology,
            "description": desc,
            "p_adjust": p_adj
        })
    # 每个 cluster 按 p.adjust 排序，取 top 10
    for cn in cluster_summaries:
        def _sort_key(item):
            try:
                return float(item["p_adjust"])
            except (ValueError, TypeError):
                return 1.0
        cluster_summaries[cn].sort(key=_sort_key)
        cluster_summaries[cn] = cluster_summaries[cn][:10]
    cluster_names.sort(key=natural_sort_key)

    return {
        "has_data": len(cluster_images) > 0 or (len(headers) > 0),
        "cluster_images": cluster_images,
        "table_headers": headers,
        "table_rows": rows,
        "cluster_names": cluster_names,
        "cluster_summaries": cluster_summaries
    }
