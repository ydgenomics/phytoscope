import os
# Set before importing other libraries that require OpenBLAS
os.environ["OPENBLAS_NUM_THREADS"] = "10"


from samap.mapping import SAMAP
from samap.analysis import (get_mapping_scores, GenePairFinder,
                            sankey_plot, chord_plot, CellTypeTriangles, 
                            ParalogSubstitutions, FunctionalEnrichment,
                            convert_eggnog_to_homologs, GeneTriangles)
from samalg import SAM
import pandas as pd
import scanpy as sc
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import scanpy.external as sce
import scipy.sparse
from samalg import SAM #import SAM

import sys
species = sys.argv[1]
keys = sys.argv[2]

species = species.split(',')
keys = keys.split(',')

paths=[f"./SAMap/tmp/{s}.pkl" for s in species]

print(species, paths, keys)

cluster_key = {}
for name, key in zip(species, keys):
    cluster_key[name] = key
    
print(cluster_key)

neigh_from_keys={}
for name in species:
    neigh_from_keys[name] = True

print(neigh_from_keys)

# Load processed SAM
sams = {}
for name, file in zip(species, paths):
    sam = SAM()
    sam.load(file)
    sams[name] = sam

print(sams.keys())  # dict_keys(['At', 'Sp'])

sm = SAMAP(
    sams,
    f_maps = './SAMap/tmp/maps/',
    keys=cluster_key
)

# run the SAMap algorithm using the run function.
sm.run(pairwise=True, neigh_from_keys=neigh_from_keys)

samap = sm.samap

D, MappingTable = get_mapping_scores(sm, cluster_key, n_top = 0)

# Save full MappingTable
MappingTable.to_csv("./SAMap/SAMap_result/MappingTable.csv")

# === Process MappingTable: cross-species cluster identity ===
if len(species) == 2:
    # Two-species mode: rows = species[0] clusters, columns = species[1] clusters
    row_prefix = species[0] + '_'
    col_prefix = species[1] + '_'
    row_mask = [str(idx).startswith(row_prefix) for idx in MappingTable.index]
    col_mask = [str(c).startswith(col_prefix) for c in MappingTable.columns]
    mt_cross = MappingTable.loc[row_mask, col_mask]
    # Strip species prefix from names
    mt_cross.index = [x.split('_', 1)[1] if '_' in x else x for x in mt_cross.index]
    mt_cross.columns = [x.split('_', 1)[1] if '_' in x else x for x in mt_cross.columns]

    # Save cleaned cross-species matrix
    mt_cross.to_csv("./SAMap/SAMap_result/MappingTable_cross.csv")

    # For each query cluster, find the best reference cell type
    cluster_identity = []
    for col in mt_cross.columns:
        best_idx = mt_cross[col].idxmax()
        best_score = mt_cross[col].max()
        purity = "pass" if best_score > 0.5 else "fail"
        label = best_idx if best_score > 0.5 else "Unknown"
        cluster_identity.append({
            "cluster": col,
            "SAMap": label,
            "score": best_score if best_score > 0.5 else pd.NA,
            "purity_check": purity
        })

    cluster_identity_df = pd.DataFrame(cluster_identity)
    cluster_identity_df.to_csv("./SAMap/SAMap_result/MappingTable_cluster_identity.csv",
                                index=False)
    print(cluster_identity_df)
else:
    print(f"[info] {len(species)} species detected, skipping cross-species cluster identity parsing.")

#sankey_plot(MappingTable, align_thr=0.05, species_order = sample[0].values)
sm.scatter()
plt.savefig("./SAMap/SAMap_result/Merge_UMAP.pdf")

gpf = GenePairFinder(sm,keys=cluster_key)
gene_pairs = gpf.find_all(align_thr=0.2)
gene_pairs.to_csv("./SAMap/SAMap_result/gene_pairs.csv")
adata=samap.adata
adata.obs['celltype']=samap.adata.obs[';'.join(keys) + '_mapping_scores']
adata.obsm['wPCA']=samap.adata.obsm['X_umap']

adata.write_h5ad(filename='./SAMap/SAMap_result/all.h5ad',compression="gzip")

import matplotlib.pyplot as plt

# 方法2：手动控制保存路径
fig, axs = plt.subplots(2, 1, figsize=(8, 12))
sc.pl.umap(adata, color='species', title='Colored by Species', 
           ax=axs[0], frameon=False, show=False)
sc.pl.umap(adata, color='celltype', title='Colored by Cell Type', 
           ax=axs[1], frameon=False, show=False)
plt.savefig('./SAMap/SAMap_result/umap_species_celltype.pdf', bbox_inches='tight', dpi=300)