function postDiffEOG = Differentiation(postEroEOG)
%DIFFERENTIATION performs differentiation filtering of the order 2. As the
%paper goes, it follows the erosion filter.

%Zhang, Liang. 05/22/2015.

postDiffEOG = nan(1, length(postEroEOG) - 2);
for i_pt = 1:length(postDiffEOG)
    postDiffEOG(i_pt) = 1 / 2 * (postEroEOG(i_pt + 2) - postEroEOG(i_pt));
end