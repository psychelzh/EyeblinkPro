#!/bin/sh
#PBS -l nodes=1:ppn=12
#PBS -d /brain/guixue/geneproject/EEG/EEG_Gene_Data
#PBS -N TASK_EBR
#PBS -q long
#PBS -o logs/TASK_output.txt
#PBS -e logs/TASK_error.txt
/opt/software/MATLAB/R2017a/bin/matlab -nodisplay < TASK.m
