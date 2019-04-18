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
[val, stat] = deAmpThreshVal(localmax, 2);
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
[loc, LB, RB] = dePeak(EOG, sr, dp, 400);

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