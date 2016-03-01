function eyeblinkplot(EOGv, stat, sr, starttime)
%For visual checking of the fitness of the algorithm. And also a way of
%checking the validity of data.

%By Zhang, 2/29/2016. 

%Checking input argument.
if nargin <= 3
    starttime = 4;
end
if nargin <= 2
    sr = 256;
end
if nargin <= 1
    error('UDF:EYEBLINKPLOT:NotEnoughInput', 'At least two input arguments are needed.');
end

%Initializing processing.
startpoint = floor(sr * starttime) + 1;
%Plotting.
ntrial = length(EOGv.trial);
for itrial = 1:ntrial
    figure
    hold on
    EOG = EOGv.trial{itrial}(3, startpoint:end);
    plot((1:length(EOG)) / sr, EOG)
    for i = 1:length(stat(itrial).blinkpeak)
        plot((stat(itrial).LB(i):stat(itrial).RB(i)) / sr, EOG(stat(itrial).LB(i):stat(itrial).RB(i)), 'g')
        plot(stat(itrial).blinkpeak(i) / sr, EOG(stat(itrial).blinkpeak(i)), 'xr')
    end
    xlabel('Time(s)')
    ylabel('EOG(\muV)')
    %Wait until user close the gui.
    uiwait(gcf)
end
