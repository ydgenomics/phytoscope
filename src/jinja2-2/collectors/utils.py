"""
通用工具函数：图片转 Base64、CSV 读取、glob 安全匹配等。
"""

import os
import csv
import base64
import glob as glob_module
from pathlib import Path


def image_to_base64(img_path):
    """安全读取图片并转换为 base64 字符串。文件不存在时返回 None。"""
    if not img_path or not os.path.exists(img_path) or not os.path.isfile(img_path):
        return None
    with open(img_path, "rb") as f:
        return base64.b64encode(f.read()).decode('utf-8')


def read_csv_headers_rows(filepath, delimiter=','):
    """读取 CSV 文件，返回 (headers, rows)。文件不存在时返回 ([], [])。"""
    if not os.path.exists(filepath):
        return [], []
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.reader(f, delimiter=delimiter)
        try:
            headers = [h.strip() for h in next(reader) if h.strip()]
        except StopIteration:
            return [], []
        rows = []
        for row in reader:
            if row:
                rows.append([cell.strip() for cell in row])
    return headers, rows


def safe_glob(pattern):
    """安全的 glob，始终返回列表（无匹配时返回空列表）。"""
    return glob_module.glob(pattern)


def safe_glob_first(pattern):
    """返回第一个匹配文件路径，无匹配返回 None。"""
    results = safe_glob(pattern)
    return results[0] if results else None


def natural_sort_key(text):
    """自然排序 key：数字部分按数值排序。"""
    import re
    return [int(c) if c.isdigit() else c.lower() for c in re.split(r'(\d+)', text)]
