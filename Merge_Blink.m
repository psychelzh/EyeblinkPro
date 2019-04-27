% This script is used to merge all the blink results from 'EOG' folder.
% The minimal version of MATLAB to run this script should be R2018a
%
% All rights are reserved. 2019 (c) Liang Zhang <psychelzh@outlook.com>

data_path = 'EOG';
log_path = 'logs';
tasknames = {'FLT', 'REST', 'RLA', 'RLAT', 'RLB', 'RLBT', 'SM', 'TEST'};
blink_res = cell(length(tasknames), 1);
for i_task = 1:length(tasknames)
    taskname = tasknames{i_task};
    data_suffix = {'', '_repaired'};
    blink_res_task = cell(length(data_suffix), 1);
    for i_suffix = 1:length(data_suffix)
        blink_res_raw = load(fullfile(data_path, ...
            sprintf('blink_res_%s%s', taskname, data_suffix{i_suffix})));
        check_res = readtable(fullfile(log_path, ...
            sprintf('check_results_%s%s.txt', taskname, data_suffix{i_suffix})));
        blink_res_finally = blink_res_raw.blink_res;
        if ismember('Recheck', check_res.Properties.VariableNames)
            blink_res_finally(ismember(check_res.Recheck, -2:0), :) = [];
        else
            blink_res_finally(ismember(check_res.Message, -2:0), :) = [];
        end
        blink_res_task{i_suffix} = blink_res_finally;
    end
    blink_res_task = cat(1, blink_res_task{:});
    blink_res_task = addvars(blink_res_task, ...
        repmat({taskname}, height(blink_res_task), 1), ...
        'NewVariableNames', 'task');
    blink_res_task = blink_res_task(:, {'task', 'pid', 'rate_blink'});
    blink_res{i_task} = blink_res_task;
end
blink_res = unstack(cat(1, blink_res{:}), "rate_blink", "task");
writetable(blink_res, fullfile(log_path, 'blink_res.xlsx'))
