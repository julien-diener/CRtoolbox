function [ pyr ] = makePyramid( img, level, blur )
% pyramid = makePyramid( image, level_number, blur_radius=0 );
%
% Make a pyramid of image as described in [Bouguet02]: "Pyramidal Implementation 
% of the Lucas Kanade Feature Tracker: Description of the algorithm", 
% Jean-Yves Bouguet, 2002.
%
% INPUT:
% - 'image' should be a 2D array (i.e. gray) with format double or single
% - 'level_number' is the number of level of the output pyramid (pyr)
% - 'blur_radius', convolute pyramid images by a blur filter with this radius
%
% OUTPUT:
% - pyramid(i).img   is image of pyramid at level i (starting at 1, not 0 as in [Bouguet02])
% - pyramid(i).gradX is the x gradient of image pyramid(i).img 
% - pyramid(i).gradY is the y gradient of image pyramid(i).img 
%
% See also: private/pyrLK, computeKLT

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

pyr = repmat(struct('img',[],'gradX',[],'gradY',[]),1,level);

if nargin>2 && blur>0
    filter = 1;
    F = conv2([1 2 1],[1 2 1]')/16;
    for i=1:blur
        filter = conv2(filter,F);
    end
else
    filter = [];
end


for i=1:level
    % compute pyramid
    if i==1
        pyr(i).img = img();
    else
       % img_0 = pyr(i-1).img;
        [sx,sy] = size(pyr(i-1).img);

        ind0_x = 1:2:sx-1;
        ind0_y = 1:2:sy-1;
        ind1_x = 2:2:sx;
        ind1_y = 2:2:sy;
        ind2_x = 3:2:sx;
        ind2_y = 3:2:sy;
        
        if length(ind2_x)<length(ind1_x), ind2_x = [ind2_x ind2_x(end)]; end;
        if length(ind2_y)<length(ind1_y), ind2_y = [ind2_y ind2_y(end)]; end;

        pyr(i).img = 0.25*pyr(i-1).img(ind1_x,ind1_y);

        pyr(i).img = pyr(i).img  +  0.125 * pyr(i-1).img(ind0_x,ind1_y);
        pyr(i).img = pyr(i).img  +  0.125 * pyr(i-1).img(ind1_x,ind0_y);
        pyr(i).img = pyr(i).img  +  0.125 * pyr(i-1).img(ind2_x,ind1_y);
        pyr(i).img = pyr(i).img  +  0.125 * pyr(i-1).img(ind1_x,ind2_y);

        pyr(i).img = pyr(i).img  +  0.0625* pyr(i-1).img(ind0_x,ind0_y);
        pyr(i).img = pyr(i).img  +  0.0625* pyr(i-1).img(ind2_x,ind0_y);
        pyr(i).img = pyr(i).img  +  0.0625* pyr(i-1).img(ind2_x,ind2_y);
        pyr(i).img = pyr(i).img  +  0.0625* pyr(i-1).img(ind0_x,ind2_y);
    end
    
    % blur images
    if ~isempty(filter)
        pyr(i).img = conv2(pyr(i).img,filter,'same');
    end
    
    % compute gradient
    pyr(i).gradX = conv2(pyr(i).img(),[1 0 -1] ,'same');
    pyr(i).gradY = conv2(pyr(i).img(),[1 0 -1]','same');
end