function Check_Blink(taskname, varargin)
%CHECK_BLINK Checks the fitness of data subject by subject
%   CHECK_BLINK(TASKNAME) checks blink detection results for the test with
%   name specified with TASKNAME with a normal procedure.
%
%   CHECK_BLINK(TASKNAME, 'Param1', val1, ...) enables you to specify some
%   optional parameter name/value pairs to do more checking. Parameters
%   are:
%
%       'Recheck' -- a logical scalar or double vector with -2, -1, 0, 1
%       values. It defaults to false, indicating this is the first check
%       for all the subjects. After checking, the checking results are
%       stored in the log with variable name of 'Message'. See the
%       following what does each message mean. When specified as true, it
%       means that this is a recheck and all subjects will be included.
%       When specified as one or more values from -2, -1, 0, 1, only
%       subjects whose first check results are the same as you specified
%       will be included. Anyway, after rechecking, the checking results
%       log will be added one variable with name 'Recheck'.
%
%       'SubjectList' -- a vector containing subject identifiers of
%       interest.
%
%       'Start' -- a positive integer indicating which subject to start.
%
%       'Glance' -- logical scalar indicates if this is just a "glance" of
%       the result. If true, there won't be a dialogue to ask for checking
%       results, so that there is no results recorded. It defaults to
%       false.
%
%       'Repaired' -- logical scalar indicates if this is to check the
%       blink detection after EOG data is repaired. It defaults to false.
%       When set as true, it will read dataset with suffix "repaired".
%
%   Note 1:
%       The output checking result contains a variable 'Message', which
%       codes the checking results in following way:
%           -2 -- 'later examination needed',
%           -1 -- 'upper and lower is inverted',
%            0 -- 'not valid/bad fitness', and
%            1 -- 'valid and accepted'.
%
%See also eyeblinkplot

%By Zhang, 2/28/2016.

% utilies functions are under this directory
addpath scripts

% parse input
p = inputParser;
p.addRequired('TaskName', ...
    @(x) validateattributes(x, {'char'}, {'scalartext', 'nonempty'}));
p.addParameter('Recheck', false, ...
    @(x) (all(ismember(x, -2:1)) && ~islogical(x)) || (isscalar(x) && islogical(x)));
p.addParameter('SubjectList', [], ...
    @(x) validateattributes(x, {'numeric'}, {'positive', 'integer'}));
