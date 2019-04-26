#!/bin/sh
# loop through all the tasks
for task in "FLT" "REST" "RLA" "RLAT" "RLB" "RLBT" "SM" "TEST"
do
    printf "restoredefaultpath\nRepair_Blink('$task');\nexit;" > repair_blink_$task.m
    sed "s/TASK/$task/g" repair_blink_template.sh > repair_blink.sh
    qsub repair_blink.sh
    rm repair_blink.sh
done
