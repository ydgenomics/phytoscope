cd /phytoscope/src/integration_scib/out
input_rds="/data/work/MetaNeighbor/Sp_metaneighbor.rds"
prefix='Sp'
batch_key='biosample'
key_list='biosample,sample,metaneighbor'
resolution=0.5
cluster_name='celltype'
run_sct="yes"

Rscript /phytoscope/src/integration_scib/BBKNNR_integration.R \
--input_rds $input_rds --prefix $prefix --batch_key $batch_key \
--key_list $key_list --resolution $resolution --cluster_name $cluster_name

Rscript /phytoscope/src/integration_scib/rliger.INMF_integration.R \
--input_rds $input_rds --prefix $prefix --batch_key $batch_key \
--key_list $key_list --resolution $resolution --cluster_name $cluster_name

if [ "$run_sct" == "yes" ]; then
    Rscript /phytoscope/src/integration_scib/SCTransform.CCA_integration.R \
    --input_rds $input_rds --prefix $prefix --batch_key $batch_key \
    --key_list $key_list --resolution $resolution --cluster_name $cluster_name

    Rscript /phytoscope/src/integration_scib/SCTransform.harmony_integration.R \
    --input_rds $input_rds --prefix $prefix --batch_key $batch_key \
    --key_list $key_list --resolution $resolution --cluster_name $cluster_name
fi

input_h5ad="/data/work/Convert/Sp_metaneighbor.rh.h5ad"
prefix='Sp'
batch_key='biosample'
key_list='biosample,sample,metaneighbor'
resolution=0.5
cluster_name='celltype'

python /phytoscope/src/integration_scib/unintegration.py \
$input_h5ad --prefix $prefix --batch_key $batch_key --key_list $key_list \
--cluster_name $cluster_name --resolution $resolution

python /phytoscope/src/integration_scib/harmony_integration.py \
$input_h5ad --prefix $prefix --batch_key $batch_key --key_list $key_list \
--cluster_name $cluster_name --resolution $resolution

python /phytoscope/src/integration_scib/scVI_integration.py \
$input_h5ad --prefix $prefix --batch_key $batch_key --key_list $key_list \
--cluster_name $cluster_name --resolution $resolution


mkdir -p /phytoscope/src/integration_scib/out/scib-metrics && cd /phytoscope/src/integration_scib/out/scib-metrics
unintegrated_h5ad="/phytoscope/src/integration_scib/out/Sp_unintegrated.h5ad"
integrated_file="/phytoscope/src/integration_scib/out/iNMF_rliger.INMF_integrated.csv,/phytoscope/src/integration_scib/out/X_pca_harmony_harmony_integrated.csv,/phytoscope/src/integration_scib/out/X_scVI_scVI_integrated.csv"
tests_file="true,true,true,true,true,true,true,true,true,true"
batch_key="biosample"
label_key="metaneighbor"
n_jobs=32
prefix="Sp"

python /phytoscope/src/integration_scib/scIB.py \
--unintegrated_h5ad $unintegrated_h5ad --integrated_file $integrated_file \
--tests_file $tests_file --batch_key $batch_key --label_key $label_key \
--n_jobs $n_jobs --prefix $prefix