#!/bin/bash
#
#SBATCH --job-name=Prep_1
#SBATCH --output=JOB_Prep_1-%j.out
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

### VCF for imputed genotypes and replace the chr number by ${CHR} 
VCF_imputed=${3}

CHR=${4}

########################################
########################################

cd $WORK_DIR

##### Create folders
mkdir -p ${WORK_DIR}Genotypes

### Path to Softwares binaries
PLINK1_PATH=${WORK_DIR}Software/plink
PLINK2_PATH=${WORK_DIR}Software/plink2

### Run
$PLINK2_PATH \
--vcf ${VCF_imputed} dosage=DS \
--make-pgen --id-delim \
--snps-only \
--rm-dup exclude-mismatch \
--out ${WORK_DIR}Genotypes/TEMP_chr${CHR}.dose

cat ${WORK_DIR}Genotypes/TEMP_chr${CHR}.dose.pvar | grep -v '^#' | awk '{print $3, $1":"$2}' | sort | uniq \
> ${WORK_DIR}Genotypes/TEMP_Recode_ID_SNPs_chr${CHR}.txt

$PLINK2_PATH \
--pfile ${WORK_DIR}Genotypes/TEMP_chr${CHR}.dose \
--snps-only \
--update-name ${WORK_DIR}Genotypes/TEMP_Recode_ID_SNPs_chr${CHR}.txt \
--make-pgen \
--out ${WORK_DIR}Genotypes/TEMP_TEMP_chr${CHR}.dose

# remove duplicate IDs
$PLINK2_PATH \
--pfile ${WORK_DIR}Genotypes/TEMP_TEMP_chr${CHR}.dose \
--snps-only \
--rm-dup exclude-mismatch \
--make-pgen \
--out ${WORK_DIR}Genotypes/${STUDY}.chr${CHR}.dose.noDUP.forRegenieStep2

rm ${WORK_DIR}Genotypes/TEMP_Recode_ID_SNPs_chr${CHR}.txt
rm ${WORK_DIR}Genotypes/TEMP_chr${CHR}.dose.*
rm ${WORK_DIR}Genotypes/TEMP_TEMP_chr${CHR}.dose.*

echo '########################################'
echo 'Job finished' $(date --iso-8601=seconds)


#########################

