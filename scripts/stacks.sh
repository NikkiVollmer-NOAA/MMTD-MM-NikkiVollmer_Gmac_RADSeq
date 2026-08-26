#!/bin/bash
#SBATCH -D /home/nvollmer/GmacPopGen/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=medmem
#SBATCH --cpus-per-task=16
#SBATCH --mem=120G
#SBATCH --time=48:00:00
#SBATCH --job-name=stacks_refmap
#SBATCH --output=stacks_refmap_%j.out
#SBATCH --error=stacks_refmap_%j.err

# ------------------------------------------------------------------------------
# Purpose: Run Stacks (ref_map.pl, which wraps gstacks + populations) on the
# merged, reference-aligned BAMs to call SNPs, following the reference-based
# workflow used in Vollmer et al. 2025. All 317 individuals are assigned to a
# single placeholder population (see stacks_prep.slurm / popmap.tsv) since
# real population structure is unknown at this stage -- that's determined
# later via STRUCTURE/ADMIXTURE from the resulting SNP data.
#
# IMPORTANT: --rm-pcr-duplicates is deliberately NOT used. That option assumes
# duplicate reads can be identified by shared start/end coordinates, which is
# appropriate for randomly-sheared whole-genome shotgun data -- but nextRAD/
# RAD-type reads legitimately pile up at fixed restriction/cut sites by
# design, so coordinate-based dedup would strip out real biological signal,
# not just PCR artifacts. This mirrors the very first consideration flagged
# for this project's pipeline.
#
# The `populations` sub-step is run with minimal filtering (-r 0, no MAF/
# missingness cutoffs) so it outputs a comprehensive VCF. Real filtering
# (remove indels -> sites <10x coverage -> individuals <10x mean depth ->
# MAF<0.05) is deferred to VCFtools afterward, in that exact order, matching
# the paper's protocol -- Stacks itself is not used to pre-filter.
# ------------------------------------------------------------------------------

module load bio/stacks/2.65  

BAM_DIR=/home/nvollmer/GmacPopGen/stacks_input/bams
POPMAP=/home/nvollmer/GmacPopGen/stacks_input/popmap.tsv
OUTDIR=/home/nvollmer/GmacPopGen/stacks_output

mkdir -p "$OUTDIR"

ref_map.pl \
    -T 16 \
    --samples "$BAM_DIR" \
    --popmap "$POPMAP" \
    -o "$OUTDIR" \
    -X "populations:--vcf" \
    -X "populations:-r 0"
