#!/usr/bin/env Rscript
options(bitmapType='cairo')
args = commandArgs(trailingOnly=TRUE)
INPUT_PHENO <- args[1]
INPUT_COVAR <- args[2]
WORK_DIRECTORY <- args[3]
REF_PSAM_FILE <- args[4]
STUDY_NAME <- args[5]

library(stringr)
library(dplyr)

####### Import Phenotype data
DATA_PHENO <- read.delim(INPUT_PHENO, header=T, stringsAsFactors=F, sep="\t")
str(DATA_PHENO)
colnames(DATA_PHENO)[1] <- "ID"

# Keep participants with genotype data
ref <- read.table(REF_PSAM_FILE, header=F, sep="\t", stringsAsFactors=F)
DATA_PHENO <- DATA_PHENO[which(DATA_PHENO$ID %in% ref$V1),]
str(DATA_PHENO)

# Remove duplicated IDs
table(duplicated(DATA_PHENO$ID))
if(length(DATA_PHENO$ID[which(duplicated(DATA_PHENO$ID) == T)]) >= 1){
DUP <- DATA_PHENO$ID[which(duplicated(DATA_PHENO$ID) == T)]
DATA_PHENO <- DATA_PHENO[-which(DATA_PHENO$ID %in% DUP),]
}

# List phenotypes
LIST_PHENO <- colnames(DATA_PHENO)[-1]

####### Import Covariates data
DATA_COVAR <- read.delim(paste0(INPUT_COVAR), header=T, stringsAsFactors=F, sep="\t",na.strings="NA")
str(DATA_COVAR)
colnames(DATA_COVAR)[1] <- "ID"

# List covariates
LIST_COVAR <- colnames(DATA_COVAR)[-1]

# Remove duplicated IDs
table(duplicated(DATA_COVAR$ID))
if(length(DATA_COVAR$ID[which(duplicated(DATA_COVAR$ID) == T)]) >= 1){
DUP <- DATA_COVAR$ID[which(duplicated(DATA_COVAR$ID) == T)]
DATA_COVAR <- DATA_COVAR[-which(DATA_COVAR$ID %in% DUP),]
}

####### Merge Phenotypes and Covariates
DATA <- merge(DATA_COVAR, DATA_PHENO, by="ID")
str(DATA)


