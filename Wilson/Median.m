function postMedianEOG = Median(postDiffEOG, M)
%MEDIAN performs median filtering of the order M.

%Zhang, Liang. 05/22/2015.

if nargin < 2
    %It is said to be less than a quarter of the duration of an eye blink. 
    %Here a typical eye blink duration is 200 ms, and sampling rate is 256 Hz.
    M = 10; %Less than 12.8.
end
postMedianEOG = nan(1, length(postDiffEOG) - 2 * M);
for i_pt = 1:length(postMedianEOG)
    postMedianEOG(i_pt) = median(postDiffEOG(i_pt:i_pt + 2 * M));
end