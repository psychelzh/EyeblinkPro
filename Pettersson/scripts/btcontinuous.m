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
if ~isempty(sel)
    dis = diff(sel);
    loctrl = find(~(dis < cfg.trialdef.minevent)); %One trial must contain enough events.
    ntrl = length(loctrl);
    trl = nan(ntrl, 3);
    for itrl = 1:ntrl
        trl(itrl, 1) = event(sel(loctrl(itrl))).sample;
        trl(itrl, 2) = event(sel(loctrl(itrl) + 1)).sample;
        trl(itrl, 3) = 0;
    end
else
    error('no trials were defined');
end
