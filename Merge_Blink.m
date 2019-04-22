% This script is used to merge all the blink results from 'EOG' folder.
% The minimal version of MATLAB to run this script should be R2018a
%
% All rights are reserved. 2019 (c) Liang Zhang <psychelzh@outlook.com>
data_path = 'EOG';
data_files = dir(fullfile(data_path, 'blink_res_*.mat'));
blink_res = [];
for i_file = 1:length(data_files)
    data_file_name = data_files(i_file).name;
    taskname = regexp(data_file_name, '(?<=blink_res_)\w+', 'match', 'once');
    data_file_content = load(fullfile(data_path, data_file_name));
    blink_res_single = data_file_content.blink_res;
    blink_res_single = addvars(blink_res_single, ...
        repmat(string(taskname), height(blink_res_single), 1), ...
        'After', 1, 'NewVariableNames', 'task_name');
    blink_res = cat(1, blink_res, blink_res_single);
end
save(fullfile(data_path, 'blink_res'), 'blink_res')
EBR = unstack(blink_res(:, {'pid', 'task_name', 'rate_blink'}), 'rate_blink', 'task_name');
writetable(EBR, fullfile(data_path, 'EBR.txt'), 'Delimiter', '\t')
