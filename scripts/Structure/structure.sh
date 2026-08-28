#!/bin/bash
#SBATCH --job-name STRUCT
#SBATCH --mail-user=nicole.vollmer@noaa.gov
#SBATCH --mail-type=END
#SBATCH -o %x_%j.out
#SBATCH -e %x_%j.err
#SBATCH -D /home/nvollmer/GmacPopoGen/log/structure
#SBATCH --array=1-100%10
#SBATCH --mem=16G
#SBATCH --partition=standard
#SBATCH --time=7-00:00:00

# Initialize Mamba for non-interactive bash shell
eval "$(mamba shell hook --shell bash)"
# Activate the mamba environment containing structure
mamba activate structure-2.3.4

cd ~/structure

# Read line $SLURM_ARRAY_TASK_ID from tasks.txt
K=$(sed -n "${SLURM_ARRAY_TASK_ID}p" tasks.txt | cut -f1)
RUN=$(sed -n "${SLURM_ARRAY_TASK_ID}p" tasks.txt | cut -f2)

# Set the seed using the task ID -- RANDOMIZE=0 in mainparams.txt is required
# for this -D flag to actually take effect (RANDOMIZE=1 would silently ignore
# it and self-randomize instead)
SEED=$SLURM_ARRAY_TASK_ID

structure -K $K -D $SEED -m mainparams.txt -e extraparams.txt -o k${K}_run${RUN} 2>&1 | tee k${K}_run${RUN}.log
