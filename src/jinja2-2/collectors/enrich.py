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

    return {
        "has_data": len(cluster_images) > 0 or (len(headers) > 0),
        "cluster_images": cluster_images,
        "table_headers": headers,
        "table_rows": rows
    }
