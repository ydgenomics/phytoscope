"""
DEA 数据收集：只展示 allmarkers CSV 表格。
"""
import os
from .utils import read_csv_headers_rows, safe_glob_first


def collect_dea(dea_dir):
    dea_dir = str(dea_dir)
    pattern = os.path.join(dea_dir, "allmarkers_*.csv")
    csv_path = safe_glob_first(pattern)

    headers, rows = read_csv_headers_rows(csv_path) if csv_path else ([], [])

    return {
        "has_data": len(headers) > 0 and len(rows) > 0,
        "headers": headers,
        "rows": rows,
        "filename": os.path.basename(csv_path) if csv_path else "allmarkers.csv"
    }
