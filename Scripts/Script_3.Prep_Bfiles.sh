#!/bin/bash
#
#SBATCH --job-name=Prep_3
#SBATCH --output=JOB_Prep_3-%j.out
#SBATCH --mem=25GB
#srun hostname

### Advertisement ###
echo "####################################################" 
echo "#   TERASTROKE - Script for preparation and GWAS   #" 
echo "####################################################" 
echo -e '\n'

### Study Name
STUDY=${1}

### Directory to use for all data preparation and analyses
WORK_DIR=${2}

### Plink binary files for non imputed QCed genotypes (without .bed/.bim/.fam)
Plink_BFILE_nonimputed=${3}

### Trait
PHENO=${4}

########################################
########################################

cd $WORK_DIR

### Path to Softwares binaries
PLINK1_PATH=${WORK_DIR}Software/plink
PLINK2_PATH=${WORK_DIR}Software/plink2

##### Create folders
mkdir -p ${WORK_DIR}Genotypes

### Run 
$PLINK2_PATH \
--bfile ${Plink_BFILE_nonimputed} \
--keep ${WORK_DIR}Phenotypes/List_IDs.TERASTROKE.${STUDY}.${PHENO}.txt \
--mac 10 \
--snps-only \
--make-bed \
--out ${WORK_DIR}Genotypes/${STUDY}.Genotypes.ForRegenieStep1.${PHENO}

##### If too many variants (>500k) are present 
#$PLINK1_PATH \
#--bfile ${Plink_BFILE_nonimputed} \
#--maf 0.05 \
#--snps-only \
#--indep-pairwise 1000 100 0.9 \
#--out ${WORK_DIR}Genotypes/${STUDY}.Genotypes.ForRegenieStep1

#$PLINK1_PATH \
#--bfile ${Plink_BFILE_nonimputed} \
#--maf 0.05 \
#--snps-only \
#--extract ${WORK_DIR}Genotypes/${STUDY}.Genotypes.ForRegenieStep1.prune.in \
#--make-bed \
#--out ${WORK_DIR}Genotypes/${STUDY}.Genotypes.ForRegenieStep1

echo '########################################'
echo 'Job finished' $(date --iso-8601=seconds)


#######################
