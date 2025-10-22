####################################################
#   TERASTROKE - Script for preparation and GWAS   #
####################################################


#### The scripts are designed to be run in the predefined order (dependency between the scripts)
#### Please make sure to strictly follow this readme

##### The scripts used in these readme worked for a relatively small cohort (n<1000). It should also work for larger sample size but a bit slower.
##### If your cluster is powerful, feel free to adapt the slurm options in the Script_1.Prep_pgen.sh & Script_4.Run_Regenie.sh (e.g. with :
#SBATCH --cpus-per-task=4
#### And in the regenie commands to use multi-threading options add: --threads 4 

###### First, create a phenotype file with all phenotypes available in your cohort (tab-delimited and missing data coded as "NA"):
## per trait to be analyzed 
## per ancestry
## after removing all individuals with exclusion criteria (History of stroke at baseline (for longitudinal cohort studies), any other relevant study-specific criteria)
## with the following columns:
# 		Individual ID (called "ID"), in first column
# 		Phenotypes called "{ANCESTRY}_{TRAIT}": 1 = case, 2 = control (for stroke subtypes, please code the cases for alternative subtypes as "NA" to avoid including them in the control group)
## ANCESTRY:
# 		"EUR"  : European Ancestry
# 		"AFR"  : African Ancestry
# 		"HIS"  : Hispanic Ancestry 
# 		"EAS"  : East Asian ancestry
# 		"SEAS" : South East Asian ancestry 
# 		"SAS"  : South Asian ancestry 
# 		"MEA"  : Middle Eastern ancestry
## TRAIT:
# 		"AS"  : Any stroke
# 		"AIS" : Any ischemic stroke
# 		"CES" : Cardioembolic ischemic stroke
# 		"LAS" : Large artery ischemic stroke 
# 		"SVS" : Small vessel ischemic stroke
# 		"ICH" : Intracerebral hemorrhage

###### Then, prepare a dataset for the full sample with the following covariates (tab-delimited and missing data coded as "NA") :
### 		Individual ID (called "ID"), in first column
### 		Genetic PCs for your sample (named PC1, PC2, PC3, PC4,...)
###			Age (in years), 
### 		Sex (called "SEX", coded 0 for men, 1 for women), 
###			+/- other covariates (e.g. the site for multi-centric studies)
###	Note: for categorical variables with more than 2 categories (N categories), please create N-1 indicator variable coded 0/1


###################
##### Scripts #####
###################

###
### NOTE: the parts between < > (e.g. <EXAMPLE>) must be updated with the corresponding information for your analysis
###

##### Run the scripts

# Change working directory to be where you want to write the files 
#(unzip the zip files we provided, it will create the "Scripts" and "Software" folders in this directory)
# Directory to use for all data preparation and analyses
WORK_DIR=<PATH_TO_WORKING_DIRECTORY>

