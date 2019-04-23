function Check_Blink(taskname, start)
%CHECK_BLINK Checks the fitness of data subject by subject
%
%The output res_description contains a variable 'Message', which codes the
%checking results in following way:
%   -1, denote 'later examination needed',
%   0, denote 'not valid/bad fitness', and
%   1, denote 'valid and accepted'.
%
%See also eyeblinkplot

%By Zhang, 2/28/2016.

% utilies functions are under this directory
addpath scripts

% get the task setting for this task
tasksetting = get_config(taskname);

% initialize logging file
log_dir = 'logs';
check_result_log = fullfile(log_dir, sprintf('check_results_%s.txt', taskname));
completion_log = fullfile(log_dir, sprintf('completion_%s', taskname));

% set start if not specified
if nargin < 2
    if exist(completion_log, 'file')
        start = load(completion_log);
        if start == 0
            fprintf('Log file ''%s'' indicates the checking has completed. Exiting.\n', completion_log)
            rmpath scripts
            return
        end
    else
        start = 1;
    end
end

% load data
load(fullfile('EOG', sprintf('EOG_%s', taskname))) %#ok<*LOAD>
load(fullfile('EOG', sprintf('blink_res_%s', taskname)))
num_subj = length(EOG);
fprintf('%d subjects found in total.\n', num_subj);
if start ~= 1 %Report if not start from the first subject.
    fprintf('Try starting from subject %d.\n', start);
    if exist(check_result_log, 'file')
        fprintf('Reading existing data from ''%s''.\n', check_result_log);
        check_result = readtable(check_result_log);
        if ~isequal(check_result.pid, [EOG.pid]')
            warning('EBR:CHECK_BLINK:UnconsistentCheckResult', ...
                'The subject identities in the check result are not consistent with those in `EOG`.')
            fprintf('Force to start from subject 1.\n')
            start = 1;
        end
    else
        fprintf('No check result excel found, will force to start from subject 1, then.\n');
        start = 1;
    end
end
if start == 1
    check_result = table([EOG.pid]', nan(num_subj, 1), 'VariableNames', {'pid', 'Message'});
end
for i_subj = start:num_subj
    fprintf('Now processing subject %d, remaining %d subjects.\n', i_subj, num_subj - i_subj);
    stat = blink_res.stat{i_subj};
    EOGv = EOG(i_subj).EOGv;
    tasksetting.pid = EOG(i_subj).pid;
    if ~isempty(stat)
        eyeblinkplot(EOGv, stat, tasksetting);
        inputprompt    = {'How about it? Message (-1=needs further examin, 0=no fitness, 1=okay):'};
        inputtitle     = 'Record';
        num_lines      = 1;
        defans         = {'1'};
        options.Resize = 'off';
        userinput      = inputdlg(inputprompt, inputtitle, num_lines, defans, options);
    else
        fprintf('No data for this subject. Continue to the next.\n');
        userinput      = {'0'};
    end
    dlmwrite(completion_log, i_subj);
    if ~isempty(userinput)
        check_result.Message(i_subj) = str2double(userinput);
    else
        fprintf('User canceled at subject of %d.\n%d subjects are checked in total for this turn.\n', ...
            i_subj, i_subj - start);
        break
    end
end
%Output the results into an Excel file.
writetable(check_result, check_result_log, 'Delimiter', '\t');
% store 0 to completion log when all are done
if i_subj == num_subj && ~isempty(userinput)
    dlmwrite(completion_log, 0);
end
% utilies functions are under this directory
rmpath scripts
