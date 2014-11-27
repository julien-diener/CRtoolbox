function img1 = divSize(img0, S1, method)
% resized_image = divSize(image, new_size, method=mean )
%
% Divide size of image by k=[kw,kh] such that new_size = floor(size(image)./k)
% method can be:
%  - mean: resized_image(i,j) is the mean of all corresponding pixels in image
%  - sum:  resized_image(i,j) is the sum  of all corresponding pixels in image
%  - max:  resized_image(i,j) is the max  of all corresponding pixels in image
%  - min:  resized_image(i,j) is the min  of all corresponding pixels in image
%
% Note: resized_image is an array, not a CRImage.

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<3, method = 'mean'; end

dS = floor(size(img0())./S1);
S0 = S1.*dS;

% divide image in one direction
img1 = reshape(img0.data(1:S0(1),1:S0(2)),dS(1),prod(S0)./dS(1));
switch method
    case 'mean', img1 = mean(img1);
    case 'sum',  img1 = sum (img1);
    case 'max',  img1 = max (img1);
    case 'min',  img1 = min (img1);
end
img1 = reshape(img1,S1(1),S0(2));

% divide image in the other direction
img1 = reshape(img1',dS(2),prod(S1));    % transpose !
switch method
    case 'mean', img1 = mean(img1);
    case 'sum',  img1 = sum (img1);
    case 'max',  img1 = max (img1);
    case 'min',  img1 = min (img1);
end
img1 = reshape(img1,S1(2),S1(1))';       % transpose (back) !
