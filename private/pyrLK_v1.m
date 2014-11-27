function [ sp warn error ] = pyrLK( pyr1, pyr2, pts0, winSize, maxIter, threshold)
% [ speed failure error ] = pyrLK( img1, img2, features, windowSize=5, ...  
%                                   maxIteration=2, stopThreshold=0.5 )
%
% pyrLK tracks 'features' from images in pyr1 to pyr2
% it is a matlab implementation of the iterative-pyramidal-Lucas-Kanade
% motion tracker described in [BOUGUET02]: 
% "Pyramidal Implementation of the Lucas Kanade Feature Tracker:
%  Description of the algorithm" 
%
% Input:
%  - pyr1 and pyr2 are pyramids of images made with 'makePyramide.m'
%  - windowSize is the size of the square used to estimate local gradient
%  - iterate at most maxIteraction times per pyramid level
%  - or stop if convergence is less than stopThreshold (in pixels)
% * 'windowSize', 'maxIteration' and 'stopThreshold' can be scalars or 
%   vectors with a different value for each pyramid level.
%
% Output:
%  - speed:   estimated speed of features (in lower pyramid image)
%  - failure: tracking failure (see below)
%  - error:   final difference of pixel color
%
% 'failure' is an array containing 2 counts of failures for each particle. 
% The first is the number of times LK has failed due to a weak gradient of 
% color intensity in the area around the features. 
% The second is the number of times it has been tracked out of the image and
% force back inside, or lost due to algorithmic failure (this should not 
% happened anymore, otherwise warnings are also displayed).
%
% See also: crKLT, crKLT_config, private/makePyramid 


% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<3, error('pyrLK:not_enough_input','Not enough input'); end
if nargin<4, winSize   = 5;    end
if nargin<5, maxIter   = 2;    end
if nargin<6, threshold = 0.5;  end


pyrNumber = length(pyr1);

if length(winSize)<pyrNumber
    winSize = [ones(1,pyrNumber-length(winSize))*winSize(1) winSize];
end
if length(threshold)<pyrNumber
    threshold = [ones(1,pyrNumber-length(threshold))*threshold(1) threshold];
end
if length(maxIter)  <pyrNumber
    maxIter = [ones(1,pyrNumber-length(maxIter))*maxIter(1) maxIter];
end

    
% initializes some variables:
% sp: displacement (speed) of features
% ds: radius of neighborhood
sp = zeros(size(pts0));
ds = max(floor(winSize/2),1);
winSize = 2*ds +1;

