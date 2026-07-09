### Date: 260309
### Image: harmony-py--
### Ref: https://github.com/Papatheodorou-Group/BENGAL/blob/main/bin/harmony_integration.py

import click
import matplotlib.pyplot as plt
import scanpy as sc
import pandas as pd
import harmonypy
import leidenalg
from matplotlib.backends.backend_pdf import PdfPages
import time

"""

"""

@click.command()
@click.argument("input_h5ad", type=click.Path(exists=True))
@click.option('--prefix', type=str, default=None, help="Prefix of output files")
@click.option('--batch_key', type=str, default=None, help="Batch key in identifying HVG and harmony integration")
@click.option('--key_list', type=str, default=None, help="Visulaized keys")
@click.option('--cluster_name', type=str, default=None, help="New cluster name")
@click.option('--resolution', type=float, default=0.5, help="set for resolution, is float")

def run_harmony(input_h5ad, prefix, batch_key, key_list, cluster_name, resolution):  
    key_list = key_list.split(",")
    key_list.append(cluster_name)
    out_umap = prefix + '_harmony_integrated.pdf'
    out_h5ad = prefix + '_harmony_integrated.h5ad'
    click.echo('Start scVI integration - use cpu mode')
    click.echo('Start harmony integration')
    start = time.time()
    # sc.set_figure_params(dpi_save=300, frameon=False, figsize=(10, 6))
    adata = sc.read_h5ad(input_h5ad)
    adata.var_names_make_unique()
    sc.pp.normalize_total(adata, target_sum=1e4)
    sc.pp.log1p(adata)
    click.echo("HVG")
    sc.pp.highly_variable_genes(adata, batch_key=batch_key)
    #sc.pp.scale(adata, max_value=10)
    sc.pp.scale(adata)
    sc.tl.pca(adata)
    # sc.tl.pca(input_ad, svd_solver="arpack", mask_var="highly_variable")
    sc.pp.neighbors(adata, use_rep='X_pca', n_neighbors=15, n_pcs=40)
    sc.tl.umap(adata, min_dist=0.3) ## to match min_dist in seurat
    #adata.obsm['X_umapraw'] = adata.obsm['X_umap']
    click.echo("Harmony")
    sc.external.pp.harmony_integrate(adata, key=batch_key, basis = 'X_pca')
    #sc.pp.neighbors(adata, use_rep='X_pca_harmony', key_added = 'harmony', n_neighbors=15, n_pcs=40)
    sc.pp.neighbors(adata, use_rep='X_pca_harmony', n_neighbors=15, n_pcs=40)
    sc.tl.leiden(adata, resolution=resolution, key_added=cluster_name, flavor='igraph', n_iterations=2, directed=False) 
    sc.tl.umap(adata, neighbors_key = 'neighbors') ## to match min_dist in seurat
    with PdfPages(out_umap) as pdf:
        sc.pl.umap(adata, color=key_list, legend_loc='right margin', ncols=1)
        plt.savefig(pdf, format='pdf', dpi=300, bbox_inches='tight')
        plt.close()
    #adata.obsm['X_umapharmony'] = adata.obsm['X_umap']
    #click.echo("scvi integrated adata structure")
    #
    adata
    click.echo("Save output")
    adata.write(filename=out_h5ad,compression="gzip")
    click.echo("Done harmony")
    
    obsm_key = 'X_pca_harmony'
    obsm_data = adata.obsm[obsm_key]
    reduc_name = obsm_key.replace("X_", "") if obsm_key.startswith("X_") else obsm_key
    df = pd.DataFrame(
        obsm_data,
        index=adata.obs_names,
        columns=[f"{reduc_name}_{i+1}" for i in range(obsm_data.shape[1])]
    )
    df.index.name = "cell_id"
    df.reset_index(inplace=True)
    df.to_csv(obsm_key+'_harmony_integrated.csv', index=False)
    
    elapsed_h = (time.time() - start) / 3600
    click.echo(f"[TIME] 总运行时间: {elapsed_h:.3f} h")


if __name__ == '__main__':
    run_harmony()
