"""
Overview 数据收集：混合模式表单（Python 预填 + 用户编辑 + localStorage）。
"""

def collect_overview(args):
    return {
        "species": args.species,
        "tissue": args.tissue,
        "background": args.background,
    }
