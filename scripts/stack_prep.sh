#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:15:00
#SBATCH --job-name=stacks_prep
#SBATCH --output=stacks_prep_%j.out
#SBATCH --error=stacks_prep_%j.err

# ------------------------------------------------------------------------------
# Purpose: Prepare inputs for Stacks (gstacks/ref_map.pl):
#   1. Symlink each merged BAM (<lab_id>.merged.bam) to the naming gstacks
#      expects (<lab_id>.bam), in a dedicated directory -- original merged
#      BAMs are never touched or copied.
#   2. Generate a population map (popmap.tsv) listing every individual with
#      a single placeholder population ID ("1"). Real population structure
#      is unknown at this stage -- that's what STRUCTURE/ADMIXTURE will
#      determine later from the resulting SNP data. This mirrors the paper's
#      approach of running STRUCTURE "without any prior population
#      assignment."
# ------------------------------------------------------------------------------

MERGED_DIR=/home/nvollmer/GmacPopGen/merged
STACKS_BAM_DIR=/home/nvollmer/GmacPopGen/stacks_input/bams
POPMAP=/home/nvollmer/GmacPopGen/stacks_input/popmap.tsv

mkdir -p "$STACKS_BAM_DIR"
mkdir -p "$(dirname "$POPMAP")"

> "$POPMAP"  # truncate/create fresh

for BAM in "${MERGED_DIR}"/*.merged.bam; do
    LAB_ID=$(basename "$BAM" .merged.bam)
    LINK="${STACKS_BAM_DIR}/${LAB_ID}.bam"

    if [[ -L "$LINK" || -e "$LINK" ]]; then
        rm -f "$LINK"
    fi
    ln -s "$(realpath "$BAM")" "$LINK"

    # also symlink the .bai index if it exists
    if [[ -f "${BAM}.bai" ]]; then
        ln -sf "$(realpath "${BAM}.bai")" "${LINK}.bai"
    fi

    echo -e "${LAB_ID}\t1" >> "$POPMAP"
done

N=$(wc -l < "$POPMAP")
echo "Done. Popmap written with $N individuals: $POPMAP"
echo "Symlinked BAMs in: $STACKS_BAM_DIR"
