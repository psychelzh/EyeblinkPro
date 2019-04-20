#!/bin/sh
# loop through all the tasks
for task in "FLT" "REST" "RLA" "RLAT" "RLB" "RLBT" "SM" "TEST"
do
    printf "restoredefaultpath\naddpath ~/zhangliang/toolbox/fieldtrip-20190416/\nCalc_Blink('$task');\nexit;" > calc_blink_$task.m
    sed "s/TASK/$task/g" calc_blink_template.sh > calc_blink.sh
    qsub calc_blink.sh
    rm calc_blink.sh
done
