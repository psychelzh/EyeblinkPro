function EOG = extract_eog(taskname)
%This function is used to do some prepocessing for all the EEG data stored
%in .bdf (Biosemi) files using FieldTrip. EOG data is extracted and stored
%in the generated file as variable EOG, which is a structure with five
%fields:
%   1. Subject ID;
%   2. Sampling rate; (When prepocessing, resampling is done, so this is
%   not the original sampling rate.)
%   3. Event: all the events in each trial
%   4. EOGv: vertical EOG (containing time info)
%   5. EOGh: horizontal EOG (containing time info)
%
%See also FT_DEFINETRIAL, FT_TRIALFUN_GENERAL, FT_PREPROCESSING

% get the configurations of this task
tasksetting = get_config(taskname);

% check configuration of `trigger`, which is required
if isempty(tasksetting.trigger)
    error('EBR:EXTRACT_EOG:NO_TRIGGER_SPECIFIED', ...
        'Input trial definition must have at least one specific trigger value.');
end

% there needs two triggers specified
if length(tasksetting.trigger) ~= 2
    error('Continuous data will be read, and the number of triggers of the trial begin and end are not right.');
end

%Possible channel of interest and output fields.
coi       = {...
    'EXG3', 'EXG4'; ... %For vloc.
    'EXG5', 'EXG6'; ... %For hloc.
    };
locFields = {'vloc', 'hloc'};
outFields = {'EOGv', 'EOGh'};

% preallocate results as an empty structure
EOG = struct;

% iterate file by file
data_files = dir(fullfile(tasksetting.datapath, ...
    sprintf('%s*.bdf', tasksetting.dataprefix)));
% make sure the 'datasuffix' is correct
data_files = data_files(...
    ~cellfun(@isempty, regexp({data_files.name}, ...
    sprintf('\\d+%s\\.', tasksetting.datasuffix), ...
    'start', 'once')));
num_data_files = length(data_files);
fprintf('found %d files.\n', num_data_files);
for i_file = 1:num_data_files
    fprintf('now preprocessing %dth file...\n', i_file);
    data_file_name = data_files(i_file).name;
    EOG(i_file).pid = str2double(regexp(data_file_name, '\d+', 'match', 'once')); %#ok<*AGROW>
    initialVars = who;
    try
        % define trials of EEG data
        cfg                     = [];
        cfg.dataset             = fullfile(tasksetting.datapath, data_file_name);
        cfg.channel             = tasksetting.channel;
        cfg.trialdef.eventtype  = 'STATUS';
        cfg.trialdef.eventvalue = mod(tasksetting.trigger, 16) * 16 + 15;
        cfg.trialfun             = 'btcontinuous'; %Use a user defined trial function, see help BTCONTINUOUS.
        cfg.trialdef.minevent    = tasksetting.minevent;
        cfg                     = ft_definetrial(cfg);
        % use band pass filtering to remove artifacts
        cfg.bpfilter            = 'yes';
        cfg.bpfreq              = [0.5, 20];
        cfg.bpfilttype          = 'fir';
        data_prepro = ft_preprocessing(cfg);
        % add time and trial info to event
        trl = data_prepro.cfg.trl;
        trl_real = trl(:, 1:2) - trl(:, 3);
        event = data_prepro.cfg.event;
        event(cellfun(@isempty, {event.value})) = [];
        event = struct2table(event);
        event.offset = [];
        event.duration = [];
        event.trl = nan(height(event), 1);
        event.time = nan(height(event), 1);
        for i_trl = 1:size(trl_real, 1)
            rows_this_trl = event.sample >= trl_real(i_trl, 1) & ...
                event.sample <= trl_real(i_trl, 2);
            event.trl(rows_this_trl) = i_trl;
            event.time(rows_this_trl) = ...
                data_prepro.time{i_trl}(event.sample(rows_this_trl) - ...
                trl_real(i_trl, 1) + 1);
        end
        % resample dataset to reduce dataset size
        cfg                     = [];
        cfg.resamplefs          = 256;
        cfg.detrend             = 'no';
        data_prepro             = ft_resampledata(cfg, data_prepro);
        % store sample rate and event (with time and trial info)
        EOG(i_file).fsample = data_prepro.fsample;
        EOG(i_file).event = event;
        %Calculate the vertical EOG data and/or horizontal EOG data.
        for i_type = 1:size(coi, 1)
            EOGloc.(locFields{i_type}) = find(ismember(tasksetting.channel, coi(i_type, :)));
            if ~isempty(EOGloc.(locFields{i_type}))
                EOG(i_file).(outFields{i_type}).trial = cell(size(data_prepro.trial));
                for i_trial = 1:length(data_prepro.trial)
                    EOG(i_file).(outFields{i_type}).trial{i_trial} = [...
                        data_prepro.trial{i_trial}(EOGloc.(locFields{i_type})(1), :); ...
                        data_prepro.trial{i_trial}(EOGloc.(locFields{i_type})(2), :); ...
                        data_prepro.trial{i_trial}(EOGloc.(locFields{i_type})(1), :) - ...
                        data_prepro.trial{i_trial}(EOGloc.(locFields{i_type})(2), :)];
                    EOG(i_file).(outFields{i_type}).time{i_trial}  = data_prepro.time{i_trial};
                end
            end
        end
    catch
        fid = fopen(fullfile('logs', 'errlog.log'), 'a');
        fprintf(fid, ...
            '[%s] Error: preprocessing file %s not succeeded!\n', ...
            datestr(now), fullfile(tasksetting.datapath, data_file_name));
        fclose(fid);
    end
    clearvars('-except', initialVars{:});
end
