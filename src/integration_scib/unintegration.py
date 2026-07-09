### Date: 260703
### Image: harmony-py--
### Coder: ydgenomics

import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import scanpy as sc
import pandas
import leidenalg
import click
import time

@click.command()
@click.argument("input_h5ad", type=click.Path(exists=True))
@click.option('--prefix', type=str, default=None, help="Prefix of output files")
@click.option('--batch_key', type=str, default=None, help="Batch key in identifying HVG and harmony integration")
@click.option('--key_list', type=str, default=None, help="Visulaized keys")
@click.option('--cluster_name', type=str, default=None, help="New cluster name")
@click.option('--resolution', type=float, default=0.5, help="set for resolution, is float")

def run_unintegration(input_h5ad, prefix, batch_key, key_list, cluster_name, resolution):    
    key_list = key_list.split(",")
    start = time.time()
    adata = sc.read_h5ad(input_h5ad)
    sc.pp.normalize_total(adata, target_sum=1e4)
    sc.pp.log1p(adata)
    sc.pp.highly_variable_genes(adata)
    sc.pp.scale(adata)
    sc.tl.pca(adata, svd_solver="arpack")
    
    sc.pp.neighbors(adata, n_neighbors=20, n_pcs=40)
    click.echo("computer cluster use leiden, and save the account of clusters in celltype")
    # resolution_set = 1.0
    sc.tl.leiden(adata, resolution=resolution, key_added=cluster_name, flavor="igraph", n_iterations=2)
    sc.tl.umap(adata)
    out_umap = prefix + '_unintegrated.pdf'
    with PdfPages(out_umap) as pdf:
        required_cols = ['total_counts', 'n_genes']
        if all(col in adata.obs.columns for col in required_cols):
            sc.pl.violin(adata,  keys=['total_counts'], log=True, stripplot=False, groupby=batch_key, show=False)
            plt.savefig(pdf, format='pdf', dpi=300, bbox_inches='tight')
            plt.close()
            sc.pl.violin(adata,  keys=['n_genes'], log=True, stripplot=False, groupby=batch_key, show=False)
            plt.savefig(pdf, format='pdf', dpi=300, bbox_inches='tight')
            plt.close()
        else:
            print("obs lacked total_counts or n_genes column")
        sc.pl.umap(adata, color=key_list, legend_loc='on data', ncols=1)
        plt.savefig(pdf, format='pdf', dpi=300, bbox_inches='tight')
        plt.close()
    # 保存各分组 UMAP 为 PNG
    method_tag = "unintegrated"
    for key in [batch_key] + list(key_list):
        fig, ax = plt.subplots(figsize=(10, 8))
        sc.pl.umap(adata, color=key, ax=ax, show=False, legend_loc='on data')
        plt.savefig(f"{method_tag}_{key}.png", dpi=300, bbox_inches='tight')
        plt.close()
    adata.write(filename=prefix + '_unintegrated.h5ad',compression="gzip")
    
    elapsed_h = (time.time() - start) / 3600
    click.echo(f"[TIME] 总运行时间: {elapsed_h:.3f} h")

if __name__ == '__main__':
    run_unintegration()