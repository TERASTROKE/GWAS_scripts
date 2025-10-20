#!/bin/bash
#
#SBATCH --job-name=Prep_4
#SBATCH --output=JOB_Prep_4-%j.out
#SBATCH --mem=25GB
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

### Phenotype
PHENO=${3}

########################################
########################################

cd $WORK_DIR

### Path to Softwares binaries
PLINK1_PATH=${WORK_DIR}Software/plink
PLINK2_PATH=${WORK_DIR}Software/plink2
REGENIE_PATH=${WORK_DIR}Software/regenie

##### Pheno & Covar
PHENO_file=${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.${PHENO}.txt
COVAR_file=${WORK_DIR}Phenotypes/COVAR_REGENIE.TERASTROKE.${STUDY}.${PHENO}.txt
LIST_IDs=${WORK_DIR}Phenotypes/List_IDs.TERASTROKE.${STUDY}.${PHENO}.txt
Bfile_STEP1=${WORK_DIR}Genotypes/${STUDY}.Genotypes.ForRegenieStep1.${PHENO}

### Variable creation
OUTPUT=Results_Regenie.${STUDY}
PRED_file=${OUTPUT}_Step1.${PHENO}_pred.list

##### Create folders
mkdir -p ${WORK_DIR}Analyses_${STUDY}


########### Run Regenie

cd ${WORK_DIR}Analyses_${STUDY}

mkdir -p ${PHENO}
cd ${PHENO}

### Step 1
$REGENIE_PATH \
  --step 1 \
  --bed $Bfile_STEP1 \
  --keep $LIST_IDs \
  --covarFile $COVAR_file \
  --phenoFile $PHENO_file \
  --bsize 1000 \
  --bt \
  --strict \
  --lowmem \
  --lowmem-prefix ${OUTPUT}_Step1.${PHENO} \
  --out ${OUTPUT}_Step1.${PHENO}

### Step 2
for CHR in `seq 1 22`
do
PGENfiles_STEP2=${WORK_DIR}Genotypes/${STUDY}.chr${CHR}.dose.noDUP.forRegenieStep2
$REGENIE_PATH \
  --step 2 \
  --pgen $PGENfiles_STEP2 \
  --keep $LIST_IDs \
  --covarFile $COVAR_file \
  --phenoFile $PHENO_file \
  --bsize 200 \
  --strict \
  --bt \
  --firth --approx --pThresh 0.01 \
  --pred $PRED_file \
  --af-cc \
  --lowmem \
  --lowmem-prefix ${OUTPUT}_Step2.${PHENO} \
  --out ${OUTPUT}_Step2.chr${CHR}.${PHENO}
  
mv ${OUTPUT}_Step2.chr${CHR}.${PHENO}*.regenie ${OUTPUT}_Step2.chr${CHR}.${PHENO}.regenie 

done

rm ${OUTPUT}_Step1.${PHENO}_1.loco
rm ${OUTPUT}_Step1.${PHENO}_pred.list

mkdir -p ${WORK_DIR}Logs
mv ${OUTPUT}_Step1.${PHENO}.log ${WORK_DIR}Logs
mv ${OUTPUT}_Step2.chr*.${PHENO}.log ${WORK_DIR}Logs

CHR=1
cat ${OUTPUT}_Step2.chr${CHR}.${PHENO}.regenie | head -1 > ${WORK_DIR}Analyses_${STUDY}/${OUTPUT}_Step2.AllCHR.${PHENO}.regenie 
for CHR in `seq 1 22`
do
cat ${OUTPUT}_Step2.chr${CHR}.${PHENO}.regenie | tail -n+2 >> ${WORK_DIR}Analyses_${STUDY}/${OUTPUT}_Step2.AllCHR.${PHENO}.regenie 
done

gzip ${WORK_DIR}Analyses_${STUDY}/${OUTPUT}_Step2.AllCHR.${PHENO}.regenie 

cd ${WORK_DIR}Analyses_${STUDY}
rm -r ${PHENO}

echo '########################################'
echo 'Job finished' $(date --iso-8601=seconds)

############################# 

