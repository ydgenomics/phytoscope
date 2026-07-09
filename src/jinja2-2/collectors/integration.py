"""
Integration 数据收集：动态发现整合方法图 + scIB 评估图。
"""
import os
from .utils import image_to_base64, safe_glob


def collect_integration(integration_dir):
    integration_dir = str(integration_dir)
    png_dir = os.path.join(integration_dir, "png")
    scib_dir = os.path.join(integration_dir, "scib")

    # ===== 1. 动态抓取 Integration 方法图 =====
    file_mapping = {}  # {method: {key: b64}}
    if os.path.isdir(png_dir):
        for f in os.listdir(png_dir):
            if not f.endswith(".png") or "_" not in f:
                continue
            # harmony_biosample.png → method=harmony, key=biosample
            method_id, rest = f.rsplit("_", 1)
            key_id = rest.replace(".png", "")
            full_path = os.path.join(png_dir, f)
            b64 = image_to_base64(full_path)
            if b64:
                file_mapping.setdefault(method_id, {})[key_id] = b64

    # 排序：Unintegrated 放最后，其余按字母
    detected_methods = sorted(file_mapping.keys(),
                              key=lambda x: (x.lower() == 'unintegrated', x.lower()))
    detected_keys = sorted(set(k for m in file_mapping for k in file_mapping[m]))

    methods_list = [{"id": m, "label": m} for m in detected_methods]
    keys_list = [{"id": k, "label": k} for k in detected_keys]

    # 构建前端矩阵
    integration_matrix = []
    for m in detected_methods:
        integration_matrix.append({
            "id": m,
            "keys": {k: file_mapping.get(m, {}).get(k, "") for k in detected_keys}
        })

    # ===== 2. scIB 图 =====
    scib_b64 = None
    scib_filename = "scIB_metrics.png"
    if os.path.isdir(scib_dir):
        scib_pngs = [f for f in os.listdir(scib_dir) if f.endswith(".png")]
        if scib_pngs:
            scib_filename = scib_pngs[0]
            scib_b64 = image_to_base64(os.path.join(scib_dir, scib_pngs[0]))

    return {
        "has_data": len(detected_methods) > 0,
        "methods": methods_list,
        "key_list": keys_list,  # 避免与 dict.keys() 方法冲突
        "integration_matrix": integration_matrix,
        "scib_b64": scib_b64,
        "scib_filename": scib_filename
    }
