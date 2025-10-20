#!/bin/bash
#
#SBATCH --job-name=Prep_2
#SBATCH --output=JOB_Prep_2.out
#
#srun hostname

### Advertisement ###
echo "####################################################" 
echo "#   TERASTROKE - Script for preparation and GWAS   #" 
echo "#   Developed by: Quentin Le Grand                 #" 
echo "#   For questions: quentin.le-grand@u-bordeaux.fr  #" 
echo "####################################################" 
echo -e '\n'

### Study Name
STUDY=${1}

### Directory to use for all data preparation and analyses
WORK_DIR=${2}

### Phenotype file
INPUT_PHENO=${3}
INPUT_COVAR=${4}

########################################
########################################

cd $WORK_DIR

### Path to Softwares binaries
PLINK1_PATH=${WORK_DIR}Software/plink
PLINK2_PATH=${WORK_DIR}Software/plink2

### Ref fam file to match IDs between phenotypes and genotypes
REF_FAM_FILE=${WORK_DIR}Genotypes/${STUDY}.chr1.dose.noDUP.forRegenieStep2.psam

##### Create folders
mkdir -p ${WORK_DIR}Phenotypes

Rscript --vanilla ${WORK_DIR}Scripts/Rscript_prep_Phenotypes.R $INPUT_PHENO $INPUT_COVAR $WORK_DIR $REF_FAM_FILE $STUDY

echo '########################################'
echo 'Job finished' $(date --iso-8601=seconds)

########################################
