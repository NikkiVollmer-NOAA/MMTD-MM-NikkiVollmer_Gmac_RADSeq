#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --job-name=merge_bams
#SBATCH --output=merge_bams_%A_%a.out
#SBATCH --error=merge_bams_%A_%a.err
#SBATCH --array=0-999  # generous upper bound; auto-trimmed to actual # of individuals below

# ------------------------------------------------------------------------------
# Purpose: Merge each individual's per-lane BAMs (produced by bwa_align_bashonly.slurm,
# one per run/lane, e.g. GmacXXX_run3026_L002.sorted.bam ... GmacXXX_run3031_L002.sorted.bam)
# into a single merged, sorted, indexed BAM per individual: GmacXXX.merged.bam.
# One array task handles one individual (one lab_id folder under aligned/).
# Skips any individual whose merged BAM already exists, so this is safe to
# resubmit if it fails partway through. Also logs how many lane-BAMs went into
# each merge, so individuals with fewer than 6 (e.g. missing from a run, or
# excluded for another reason) are easy to spot afterward.
# ------------------------------------------------------------------------------

module load bio/samtools/1.23

ALIGNED_BASE=/home/nvollmer/GmacPopGen/aligned
MERGED_BASE=/home/nvollmer/GmacPopGen/merged
LOG_CSV=/home/nvollmer/GmacPopGen/merge_summary.csv

mkdir -p "$MERGED_BASE"

# Build the list of individual (lab_id) folders once; index into it by array task ID
mapfile -t LAB_IDS < <(ls -d "${ALIGNED_BASE}"/*/ | xargs -n1 basename | sort)
N=${#LAB_IDS[@]}

if [[ $SLURM_ARRAY_TASK_ID -ge $N ]]; then
    echo "Array task $SLURM_ARRAY_TASK_ID has no corresponding individual (only $N individuals found). Exiting cleanly."
    exit 0
fi

LAB_ID=${LAB_IDS[$SLURM_ARRAY_TASK_ID]}
INDIR="${ALIGNED_BASE}/${LAB_ID}"
OUTBAM="${MERGED_BASE}/${LAB_ID}.merged.bam"

if [[ -f "$OUTBAM" ]]; then
    echo "SKIP (already exists): $OUTBAM"
    exit 0
fi

# Collect this individual's per-lane BAMs
mapfile -t LANE_BAMS < <(ls "${INDIR}"/*.sorted.bam 2>/dev/null)
N_LANES=${#LANE_BAMS[@]}

if [[ $N_LANES -eq 0 ]]; then
    echo "WARNING: no BAMs found for $LAB_ID in $INDIR -- skipping" >&2
    exit 1
fi

echo "Merging $N_LANES lane BAM(s) for $LAB_ID:"
printf '  %s\n' "${LANE_BAMS[@]}"

if [[ $N_LANES -eq 1 ]]; then
    # samtools merge requires >=2 inputs; just copy/sort the single file through
    samtools sort -@ 4 -o "$OUTBAM" "${LANE_BAMS[0]}"
else
    samtools merge -@ 4 "$OUTBAM" "${LANE_BAMS[@]}"
fi

samtools index "$OUTBAM"

# Append a line to the shared summary CSV (flock avoids concurrent-write corruption
# across the many array tasks writing to this file at once)
{
    flock -x 200
    if [[ ! -s "$LOG_CSV" ]]; then
        echo "lab_id,n_lanes_merged,output_bam" >> "$LOG_CSV"
    fi
    echo "${LAB_ID},${N_LANES},${OUTBAM}" >> "$LOG_CSV"
} 200>>"${LOG_CSV}.lock"

echo "Done: $OUTBAM ($N_LANES lanes)"
