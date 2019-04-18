function [val, stat] = deAmpThreshVal(vec, start)
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
    [~, gofn] = fit((1:i)', double(Dn'), 'poly1');
    [~, gofp] = fit((i:num)', double(Dp'), 'poly1');
    sse(i) = gofn.sse + gofp.sse;
end
[ssemin, ind] = findLocalMaxima(-sse);
ssemax = max(sse(start:num - 1));
val = vec(ind(end));
stat.ind = ind(end);
stat.num = num;
stat.gof = -ssemin(end);
stat.wgof = ssemax;
