function rgb_image = isrgb( img )
% for matpiv to work without the image toolbox

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

rgb_image = size(img,3)==3;
