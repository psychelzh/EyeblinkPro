#!/bin/sh
#PBS -l nodes=1:ppn=12
#PBS -d /brain/guixue/geneproject/EEG/EEG_Gene_Data
#PBS -N CALC_BLINK_TASK
#PBS -q long
#PBS -o logs/CALC_BLINK_TASK_output.txt
#PBS -e logs/CALC_BLINK_TASK_error.txt
/opt/software/MATLAB/R2017a/bin/matlab -nodisplay < calc_blink_TASK.m
