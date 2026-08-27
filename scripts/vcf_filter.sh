#!/bin/bash
#SBATCH -D /home/nvollmer/GmacPopGen/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=60G
#SBATCH --time=24:00:00
#SBATCH --job-name=vcf_filter
#SBATCH --output=vcf_filter_%j.out
#SBATCH --error=vcf_filter_%j.err

# ------------------------------------------------------------------------------
# Purpose: Filter the raw Stacks SNP VCF (populations.snps.vcf) following the
# exact filtering order used in Vollmer et al. 2025:
#   1. Remove indels AND remove sites with <10x mean coverage (site-level,
#      averaged across all individuals)
#   2. Remove individuals with <10x mean depth (calculated from the VCF
#      produced by step 1 -- this is the paper's actual <10x individual
#      filter, distinct from the earlier BAM-level pre-Stacks sanity check)
#   3. Remove SNPs with minor allele frequency < 0.05
#
# Each step's output is kept as a separate, clearly-named intermediate VCF,
# and site/individual counts are logged at every stage so the effect of each
# filter can be inspected independently, matching the paper's stated
# step-by-step protocol rather than a single combined filter call.
# ------------------------------------------------------------------------------

module load bio/vcftools/0.1.17

WORKDIR=/home/nvollmer/GmacPopGen/vcf_filtering
INPUT_VCF=/home/nvollmer/GmacPopGen/stacks_output_singlesnp/populations.snps.vcf

mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "=== Starting VCF: $INPUT_VCF ==="
echo "Raw SNP count: $(grep -vc '^#' "$INPUT_VCF")"
echo "Raw individual count: $(grep -m1 '^#CHROM' "$INPUT_VCF" | awk '{print NF-9}')"
echo ""

# --- Step 1: remove indels + remove sites with <10x mean coverage ---------
echo "=== Step 1: remove indels, remove sites with <10x mean coverage ==="
vcftools --vcf "$INPUT_VCF" \
    --remove-indels \
    --min-meanDP 10 \
    --recode --recode-INFO-all \
    --out step1_noindel_mindepth10

STEP1_VCF="step1_noindel_mindepth10.recode.vcf"
echo "Step 1 SNP count: $(grep -vc '^#' "$STEP1_VCF")"
echo ""

# --- Step 2a: calculate per-individual mean depth on step 1 output --------
echo "=== Step 2a: calculating per-individual mean depth ==="
vcftools --vcf "$STEP1_VCF" \
    --depth \
    --out step2_individual_depth

# .idepth file columns: INDV  N_SITES  MEAN_DEPTH
echo "Individual depth summary written to step2_individual_depth.idepth"

# Identify individuals below 10x mean depth
awk 'NR>1 && $3<10 {print $1}' step2_individual_depth.idepth > individuals_below_10x.txt
N_BELOW10=$(wc -l < individuals_below_10x.txt)
N_TOTAL=$(($(wc -l < step2_individual_depth.idepth) - 1))
echo "Individuals below 10x mean depth (from VCF, not the earlier BAM-level check): $N_BELOW10 / $N_TOTAL"
echo "List written to: individuals_below_10x.txt"
echo ""

# --- Step 2b: remove those individuals from the VCF ------------------------
echo "=== Step 2b: removing individuals below 10x mean depth ==="
vcftools --vcf "$STEP1_VCF" \
    --remove individuals_below_10x.txt \
    --recode --recode-INFO-all \
    --out step2_depthfiltered

STEP2_VCF="step2_depthfiltered.recode.vcf"
echo "Step 2 SNP count: $(grep -vc '^#' "$STEP2_VCF")"
echo "Step 2 individual count: $(grep -m1 '^#CHROM' "$STEP2_VCF" | awk '{print NF-9}')"
echo ""

# --- Step 3: MAF < 0.05 filter ----------------------------------------------
echo "=== Step 3: removing SNPs with MAF < 0.05 ==="
vcftools --vcf "$STEP2_VCF" \
    --maf 0.05 \
    --recode --recode-INFO-all \
    --out step3_final_maf05

STEP3_VCF="step3_final_maf05.recode.vcf"
echo "Final SNP count: $(grep -vc '^#' "$STEP3_VCF")"
echo "Final individual count: $(grep -m1 '^#CHROM' "$STEP3_VCF" | awk '{print NF-9}')"
echo ""

echo "=== Filtering complete. Final VCF: ${WORKDIR}/${STEP3_VCF} ==="
