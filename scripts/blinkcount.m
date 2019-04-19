function [numBlk, stat] = blinkcount(EOG, sr, display)
%BLINKCOUNT counts eye blinks in the EOG data. When set 'on' to display
%variable, a figure is plotted to denote all the eye blinks found in the
%data.

%Change log:
%   Add one more output, 11/21/2015, Zhang Liang.
%   Structurize the output into a structure variable, 'blink'. 12/10/2015,
%   Zhang Liang. E-mail:psychelzh@gmail.com
%   Number of blink will be an instinct output now.

%Preallocating.
minargs = 2;
maxargs = 3;
narginchk(minargs, maxargs);
if nargin == 2
    display = 'off';
end

%S1:Find out all the local maxima and scaled the maxima set to [0, 1].
maxima = findLocalMaxima(EOG);
%Remove the values that are too big from maxima. Basically, for long
%episodes, these values might result from EMG, EKG, etc. And 1000 is kind
%of an arbitrary value determined by visual inspection.
maxima(maxima > 1000) = [];
localmax = (sort(maxima) - min(maxima)) / (max(maxima) - min(maxima));
%S2:Determine the threshold value of telling the noise and blink peak apart in the data.
[val, stat] = findAmpThreshVal(localmax, 2);
% %Here: OR value is used as a way of deciding whether the data can be used
% %in this method. By some exploration, I use 0.7 as the threshold.
% OR = 1 - stat.gof / stat.wgof;
% if OR < 0.7 %This amplitude needs calibration!!!!!
%     numBlk = nan;
%     stat.blinkpeak = [];
%     stat.LB = [];
%     stat.RB = [];
%     fprintf('Bad fitness. OR:%.2f\n', OR)
%     return
% end
dp = val * (max(maxima) - min(maxima)) + min(maxima);
%S3:Find out each peak and its duration.
[loc, LB, RB] = findPeak(EOG, sr, dp, 400);

%Generating output.
numBlk = length(loc);
stat.blinkpeak = loc;
stat.LB = LB;
stat.RB = RB;

%Plot part.
if strcmp(display,'on')
    figure
    hold on
    plot((1:length(EOG)) / sr, EOG)
    for i = 1:length(loc)
        plot((LB(i):RB(i)) / sr, EOG(LB(i):RB(i)), 'g.')
        plot(loc(i) / sr, EOG(loc(i)), 'xr')
    end
    xlabel('Time(s)')
    ylabel('EOG(\muV)')
end
end

function [maxima, ind] = findLocalMaxima(data)
%FINDLOCALMAXIMA finds out all the local maxima of data.
%   DATA should be a vector.

% Initiated by Zhang, Liang. 3/25/2015.

if nargin ~= 1
    error('findLocalMaxima:argChk', 'Wrong number of input arguments')
end

% Initiation.
maxima = [];
ind = [];

% Begin iteration.
for i = 2:length(data) - 1
    if data(i) > data(i - 1) && data(i) > data(i + 1)
        maxima = [maxima, data(i)]; %#ok<*AGROW>
        ind = [ind, i];
    end
end
end

function [val, stat] = findAmpThreshVal(vec, start)
%DEAMPTHRESHVAL is exclusively used in finding the blink analysis.
%   Statistics are included in output stat. Now contains three fields:
%   ind: index of the most suitable fitness.
%   gof: the minimun of sse.
%   wgof: the maximum of sse.

% Initiated by Zhang, Liang. 3/26/2015.
minargs = 1;
maxargs = 2;
narginchk(minargs, maxargs);
if nargin == 1
    start = 10;
end
num = length(vec);
sse = inf(1, num);
for i = start:num - 1
    Dn = vec(1:i);
    Dp = vec(i:end);
    mdln = fitlm(1:i, Dn);
    mdlp = fitlm(i:num, Dp);
    sse(i) = mdln.SSE + mdlp.SSE;
end
[ssemin, ind] = findLocalMaxima(-sse);
ssemax = max(sse(start:num - 1));
val = vec(ind(end));
stat.ind = ind(end);
stat.num = num;
stat.gof = -ssemin(end);
stat.wgof = ssemax;
end

function [loc, LB, RB] = findPeak(data, sr, pivot, limit, bound)
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
end
