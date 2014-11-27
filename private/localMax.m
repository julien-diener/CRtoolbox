function [ ind ] = localMax( image, minDist, number, mask )
% localMax find local maximum in 'image' (quickly)
%
% indices = localMax( image, minDist, number, mask=[])
%
% Input: 
%   - image:   a 1D or 2D array to detect local maximum from.
%   - minDist: minimum distance between detected features
%   - number:  maximum number of detected features
%   - mask:    (optional) apply localMax only where mask is not zero  
%
% Output:
%   indices(:,1) are the indices of the detected local maximum (1D indices)
%   indices(:,2) is the value of 'image' at these points
%
% See also: computeKLT, private/goodEnoughCorners, private/cornerImage

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

% This function replaces localMax_old that uses imdilate from the image
% processing toolbox

% manage input mask mask
if nargin<4,                mask = ones(size(image));
elseif ~isa(mask,'double'), mask = double(mask);
end

% Detect local maximum with direct neighbors
[y,x] = size(mask);
if y==1
    image = image';
    mask  = mask';
    [y,x] = size(mask);
end
if x==1
    y = 1:y-1;
    mask(y) = mask(y) & (image(y)>image(y+1));
    y = y+1;
    mask(y) = mask(y) & (image(y)>image(y-1));
else
    y = 1:y-1;
    x = 1:x-1;
    mask(y,x) = mask(y,x) & (image(y,x)>image(y+1,x)) & (image(y,x)>image(y,x+1));% & (image(y,x)>=image(y+1,x+1));
    y = y+1;
    x = x+1;
    mask(y,x) = mask(y,x) & (image(y,x)>image(y-1,x)) & (image(y,x)>image(y,x-1));%& (image(y,x)>=image(y-1,x-1));
end

% initiate iteration variables 
maxIter = 20;
M_last  = mask;
weight  = [];
image(mask==0) = 0;

% Make a circular filter F of size minDist
[x,y] = meshgrid(-minDist:minDist,-minDist:minDist);
F     = double((x.*x + y.*y)<=minDist.*minDist);

for k=1:maxIter
    % for each pixels, compute average of region defined by the filter F
    weight = conv2(mask, F,'same');
    meanA  = conv2(image,F,'same')./weight;

    % find element that a lower than the average of their region
    out = meanA > image;
    out(weight==1) = false;   % keep local maximum already detected

    image(out) = 0;
    mask (out) = 0;
    if mask==M_last, break;
    else M_last = mask;
    end
end
if k==maxIter, disp('max iteration reached'); end


% manage output
mask(weight~=1) = 0;  % did not converge
ind = find(mask==1);
[val order] = sort(image(ind),'descend');
ind      = ind(order(1:min(number,end)));
ind(:,2) = image(ind);


