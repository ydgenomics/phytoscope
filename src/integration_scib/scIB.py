# Date: 260309
# Image: /software/conda/Anaconda/bin/python 
# Coder: ydgenomics(yangdong@genomics.cn)
# [Add BRAS to Benchmarker as default, instead of regular silhouette batch](https://github.com/YosefLab/scib-metrics/pull/217)

import numpy as np
import scanpy as sc
import matplotlib.pyplot as plt
import webbrowser
from scib_metrics.benchmark import Benchmarker, BioConservation, BatchCorrection
import click
import os
import shutil
from pathlib import Path
import pandas as pd

@click.command()
@click.option("--unintegrated_h5ad", type=str)
@click.option('--integrated_file', type=str, default=None, help="NULL")
@click.option('--deals_file', type=str, default="N,N,N,N,N,N", help="NULL")
@click.option('--tests_file', type=str, default="true,true,true,true,true,true,true,true,true,true", help="NULL")
@click.option('--batch_key', type=str, default=None, help="Batch key")
@click.option('--label_key', type=str, default="biosample", help="Storying the information of biological cell name")
@click.option('--n_jobs', type=int, default=4, help="Number of jobs to use for parallelization of neighbor search")
@click.option("--prefix", type=str, default="zimia")
def main(unintegrated_h5ad, integrated_file, deals_file, tests_file, batch_key, label_key, n_jobs, prefix):
    # split
    files = integrated_file.strip().split(',')
    print(len(files));print(files)

    h5ad2pca = {'_scVI':'X_scVI', '_harmony':'X_pca_harmony', '_rliger.INMF':'X_inmfnorm', '_SCTransform.CCA':'X_pca', '_SCTransform.harmony':'X_pca'}
    # 仅保留“文件名里出现过的 h5ad2pca 键”
    methods = []
    for f in files:
        name = os.path.splitext(os.path.basename(f))[0]
        # 把第一个命中的键作为 methods 值
        key = next((k for k in h5ad2pca if k in name), None)
        if key:                       # 必须命中才保留
            methods.append(key)

    # pcas 与 methods 一一对应
    pcas = [h5ad2pca[k] for k in methods]

    print("methods:", methods)
    print("pcas:", pcas)

    deals = deals_file.strip().split(',')
    deals=deals[0:len(files)];print(deals)
    tests = tests_file.strip().split(',')
    print(tests)

    out_benchpdf=prefix+"_scIB.pdf"; print(out_benchpdf)
    out_benchcsv=prefix+"_scIB.csv"; print(out_benchcsv)
    out_h5ad=prefix+"_scIB.h5ad"; print(out_h5ad)

    # Process unintegrated data
    orig_ad = sc.read_h5ad(unintegrated_h5ad)
    orig_ad.obsm["Unintegrated"] = orig_ad.obsm["X_pca"]

    # Process integrated data and merge with unintegrated data
    for i in range(len(files)):
        file_path = files[i]
        suffix = Path(file_path).suffix.lower()
        print(f"\n处理第 {i+1} 个文件: {file_path}")
        if suffix == '.h5ad':
            print(f"  ✓ 这是 h5ad 文件，执行h5ad处理")
            adata = sc.read_h5ad(files[i])
            if deals[i] == 'N':
                orig_ad.obsm[methods[i]] = adata.obsm[pcas[i]]
            else:
                # deals[i] == 'Y', so we need to process the data which mostly have been processed by R methods
                if '_index' in adata.obs:
                    del adata.obs['_index']
                if '_index' in adata.var:
                    del adata.var['_index']
                sc.tl.pca(adata, svd_solver="arpack")
                adata.obsm[pcas[i]] = adata.obsm["X_pca"]
                adata.obsm[methods[i]] = adata.obsm[pcas[i]]
                sc.pp.neighbors(adata, n_neighbors=20, n_pcs=20, use_rep=pcas[i])
                orig_ad.obsm[methods[i]] = adata.obsm[methods[i]]
        elif suffix == '.csv':
            print(f"  ✓ 这是 csv 文件，执行csv处理")
            df = pd.read_csv(files[i], index_col="cell_id")
            # 对齐细胞顺序
            common = orig_ad.obs_names.intersection(df.index)
            if len(common) < len(orig_ad.obs_names):
                missing = len(orig_ad.obs_names) - len(common)
                print(f"     Warning: {missing} cells missing in this reduction")
            df_aligned = df.reindex(orig_ad.obs_names)
            # 存储到 obsm：pca -> X_pca
            orig_ad.obsm[methods[i]] = df_aligned.values
        else:
            print(f"  ✗ 不支持的文件类型: {suffix}")
    
    methods.append('Unintegrated')
    print(orig_ad)
    print(methods)

    import time
    start = time.time()
    def str_to_bool(value):
        return value.lower() in ("true", "yes", "1", "on")
    biocons = BioConservation(isolated_labels=str_to_bool(tests[0]), nmi_ari_cluster_labels_leiden=str_to_bool(tests[1]), nmi_ari_cluster_labels_kmeans=str_to_bool(tests[2]), silhouette_label=str_to_bool(tests[3]), clisi_knn=str_to_bool(tests[4]))
    # bacorrec = BatchCorrection(bras=True, ilisi_knn=True, kbet_per_label=True, graph_connectivity=True, pcr_comparison=True) # new version of scib-metrics
    bacorrec = BatchCorrection(silhouette_batch = True, ilisi_knn=True, kbet_per_label=True, graph_connectivity=True, pcr_comparison=True) # old version of scib-metrics
    bm = Benchmarker(
        adata=orig_ad,
        batch_key=batch_key,
        label_key=label_key,
        embedding_obsm_keys=methods,
        pre_integrated_embedding_obsm_key="X_pca",
        bio_conservation_metrics=biocons,
        batch_correction_metrics=bacorrec,
        n_jobs=n_jobs,
    )
    bm.benchmark()
    end = time.time()
    orig_ad.write(out_h5ad, compression="gzip")
    print(f"Time: {int((end - start) / 60)} min {int((end - start) % 60)} sec")

    bm.plot_results_table()
    bm.plot_results_table(min_max_scale=False)
    plt.savefig(out_benchpdf, format='pdf', bbox_inches='tight')
    plt.close()
    df = bm.get_results(min_max_scale=False)
    print(df)
    df_transposed = df.transpose()
    df_transposed.to_csv(out_benchcsv, index=True)

    total_scores = df_transposed.iloc[-1, :-1] 
    best_method = total_scores.idxmax()
    best_score  = total_scores.max()
    print("Best method: ", best_method)
    print("Highest score: ", best_score)
    try:
        idx = methods.index(best_method)
        best_h5ad = files[idx]
    except ValueError:
        best_h5ad = unintegrated_h5ad   # 预先定义好的未整合文件路径
    shutil.copy(best_h5ad, os.getcwd())   # 目标文件名保持原样

if __name__ == "__main__":
    main()