function numBlk = blinkcount(EOG, sr, display)
%BLINKCOUNT counts eye blinks in the EOG data. When set 'on' to display
%variable, a figure is plotted to denote all the eye blinks found in the
%data.

minargs = 2;
maxargs = 3;
narginchk(minargs, maxargs);
if nargin == 2
    display = 'off';
end
maxima = findLocalMaxima(EOG);
localmax = (sort(maxima) - min(maxima)) / (max(maxima) - min(maxima));
val = deAmpThreshVal(localmax, 10);
dp = val * (max(maxima) - min(maxima)) + min(maxima);
[loc, LB, RB] = dePeak(EOG, sr, dp, 400);
if strcmp(display,'on')
    figure
    hold on
    plot((1:length(EOG)) / sr, EOG)
    for i = 1:length(loc)
        plot((LB(i):RB(i)) / sr, EOG(LB(i):RB(i)), 'r.')
        plot(loc(i) / sr, EOG(loc(i)), 'xr')
    end
    xlabel('Time(s)')
    ylabel('EOG(\muV)')
end
numBlk = length(loc);