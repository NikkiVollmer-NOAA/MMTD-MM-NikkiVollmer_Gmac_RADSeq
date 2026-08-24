#!/bin/bash
#SBATCH -D /scratch2/nvollmer/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=04:00:00
#SBATCH --job-name=fastqc_trimmed
#SBATCH --output=fastqc_trimmed_%A_%a.out
#SBATCH --error=fastqc_trimmed_%A_%a.err
#SBATCH --array=0-5   # one array task per run folder (0-indexed, adjust if not exactly 6)

module load bio/fastqc/0.11.9

RUN_DIRS=(
  /home/nvollmer/GmacPopGen/trimmed/3026
  /home/nvollmer/GmacPopGen/trimmed/3027
  /home/nvollmer/GmacPopGen/trimmed/3028
  /home/nvollmer/GmacPopGen/trimmed/3029
  /home/nvollmer/GmacPopGen/trimmed/3030
  /home/nvollmer/GmacPopGen/trimmed/3031
)

RUN_DIR=${RUN_DIRS[$SLURM_ARRAY_TASK_ID]}
OUT_DIR=${RUN_DIR}/fastqc_trimmed
mkdir -p "$OUT_DIR"

# EDIT: adjust glob to match your clean file naming (e.g. *_clean.fastq.gz)
fastqc -t 4 -o "$OUT_DIR" "${RUN_DIR}"/*_clean_fastq.gz
