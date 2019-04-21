function [trl, event] = btcontinuous(cfg)
%BTCONTINUOUS determines trials/segments in the data that are interesting
%for analysis.
%
%The trialdef structure can contain the following specifications
%   cfg.trialdef.eventtype = 'string'
%   cfg.trialdef.eventvalue = row vector with two numeric elements,
%       originally is used to denote the begin and the end of the EEG task.
%   cfg.trialdef.minevent = one numeric scalar, denoting the minimal events
%       one trial should have.
%See also FT_DEFINETRIAL, FT_TRIALFUN_GENERAL

%Check if the trial definition specified.
if ~isfield(cfg, 'trialdef') ...
        || ~isfield(cfg.trialdef, 'eventtype') ...
        || ~isfield(cfg.trialdef, 'eventvalue')
    error('UDF:BTCONTINOUS:No_TrialDef_Specified', ...
        'CFG does not specify trial definition, or does not specify correctly.');
end

% default rejection parameter
if ~isfield(cfg, 'eventformat'),  cfg.eventformat  = []; end
if ~isfield(cfg, 'headerformat'), cfg.headerformat = []; end
if ~isfield(cfg, 'dataformat'),   cfg.dataformat   = []; end

%Read the events.
try
    fprintf('reading the events from ''%s''\n', cfg.headerfile);
    event = ft_read_event(cfg.headerfile, 'headerformat', cfg.headerformat, 'eventformat', cfg.eventformat, 'dataformat', cfg.dataformat);
catch
    % ensure that it has the correct fields, even if it is empty
    event = struct('type', {}, 'value', {}, 'sample', {}, 'offset', {}, 'duration', {});
end

% when start and end are the same, there needs some special treatment
if cfg.trialdef.eventvalue(1) == cfg.trialdef.eventvalue(2)
    % start by selecting all events
    sel = true(1, length(event)); % this should be a row vector
    
    % select all events of the specified type and value
    for i = 1:numel(event)
        sel(i) = sel(i) && ...
            strcmp(event(i).type, cfg.trialdef.eventtype) && ...
            ismember(event(i).value, cfg.trialdef.eventvalue);
    end
    
    % convert from boolean vector into a list of indices
    sel = find(sel);
    
    % construct trial matrix
    trl = [];
    skip_next_sel = false;
    for i_sel = 1:length(sel)
        if skip_next_sel
            skip_next_sel = false;
            continue
        end
        if i_sel == length(sel)
            break
        end
        if sel(i_sel + 1) - sel(i_sel) >= cfg.trialdef.minevent
            trl = [trl; ...
                [event(sel(i_sel)).sample, event(sel(i_sel + 1)).sample, 0]]; %#ok<*AGROW>
            skip_next_sel = true;
        end
    end
else
    % there are two different specified event values: start and end
    sel_phases = repmat(struct(), 1, 2);
    for i_value = 1:2
        % match all the start
        sel = true(1, length(event));
        for i = 1:numel(event)
            sel(i) = sel(i) && ...
                strcmp(event(i).type, cfg.trialdef.eventtype) && ...
                event(i).value == cfg.trialdef.eventvalue(i_value);
        end
        sel_phases(i_value).sel = find(sel);
    end
    trl = [];
    % the first element of sel_phases is start, and the second end
    for i_start = 1:length(sel_phases(1).sel)
        sel_start = sel_phases(1).sel(i_start);
        if i_start == length(sel_phases(1).sel)
            sel_end = sel_phases(2).sel(...
                sel_phases(2).sel > sel_phases(1).sel(i_start));
        else
            sel_end = sel_phases(2).sel(...
                sel_phases(2).sel > sel_phases(1).sel(i_start) & ...
                sel_phases(2).sel < sel_phases(1).sel(i_start + 1));
        end
        if length(sel_end) == 1 && sel_end - sel_start >= cfg.trialdef.minevent
            trl = [trl; ...
                [event(sel_start).sample, event(sel_end).sample, 0]];
        end
    end
end