p.addParameter('Start', [], ...
    @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive', 'integer'}));
p.addParameter('Glance', false, @(x) isscalar(x) && islogical(x))
p.addParameter('Repaired', false, @(x) isscalar(x) && islogical(x))
parse(p, taskname, varargin{:});
taskname = p.Results.TaskName;
recheck = p.Results.Recheck;
sub_list = p.Results.SubjectList;
start = p.Results.Start;
is_glance = p.Results.Glance;
is_repaired = p.Results.Repaired;

% judge recheck status
if islogical(recheck)
    is_recheck = recheck;
    if recheck == true
        recheck = -2:1;
    end
else
    is_recheck = true;
end

% get the task setting for this task
tasksetting = get_config(taskname);

% initialize logging file
log_dir = 'logs';
if is_repaired
    check_result_log = fullfile(log_dir, sprintf('check_results_%s_repaired.txt', taskname));
    completion_log = fullfile(log_dir, sprintf('completion_%s_repaired', taskname));
else
    check_result_log = fullfile(log_dir, sprintf('check_results_%s.txt', taskname));
    completion_log = fullfile(log_dir, sprintf('completion_%s', taskname));
end

% throw an error when to do recheck before first check is finished
if is_recheck
    if ~exist(check_result_log, 'file')
        rmpath scripts
        error('EBR:Check_Blink:NoCheckResultsFound', ...
            'When rechecking, we need the original check results in file ''%s''.', ...
            check_result_log)
    end
    completion_first_check = load(completion_log);
    if completion_first_check ~= 0
        rmpath scripts
        error('EBR:Check_Blink:FirstCheckNotFinished', ...
            'When rechecking, the first check should have been finished.')
    end
end

% load data and merge them
if is_repaired
    load(fullfile('EOG', sprintf('EOG_%s_repaired', taskname))) %#ok<*LOAD>
    load(fullfile('EOG', sprintf('blink_res_%s_repaired', taskname)))
else
    load(fullfile('EOG', sprintf('EOG_%s', taskname)))
    load(fullfile('EOG', sprintf('blink_res_%s', taskname)))
end
if length(EOG) ~= height(blink_res)
    error('EBR:Check_Blink:DatasetCorruption', ...
        'The number of subjects in EOG and blink result do not match.')
end

% when in glance, recheck or a customed sublist, do not store finish rate
if is_recheck || is_glance || ~isempty(sub_list)
    store_rate = false;
else
    store_rate = true;
end

% set subject list based on recheck setting if not specified
if is_recheck
    fprintf('Begin rechecking.\n')
    fprintf('Reading first check results from ''%s''.\n', check_result_log);
    check_result = readtable(check_result_log);
    if ~is_glance && ismember('Recheck', check_result.Properties.VariableNames)
        rmpath scripts
        error('EBR:Check_Blink:DupRecheck', ...
            'Seemingly one recheck has been done. Please delete those logs before rechecking.')
    end
    check_result.Recheck = check_result.Message;
    rows_to_check = ismember(check_result.Message, recheck);
else
    rows_to_check = true(height(blink_res), 1);
end
if ~isempty(sub_list)
    rows_to_check = rows_to_check & ismember(blink_res.pid, sub_list);
end
rows_to_check = find(rows_to_check);

% if not in recheck or glance, start could be recovered from file
if isempty(start)
    if ~is_glance && ~is_recheck && exist(completion_log, 'file')
        fprintf('Seemingly you are trying to continue the last work, recovering...\n')
        start = load(completion_log);
        if start == 0
            fprintf('Log file ''%s'' indicates the checking has completed. Exiting.\n', ...
                completion_log)
            rmpath scripts
            return
        end
    else
        start = 1;
    end
end

% begin checking
num_subj = length(rows_to_check);
fprintf('Will check %d subjects in total.\n', num_subj);
% when not in recheck, will try to continue from last checking
if ~is_recheck
    if start ~= 1 && exist(check_result_log, 'file')
        fprintf('Try starting from subject %d.\n', start);
        fprintf('Reading existing check results from ''%s''.\n', check_result_log);
        check_result = readtable(check_result_log);
        if ~isequal(check_result.pid, blink_res.pid)
            warning('EBR:CHECK_BLINK:UnconsistentCheckResult', ...
                'The subject identities in the check result are not consistent with those in `EOG`.')
            fprintf('Force to start from subject 1.\n')
            start = 1;
        end
    else
        fprintf('No check result excel found, will force to start from subject 1, then.\n');
        start = 1;
    end
    if start == 1
        check_result = table(blink_res.pid, nan(height(blink_res), 1), ...
            'VariableNames', {'pid', 'Message'});
    end
end

for i_subj = start:num_subj
    fprintf('Now processing subject %d, remaining %d subjects.\n', i_subj, num_subj - i_subj);
    row_to_check = rows_to_check(i_subj);
    stat = blink_res.stat{row_to_check};
    if isempty(stat)
        fprintf('No data for this subject. Continue to the next.\n');
        switch is_recheck
            case true
                check_result.Recheck(row_to_check) = 0;
            case false
                check_result.Message(row_to_check) = 0;
        end
        continue
    end
    EOGv = EOG(row_to_check).EOGv;
    tasksetting.pid = blink_res.pid(row_to_check);
    eyeblinkplot(EOGv, stat, tasksetting);
    if is_glance
        continue
    end
    inputprompt    = {'How about it? Message (-2=needs further examin, -1=up and down are inverted, 0=no fitness, 1=okay):'};
    inputtitle     = 'Record';
    num_lines      = 1;
    defans         = {'1'};
    options.Resize = 'off';
    userinput      = inputdlg(inputprompt, inputtitle, num_lines, defans, options);
    if ~isempty(userinput)
        switch is_recheck
            case true
                check_result.Recheck(row_to_check) = str2double(userinput);
            case false
                check_result.Message(row_to_check) = str2double(userinput);
        end
    else
        fprintf('User canceled at subject of %d.\n%d subjects are checked in total for this turn.\n', ...
            i_subj, i_subj - start);
        break
    end
    if store_rate
        dlmwrite(completion_log, i_subj);
    end
    % output the results into a file with tsv format
    writetable(check_result, check_result_log, 'Delimiter', '\t');
end
% store 0 to completion log when all are done
if store_rate && i_subj == num_subj && ~isempty(userinput)
    dlmwrite(completion_log, 0);
end
% utilies functions are under this directory
rmpath scripts
