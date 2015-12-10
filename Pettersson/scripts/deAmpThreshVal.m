function [val, gof] = deAmpThreshVal(vec, start)
%DEAMPTHRESHVAL is exclusively used in finding the blink analysis.

% Initiated by Zhang, Liang. 3/26/2015.
minargs = 1;
maxargs = 2;
narginchk(minargs, maxargs);
if nargin == 1
    start = 10;
end
sse = inf(1, length(vec));
for i = start:length(vec) - 1
    Dn = vec(1:i);
    Dp = vec(i:end);
    [~, gofn] = fit((1:i)', double(Dn'), 'poly1');
    [~, gofp] = fit((i:length(vec))', double(Dp'), 'poly1');
    sse(i) = gofn.sse + gofp.sse;
end
[gof, ind] = min(sse);
val = vec(ind);