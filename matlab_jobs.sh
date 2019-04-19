#!/bin/sh
# loop through all the tasks
for task in "FLT" "REST" "RLA" "RLAT" "RLB" "RLBT" "SM" "TEST"
do
    printf "restoredefaultpath\naddpath ~/zhangliang/toolbox/fieldtrip-20190416/\nExtract_EOG('$task');\nexit;" > $task.m
    printf "/opt/software/MATLAB/R2017a/bin/matlab -nodisplay < $task.m" > $task.sh
    qsub -d /brain/guixue/geneproject/EEG/EEG_Gene_Data -N ${task}_EBR $task.sh
    rm $task.m
    rm $task.sh
done
