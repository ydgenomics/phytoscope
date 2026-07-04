### Date: 260312
### Image: scvi-py-- /opt/conda/bin/R
### Coder: ydgenomics
### Ref: https://github.com/Papatheodorou-Group/BENGAL/blob/main/bin/scvi_integration.py

import matplotlib.pyplot as plt
import scanpy as sc
import scvi
import pandas as pd
import leidenalg
from matplotlib.backends.backend_pdf import PdfPages
import click

@click.command()
@click.argument("input_h5ad", type=click.Path(exists=True))
@click.option('--prefix', type=str, default=None, help="Prefix of output files")
@click.option('--batch_key', type=str, default=None, help="Batch key in identifying HVG and harmony integration")
@click.option('--key_list', type=str, default=None, help="Visulaized keys")
@click.option('--cluster_name', type=str, default=None, help="New cluster name")
@click.option('--resolution', type=float, default=0.5, help="set for resolution, is float")

def run_scVI(input_h5ad, prefix, batch_key, key_list, cluster_name, resolution):  
    key_list = key_list.split(",")
    key_list.append(cluster_name)
    out_umap = prefix + '_scVI_integrated.pdf'
    out_h5ad = prefix + '_scVI_integrated.h5ad'
    click.echo('Start scVI integration - use cpu mode')
    # sc.set_figure_params(dpi_save=300, frameon=False, figsize=(10, 6))
    adata = sc.read_h5ad(input_h5ad)
    adata.var_names_make_unique()
    sc.pp.highly_variable_genes(
        adata,
        flavor="seurat_v3",
        n_top_genes=2000,
        ##layer="counts",
        batch_key=batch_key,
        subset=True
    )
    adata.layers["counts"] = adata.X.copy()
    sc.pp.normalize_total(adata, target_sum=1e4)
    sc.pp.log1p(adata)
    adata.raw = adata
    print(adata.obs.columns)
    # this part need plus before it, try test
    sc.pp.scale(adata)
    sc.tl.pca(adata)
    #sc.pp.neighbors(adata)
    #sc.tl.umap(adata)
    #adata.obsm['X_umapraw'] = adata.obsm['X_umap']
    
    # sc.tl.pca(input_ad, svd_solver="arpack", mask_var="highly_variable")
    
    click.echo("setup scVI model")
    scvi.model.SCVI.setup_anndata(adata, layer="counts", batch_key=batch_key)
    vae = scvi.model.SCVI(adata, n_layers=2, n_latent=40, gene_likelihood="nb")
    vae.train()
    adata.obsm["X_scVI"] = vae.get_latent_representation()
    #sc.pp.neighbors(adata, use_rep="X_scVI", key_added='scVI', n_neighbors=15, n_pcs=40)
    sc.pp.neighbors(adata, use_rep="X_scVI", n_neighbors=15, n_pcs=40)
    #sc.tl.leiden(adata, resolution=resolution_set, key_added='leiden') # use "Leiden" to achieve resolution setting
    print(adata.uns.keys())
    #sc.tl.leiden(adata, resolution=resolution_set, key_added='celltype', neighbors_key='scVI')  # clusters information in celltype
    sc.tl.leiden(adata, resolution=resolution, key_added=cluster_name)  # clusters information in celltype
    #
    sc.tl.umap(adata, neighbors_key='neighbors', min_dist=0.3) ## to match min_dist in seurat
    with PdfPages(out_umap) as pdf:
        sc.pl.umap(adata, color=key_list, legend_loc='right margin', ncols=1)
        plt.savefig(pdf, format='pdf', dpi=300, bbox_inches='tight')
        plt.close()
    #adata.obsm['X_umapscVI'] = adata.obsm['X_umap']
    click.echo("scvi integrated adata structure")
    #
    adata
    click.echo("Save output")
    adata.write(filename=out_h5ad,compression="gzip")
    click.echo("Done scVI")
    
    obsm_key = 'X_scVI'
    obsm_data = adata.obsm[obsm_key]
    reduc_name = obsm_key.replace("X_", "") if obsm_key.startswith("X_") else obsm_key
    df = pd.DataFrame(
        obsm_data,
        index=adata.obs_names,
        columns=[f"{reduc_name}_{i+1}" for i in range(obsm_data.shape[1])]
    )
    df.index.name = "cell_id"
    df.reset_index(inplace=True)
    df.to_csv(obsm_key+'_scVI_integrated.csv', index=False)


if __name__ == '__main__':
    run_scVI()
