function [ img ] = getFrame( this, index, store)
% image = video.getFrame( imageIndex, store=true )
%
% Output:
% Image of 'video' with index 'imageIndex' (or [], if it does not exist) 
% If 'store' is set, save loaded image in memory for quicker future access
%
% see also: CRVIDEO

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<3, store = true; end;


% Check if image is already loaded in buffer
img = this.bufferRead( index );
if ~isempty(img), return; end


% Get image (if it exist)
img = CRImage(this.imageFileName(index,'exist'), index, this.depth, this.format);

if this.input && this.output && ~isempty(img)
    this.saveImage(img,index);
elseif store, 
    this.bufferWrite( img );
end