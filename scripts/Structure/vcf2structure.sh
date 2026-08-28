#!/bin/bash
#SBATCH -D /home/nvollmer/GmacPopGen/log
#SBATCH --mail-type=END
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --partition=standard
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --job-name=vcf2structure
#SBATCH --output=vcf2structure_%j.out
#SBATCH --error=vcf2structure_%j.err

# ------------------------------------------------------------------------------
# Purpose: Convert the final filtered VCF (step3_final_maf05.recode.vcf; 4,489
# SNPs, 311 individuals) into STRUCTURE input format, using PGDSpider's
# command-line interface with the same .spid configuration file used for the
# 2025 Vollmer et al. dolphin paper's conversion -- ensuring identical
# encoding/formatting behavior (diploid, no population file, SNP data type,
# no inter-marker distances) rather than re-deriving these choices from
# scratch.
# ------------------------------------------------------------------------------

module load bio/pgdspider/2.1.1.5

# PGDSpider 2.1.1.5 requires Java 8 and fails under SEDNA's default Java 17
# with a NoClassDefFoundError. No Java 8 module exists, but a system Java 8
# install is available directly -- invoked explicitly by full path below
# rather than relying on `java` on PATH (which resolves to Java 17).
JAVA8=/usr/lib/jvm/java-1.8.0-openjdk/bin/java

VCF=/home/nvollmer/GmacPopGen/vcf_filtering/step3_final_maf05.recode.vcf
SPID=/home/nvollmer/GmacPopGen/vcf_filtering/vcf2structure_snps.spid
OUTDIR=/home/nvollmer/GmacPopGen/structure
OUTFILE=${OUTDIR}/run1.txt

mkdir -p "$OUTDIR"

# The pgdspider module sets $PGDSPIDER to point to the jar file directly,
# rather than putting a PGDSpider2-cli binary on PATH -- so it needs to be
# invoked via java -jar rather than as a standalone command.
"$JAVA8" -Xmx8g -jar "$PGDSPIDER" \
    -inputfile "$VCF" -inputformat VCF \
    -outputfile "$OUTFILE" -outputformat STRUCTURE \
    -spid "$SPID"

echo "=== Done ==="
echo "Output written to: $OUTFILE"
wc -l "$OUTFILE"
