#!/bin/bash
#SBATCH -D home/nvollmer/GmacPopGen/log/array_jobs
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --job-name=multiqc_trimmed
#SBATCH --output=multiqc_trimmed_%j.out
#SBATCH --error=multiqc_trimmed_%j.err

source ~/.bashrc
mamba activate multiqc-1.17  

OUT_DIR=/home/nvollmer/GmacPopGen/multiqc_trimmed
mkdir -p "$OUT_DIR"

multiqc \
  /home/nvollmer/GmacPopGen/trimmed/3026/fastqc_trimmed \
  /home/nvollmer/GmacPopGen/trimmed/3027/fastqc_trimmed \
  /home/nvollmer/GmacPopGen/trimmed/3028/fastqc_trimmed \
  /home/nvollmer/GmacPopGen/trimmed/3029/fastqc_trimmed \
  /home/nvollmer/GmacPopGen/trimmed/3030/fastqc_trimmed \
  /home/nvollmer/GmacPopGen/trimmed/3031/fastqc_trimmed \
  -o "$OUT_DIR" \
  -n multiqc_trimmed_report
