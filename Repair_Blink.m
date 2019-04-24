function Repair_Blink(taskname)
%REPAIR_BLINK Recovers subjects with inverted upper and lower electrodes
%   Make sure Check_Blink is done before run this.
%
%See also Check_Blink
addpath scripts
log_path = 'logs';
data_path = 'EOG';
check_results = readtable(fullfile(log_path, sprintf('check_results_%s.txt', taskname)));
if ismember('Recheck', check_results.Properties.VariableNames)
    rows_to_repair = check_results.Recheck == -1;
else
    rows_to_repair = check_results.Message == -1;
end
load(fullfile(data_path, sprintf('EOG_%s.mat', taskname))) %#ok<LOAD>
EOG = EOG(rows_to_repair); %#ok<NODEF>
for i_repair = 1:length(EOG)
    EOGv_to_repair = EOG(i_repair).EOGv;
    for i_trial = 1:length(EOGv_to_repair.trial)
        EOGv_to_repair.trial{i_trial}(1:2, :) = EOGv_to_repair.trial{i_trial}(2:-1:1, :);
        EOGv_to_repair.trial{i_trial}(3, :) = -EOGv_to_repair.trial{i_trial}(3, :);
    end
    EOG(i_repair).EOGv = EOGv_to_repair;
end
blink_res = calc_blink(EOG);
save(fullfile(data_path, sprintf('EOG_%s_repaired', taskname)), 'EOG', '-v7.3', '-nocompression')
save(fullfile(data_path, sprintf('blink_res_%s_repaired', taskname)), 'blink_res', '-v7.3', '-nocompression')
rmpath scripts
