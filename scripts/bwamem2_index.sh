#!/bin/bash
#SBATCH -D /home/nvollmer/GmacPopGen/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH -n 1
#SBATCH -N 1
#SBATCH -c 1
#SBATCH --mem=80G
#SBATCH --time=05:00:00
#SBATCH --job-name=bwa_index
#SBATCH --output=%x.%A.%a.out
#SBATCH --error=%x.%A.%a.err

# ------------------------------------------------------------------------------
# Purpose: Prepare the short-finned pilot whale reference genome (Hi-C assembly,
# CNGBdb accession CNA0050704) for downstream alignment. Builds the bwa-mem2
# index directly from the gzipped FASTA (needed for bwa-mem2 alignment), and
# separately decompresses the reference to build a samtools faidx index
# (needed by many downstream tools for fast random access to reference
# sequences; faidx requires an uncompressed or bgzip-compressed FASTA, which
# plain gzip does not support).
# ------------------------------------------------------------------------------

module load aligners/bwa-mem2/2.2.1
module load bio/samtools/1.23

cd /home/nvollmer/GmacPopGen/refseq

# bwa-mem2 can index the gzipped FASTA directly
bwa-mem2 index /home/nvollmer/GmacPopGen/refseq/Hic_short-finned-pilot-whale.fa.gz

# samtools faidx needs an uncompressed FASTA; keep the original .gz intact
gunzip -k Hic_short-finned-pilot-whale.fa.gz
samtools faidx Hic_short-finned-pilot-whale.fa
