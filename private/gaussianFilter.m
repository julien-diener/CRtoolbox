function filter = gaussianFilter(r,s)
% Make a gaussian filter of radius 'r' and standard deviation 's'
%   filter = gaussianFilter(r,s)

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

[x,y]  = meshgrid(-r:r,-r:r);
filter = exp(-(x.^2 + y.^2)/(2*s.^2));
filter = filter./sum(filter(:));
