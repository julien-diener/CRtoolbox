function [ img ] = getFrame( this, index, store)
% image = videoAVI.getFrame( imageIndex, store=true )
%
% Output:
% Return image of 'videoAVI' with index 'imageIndex' (or [] if it fails)
% If 'store' is set, save loaded image in memory for quicker future access
%
% See also: CRVIDEOAVI, CRVIDEO

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<3, store = true; end;


% Check is image is already loaded in buffer
img = this.bufferRead( index );
if ~isempty(img), return; end

% Get image from avi file
img = this.readFromAvi( index );
if ~isempty(img)
    img = CRImage(img, index, this.depth, this.format);
end

if this.input && this.output && ~isempty(img)
    this.saveImage(img,index);
elseif store, 
    this.bufferWrite( img );
end