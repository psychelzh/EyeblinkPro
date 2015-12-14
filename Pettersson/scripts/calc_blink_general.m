%Read data and calculate blink rate.
clear, clc
parpath = fileparts(pwd);
datapath = [parpath, filesep, 'ResData'];
%Access to all files.
dataFilesInfo = dir([datapath, filesep, 'EOG*']);
dataFilesName = {dataFilesInfo.name};
totalfilenum = length(dataFilesName);
logid = fopen('readerror.log', 'w');
%Set a file for recording finished files.
logfinished = [datapath, filesep, 'LAST'];
if exist(logfinished, 'file')
    finished = load(logfinished);
    startfile = finished(end) + 1;
else
    startfile = 1;
end
%Determine whether to show multiwaitbar or not.
switch computer
    case {'PCWIN', 'PCWIN64'}
        useWaitBar = true;
    otherwise
        useWaitBar = false;
end
%Give information of rate of progress.
if useWaitBar
    multiWaitbar('CloseAll');
    multiWaitbar('Global Task', 0);
end
for ifile = startfile:totalfilenum
    %Refresh waitbar "Global Task".
    if useWaitBar
        rop = (ifile - 1) / totalfilenum;
        multiWaitbar('Global Task', rop);
    end
    thisFile = dataFilesName{ifile};
    load([datapath, filesep, thisFile])
    nsubj = length(EOG);
    pid        = nan(nsubj, 1); %Participant ID
    nblink     = nan(nsubj, 1); %Number of blinks.
    task_dur   = nan(nsubj, 1); %Duration of the task.
    rate_blink = nan(nsubj, 1); %Number of blinks of each minute.
    stat       = cell(nsubj, 1);
    %Coined from LSY, the baseline 1 sec and the first 3 sec after the stimulus 
    %onset will be discard to reduce influence from intentioanl eye movement.
    %In total, first 4 sec of the epoch will be discarded.
    taskname = regexp(thisFile, '(?<=EOG_)[A-Z]+', 'match', 'once');
    if strcmp(taskname, 'REST')
        starttime = 4;
    else 
        starttime = 0;
    end
    %Add a subtask waitbar.
    if useWaitBar
        multiWaitbar(['Processing Task: ', taskname], 0);
    end
    for isub = 1:nsubj
        %Refresh subtask waitbar.
        if useWaitBar
            ros = (isub - 1) / nsubj;
            multiWaitbar(['Processing Task: ', taskname], ros);
        end
        pid(isub) = EOG(isub).pid;
        fprintf('Now processing %d\n', pid(isub));
        if isempty(EOG(isub).EOGv)
            continue
        end
        ntrial = length(EOG(isub).EOGv.trial);
        if ntrial == 0
            fprintf(logid, 'No trial data found for %dth subject %d.\n', isub, pid(isub));
        else
            nblink(isub)   = 0;
            task_dur(isub) = 0;
            for itrial = 1:ntrial
                if ~isempty(EOG(isub).EOGv.trial{itrial})
                    try
                        startpoint = floor(EOG(isub).fsample * starttime) + 1;
                        [numBlk, blinkstat] = blinkcount(EOG(isub).EOGv.trial{itrial}(3, startpoint:end), EOG(isub).fsample);
                        if ~isnan(numBlk)
                            nblink(isub) = nblink(isub) + numBlk;
                            task_dur(isub) = task_dur(isub) + EOG(isub).EOGv.time{itrial}(end) - EOG(isub).EOGv.time{itrial}(startpoint);
                            stat{isub}(itrial) = blinkstat;
                        else
                            stat{isub}(itrial) = blinkstat;
                        end
                    catch exception
                        fprintf(logid, 'Fatal error occured when calculating blinks for %dth subject %d.\n\tErrorMessage: %s\n', ...
                            isub, pid(isub), exception.message);
                        fclose(logid);
                        rethrow(exception);
                    end
                else
                    fprintf(logid, 'No data in the %dth trial for %dth subject %d,\n', itrial, isub, pid(isub));
                end
            end
            rate_blink(isub) = nblink(isub) / (task_dur(isub) / 60);
        end
    end
    blink_res = table(pid, nblink, task_dur, rate_blink, stat);
    save([datapath, filesep, 'blink_res_', taskname], 'blink_res');
    dlmwrite(logfinished, ifile, '-append');
    if useWaitBar
        multiWaitbar(['Processing Task: ', taskname], 'Close');
    end
end
if useWaitBar
    multiWaitbar('CloseAll');
end
fclose(logid);
