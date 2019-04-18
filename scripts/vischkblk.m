function res = vischkblk(EOG, blink_res, start)
%This script is a wrapper function to check the fitness of data 
%subject by subject, which calls the following user-defined function:
%   eyeblinkplot
%
%The output res_description contains a variable 'Message', which codes the
%checking results in following way:
%   -1, denote 'later examination needed', 
%   0, denote 'not valid/bad fitness', and
%   1, denote 'valid and accepted'.

%By Zhang, 2/28/2016.

%Initializing jobs.
parpath = fileparts(pwd);
datapath = [parpath, filesep, 'ResData'];
if ~exist(datapath, 'dir')
    error('UDF:VISCHKBLK:LegalDataPathNotFound', 'Datapath %s not found.', datapath);
end
resdatafile = [datapath, filesep, 'checkResult.xlsx'];
completedfile = [datapath, filesep, 'completed'];

%Checking input argument.
if nargin == 2
    if exist(completedfile, 'file')
        start = load(completedfile);
    else
        start = 1;
    end
end

%Suppose the data are already loaded into workspace. We could begin at
%once.
nsubj = length(EOG);
fprintf('%d subjects found in total.\n', nsubj);
reslabel = {'PID', 'Message'};
if start ~= 1 %Report if not start from the first subject.
    fprintf('Start from subject of %d.\n', start);
    if exist(resdatafile, 'file')
        fprintf('Reading existing data from ''%s''.\n', resdatafile);
        res_description = xlsread(resdatafile);
    else
        res_description = nan(nsubj, length(reslabel));
        fprintf('No check result excel found, please have a check after this check.\n');
    end
else
    res_description = nan(nsubj, length(reslabel));
end
if size(res_description, 1) < nsubj
    res_description = [res_description; nan(nsubj - size(res_description, 1), length(reslabel))];
end
for isubj = start:nsubj
    fprintf('Now processing subject %d, remaining %d subjects.\n', isubj, nsubj - isubj);
    stat = blink_res.stat{isubj};
    EOGv = EOG(isubj).EOGv;
    cfg.pid = EOG(isubj).pid;
    if ~isempty(stat)
        eyeblinkplot(EOGv, stat, cfg);
        inputprompt    = {'How about it? Message:'};
        inputtitle     = 'Record';
        num_lines      = 1;
        defans         = {'1'};
        options.Resize = 'off';
        userinput      = inputdlg(inputprompt, inputtitle, num_lines, defans, options);
    else
        fprintf('No data for this subject. Continue to the next.\n');
        userinput      = {'0'};
    end
    dlmwrite(completedfile, isubj);
    if ~isempty(userinput)
        res_description(isubj, 1) = EOG(isubj).pid;
        res_description(isubj, 2) = str2double(userinput{:});
    else
        fprintf('User canceled at subject of %d.\n%d subjects are checked in total for this turn.\n', ...
            isubj, isubj - start);
        break;
    end
end
res_description = array2table(res_description, 'VariableNames', reslabel);
if nargout >= 1
    res = res_description;
end
%Output the results into an Excel file.
writetable(res_description, resdatafile);
