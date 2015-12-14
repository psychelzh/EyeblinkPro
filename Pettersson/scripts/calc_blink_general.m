%Read data and calculate blink rate.
clear, clc
parpath = fileparts(pwd);
datapath = [parpath, filesep, 'ResData'];
%Access to all files.
dataFilesInfo = dir([datapath, filesep, 'EOG*']);
dataFilesName = {dataFilesInfo.name};
totalfilenum = length(dataFilesName);
logid = fopen('readerror.log', 'w');
%Read from finished log file.
logfinished = [datapath, filesep, 'LAST'];
if exist(logfinished, 'file')
    finished = load(logfinished);
    if finished(2) == -1 %Task denoted by "-1" is completed.
        startfile = finished(1) + 1;
        startsubj = 1;
    else %Task denoted by numbers other than "-1" is not completed.
        startfile = finished(1);
        startsubj = finished(2) + 1;
    end
else
    startfile = 1;
    startsubj = 1;
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
%For time estimation.
tic
for ifile = startfile:totalfilenum
    initialVarsF = who;
    %For information of timing.
    elapsedtimeF = toc;
    rop = (ifile - startfile) / (totalfilenum - startfile + 1);
    if rop == 0
        remTimeFile = nan;
    else
        remTimeFile = elapsedtimeF * (1 - rop) / rop;
    end
    etaF = iGetTimeString(remTimeFile);
    %Refresh waitbar "Global Task".
    if useWaitBar
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
    dataname = [datapath, filesep, 'blink_res_', taskname];
    if strcmp(taskname, 'REST')
        starttime = 4;
    else 
        starttime = 0;
    end
    %Add a subtask waitbar.
    if useWaitBar
        multiWaitbar(['Processing Task: ', taskname], 0);
    end
    fprintf('Processing task: %s. Estimated remaining time: %s\n', taskname, etaF);
    if ifile == startfile
        if startsubj > 1
            if exist(dataname, 'file')
                load(dataname)
                pid = blink_res.pid;
                nblink = blink_res.nblink;
                task_dur = blink_res.task_dur;
                rate_blink = blink_res.rate_blink;
                stat = blink_res.stat;
            else
                fprintf(logid, 'Data file %s not found, please have a check later.\n', dataname);
            end
        end
    else
        startsubj = 1;
    end
    for isub = startsubj:nsubj
        blink_res = table(pid, nblink, task_dur, rate_blink, stat);
        save(dataname, 'blink_res');
        %Set a file for recording finished files.
        dlmwrite(logfinished, [ifile, isub - 1]); %Completed "isub - 1" subjects.
        initialVarsS = who;
        %For information of timing.
        elapsedtimeS = toc;
        ros = (isub - startsubj) / (nsubj - startsubj + 1);
        if ros == 0
            remTimeTask = nan;
        else
            remTimeTask = (elapsedtimeS - elapsedtimeF) * (1 - ros) / ros;
        end
        etaS = iGetTimeString(remTimeTask);
        %Refresh subtask waitbar.
        if useWaitBar
            multiWaitbar(['Processing Task: ', taskname], ros);
        end
        pid(isub) = EOG(isub).pid;
        fprintf('Now processing %d. Estimated remaining time for this task: %s\n', pid(isub), etaS);
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
        clearvars('-except', initialVarsS{:})
    end
    blink_res = table(pid, nblink, task_dur, rate_blink, stat);
    save(dataname, 'blink_res');
    %Set a file for recording finished files.
    dlmwrite(logfinished, [ifile, -1]); %-1 denotes that all the subjects in current task have been analyzed.
    if useWaitBar
        multiWaitbar(['Processing Task: ', taskname], 'Close');
    end
    clearvars('-except', initialVarsF{:})
end
if useWaitBar
    multiWaitbar('CloseAll');
end
fclose(logid);
