function [ image ] = saveImage( this, image, index)
%  image = video.saveImage( image, index = image.index or 1 )
%
% 'image' should be a CRImage or data array (in this case default index is 0)

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if ~this.output
    crError('Video has no output configured');
    return;
end

if ~isa(image,'CRImage')
    if numel(image)==1
        value = image;
        image = CRImage(1,1,1,this.format);
        image = image +value;
    else
        image = CRImage(image,0,[],this.format);
    end
end
if nargin==3
    image.index = index;
end

if ~exist(this.outputPath,'dir')
    mkdir(this.outputPath);
end

image.save(this.imageFileName(image.index));
this.bufferWrite( image );
