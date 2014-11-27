function [ this ] = makeInput( this, fileName, maxLength, startImage )
% videoAvi.makeInput( fileName, maxLength=0, startImage=1 )
%
% Configure the input of 'video'. 
% 
% Input:
%  - fileName:   Full path to the video file
%  - maxLength:  Enforce a maximum number of images (0 means no restriction)
%  - startImage: Enforce a shifted start
%
% Output:
%    'video.input' is 'true' if no error occurs (and length(video)>0). 
%    Otherwise 'video.format' stores the error message.
%
% See also: CRVIDEO, CRVIDEOAVI, CRVIDEO.MAKEOUTPUT

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


this.input = false;

if nargin<3, maxLength  = 0; end;
if nargin<4, startImage = 1; end;

try this.fileInfo = aviinfo(fileName);
catch
    this.last   = -2;  % flag indicating an error
    this.format = 'Error while loading video, cannot open file';
    return;
end


% fill fields 'inputPath' and 'inputFile'
[this.inputPath this.inputFile] = this.parseImageName( fileName, '.' );


% fill field 'first'
this.first = startImage;

% fill field 'last' (if maxLength==0, last is the last image in sequence)
this.setLength(maxLength); 

this.input = true;
