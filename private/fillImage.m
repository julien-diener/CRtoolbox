function [ image none ] = fillImage( ind, val, w, h, s, d)
% [ image none ] = fillImage( indices, values, width, height, smooth, max_dist)
%
% Fill an image with 'value' at pixels 'indices', then "interpolate"
% on all other pixels using a smoothing filter.
%
% Input:
% 'indices':  should be Nx2, i.e. x and y coordinates of N points
% 'value':    should be Nxk where k is the number of channels of the 
%             returned image (i.e. image will be w x h x k).
% 'smooth':   smoothing coefficient (in pixels)
% 'max_dist': maximum distance to which the interpolation is done
%             (the results is the same for all value > 9*smooth !)
%
% Output:
% 'image' the interpolated field
% 'none'  a mask that indicates pixels for which no value was computed
%         (too far from the input features)
%
% See also: computeKLT

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<6, d = 5*s; end

% initiate returned image and weighting matrix
image   = zeros(size(val,2),w,h);
weight  = zeros(w,h);

% convert indices to suitable format (rounded, clamped and mono-dimensional)
ind  = round(ind);
ind(ind<1) = 1;
ind(ind(:,1)>w,1) = w;
ind(ind(:,2)>h,2) = h;
ind = (ind(:,2)-1)*w + ind(:,1);

% copy values in returned image and make initial weight
image(:,ind) = val';
image  = shiftdim(image,1);
weight(ind) = 1;

% make filter
filter = gaussianFilter(d,s);
filter = filter - max(filter(:,1));
filter(filter<0) = 0;

% propagate values in image and corresponding weight
for i=1:size(image,3)
    image(:,:,i) = conv2(image(:,:,i),filter,'same');
end
weight = conv2(weight,filter,'same');

% normalize
for i=1:size(image,3)
    image(:,:,i) = image(:,:,i)./weight;
end

if nargout==2 
    none = (weight==0);
end
