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