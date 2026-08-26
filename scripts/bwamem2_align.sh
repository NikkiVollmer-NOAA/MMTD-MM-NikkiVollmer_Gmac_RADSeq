#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=20
#SBATCH --mem=60G
#SBATCH --time=24:00:00
#SBATCH --job-name=bwa_align
#SBATCH --output=bwa_align_%A_%a.out
#SBATCH --error=bwa_align_%A_%a.err
#SBATCH --array=0-5

# ------------------------------------------------------------------------------
# Purpose: Align trimmed nextRAD reads to the short-finned pilot whale reference
# genome using bwa-mem2, one array task per sequencing run (3026-3031).
#
# WHY THIS LOOKS UP LAB ID FROM pilot_key.txt INSTEAD OF USING THE FILENAME
# DIRECTLY AS THE SAMPLE NAME (as in the original Ana Costa-based script):
# the same physical barcode (e.g. CCATATGT-CTCTCTAT) was reused for two
# DIFFERENT animals between the two plate layouts used in this project --
# Gmac151 in runs 3026-3028, but Gmac263 in runs 3029-3031. So the barcode
# alone does not reliably identify the individual; the correct lab ID depends
# on BOTH the barcode AND which run/plate the file came from. This script
# reads pilot_key.txt directly (which is already organized into per-run
# blocks) to look up the correct lab ID for each file before alignment, and
# uses that lab ID as the @RG SM tag -- this is what samtools merge will use
# later to correctly group each individual's six lanes into one BAM.
# ------------------------------------------------------------------------------

module load aligners/bwa-mem2/2.2.1
module load bio/samtools/1.23

RUN_DIRS=(3026 3027 3028 3029 3030 3031)
RUN=${RUN_DIRS[$SLURM_ARRAY_TASK_ID]}

REF=/home/nvollmer/GmacPopGen/refseq/Hic_short-finned-pilot-whale.fa.gz
KEY=/home/nvollmer/GmacPopGen/pilot_key.txt
TRIMMED_DIR=/home/nvollmer/GmacPopGen/trimmed/${RUN}
OUTBASE=/home/nvollmer/GmacPopGen/aligned

# --- Step 1: pull out just this run's block from the key file -------------
# pilot_key.txt looks like:
#   run_3026
#   BARCODE<TAB>LabID
#   BARCODE<TAB>LabID
#   run_3027
#   ...
# awk grabs only the lines between "run_${RUN}" and the next "run_" header.
RUN_KEY=$(awk -v run="run_${RUN}" '
    $0 == run {flag=1; next}
    /^run_/ {flag=0}
    flag && NF {print}
' "$KEY")

# --- Step 2: loop over this run's trimmed fastq files ----------------------
for FASTQ in "${TRIMMED_DIR}"/*_clean_fastq.gz; do
    FNAME=$(basename "$FASTQ")

    # skip the undetermined bucket -- not a real sample
    if [[ "$FNAME" == Undetermined* ]]; then
        continue
    fi

    # parse barcode and lane out of: <run>_<i7-i5>_S###_L###_R1_001_clean_fastq.gz
    BARCODE=$(echo "$FNAME" | sed -E 's/^[0-9]+_([ACGT]+-[ACGT]+)_S[0-9]+_(L[0-9]+)_R1_001_clean_fastq\.gz/\1/')
    LANE=$(echo "$FNAME" | sed -E 's/^[0-9]+_([ACGT]+-[ACGT]+)_S[0-9]+_(L[0-9]+)_R1_001_clean_fastq\.gz/\2/')

    # look up the lab ID for this barcode, within this run's key block only
    LAB_ID=$(echo "$RUN_KEY" | awk -F'\t' -v bc="$BARCODE" '$1 == bc {print $2}')

    if [[ -z "$LAB_ID" ]]; then
        echo "WARNING: no lab ID found for barcode $BARCODE in run $RUN -- skipping $FNAME" >&2
        continue
    fi

    OUTDIR="${OUTBASE}/${LAB_ID}"
    mkdir -p "$OUTDIR"
    OUTBAM="${OUTDIR}/${LAB_ID}_run${RUN}_${LANE}.sorted.bam"

    if [[ -f "$OUTBAM" ]]; then
        echo "SKIP (already exists): $OUTBAM"
        continue
    fi

    echo "Aligning: $FNAME  ->  $OUTBAM  (SM:${LAB_ID})"

    bwa-mem2 mem -t 20 \
        -R "@RG\tID:${RUN}_${LANE}\tPL:ILLUMINA\tSM:${LAB_ID}" \
        "$REF" "$FASTQ" \
      | samtools view -b - \
      | samtools sort -@ 4 -o "$OUTBAM" -

    samtools index "$OUTBAM"
done
