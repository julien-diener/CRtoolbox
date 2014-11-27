function [ corner qual ] = goodEnoughCorners( image, param, mask )
%  [corner quality] = goodEnoughCorners( image , parameters, mask=[])
%
% find "good-enough" corners in 'image' "quickly-enough" 
% It uses  functions cornerImage() and localMax()
%
% Input: 
%   - image: a CRImage or an array
%   - parameters: CRParam or structure with fields
%        * minDist:    minimum distance between detected corners
%        * maxFeature: maximum number of detected corner
%   - mask:   (optional) apply corner detection only where mask~= zero  
%
% Output:
%   - 'corners': detected corners
%   - 'quality': qualtity of the corners (the higher the better)
%
% See also: crKLT, crKLT_config, private/pyrLK,
% private/cornerImage, private/localMax

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<3, mask = []; end;

cornerImg = cornerImage(image(),get(param,'minDist')/2);
corner    = localMax(cornerImg,get(param,'minDist'),get(param,'maxFeature'),mask());
corner(corner(:,2)<=0,:) = [];

if nargout==2
    qual = corner(:,2);
end
[corner(:,1) corner(:,2)] = ind2sub(size(image),corner(:,1));
