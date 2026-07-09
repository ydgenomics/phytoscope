"""
MetaNeighbor 数据收集：AUROC 矩阵 → Plotly 交互热图。
"""
import os
import pandas as pd
import plotly.express as px
import plotly.io as pio
from .utils import safe_glob_first


def collect_metaneighbor(metaneighbor_dir):
    metaneighbor_dir = str(metaneighbor_dir)
    pattern = os.path.join(metaneighbor_dir, "*metaNeighbor*.csv")
    csv_path = safe_glob_first(pattern)

    if not csv_path or not os.path.exists(csv_path):
        return {"has_data": False, "heatmap_json": "{}"}

    df = pd.read_csv(csv_path, index_col=0)

    fig = px.imshow(
        df,
        labels=dict(x="Target Cells", y="Source Cells", color="AUROC"),
        x=df.columns.tolist(),
        y=df.index.tolist(),
        color_continuous_scale="RdBu_r",
        zmin=0.2,
        zmax=1.0,
        title="MetaNeighbor Cell Type Replicability (AUROC)"
    )
    fig.update_layout(
        width=800, height=750,
        xaxis=dict(side="bottom", tickangle=-45),
        font=dict(family="Arial, sans-serif", size=11)
    )

    heatmap_json = pio.to_json(fig)

    return {
        "has_data": True,
        "heatmap_json": heatmap_json
    }
