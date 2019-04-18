function tasksetting = get_config(taskname)
%GET_CONFIG Get the configurations of current task
%   Make sure 'config.json' is under the working directory.
config_filename = 'config.json';
if ~exist(config_filename, 'file')
    error('EBR:configFileLoss', ...
        'Could not find file %s!', config_filename);
end
config_bank = jsondecode(fileread(config_filename));
tasksetting = config_bank.default;
tasksetting_update = config_bank.(taskname);
modified_fields = fieldnames(tasksetting_update);
for i_modified_field = 1:length(modified_fields)
    modified_field = modified_fields{i_modified_field};
    tasksetting.(modified_field) = tasksetting_update.(modified_field);
end

