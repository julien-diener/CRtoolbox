function mask = crRoiPoly( axe )
% crRoiPoly is made to replace roipoly of the image toolbox
% It is equivalent as calling crDrawPoly then crFillMask
%
%   mask = crRoiPoly( axe = gca)
%
% 'mask' is a logical array with the same size as the axes if current 'axe'
%
% See also: crDrawPoly, crFillMask

% Author: Julien diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<1, axe = gca; end

% Compute size of y and x axes
S = [ get(axe,'ylim') ; get(axe,'xlim') ];
S = round(S(:,2) - S(:,1));

poly = crDrawPoly( axe );
mask = crFillMask( poly, S);