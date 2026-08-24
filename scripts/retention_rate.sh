#!/bin/bash
#SBATCH -D /home/nvollmer/GmacPopGen/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=06:00:00
#SBATCH --job-name=retention_rate
#SBATCH --output=retention_rate_%j.out
#SBATCH --error=retention_rate_%j.err

# ------------------------------------------------------------------------------
# Purpose: Calculate per-sample read retention after Nextera adapter/quality
# trimming with BBDuk. For each of the six sequencing run folders (3026-3031),
# this script pairs each trimmed ("_clean_fastq.gz") file with its corresponding
# raw ("*.fastq.gz") file, counts the number of reads in each (via line count / 4),
# and calculates the percentage of reads retained after trimming. Results are
# written to a single CSV (retention_summary.csv) with columns: run, sample_file,
# raw_reads, trimmed_reads, retention_pct. Samples whose raw file cannot be located
# are flagged as RAW_FILE_NOT_FOUND rather than causing the script to fail, so
# missing pairs can be investigated afterward. Output is used to identify any
# samples or runs with unusually low read retention prior to alignment.
# ------------------------------------------------------------------------------

RAW_BASE=/home/nvollmer/GmacPopGen/rawdata
CLEAN_BASE=/home/nvollmer/GmacPopGen/trimmed
OUTFILE=/home/nvollmer/GmacPopGen/retention_summary.csv

echo "run,sample_file,raw_reads,trimmed_reads,retention_pct" > "$OUTFILE"

RUN_DIRS=(3026 3027 3028 3029 3030 3031)

for RUN in "${RUN_DIRS[@]}"; do
    for CLEAN in "${CLEAN_BASE}/${RUN}"/*_clean_fastq.gz; do
        [[ -e "$CLEAN" ]] || continue   # skip if no files match (e.g. folder not populated yet)

        BASENAME=$(basename "$CLEAN")
        # strip "_clean_fastq.gz" and add back ".fastq.gz" to get the raw filename
        SAMPLE_STEM=${BASENAME%_clean_fastq.gz}
        RAW="${RAW_BASE}/${RUN}/${SAMPLE_STEM}.fastq.gz"

        if [[ -f "$RAW" ]]; then
            RAW_READS=$(( $(zcat "$RAW" | wc -l) / 4 ))
            CLEAN_READS=$(( $(zcat "$CLEAN" | wc -l) / 4 ))
            PCT=$(echo "scale=2; ($CLEAN_READS/$RAW_READS)*100" | bc)
            echo "${RUN},${SAMPLE_STEM},${RAW_READS},${CLEAN_READS},${PCT}" >> "$OUTFILE"
        else
            echo "${RUN},${SAMPLE_STEM},NA,NA,RAW_FILE_NOT_FOUND:${RAW}" >> "$OUTFILE"
        fi
    done
done
