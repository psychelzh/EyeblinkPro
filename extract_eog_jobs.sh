#!/bin/sh
# loop through all the tasks
for task in "FLT" "REST" "RLA" "RLAT" "RLB" "RLBT" "SM" "TEST"
do
    printf "restoredefaultpath\naddpath ~/zhangliang/toolbox/fieldtrip-20190416/\nExtract_EOG('$task');\nexit;" > $task.m
    sed "s/TASK/$task/g" extract_eog_template.sh > extract_eog.sh
    qsub extract_eog.sh
    rm extract_eog.sh
done
