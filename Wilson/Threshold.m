function postThreshEOG = Threshold(postMedianEOG, W)
%THRESHOLD performs the threshold filtering of the threshold of W.

postThreshEOG = postMedianEOG;
postThreshEOG(abs(postThreshEOG) < W) = 0;