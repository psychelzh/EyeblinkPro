function postEroEOG = Erosion(EOG, E)
%EROSION performs erosion filtering of the order K.

%Zhang, Liang. 05/22/2015.

if nargin < 2
    %It is said to be less than half of the duration of an eye blink. Here
    %a typical eye blink duration is 200 ms, and sampling rate is 256 Hz.
    E = 20; %Less than 25.6.
end
%Initialization.
postEroEOG = nan(1, length(EOG) - 2 * E);
%Begin erosion.
for i_pt = 1:length(postEroEOG)
    postEroEOG(i_pt) = max(EOG(i_pt:i_pt + 2 * E));
end