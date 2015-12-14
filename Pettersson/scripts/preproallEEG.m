function outEOG = preproallEEG(tasksettingM)
%This function is used to do some prepocessing for all the EEG data stored
%in .bdf (Biosemi) files using FieldTrip. EOG data is extracted and stored
%in the generated file EOG.mat as variable EOGv, which is a structure
%stored 4 pieces of information in its 4 fields:
%   1. Subject ID;
%   2. Sampling rate; (When prepocessing, resampling is done, so this is
%   not the original sampling rate.)
%   3. Epochs of EEG data (EOG only);
%   4. Time information of each epoch.
%
%TRIALPAR has these fields at most:
%   trigger (numeric)
%   continuous ('yes' or 'no')
%   trialprepost (a row vector with two elements)
%   channel (specify all of the channels selected for analysis, default {'EXG3' 'EXG4'})
%   starttime (specify if all the data in each trial will be used or not)
%   
%
%See also FT_DEFINETRIAL, FT_TRIALFUN_GENERAL, FT_PREPROCESSING

%By Zhang, Liang, 2015/11/4. E-mail:psychelzh@gmail.com.
%Change log:
%   Add two field for trialpar to specify channels and filtering or not 
%   used in the data analysis. Zhang, Liang, 2015/11/17.
%   Let the 3rd parameter wrapped into trialpar. Zhang, Liang, 2015/11/17.

%Get the setting of each task.
eval(tasksettingM); %The tasksetting variable will be created.
trialpar = tasksetting.trialpar;

%Check input trialpar.
if ~isfield(trialpar, 'trigger') ...
        || isempty(trialpar.trigger)
    error('UDF:PREPRO:NO_TRIGGER_SPECIFIED', ...
        'Input trial definition must have at least one specific trigger value.');
end
%Check whether read continuous data or not.
if ~isfield(trialpar, 'continuous')
    if isfield(trialpar, 'trialprepost') ...
            && ~isempty(trialpar.trialprepost) ...
            && ~any(isnan(trialpar.trialprepost))
        trialpar.continuous = 'no';
    else
        trialpar.continuous = 'yes';
    end
end

%Check configuration.
if strcmpi(trialpar.continuous, 'yes')
    if length(trialpar.trigger) ~= 2
        error('Continuous data will be read, and the number of triggers of the trial begin and end are not right.');
    end
else
    if ~isfield(trialpar, 'trialprepost') ...
            || isempty(trialpar.trialprepost) ...
            || any(isnan(trialpar.trialprepost))
        pre  = input('You used epoch analysis, how long is the trial before the stimulus (Unit:sec)? Please input a number:\n');
        post = input('And how long is the trial after the stimulus (Unit:sec)? Please input a number:\n');
        trialpar.trialprepost = [pre, post]; %User input its trial parameters.
    end
end

%Check channel input.
if ~isfield(trialpar, 'channel'), trialpar.channel = {'EXG3' 'EXG4'}; end
%Check starttime.
if ~isfield(trialpar, 'starttime'), trialpar.starttime = 0; end

%Possible channel of interest and output fields.
coi       = {...
    'EXG3', 'EXG4'; ... %For vloc.
    'EXG5', 'EXG6'; ... %For hloc.
    };
locFields = {'vloc', 'hloc'};
outFields = {'EOGv', 'EOGh'};

%Access to filenames.
datapath = tasksetting.datapath;
dataname = [tasksetting.dataprefix, '*.bdf'];
filesInfo = dir([datapath, filesep, dataname]);
filesName = {filesInfo.name};
subid = str2double(regexp(filesName, '\d{4}', 'match', 'once'));
totalfilenum = length(filesName);
fprintf('found %d files.\n', totalfilenum);
%Give information of rate of progress.
hwb = waitbar(0, '0', ...
    'Name', sprintf('Processing %d files', totalfilenum), ...
    'CreateCancelBtn', ...
    'setappdata(gcbf, ''canceling'', 1)');
