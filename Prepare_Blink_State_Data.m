% Prepare dataset for future analysis in R language
%
% This script is used to transform matlab's complex data structure to an
% easy to read tabular data and output it to a tsv format file.
function Prepare_Blink_State_Data(taskname)
addpath scripts
% merge EOG data and calculated blink results
data_path = 'EOG';
% get the trigger mapping of value and name
tasksetting = get_config(taskname);
trigger_map_config = struct2table(tasksetting.triggermap);
trigger_map_table = stack(trigger_map_config, 1:width(trigger_map_config), ...
    'IndexVariableName', 'name', 'NewDataVariableName', 'key');
trigger_map = containers.Map(mod(trigger_map_table.key, 16) * 16 + 15, ...
    cellstr(trigger_map_table.name));
load(fullfile(data_path, sprintf('blink_res_%s', taskname))) %#ok<*LOAD>
load(fullfile(data_path, sprintf('EOG_%s', taskname)))
num_subj = height(blink_res);
for i_subj = 1:num_subj
    event_subj = EOG(i_subj).event;
    stat_subj = blink_res.stat{i_subj};
    EOGv_subj = EOG(i_subj).EOGv;
    if isempty(event_subj)
        continue
    end
    % map event value to real event name
    event_subj.sample = [];
    event_subj.name = strings(height(event_subj), 1);
    event_subj_has_name = isKey(trigger_map, num2cell(event_subj.value));
    event_subj.name(event_subj_has_name) = ...
        values(trigger_map, num2cell(event_subj.value(event_subj_has_name)));
    % blink related events
    event_blink = table;
    blink_fields = {'LB', 'blinkpeak', 'RB'};
    blink_event_names = string(strcat('blink_', {'start', 'peak', 'end'}));
    for i_trl = 1:length(stat_subj)
        event_blink_trial = table;
        for i_blk_fld = 1:length(blink_fields)
            blink_field = blink_fields{i_blk_fld};
            blink_event_name = blink_event_names(i_blk_fld);
            event_blink_field = table( ...
                repmat({'BLINK'}, length(stat_subj(i_trl).(blink_field)), 1), ...
                EOGv_subj.trial{i_trl}(3, stat_subj(i_trl).(blink_field))', ...
                repmat(i_trl, length(stat_subj(i_trl).(blink_field)), 1), ...
                EOGv_subj.time{i_trl}(stat_subj(i_trl).(blink_field))', ...
                repmat(blink_event_name, length(stat_subj(i_trl).(blink_field)), 1), ...
                'VariableNames', {'type', 'value', 'trl', 'time', 'name'});
            event_blink_trial = cat(1, event_blink_trial, event_blink_field);
        end
        event_blink = cat(1, event_blink, event_blink_trial);
    end
    event_subj = cat(1, event_subj, event_blink);
    event_subj = sortrows(event_subj, {'trl', 'time'});
    % add trial id to events
    event_subj.trial = nan(height(event_subj), 1);
    trial_id = 0;
    is_in_trial = false;
    for i_event = 1:height(event_subj)
        name_this_event = event_subj.name(i_event);
        if startsWith(name_this_event, 'stim')
            if trial_id == 0
                trial_id = trial_id + 1;
            else
                if ~isempty(tasksetting.trialdur)
                    trial_id = trial_id + ...
                        round((event_subj.time(i_event) - time_last_stim) / ...
                        tasksetting.trialdur);
                else
                    trial_id = trial_id + 1;
                end
            end
            time_last_stim = event_subj.time(i_event);
            is_in_trial = true;
        end
        if is_in_trial
            event_subj.trial(i_event) = trial_id;
        end
        if startsWith(name_this_event, 'resp')
            is_in_trial = false;
        end
        if startsWith(name_this_event, 'start')
            trial_id = 0;
        end
    end
    event_subj.pid = repmat(blink_res.pid(i_subj), height(event_subj), 1);
    event_subj.task = repmat({taskname}, height(event_subj), 1);
    event_subj = event_subj(:, {'pid', 'task', 'trl', 'trial', 'type', 'name', 'value', 'time'});
    writetable(event_subj, fullfile(data_path, 'events', sprintf('event_%s_sub%d.txt', taskname, blink_res.pid(i_subj))), 'Delimiter', '\t')
end
rmpath scripts
