function [loc, LB, RB] = dePeak(data, sr, pivot, limit, bound)
%DEPEAK is used exclusively for the blink analysis to determine peaks.
%   List of input:
%   #1. data: EOG raw data.
%   #2. sr: sampling rate.
%   #3. pivot: the determinant for eye blink peaks.
%   #4. limit: eye blink maximum duration.
%   #5. bound: for calculating boundaries of eye blinks.

% Initiated by Zhang, Liang. 3/26/2014.
minargs = 3;
maxargs = 5;
narginchk(minargs, maxargs);
if nargin == 3
    limit = 400; %Max duration set at 360ms.
    bound = 0.1;    
elseif nargin == 4
    bound = 0.1;
end
limitpoints = floor(limit / 1000 * sr);
[maxima, loc] = findLocalMaxima(data);
loc(maxima <= pivot) = [];
maxima(maxima <= pivot) = [];
%Here we use NaN to denote "Not found".
LB = nan(1, length(loc));
RB = nan(1, length(loc));
for i = 1:length(maxima)
    % Find left bound.
    for li = loc(i):-1:loc(i) - limitpoints
        if li == 0
            loc(i) = nan;
            break;
        else
            if data(li) <= data(loc(i)) * bound
                LB(i) = li;
                break;
            elseif data(li) > data(loc(i))
                loc(i) = nan;
                break;
            end
        end
    end
    % Find right bound if left bound is found.
    if ~isnan(LB(i))
        for ri = loc(i):loc(i) + limitpoints
            if ri > length(data)
                loc(i) = nan;
                break;
            else
                if data(ri) <= data(loc(i)) * bound
                    RB(i) = ri;
                    break;
                elseif data(ri) > data(loc(i))
                    loc(i) = nan;
                    LB(i) = nan;
                    break;
                end
            end
        end
    end
    
    %Have a check if this peak is okay.
    if isnan(LB(i)) || isnan(RB(i))
        loc(i) = nan;
    else
        nInPeaks = length(findLocalMaxima(data(LB(i):RB(i))));
        if nInPeaks == 1 %Single blink.
            if RB(i) - LB(i) > limitpoints
                loc(i) = nan;
                LB(i) = nan;
                RB(i) = nan;
            end
        else % More than one peak, treat as double peaks.
            if RB(i) - LB(i) > 2 * limitpoints
                loc(i) = nan;
                LB(i) = nan;
                RB(i) = nan;
            end
        end
    end
end
loc(isnan(RB)) = [];
LB(isnan(RB)) = [];
RB(isnan(RB)) = [];