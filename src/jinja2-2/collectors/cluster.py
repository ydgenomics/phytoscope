"""
Cluster 数据收集：动态发现 CHOIR 各条件的 DimPlot。
"""
import os
import re
from .utils import image_to_base64, safe_glob, natural_sort_key


def collect_cluster(cluster_dir):
    cluster_dir = str(cluster_dir)
    pattern = os.path.join(cluster_dir, "CHOIR_*_DimPlot.png")
    pngs = safe_glob(pattern)
    pngs.sort(key=natural_sort_key)

    conditions = []
    for png in pngs:
        basename = os.path.basename(png)
        # CHOIR_choir_ctrl_DimPlot.png → "ctrl"
        name = basename.replace("CHOIR_choir_", "").replace("_DimPlot.png", "")
        b64 = image_to_base64(png)
        if b64:
            conditions.append({
                "id": name,
                "label": name,
                "b64": b64,
                "filename": basename
            })

    return {
        "has_data": len(conditions) > 0,
        "conditions": conditions
    }
