# TERASTROKE - GWAS Scripts

**Developed by:** Quentin Le Grand  
**Contact:** quentin.le-grand@u-bordeaux.fr or rainer.malik@med.uni-muenchen.de

## Overview

These scripts are designed for preparation and execution of Genome-Wide Association Studies (GWAS) for stroke phenotypes. The scripts must be run in the predefined order due to dependencies between them.

**Note:** These scripts have been tested on relatively small cohorts (n<1000) but should work for larger sample sizes (may be slower). If your cluster is powerful, you can adapt the SLURM options in `Script_1.Prep_pgen.sh` and `Script_4.Run_Regenie.sh`.

## Prerequisites

### Required Software
- [PLINK 1.9](https://www.cog-genomics.org/plink/)
- [PLINK 2.0](https://www.cog-genomics.org/plink/2.0/)
- [Regenie v3.4.1](https://github.com/rgcgithub/regenie/releases/tag/v3.4.1)
- R (≥3.6.1) with packages: `stringr`, `dplyr`, `data.table`
- GCC (≥5.1)

Place executables in `${WORK_DIR}/Software/` named as `plink`, `plink2`, and `regenie`.

### R Package Installation
```r
R
install.packages("stringr")
install.packages("dplyr")
install.packages("data.table")
q()
```

## Data Preparation

### 1. Phenotype File

Create a tab-delimited phenotype file with missing data coded as "NA":

**Format:**
- **Column 1:** Individual ID (called "ID")
- **Subsequent columns:** Phenotypes named `{ANCESTRY}_{TRAIT}`
  - Cases: `1`
  - Controls: `0`
  - Missing/Alternative subtype cases: `NA`

**Ancestry Codes:**
- `EUR` - European Ancestry
- `AFR` - African Ancestry
- `HIS` - Hispanic Ancestry
- `EAS` - East Asian Ancestry
- `SEAS` - South East Asian Ancestry
- `SAS` - South Asian Ancestry
- `MEA` - Middle Eastern Ancestry

**Trait Codes:**
- `AS` - Any stroke
- `AIS` - Any ischemic stroke
- `CES` - Cardioembolic ischemic stroke
- `LAS` - Large artery ischemic stroke
- `SVS` - Small vessel ischemic stroke
- `ICH` - Intracerebral hemorrhage

**Exclusion criteria:** Remove individuals with history of stroke at baseline (for longitudinal studies) and any other study-specific criteria.

### 2. Covariates File

Create a tab-delimited covariates file with missing data coded as "NA":

**Required columns:**
- Individual ID (called "ID") - first column
- Genetic PCs (named PC1, PC2, PC3, PC4, ...)
- Age (in years)
- Sex (called "SEX", coded 0 for men, 1 for women)
- Optional: Additional covariates (e.g., site for multi-centric studies)

**Note:** For categorical variables with >2 categories (N categories), create N-1 indicator variables coded 0/1.

## Installation
```bash
# Set working directory
WORK_DIR=<PATH_TO_WORKING_DIRECTORY>
cd $WORK_DIR

# Clone this repository or download scripts
git clone https://github.com/TERASTROKE/GWAS_scripts.git
cd GWAS_scripts

# Make scripts executable
chmod +x ./Scripts/*
chmod +x ./Software/*

# Set study name
STUDY=<STUDY_NAME>
```

## Usage

### Step 1: Prepare Genotype Files (pgen format)
```bash
for CHR in `seq 1 22`
do
  VCF_imputed=<PATH_TO_VCF_IMPUTED_FILE.${CHR}.dose.vcf.gz>
  sbatch ./Scripts/Script_1.Prep_pgen.sh $STUDY $WORK_DIR $VCF_imputed $CHR
done

# Check for errors
rm Error_file_Script_1.Prep_pgen.txt
for FILE in `ls JOB_Prep_1-*.out`
do
  echo $FILE >> Error_file_Script_1.Prep_pgen.txt
  cat $FILE | grep -e 'error\|Error\|ERROR\|No such\|No Such\|no such' >> Error_file_Script_1.Prep_pgen.txt
  echo "" >> Error_file_Script_1.Prep_pgen.txt
done
```

### Step 2: Prepare Phenotypes and Covariates
```bash
INPUT_PHENO=<PATH_TO_INPUT_PHENOTYPE_FILE>
INPUT_COVAR=<PATH_TO_INPUT_COVARIATES_FILE>

sbatch ./Scripts/Script_2.Prep_Pheno.sh $STUDY $WORK_DIR $INPUT_PHENO $INPUT_COVAR

# Check for errors
rm Error_file_Script_2.Prep_Pheno.txt
for FILE in `ls JOB_Prep_2.out`
do
  echo $FILE >> Error_file_Script_2.Prep_Pheno.txt
  cat $FILE | grep -e 'error\|Error\|ERROR\|No such\|No Such\|no such' >> Error_file_Script_2.Prep_Pheno.txt
  echo "" >> Error_file_Script_2.Prep_Pheno.txt
done
```

### Step 3: Prepare Genotypes for REGENIE Step 1

Target: ~500k variants (400k works). If >1M variants, uncomment pruning settings in script.
```bash
Plink_BFILE_nonimputed=<PATH_TO_PLINK_BFILES>

LIST_PHENO=`ls ${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.*.txt | sed -e "s#${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.##g" -e "s#.txt##g"`
NB_PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | wc -l`

for i in `seq 1 ${NB_PHENO}`
do
  PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | head -$i | tail -1`
  sbatch ./Scripts/Script_3.Prep_Bfiles.sh $STUDY $WORK_DIR $Plink_BFILE_nonimputed $PHENO
done

# Check number of variants
for i in `seq 1 ${NB_PHENO}`
do
  PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | head -$i | tail -1`
  echo ${PHENO} `cat ${WORK_DIR}Genotypes/${STUDY}.Genotypes.ForRegenieStep1.${PHENO}.bim | wc -l`
done

# Check for errors
rm Error_file_Script_3.Prep_bed.txt
for FILE in `ls JOB_Prep_3-*.out`
do
  echo $FILE >> Error_file_Script_3.Prep_bed.txt
  cat $FILE | grep -e 'error\|Error\|ERROR\|No such\|No Such\|no such' >> Error_file_Script_3.Prep_bed.txt
  echo "" >> Error_file_Script_3.Prep_bed.txt
done
```

### Step 4: Run GWAS Analyses

**Note:** This runs 1 job per analysis. If your cluster cannot manage all GWAS in parallel, split `NB_PHENO` into batches (e.g., 1-50, 51-84).
```bash
cd $WORK_DIR
LIST_PHENO=`ls ${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.*.txt | sed -e "s#${WORK_DIR}Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.${STUDY}.##g" -e "s#.txt##g"`
NB_PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | wc -l`

for i in `seq 1 ${NB_PHENO}`
do
  PHENO=`echo ${LIST_PHENO} | sed 's/ /\n/g' | head -$i | tail -1`
  sbatch ./Scripts/Script_4.Run_Regenie.sh $STUDY $WORK_DIR $PHENO
done

# Check for errors
rm Error_file_Script_4.Run_GWAS.txt
for FILE in `ls JOB_Prep_4-*.out`
do
  echo $FILE >> Error_file_Script_4.Run_GWAS.txt
  cat $FILE | grep -e 'error\|Error\|ERROR\|No such\|No Such\|no such' >> Error_file_Script_4.Run_GWAS.txt
  echo "" >> Error_file_Script_4.Run_GWAS.txt
done
```

### Step 5: Prepare Output for Sharing
```bash
cd $WORK_DIR

# File with imputation scores (tab-delimited: col1=SNP in CHR:POS format hg19, col2=Rsq)
INDEX_RSQ=<PATH_TO_FILE_WITH_SNP_RSQ>
cp ${INDEX_RSQ} ${WORK_DIR}Analyses_${STUDY}

# Organize logs
mkdir -p Logs
mv *.out ./Logs
mv Error_file_*.txt ./Logs

# Zip results
zip ./Analyses_${STUDY}.zip -r ./Analyses_${STUDY}
```

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `Script_1.Prep_pgen.sh` | Convert VCF files to PGEN format for REGENIE Step 2 |
| `Script_2.Prep_Pheno.sh` | Prepare phenotype and covariate files |
| `Script_3.Prep_Bfiles.sh` | Prepare binary PLINK files for REGENIE Step 1 |
| `Script_4.Run_Regenie.sh` | Run REGENIE GWAS analysis (both steps) |
| `Rscript_prep_Phenotypes.R` | R script for phenotype file processing |

## Performance Optimization

For powerful clusters, modify SLURM settings in scripts:
```bash
#SBATCH --cpus-per-task=4
```

And add threading to REGENIE commands:
```bash
--threads 4
```

## Support

For questions or issues, please contact: quentin.le-grand@u-bordeaux.fr or rainer.malik@med.uni-muenchen.de


