function blink_res = cblink(fileName)
%

load(fileName)
nsubj = length(EOG);
pid        = nan(nsubj, 1); %Participant ID
nblink     = nan(nsubj, 1); %Number of blinks.
task_dur   = nan(nsubj, 1); %Duration of the task.
rate_blink = nan(nsubj, 1); %Number of blinks of each minute.
stat       = cell(nsubj, 1); %Useful statistics.
%Coined from LSY, the baseline 1 sec and the first 3 sec after the stimulus 
%onset will be discard to reduce influence from intentioanl eye movement.
%In total, first 4 sec of the epoch will be discarded.
taskname = regexp(fileName, '(?<=EOG_)[A-Z]+', 'match', 'once');
dataname = [fileparts(fileName), filesep, 'blink_res_', taskname];
starttime = 4;
fprintf('Processing task: %s.\n', taskname);
tic
for isub = 1:nsubj
    initialVarsS = who;
    %For information of timing.
    elapsedtimeS = toc;
    ros = (isub - 1) / nsubj;
    if ros == 0
        remTimeTask = nan;
    else
        remTimeTask = elapsedtimeS * (1 - ros) / ros;
    end
    etaS = iGetTimeString(remTimeTask);
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