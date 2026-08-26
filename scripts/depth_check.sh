#!/bin/bash
#SBATCH -D /home/nvollmer/GmacPopGen/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --job-name=depth_check
#SBATCH --output=depth_check_%A_%a.out
#SBATCH --error=depth_check_%A_%a.err
#SBATCH --array=0-316%25

# ------------------------------------------------------------------------------
# Purpose: Compute per-individual sequencing depth from merged BAMs, as an
# early sanity check before Stacks/SNP calling -- NOT a substitute for the
# paper's actual <10x mean-depth filter, which is computed from the VCF
# (via VCFtools, on called SNP sites) after Stacks processing. A genome-wide
# BAM average would be misleading here anyway, since reduced-representation
# (nextRAD) data only covers a small fraction of the ~2.25 Gb reference near
# restriction/cut sites -- most of the genome has zero coverage by design.
#
# Uses `samtools coverage`, which reports per-contig meandepth (averaged over
# the FULL contig length, including zero-coverage bases) and covbases (# of
# bases with >=1x coverage). From these we compute two genome-wide summary
# metrics per individual:
#   - meandepth_genomewide: total depth / total reference length (expected
#     to be very low/near-zero for RRS data -- this is normal, not a problem)
#   - meandepth_at_covered_sites: total depth / total covered bases -- a much
#     more meaningful "how deep is the RAD data" metric, comparable across
#     individuals regardless of how sparse genome-wide capture is
# One array task handles one individual's merged BAM.
# ------------------------------------------------------------------------------

module load bio/samtools/1.23

MERGED_BASE=/home/nvollmer/GmacPopGen/merged
LOG_CSV=/home/nvollmer/GmacPopGen/depth_summary.csv

mapfile -t BAMS < <(ls "${MERGED_BASE}"/*.merged.bam | sort)
N=${#BAMS[@]}

if [[ $SLURM_ARRAY_TASK_ID -ge $N ]]; then
    echo "Array task $SLURM_ARRAY_TASK_ID has no corresponding BAM (only $N found). Exiting cleanly."
    exit 0
fi

BAM=${BAMS[$SLURM_ARRAY_TASK_ID]}
LAB_ID=$(basename "$BAM" .merged.bam)

echo "Computing coverage for $LAB_ID ($BAM)"

# samtools coverage outputs one row per reference contig:
# #rname startpos endpos numreads covbases coverage meandepth meanbaseq meanmapq
COVERAGE_OUT=$(samtools coverage "$BAM")

READ_STATS=$(echo "$COVERAGE_OUT" | awk -F'\t' '
    NR==1 {next}  # skip header
    {
        contiglen = $3 - $2 + 1
        total_length += contiglen
        total_covbases += $5
        total_depth += $7 * contiglen
    }
    END {
        if (total_length > 0) {
            genomewide = total_depth / total_length
        } else { genomewide = 0 }
        if (total_covbases > 0) {
            at_covered = total_depth / total_covbases
        } else { at_covered = 0 }
        pct_covered = (total_covbases / total_length) * 100
        printf "%.6f,%.6f,%.4f,%d,%d\n", genomewide, at_covered, pct_covered, total_covbases, total_length
    }
')

MEANDEPTH_GENOMEWIDE=$(echo "$READ_STATS" | cut -d',' -f1)
MEANDEPTH_AT_COVERED=$(echo "$READ_STATS" | cut -d',' -f2)
PCT_GENOME_COVERED=$(echo "$READ_STATS" | cut -d',' -f3)
TOTAL_COVBASES=$(echo "$READ_STATS" | cut -d',' -f4)
TOTAL_LENGTH=$(echo "$READ_STATS" | cut -d',' -f5)

{
    flock -x 200
    if [[ ! -s "$LOG_CSV" ]]; then
        echo "lab_id,meandepth_genomewide,meandepth_at_covered_sites,pct_genome_covered,total_covbases,total_ref_length" >> "$LOG_CSV"
    fi
    echo "${LAB_ID},${MEANDEPTH_GENOMEWIDE},${MEANDEPTH_AT_COVERED},${PCT_GENOME_COVERED},${TOTAL_COVBASES},${TOTAL_LENGTH}" >> "$LOG_CSV"
} 200>>"${LOG_CSV}.lock"

echo "Done: $LAB_ID  meandepth_at_covered_sites=${MEANDEPTH_AT_COVERED}  pct_genome_covered=${PCT_GENOME_COVERED}%"