warn = zeros(size(pts0,1),2); 
warning('off','MATLAB:singularMatrix');
for k=pyrNumber:-1:1
    % initialize variables used in current pyramid level
    sp   = 2*sp;
    pts  = pts0./(2^(k-1));
    img1 = pyr1(k).img;
    img2 = pyr2(k).img;
    Px   = pyr1(k).gradX;
    Py   = pyr1(k).gradY;
    
    % relative indices of the neighborhood of a feature
    clear r
    [r(:,:,1),r(:,:,2)] = meshgrid(-ds(k):ds(k));
    r = [ reshape(r(:,:,1),winSize(k).^2,1) reshape(r(:,:,2),winSize(k).^2,1) ];
    
    % for each feature to track
    for i=1:size(pts,1)
        % initialize variable use for current feature
        count = 0;              % number of iteration
        ldspl = threshold(k)+1; % norm of last iteration displacement 'dsp'
        Sdsp  = [0 0];          % sum of displacement evaluated at this level

        % function bilinear is implemented below
        a = [ bilinear(Px, [ pts(i,1)+r(:,1) pts(i,2)+r(:,2)]) ...
              bilinear(Py, [ pts(i,1)+r(:,1) pts(i,2)+r(:,2)]) ];


        try
        A = inv(a'*a);
        I = bilinear(img1(), [ pts(i,1)+r(:,1) pts(i,2)+r(:,2) ]);
        catch
            warn(i,1) = warn(i,1)+1;
            continue;
        end

        % iterate until it converges (or fails to)
        while count<maxIter(k) && ldspl>threshold(k) && norm(Sdsp)<5

            b = I - bilinear(img2(), [ pts(i,1)+sp(i,1)+r(:,1) pts(i,2)+sp(i,2)+r(:,2) ]);
            B = a'*b;

             dsp    = A*B;
            ldspl   = norm(dsp);
            sp(i,:) = sp(i,:) + dsp(2:-1:1)';
            Sdsp    = Sdsp    + dsp(2:-1:1)';

            count = count+1;
        end
        
    end
    % clamp estimated speed to stay in image
        % lower clamp
    ind     = find( sp < -pts +ds(k) );
    sp(ind) = -pts(ind)+ds(k);
    ind     = mod(ind-1,size(sp,1))+1;
        % higher clamp
    sp      = sp + pts;
    ind2    = find(sp(:,1)>size(img1,1)-ds(k));
    sp(ind2,1) = size(img1,1)-ds(k);
    ind     = union(ind,ind2);
    ind2    = find(sp(:,2)>size(img1,2)-ds(k));
    sp(sp(:,2)>size(img1,2)-ds(k),2) = size(img1,2)-ds(k);
    sp      = sp - pts;
    ind     = union(ind,ind2);

    warn(ind,2) = warn(ind,2) + 1;
end
warning('on','MATLAB:singularMatrix');

% compute error if asked
if nargout==3
    error = zeros(size(pts,1),2);
    for i=1:size(pts0,1)
        b = I - bilinear(img2(), [ pts0(i,1)+sp(i,1)+r(:,1) pts0(i,2)+sp(i,2)+r(:,2) ]);
        error(i,:) = sum(b.^2);
    end
end


% return values of pixels with non-integer idnices 'ind' in 'array' using 
% bilinear interpolation. Same purpose as 'interp2' but specific to our 
% case and much quicker.
function interp = bilinear( array, ind )
    ind_0  = floor(ind);                          % top    - left
    ind_x  = ind_0;  ind_x(:,1) = ind_x(:,1) +1;  % top    - right
    ind_y  = ind_0;  ind_y(:,2) = ind_y(:,2) +1;  % bottom - left
    ind_xy = ind_0;  ind_xy     = ind_xy     +1;  % bottom - right

    alpha  = ind - ind_0;
    beta   = 1 - alpha;
    
    % check if still in array
    [sx,sy] = size(array);
    
    % clamp indices
    ind_0 (ind_0 <1) = 1; ind_0 (ind_0 (:,1)>sx,1)=sx; ind_0 (ind_0 (:,2)>sy,2)=sy; 
    ind_x (ind_x <1) = 1; ind_x (ind_x (:,1)>sx,1)=sx; ind_x (ind_x (:,2)>sy,2)=sy; 
    ind_y (ind_y <1) = 1; ind_y (ind_y (:,1)>sx,1)=sx; ind_y (ind_y (:,2)>sy,2)=sy; 
    ind_xy(ind_xy<1) = 1; ind_xy(ind_xy(:,1)>sx,1)=sx; ind_xy(ind_xy(:,2)>sy,2)=sy; 
    
    % convert to 1D indices (same as sub2ind but quicker)
    ind_0 (:,1) = (ind_0 (:,2)-1)*sx + ind_0 (:,1);
    ind_x (:,1) = (ind_x (:,2)-1)*sx + ind_x (:,1);
    ind_y (:,1) = (ind_y (:,2)-1)*sx + ind_y (:,1);
    ind_xy(:,1) = (ind_xy(:,2)-1)*sx + ind_xy(:,1);
    
    % compute the sum of the bilinear interpolation
    % interp = zeros(size(alpha,1),1);
    try
    interp =          beta (:,1).*beta (:,2).*array(ind_0 (:,1));
    interp = interp + alpha(:,1).*beta (:,2).*array(ind_x (:,1));
    interp = interp + beta (:,1).*alpha(:,2).*array(ind_y (:,1));
    interp = interp + alpha(:,1).*alpha(:,2).*array(ind_xy(:,1));
    catch
        warn(i,2) = warn(i,2) +1; 
        %crWarning('function bilinear failed (in pyrLK.m) - node:%4d, pyrLevel:%d',i,k);
        interp = zeros(size(ind_0(:,1)));
    end
end

% end main function
end
