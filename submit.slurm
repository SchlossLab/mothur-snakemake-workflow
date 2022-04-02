#!/bin/bash
#SBATCH --job-name=smk-submit
#SBATCH --output=%x-%j.out
#SBATCH --mail-user=salucas@umich.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --account=pschloss1
#SBATCH --partition=standard
#SBATCH --time=360:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=2g

### Set Up Environment
### Need to access the internet
source /etc/profile.d/http_proxy.sh

### Conda environment:
source ~/miniconda3/etc/profile.d/conda.sh
conda activate snakemake

### This chunk changes directory to the directory from which it was submitted
echo "Changing directory to $SLURM_SUBMIT_DIR"
cd $SLURM_SUBMIT_DIR

### Run script
snakemake --profile config/slurm