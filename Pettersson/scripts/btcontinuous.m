function [trl, event] = btcontinuous(cfg)
%BTCONTINUOUS determines trials/segments in the data that are interesting
%for analysis.
%
%The trialdef structure can contain the following specifications
%   cfg.trialdef.eventtype = 'string'
%   cfg.trialdef.eventvalue = row vector with two numeric elements,
%       originally is used to denote the begin and the end of the EEG task.
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

% start by selecting all events
sel = true(1, length(event)); % this should be a row vector

% select all events of the specified type
for i=1:numel(event)
    sel(i) = sel(i) && strcmp(event(i).type, cfg.trialdef.eventtype);
end

% select all events with the specified value
for i=1:numel(event)
    sel(i) = sel(i) && ismember(event(i).value, cfg.trialdef.eventvalue);
end

% convert from boolean vector into a list of indices
sel = find(sel);

%Generate the trl matrix.
if length(sel) == 2
    trl(1) = event(sel(1)).sample;
    trl(2) = event(sel(2)).sample;
    trl(3) = 0;
else
    error('no trials were defined');
end