### Date: 260706
### Image: Alignment
### Ref: [DIAMOND:快又准的蛋白序列比对软件](https://mp.weixin.qq.com/s/5UhthY9PHfN7zxZbJdZaJA)
fasta1=${1:-"/data/input/Files/User/yangdong/P/p-jintian/assemble2/renamed_transcript_filtered.pep"}
fasta2=${2:-"/Files/User/yangdong/OPEN/shoot.plantcellatlas/at/at.pep"}
type=${3:-"protein"} # nucleotide or protein
method=${4:-"diamond"} # diamond or blast
n_cpu=${5:-40}
name1=$(basename "$fasta1")
name2=$(basename "$fasta2")

mkdir result
if [[ "$type" == "nucleotide" ]]; then
  echo "Use blastn alignement nucleotide sequences..."
  makeblastdb -in $fasta1 -dbtype nucl -out $name1
  makeblastdb -in $fasta2 -dbtype nucl -out $name2
  blastn -query $fasta1 -db $name2 -out "./result/blastn_"$name1"_vs_"$name2".txt" -outfmt 6 -evalue 1e-10 -num_threads $n_cpu
  blastn -query $fasta2 -db $name1 -out "./result/blastn_"$name2"_vs_"$name1".txt" -outfmt 6 -evalue 1e-10 -num_threads $n_cpu
else
  if [[ "$method" == "diamond" ]]; then
    echo "Use diamond alignement protein sequences..."
    diamond makedb --in $fasta1 --db $name1
    diamond makedb --in $fasta2 --db $name2
    diamond blastp --db $name2 -q $fasta1 -o "./result/blastp_"$name1"_vs_"$name2".txt"
    diamond blastp --db $name1 -q $fasta2 -o "./result/blastp_"$name2"_vs_"$name1".txt"
  else
    echo "Use blastp alignement protein sequences..."
    makeblastdb -in $fasta1 -dbtype prot -out $name1
    makeblastdb -in $fasta2 -dbtype prot -out $name2
    blastp -query $fasta1 -db $name2 -out "./result/blastp_"$name1"_vs_"$name2".txt" -outfmt 6 -evalue 1e-10 -num_threads $n_cpu
    blastp -query $fasta2 -db $name1 -out "./result/blastp_"$name2"_vs_"$name1".txt" -outfmt 6 -evalue 1e-10 -num_threads $n_cpu
  fi
fi


# get reciprocal result
echo -e "Query_ID\tRefer_ID\tIdentity(%)\tAlignment_Length\tMismatches\tGap_Openings\tQ_Start\tQ_End\tS_Start\tS_End\tE-value\tBit_Score" > header.tsv
n=0
for i in $(ls */*.txt)
do 
  cat header.tsv $i > "$n".txt
  awk -F '\t' '$3 >= 70' "$n".txt > "$n"_filter.txt
  awk '!seen[$1]++' "$n"_filter.txt > "$n"_unique.tsv
  let n++
done

awk 'NR==FNR{a[$2"_"$1]=$1}NR!=FNR{if(a[$1"_"$2])print $1"\t"a[$1"_"$2]}' 0_unique.tsv 1_unique.tsv > reciprocal_best.txt