% totalfilenum = 4;
for ifile = 1:totalfilenum
    %Check cancel information.
    if getappdata(hwb, 'canceling')
        break
    end
    fprintf('now preprocessing %dth file...\n', ifile);
    rop = ifile / totalfilenum;
    if rop < 1
        waitbar(rop, hwb, sprintf('Completed %d%%...', floor(rop * 100)));
    else
        waitbar(rop, hwb, 'All comleted soon.');
    end
    EOG(ifile).pid     = subid(ifile); %#ok<*AGROW>
    initialVars = who;
    try
        %Configuration for trial definition.
        cfg                     = [];
        cfg.dataset             = [datapath, '\', filesName{ifile}];
        cfg.channel             = trialpar.channel;
        cfg.trialdef.eventtype  = 'STATUS';
        cfg.trialdef.eventvalue = mod(trialpar.trigger, 16) * 16 + 15;
        if strcmpi(trialpar.continuous, 'yes')
            cfg.trialfun             = 'btcontinuous'; %Use a user defined trial function, see help BTCONTINUOUS.
            cfg.trialdef.minevent    = tasksetting.trialpar.minevent;
        else
            cfg.trialdef.prestim     = trialpar.trialprepost(1);
            cfg.trialdef.poststim    = trialpar.trialprepost(2);
        end
        cfg                     = ft_definetrial(cfg);
        %Configuration for filtering.
        cfg.bpfilter            = 'yes';
        cfg.bpfreq              = [0.5, 20];
        cfg.bpfilttype          = 'fir';
        dataPrepro = ft_preprocessing(cfg);
        %Configuration for resampling.
        cfg                     = [];
        cfg.resamplefs          = 256;
        cfg.detrend             = 'no';
        dataPrepro              = ft_resampledata(cfg, dataPrepro);
        %From the start time to the start point.
        startpoint = floor(dataPrepro.fsample * trialpar.starttime) + 1;
        %Calculate the vertical EOG data and/or horizontal EOG data.
        EOG(ifile).fsample = dataPrepro.fsample;
        for i = 1:size(coi, 1)
            EOGloc.(locFields{i}) = find(ismember(trialpar.channel, coi(i, :)));
            if ~isempty(EOGloc.(locFields{i}))
                EOG(ifile).(outFields{i}).trial   = cell(size(dataPrepro.trial)); 
                EOG(ifile).(outFields{i}).time    = cell(size(dataPrepro.trial));
                for triali = 1:length(dataPrepro.trial)
                    EOG(ifile).(outFields{i}).trial{triali} = [...
                        dataPrepro.trial{triali}(EOGloc.(locFields{i})(1), startpoint:end); ...
                        dataPrepro.trial{triali}(EOGloc.(locFields{i})(2), startpoint:end); ...
                        dataPrepro.trial{triali}(EOGloc.(locFields{i})(1), startpoint:end) - ...
                        dataPrepro.trial{triali}(EOGloc.(locFields{i})(2), startpoint:end)];
                    EOG(ifile).(outFields{i}).time{triali}  = dataPrepro.time{triali}(startpoint:end);
                end
            end
        end
    catch
        fid = fopen('errlog.log', 'w');
        fprintf(fid, 'Error found while reading file %s.\n', [datapath, '\', filesName{ifile}]);
        if exist('dataPrepro', 'var') 
            EOG(ifile).pid     = subid(ifile);
            EOG(ifile).fsample = dataPrepro.fsample;
            for i = 1:size(coi, 1)
                EOGloc.(locFields{i}) = find(ismember(trialpar.channel, coi(i, :)));
                if ~isempty(EOGloc.(locFields{i}))
                    EOG(ifile).(outFields{i}).trial   = {};
                    EOG(ifile).(outFields{i}).time    = {};
                end
            end
        end
        fclose(fid);
    end
    clearvars('-except', initialVars{:});
end
delete(hwb)
%Save data.
if exist('EOG', 'var')
    save_data_path = tasksetting.outpath;
    save_data_name = [tasksetting.outdataprefix, '_', datestr(now, 'mm-dd-HH-MM')];
    if ~exist(save_data_path, 'dir')
        mkdir(save_data_path);
    end
    save([save_data_path, filesep, save_data_name], 'EOG');
    fprintf('Save done!\nEOG data saved to folder %s as %s.mat.\n', save_data_path, save_data_name);
    if nargout > 0, outEOG = EOG; end
else
    if nargout > 0, outEOG = struct; end
end
