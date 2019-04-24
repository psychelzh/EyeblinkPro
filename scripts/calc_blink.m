% All rights are reserved. (c) 2019 Liang Zhang (psychelzh@outlook.com)
function blink_res = calc_blink(EOG)
% This script is used to determine eye blink pattern in EOG dataset
% Please run Extract_EOG before using this.
h_log_err = fopen(fullfile('logs', 'errlog.log'), 'a');
nsubj      = length(EOG);
% preallocate
pid        = nan(nsubj, 1); %Participant ID
nblink     = nan(nsubj, 1); %Number of blinks.
task_dur   = nan(nsubj, 1); %Duration of the task.
rate_blink = nan(nsubj, 1); %Number of blinks of each minute.
stat       = cell(nsubj, 1);
for isub = 1:nsubj
    pid(isub) = EOG(isub).pid;
    fprintf('Now detecting blinks subject %d (id: %d).\n', isub, pid(isub));
    if isempty(EOG(isub).EOGv)
        continue
    end
    ntrial = length(EOG(isub).EOGv.trial);
    if ntrial == 0
        fprintf(h_log_err, '[%s] No trial data found for subject %d (id: %d).\n', ...
            datestr(now), isub, pid(isub));
    else
        nblink(isub)   = 0;
        task_dur(isub) = 0;
        for itrial = 1:ntrial
            if ~isempty(EOG(isub).EOGv.trial{itrial})
                try
                    [numBlk, blinkstat] = blinkcount(EOG(isub).EOGv.trial{itrial}(3, :), EOG(isub).fsample);
                    if ~isnan(numBlk)
                        nblink(isub) = nblink(isub) + numBlk;
                        task_dur(isub) = task_dur(isub) + EOG(isub).EOGv.time{itrial}(end) - EOG(isub).EOGv.time{itrial}(1);
                        stat{isub}(itrial) = blinkstat;
                    else
                        stat{isub}(itrial) = blinkstat;
                    end
                catch exception
                    fprintf(h_log_err, '[%s] Fatal error occured when detecting blinks for subject %d.\n\tErrorMessage: %s\n', ...
                        datestr(now), pid(isub), exception.message);
                end
            else
                fprintf(h_log_err, '[%s] No data in the %dth trial for subject %d,\n', datestr(now), itrial, pid(isub));
            end
        end
        rate_blink(isub) = nblink(isub) / (task_dur(isub) / 60);
    end
end
blink_res = table(pid, nblink, task_dur, rate_blink, stat);
fclose(h_log_err);
