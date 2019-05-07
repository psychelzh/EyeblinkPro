#!/bin/sh
#PBS -l nodes=1:ppn=12
#PBS -d /brain/guixue/geneproject/EEG/EEG_Gene_Data
#PBS -N REPAIR_BLINK_TASK
#PBS -q long
#PBS -o logs/REPAIR_BLINK_TASK_output.txt
#PBS -e logs/REPAIR_BLINK_TASK_error.txt
/opt/software/MATLAB/R2017a/bin/matlab -nodisplay < repair_blink_TASK.m