####### Prepare final files for analyses 
for (PHENO in LIST_PHENO){

### Full sample
DATA_PHENO <- subset(DATA, select = c("ID", PHENO, LIST_COVAR))

# No NA
DATA_PHENO <- DATA_PHENO[complete.cases(DATA_PHENO),]

# if N cases >= 30
N_CASES <- length(DATA_PHENO$ID[which(DATA_PHENO[,PHENO] == 1)])

if(N_CASES >= 30){
# Write final Pheno and Covar files for REGENIE
DATA_PHENO_fin <- subset(DATA_PHENO, select = c("ID", "ID", PHENO))
colnames(DATA_PHENO_fin)[1] <- "FID"
colnames(DATA_PHENO_fin)[2] <- "IID"
write.table(DATA_PHENO_fin, paste0(WORK_DIRECTORY,"Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.",STUDY_NAME,".",PHENO,".txt"), col.names=T, row.names=F, quote=F, sep="\t")

DATA_PHENO_COVAR_fin <- subset(DATA_PHENO, select = c("ID", "ID", LIST_COVAR))
colnames(DATA_PHENO_COVAR_fin)[1] <- "FID"
colnames(DATA_PHENO_COVAR_fin)[2] <- "IID"
write.table(DATA_PHENO_COVAR_fin, paste0(WORK_DIRECTORY,"Phenotypes/COVAR_REGENIE.TERASTROKE.",STUDY_NAME,".",PHENO,".txt"), col.names=T, row.names=F, quote=F, sep="\t")

DATA_PHENO_ID_fin <- subset(DATA_PHENO, select = c("ID", "ID"))
colnames(DATA_PHENO_ID_fin)[1] <- "FID"
colnames(DATA_PHENO_ID_fin)[2] <- "IID"
write.table(DATA_PHENO_ID_fin, paste0(WORK_DIRECTORY,"Phenotypes/List_IDs.TERASTROKE.",STUDY_NAME,".",PHENO,".txt"), col.names=F, row.names=F, quote=F, sep="\t")
}

### Male only
LIST_COVAR_noSex <- LIST_COVAR[-which(LIST_COVAR == "SEX")]

DATA_PHENO_MALE <- DATA_PHENO[which(DATA_PHENO$SEX == 0),]

# if N cases >= 30
N_CASES <- length(DATA_PHENO_MALE$ID[which(DATA_PHENO_MALE[,PHENO] == 1)])

if(N_CASES >= 30){
# Write final Pheno and Covar files for REGENIE
DATA_PHENO_fin <- subset(DATA_PHENO_MALE, select = c("ID", "ID", PHENO))
colnames(DATA_PHENO_fin)[1] <- "FID"
colnames(DATA_PHENO_fin)[2] <- "IID"
write.table(DATA_PHENO_fin, paste0(WORK_DIRECTORY,"Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.",STUDY_NAME,".",PHENO,".MALE_only.txt"), col.names=T, row.names=F, quote=F, sep="\t")

DATA_PHENO_COVAR_fin <- subset(DATA_PHENO_MALE, select = c("ID", "ID", LIST_COVAR_noSex))
colnames(DATA_PHENO_COVAR_fin)[1] <- "FID"
colnames(DATA_PHENO_COVAR_fin)[2] <- "IID"
write.table(DATA_PHENO_COVAR_fin, paste0(WORK_DIRECTORY,"Phenotypes/COVAR_REGENIE.TERASTROKE.",STUDY_NAME,".",PHENO,".MALE_only.txt"), col.names=T, row.names=F, quote=F, sep="\t")

DATA_PHENO_ID_fin <- subset(DATA_PHENO_MALE, select = c("ID", "ID"))
colnames(DATA_PHENO_ID_fin)[1] <- "FID"
colnames(DATA_PHENO_ID_fin)[2] <- "IID"
write.table(DATA_PHENO_ID_fin, paste0(WORK_DIRECTORY,"Phenotypes/List_IDs.TERASTROKE.",STUDY_NAME,".",PHENO,".MALE_only.txt"), col.names=F, row.names=F, quote=F, sep="\t")
}

### Female only
DATA_PHENO_FEMALE <- DATA_PHENO[which(DATA_PHENO$SEX == 1),]

# if N cases >= 30
N_CASES <- length(DATA_PHENO_FEMALE$ID[which(DATA_PHENO_FEMALE[,PHENO] == 1)])

if(N_CASES >= 30){
# Write final Pheno and Covar files for REGENIE
DATA_PHENO_fin <- subset(DATA_PHENO_FEMALE, select = c("ID", "ID", PHENO))
colnames(DATA_PHENO_fin)[1] <- "FID"
colnames(DATA_PHENO_fin)[2] <- "IID"
write.table(DATA_PHENO_fin, paste0(WORK_DIRECTORY,"Phenotypes/PHENO_FILE_REGENIE.TERASTROKE.",STUDY_NAME,".",PHENO,".FEMALE_only.txt"), col.names=T, row.names=F, quote=F, sep="\t")

DATA_PHENO_COVAR_fin <- subset(DATA_PHENO_FEMALE, select = c("ID", "ID", LIST_COVAR_noSex))
colnames(DATA_PHENO_COVAR_fin)[1] <- "FID"
colnames(DATA_PHENO_COVAR_fin)[2] <- "IID"
write.table(DATA_PHENO_COVAR_fin, paste0(WORK_DIRECTORY,"Phenotypes/COVAR_REGENIE.TERASTROKE.",STUDY_NAME,".",PHENO,".FEMALE_only.txt"), col.names=T, row.names=F, quote=F, sep="\t")

DATA_PHENO_ID_fin <- subset(DATA_PHENO_FEMALE, select = c("ID", "ID"))
colnames(DATA_PHENO_ID_fin)[1] <- "FID"
colnames(DATA_PHENO_ID_fin)[2] <- "IID"
write.table(DATA_PHENO_ID_fin, paste0(WORK_DIRECTORY,"Phenotypes/List_IDs.TERASTROKE.",STUDY_NAME,".",PHENO,".FEMALE_only.txt"), col.names=F, row.names=F, quote=F, sep="\t")
}

}

###################
