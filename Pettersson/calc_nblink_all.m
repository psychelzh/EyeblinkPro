clear, clc
load('EOG.mat')
nsubj = length(EOGv);
nblink = nan(nsubj, 2);
for isub = 1:nsubj
    nblink(isub, 1) = EOGv(isub).pid;
    if ~isempty(EOGv(isub).trial)
        ntrial = length(EOGv(isub).trial);
        nblink(isub, 2) = 0;
        for itrial = 1:ntrial
            if all(EOGv(isub).trial{itrial} == 0)
                nblink(isub, 2) = nan;
                break;
            else
                nblink(isub, 2) = nblink(isub, 2) + blinkcount(EOGv(isub).trial{itrial}, EOGv(isub).fsample);
            end
        end
    end
end