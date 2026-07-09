import sys
import scanpy as sc
from matplotlib.pyplot import rc_context
import matplotlib.pyplot as plt
import pandas as pd
import pprint

if len(sys.argv) < 4:
    print("Usage: python summary.py <input_h5ad> <markers_csv> <cluster_key>")
    sys.exit(1)

input_h5ad = sys.argv[1]
markers_csv = sys.argv[2]
cluster_key = sys.argv[3]

adata = sc.read_h5ad(input_h5ad)
print(adata)

df = pd.read_csv(markers_csv)
df.head()

# 1. 先将基因名那一列按逗号切分成列表
df["gene_list"] = df["geneSymbolmore1"].str.split(",")

# 2. 用 explode 将列表炸开成单行，再根据 shortName 分组转字典
marker_genes_dict = df.explode("gene_list").groupby("shortName")["gene_list"].apply(list).to_dict()

pprint.pprint(marker_genes_dict)

sc.pl.dotplot(adata, marker_genes_dict, cluster_key, dendrogram=True, show=False)
fig = plt.gcf()
fig.savefig("dotplot.png", bbox_inches="tight", dpi=300)