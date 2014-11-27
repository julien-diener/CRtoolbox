function [ g ] = cornerImage( gradX, gradY, radius )
% [ cornerImage ] = cornerImage( image, radius )
% [ cornerImage ] = cornerImage( gradX, gradY, radius )
%
% This function approximate thegood feature to track algorithm which
% compute for each pixel, the lower eigenvalue of its neighborhood.
% Because I did not find a "matlab oriented" algorithm, this is very really
% slow. This function compute a 3 bin histogram of the gradient over the
% pixel neighborhood (actually each bin stores the sum of the neighbor
% gradient norm). The lowest bin is considered a propertional to the lower
% eigenvalue.
%
% See also: crKLT, crKLT_config, private/goodEnoughCorners

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<2, error('Not enough input arguments.'); end
    
if nargin==2
    radius = gradY;
    gradY  = conv2(gradX, [1 2 0 -2 -1]', 'same');
    gradX  = conv2(gradX, [1 2 0 -2 -1],  'same');
end
radius = floor(radius);


R = sqrt(gradX.*gradX + gradY.*gradY);  % gradient direction
T = mod(atan2(gradY,gradX),pi);         % gradient norm

% Make a filter F of radius 'radius' to compute local mean
F = gaussianFilter(radius,radius/2);

N = 3;                        % number of bins in histogram
B = zeros([N,size(gradX)]);   % bins
r = linspace(-eps,pi,N+1);    % bins range

for i=1:N
    m = (r(i)<T) & (T<=r(i+1));
    B(i,m) = R(m);
    B(i,:,:) = conv2(squeeze(B(i,:,:)),F,'same');
end

g = squeeze(min(B));
