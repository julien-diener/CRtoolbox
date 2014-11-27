function mask = crFillMask( poly, S )
% create and fill a mask using an input polygon
%   mask = crFillMask( polygon, size )
%
% Input  'polygon' must be a N-by-2 matrix containing the polygon indices 
% s.t. the first row contains the x-coordinates (as returned by crDrawPoly)
% Output 'mask' is a logical matrix with size 'size'
%
% See also: crRoiPoly, crDrawPoly

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

% Close the polygon if it is not closed already
if any(poly(1,:)~=poly(end,:))
    poly(end+1,:) = poly(1,:);
end

% create mask to be returned with an additional border of 1 pixel
mask = zeros( S(:)'+2 );   

% round vertex position to simplify algorithm (sorry if you need more precision)
% and shift coordinates to fit mask size with the additional borders
poly = round(poly+1);  


% For each line of polygon, draw lines in mask
% --------------------------------------------
% We track the direction of neighboring ligns to avoid drawing 
% vertex pixel twice if it is not necessary
lastXDir = sign(poly(end,1)-poly(end-1,1)+eps);
for i=1:size(poly,1)-1
    xDir = sign(poly(i+1,1)-poly(i,1)+eps);
    drawLine(poly([i i+1],:), xDir*lastXDir<0);
    lastXDir = xDir;
end

% Fill up interior of polygon
% ---------------------------
mask(:) = mask(:) | rem(cumsum(mask(:)),2);  % neat, isn't it?

% remove the mask border
mask = mask(2:end-1,2:end-1);


% ---------- drawLine(p, draw_1st_pixel) ----------
% Draw a line from p(:,1) to p(:,2) 
% with one and only one pixel for each column of the mask
% Draw the first pixel of the lign only if asked to
function drawLine(p, draw_1st_pixel)
    % compute indices of the line pixels
    dp = p(2,:)-p(1,:);                            % vector from p1 to p2
    dp(1) = dp(1)+eps;
    ind(:,1) = 0:sign(dp(1)):round(dp(1));         % x-coord along this vector
    ind(:,2) = p(1,2) + (ind(:,1)./dp(1)).*dp(2);  % y indices
    ind(:,1) = p(1,1) +  ind(:,1);                 % x indices
    
    % In case the first pixel of the ligne should not be drawn.
    if ~draw_1st_pixel, ind(1,:) = []; end
    
    % round indices and clamp those that are out of mask boundaries
    ind = round(ind);
    ind(ind(:,2)<1,2) = 1;     ind(ind(:,2)>size(mask,1),2) = size(mask,1); % 1 &only 1 pixel
    ind(ind(:,1)<1,:) = [];    ind(ind(:,1)>size(mask,2),:) = [];
    
    % convert to 1D indices
    ind = ind(:,2) + (ind(:,1)-1).*size(mask,1);
    
    % draw the line
    mask(ind) = mask(ind) +1;
end

end