cd $WORK_DIR
unzip ./Files_TERASTROKE.zip
mv ./Files_TERASTROKE/* .
rm -r ./Files_TERASTROKE/
chmod +x ./Scripts/*
chmod +x ./Software/*

# If the versions provided for Plink and Regenie are not working on your system, please download the correct one here:
# https://www.cog-genomics.org/plink/
# https://www.cog-genomics.org/plink/2.0/
# https://github.com/rgcgithub/regenie/releases/tag/v3.4.1
# Please make sure to put the executables in the folder ${WORK_DIR}/Software/ and name them "plink", "plink2" and "regenie"



# Study Name
STUDY=<STUDY>

#################### Preparation of genotypes
###### Prepare genotypes pgen
for CHR in `seq 1 22`
do
### VCF for imputed genotypes and replace the chr number by ${CHR} 
VCF_imputed=<PATH_TO_VCF_IMPUTED_FILE.${CHR}.dose.vcf.gz>
# Run script
sbatch ./Scripts/Script_1.Prep_pgen.sh $STUDY $WORK_DIR $VCF_imputed $CHR
done

#### Check errors in logs
rm Error_file_Script_1.Prep_pgen.txt
for FILE in `ls JOB_Prep_1-*.out`
do
echo $FILE >> Error_file_Script_1.Prep_pgen.txt
cat $FILE | grep -e 'error\|Error\|ERROR\|No such\|No Such\|no such' >> Error_file_Script_1.Prep_pgen.txt
echo "" >> Error_file_Script_1.Prep_pgen.txt
done


### Load R after installing the required packages
module load R/3.6.1
###### to run the first time :
R
install.packages("stringr")
install.packages("dplyr")
install.packages("data.table")
q()
n
#####

### Load GCC version >= 5.1
gcc --version
# if version <5.1, please update


#################### Prepare phenotypes
# Phenotype files (tab-delimited and missing data coded as "NA")
INPUT_PHENO=<PATH_TO_INPUT_PHENOTYPE_FILE>

# Covariates file (tab-delimited and missing data coded as "NA")
INPUT_COVAR=<PATH_TO_INPUT_COVARIATES_FILE>

# Run script
sbatch ./Scripts/Script_2.Prep_Pheno.sh $STUDY $WORK_DIR $INPUT_PHENO $INPUT_COVAR

#### Check errors in logs
rm Error_file_Script_2.Prep_Pheno.txt
for FILE in `ls JOB_Prep_2.out`
do
echo $FILE >> Error_file_Script_2.Prep_Pheno.txt
cat $FILE | grep -e 'error\|Error\|ERROR\|No such\|No Such\|no such' >> Error_file_Script_2.Prep_Pheno.txt
echo "" >> Error_file_Script_2.Prep_Pheno.txt
done

#################### Preparation of genotypes - REGENIE Step 1
###### Prepare genotypes bfile to have ~500k (400k works) variants in Regenie step1 
# Plink binary files for non imputed QCed genotypes or imputed with Rsq >0.95 (without .bed/.bim/.fam)
# If too many variants are present (>1M) with the initial settings, please uncomment pruning settings (lines 48-61), 
# please change the pruning parameters if needed (e.g. --indep-pairwise 1000 100 0.5)
Plink_BFILE_nonimputed=<PATH_TO_PLINK_BFILES>

LIST_PHENO=`ls ${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.*.txt | sed -e "s#${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.##g" -e "s#.txt##g"`
NB_PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | wc -l`
for i in `seq 1 ${NB_PHENO}`
do
PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | head -$i | tail -1`
# Run script
sbatch ./Scripts/Script_3.Prep_Bfiles.sh $STUDY $WORK_DIR $Plink_BFILE_nonimputed $PHENO
done

#### Check number of variants for Regenie Step 1 
LIST_PHENO=`ls ${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.*.txt | sed -e "s#${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.##g" -e "s#.txt##g"`
NB_PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | wc -l`
for i in `seq 1 ${NB_PHENO}`
do
PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | head -$i | tail -1`
echo ${PHENO} `cat ${WORK_DIR}Genotypes/${STUDY}.Genotypes.ForRegenieStep1.${PHENO}.bim | wc -l`
done

#### Check errors in logs
rm Error_file_Script_3.Prep_bed.txt
for FILE in `ls JOB_Prep_3-*.out`
do
echo $FILE >> Error_file_Script_3.Prep_bed.txt
cat $FILE | grep -e 'error\|Error\|ERROR\|No such\|No Such\|no such' >> Error_file_Script_3.Prep_bed.txt
echo "" >> Error_file_Script_3.Prep_bed.txt
done

################## Run analyses
##### Will run 1 job per analysis.
##### If your cluster cannot manage the full number of GWAS in parallel, cut NB_PHENO into several parts (e.g. 1-50, 50-84)
cd $WORK_DIR
LIST_PHENO=`ls ${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.*.txt | sed -e "s#${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.##g" -e "s#.txt##g"`
NB_PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | wc -l`
for i in `seq 1 ${NB_PHENO}`
do
PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | head -$i | tail -1`
# Run script
sbatch ./Scripts/Script_4.Run_Regenie.sh $STUDY $WORK_DIR $PHENO
done

#### Check errors in logs
rm Error_file_Script_4.Run_GWAS.txt
for FILE in `ls JOB_Prep_4-*.out`
do
echo $FILE >> Error_file_Script_4.Run_GWAS.txt
cat $FILE | grep -e 'error\|Error\|ERROR\|No such\|No Such\|no such' >> Error_file_Script_4.Run_GWAS.txt
echo "" >> Error_file_Script_4.Run_GWAS.txt
done

################## Prepare Clean output
cd $WORK_DIR
### File with Imputation scores (col1=SNP in CHR:POS format hg19 and col2=Rsq) - tab delimited
INDEX_RSQ=<PATH_TO_FILE_WITH_SNP_RSQ>
cp ${INDEX_RSQ} ${WORK_DIR}Analyses_${STUDY}
################ Zip the results and prepare file to share
mkdir -p Logs
mv *.out ./Logs
mv Error_file_*.txt ./Logs

zip ./Analyses_${STUDY}.zip -r ./Analyses_${STUDY}

########################################
