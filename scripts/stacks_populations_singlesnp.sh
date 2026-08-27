#!/bin/bash
#SBATCH -D /home/nvollmer/GmacPopGen/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=medmem
#SBATCH --cpus-per-task=16
#SBATCH --mem=170G
#SBATCH --time=12:00:00
#SBATCH --job-name=populations_singlesnp
#SBATCH --output=populations_singlesnp_%j.out
#SBATCH --error=populations_singlesnp_%j.err

# ------------------------------------------------------------------------------
# Purpose: Re-run the Stacks `populations` step against the existing gstacks
# catalog (already built -- this does NOT re-run gstacks/ref_map.pl, so it
# should be dramatically faster than the original ~18hr run), this time with:
#   --write-single-snp : keep only the first variant position per locus, to
#     avoid linkage/pseudoreplication among SNPs on the same ~145bp nextRAD
#     fragment -- matches the actual (undocumented-in-text) protocol used in
#     Vollmer et al. 2025, per the author's own project notes.
#   --ordered-export    : write the VCF sorted by genomic coordinate rather
#     than internal catalog-locus order.
# Output is written to a NEW directory (stacks_output_singlesnp) rather than
# overwriting the original multi-SNP populations.* output, so both are
# available for comparison if needed.
# ------------------------------------------------------------------------------

module load bio/stacks/2.65

CATALOG_DIR=/home/nvollmer/GmacPopGen/stacks_output
OUTDIR=/home/nvollmer/GmacPopGen/stacks_output_singlesnp
POPMAP=/home/nvollmer/GmacPopGen/stacks_input/popmap.tsv

mkdir -p "$OUTDIR"

populations \
    -P "$CATALOG_DIR" \
    -O "$OUTDIR" \
    -M "$POPMAP" \
    -t 16 \
    --vcf \
    -r 0 \
    --write-single-snp \
    --ordered-export

echo "=== Done ==="
echo "New SNP count: $(grep -vc '^#' ${OUTDIR}/populations.snps.vcf)"
echo "New individual count: $(grep -m1 '^#CHROM' ${OUTDIR}/populations.snps.vcf | awk '{print NF-9}')"
