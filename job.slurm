#!/bin/sh
#SBATCH --partition=CPUQ
#SBATCH --account=ie-idi
#SBATCH --time=1-00:00:00
#SBATCH --nodes=1
#SBATCH -c 8
#SBATCH --mem=32G
#SBATCH --constraint="pec6520"
#SBATCH --array=1-10
#SBATCH --job-name="matroid_experiments"
#SBATCH --output=log/slurm_%A_%a.out
#SBATCH --mail-user=amandust@stud.ntnu.no
#SBATCH --mail-type=ALL

WORKDIR=${SLURM_SUBMIT_DIR}
cd ${WORKDIR}

module purge
module load Julia/1.9.3-linux-x86_64
module list

unbuffer julia --heap-size-hint=16G run_job.jl $SLURM_ARRAY_TASK_ID 100 # Enter experiment here
