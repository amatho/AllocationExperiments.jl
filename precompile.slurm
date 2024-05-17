#!/bin/sh
#SBATCH --partition=CPUQ
#SBATCH --account=ie-idi
#SBATCH --time=0-00:30:00
#SBATCH --nodes=1
#SBATCH -c 4
#SBATCH --mem=8G
#SBATCH --constraint="pec6520"
#SBATCH --job-name="matroid_precompile"
#SBATCH --output=log/srun_pre.out
#SBATCH --mail-user=amandust@stud.ntnu.no
#SBATCH --mail-type="FAIL,END"

WORKDIR=${SLURM_SUBMIT_DIR}
cd ${WORKDIR}

module purge
module load Julia/1.9.3-linux-x86_64
module list

julia run_precompile.jl
