"""
DEA 数据收集：支持多个 CSV 表格，通过 Tab 切换展示。
"""
import os
from .utils import read_csv_headers_rows, safe_glob, natural_sort_key


def collect_dea(dea_dir):
    dea_dir = str(dea_dir)
    pattern = os.path.join(dea_dir, "*.csv")
    csv_files = safe_glob(pattern)
    csv_files.sort(key=lambda x: natural_sort_key(os.path.basename(x)))

    # 确定显示名称：allmarkers → "All Markers", conserved_markers → "Conserved Markers"
    def _table_name(filename):
        base = os.path.basename(filename).replace('.csv', '')
        if 'conserved' in base.lower():
            return "Conserved Markers"
        if 'allmarker' in base.lower():
            return "All Markers"
        return base.replace('_', ' ').title()

    tables = []
    for f in csv_files:
        headers, rows = read_csv_headers_rows(f)
        if headers and rows:
            tables.append({
                "name": _table_name(f),
                "filename": os.path.basename(f),
                "headers": headers,
                "rows": rows
            })

    return {
        "has_data": len(tables) > 0,
        "tables": tables,
        "active_table": 0  # 默认显示第一个
    }
