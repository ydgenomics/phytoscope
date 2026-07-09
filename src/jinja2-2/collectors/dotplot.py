"""
Dotplot 数据收集：嵌入 dotplot.png。
"""
import os
from .utils import image_to_base64, safe_glob_first


def collect_dotplot(summary_dir):
    png_pattern = os.path.join(str(summary_dir), "dotplot.png")
    png_path = safe_glob_first(png_pattern) or png_pattern

    b64 = image_to_base64(png_path)
    return {
        "has_data": b64 is not None,
        "b64": b64,
        "filename": "dotplot.png"
    }
