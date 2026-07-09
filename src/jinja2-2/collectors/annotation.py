"""
Annotation 数据收集：sctype / singler / SAMap 三个子方法。
每个子方法：UMAP PNG (Base64) + prob_clusters 矩阵 → Plotly 热图。
"""
import os
import pandas as pd
import plotly.express as px
import plotly.io as pio
from .utils import image_to_base64, safe_glob_first, safe_glob


def _collect_sub_annotation(sub_dir, umap_suffix, prob_suffix):
    """
    通用子方法收集：scans UMAP PNG + prob_clusters CSV → 返回 {umap_b64, heatmap_json, has_data}
    """
    sub_dir = str(sub_dir)
    if not os.path.isdir(sub_dir):
        return {"has_data": False, "umap_b64": None, "umap_filename": "", "heatmap_json": "{}"}

    # UMAP 图
    umap_pattern = os.path.join(sub_dir, f"*{umap_suffix}.png")
    umap_path = safe_glob_first(umap_pattern)
    umap_b64 = image_to_base64(umap_path) if umap_path else None
    umap_filename = os.path.basename(umap_path) if umap_path else ""

    # 热图 CSV
    prob_pattern = os.path.join(sub_dir, f"*{prob_suffix}.csv")
    prob_path = safe_glob_first(prob_pattern)
    heatmap_json = "{}"
    if prob_path and os.path.exists(prob_path):
        try:
            df = pd.read_csv(prob_path, index_col=0)
            # 行=细胞类型, 列=cluster
            fig = px.imshow(
                df,
                labels=dict(x="Cluster", y="Cell Type", color="Score"),
                x=df.columns.tolist(),
                y=df.index.tolist(),
                color_continuous_scale="Blues",
                zmin=0,
                zmax=1,
                title=f"Annotation Probability Matrix"
            )
            fig.update_layout(
                width=700, height=600,
                xaxis=dict(side="bottom", tickangle=-45),
                font=dict(family="Arial, sans-serif", size=11)
            )
            heatmap_json = pio.to_json(fig)
        except Exception:
            pass

    return {
        "has_data": umap_b64 is not None,
        "umap_b64": umap_b64,
        "umap_filename": umap_filename,
        "heatmap_json": heatmap_json
    }


def collect_annotation(anno_dir):
    anno_dir = str(anno_dir)

    sctype_dir = os.path.join(anno_dir, "sctype")
    singler_dir = os.path.join(anno_dir, "singler")
    samap_dir = os.path.join(anno_dir, "SAMap_result")

    sctype = _collect_sub_annotation(sctype_dir, "_sctype", "_sctype_prob_clusters")
    singler = _collect_sub_annotation(singler_dir, "_singler", "_singler_prob_clusters")

    # SAMap 文件命名不同
    samap = {"has_data": False, "umap_b64": None, "umap_filename": "", "heatmap_json": "{}"}
    if os.path.isdir(samap_dir):
        # UMAP
        umap_pattern = os.path.join(samap_dir, "DimPlot_*.png")
        umap_path = safe_glob_first(umap_pattern)
        if umap_path:
            samap["umap_b64"] = image_to_base64(umap_path)
            samap["umap_filename"] = os.path.basename(umap_path)

        # 热图：MappingTable_cross.csv
        cross_path = os.path.join(samap_dir, "MappingTable_cross.csv")
        if os.path.exists(cross_path):
            try:
                df = pd.read_csv(cross_path, index_col=0)
                fig = px.imshow(
                    df,
                    labels=dict(x="Target", y="Source", color="Score"),
                    x=df.columns.tolist(),
                    y=df.index.tolist(),
                    color_continuous_scale="Blues",
                    title="SAMap Cross-Mapping Matrix"
                )
                fig.update_layout(
                    width=700, height=600,
                    xaxis=dict(side="bottom", tickangle=-45),
                    font=dict(family="Arial, sans-serif", size=11)
                )
                samap["heatmap_json"] = pio.to_json(fig)
            except Exception:
                pass

        samap["has_data"] = samap["umap_b64"] is not None

    return {
        "has_data": sctype["has_data"] or singler["has_data"] or samap["has_data"],
        "sctype": sctype,
        "singler": singler,
        "samap": samap
    }
