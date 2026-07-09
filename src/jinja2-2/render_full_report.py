#!/usr/bin/env python3
"""
Phytoscope Full Report Renderer
将各分析模块结果整合为单文件交互式 HTML 报告。

Usage:
    python render_full_report.py \\
        --results_dir /path/to/output \\
        --species "Sedum plumbizincicola" \\
        --tissue "shoot" \\
        --output phytoscope_full_report.html

Options:
    --results_dir    各模块输出文件所在根目录
    --species        物种名
    --tissue         组织
    --background     项目背景（可选）
    --output         输出 HTML 路径
"""

import argparse
import os
import sys
from pathlib import Path
from datetime import date
from jinja2 import Environment, FileSystemLoader

# 默认系统提示词
DEFAULT_SYSTEM_PROMPT = """你是一位植物单细胞转录组学专家，擅长分析植物组织的单细胞测序数据。

你的任务是根据提供的分析结果（聚类、细胞注释、整合评估、差异表达、富集分析、MetaNeighbor 可重复性分析），撰写一份专业的生物学解读报告。

报告结构要求：
1. **项目概述** — 简要回顾实验设计和数据概况
2. **细胞类型图谱** — 描述鉴定出的主要细胞类型及其 Marker 基因特征
3. **注释方法比较** — 比较 ScType、SingleR、SAMap 三种方法的一致性和差异
4. **整合分析评估** — 评估不同整合方法的效果，推荐最佳方案
5. **关键通路与生物学意义** — 结合富集分析讨论关键 GO/KEGG 通路
6. **结论与建议** — 总结主要发现，提出后续实验验证建议

要求：
- 使用中文撰写，Markdown 格式
- 引用数据中的具体 cluster 编号和基因名
- 指出注释结果中的高置信度和低置信度结论
- 结合植物生物学背景知识进行深入解读
- 如有与已知文献不一致之处，请指出可能原因"""

# 确保可以 import collectors 包
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from collectors.enrich import collect_enrich
from collectors.integration import collect_integration
from collectors.metaneighbor import collect_metaneighbor
from collectors.cluster import collect_cluster
from collectors.dea import collect_dea
from collectors.annotation import collect_annotation
from collectors.dotplot import collect_dotplot
from collectors.overview import collect_overview


def main():
    parser = argparse.ArgumentParser(description="Phytoscope Full Report Renderer")
    parser.add_argument("--results_dir", required=True, help="输出文件根目录")
    parser.add_argument("--species", default="Unknown", help="物种名")
    parser.add_argument("--tissue", default="Unknown", help="组织")
    parser.add_argument("--background", default="", help="项目背景")
    parser.add_argument("--output", default="phytoscope_full_report.html", help="输出 HTML 路径")
    args = parser.parse_args()

    base = Path(args.results_dir)

    # ===== 1. 收集所有模块数据 =====
    context = {
        "project": {
            "species": args.species,
            "tissue": args.tissue,
            "background": args.background,
            "date": date.today().isoformat()
        },
        "overview":     collect_overview(args),
        "default_system_prompt": DEFAULT_SYSTEM_PROMPT,
        "cluster":      collect_cluster(base / "cluster"),
        "metaneighbor": collect_metaneighbor(base / "metaneighbor"),
        "dea":          collect_dea(base / "utils" / "seurat" / "DEA"),
        "enrich":       collect_enrich(base / "anno" / "enrich"),
        "integration":  collect_integration(base / "integration_scib"),
        "annotation":   collect_annotation(base / "anno"),
        "dotplot":      collect_dotplot(base / "utils" / "summary"),
    }

    # ===== 2. 渲染模板 =====
    template_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "templates")
    env = Environment(loader=FileSystemLoader(template_dir), autoescape=True)
    template = env.get_template("base.html")
    html = template.render(**context)

    # ===== 3. 输出 =====
    output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), args.output)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html)

    file_size_kb = os.path.getsize(output_path) / 1024
    print(f"✅ 完整报告已生成: {output_path} ({file_size_kb:.1f} KB)")


if __name__ == "__main__":
    main()
