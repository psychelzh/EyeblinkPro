addpath scripts
% set tasks of interest
tasks = {'FLT', 'REST', 'RLA', 'RLAT', 'RLB', 'RLBT', 'RLB', 'RLBT', 'SM', 'TEST'};
for i_task = 1:length(tasks)
    task = tasks{i_task};
    EOG = extract_eog(task);
    save(fullfile('EOG', sprintf('EOG_%s', task)))
end
rmpath scripts
