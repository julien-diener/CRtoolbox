function [ this ] = makeInput( this, fileName, maxLength, startImage )
% (1) video.makeInput( fileName, maxLength=0, startImage=1 )
% (2) video.makeInput( 'updateInput' )
% (3) video.makeInput( 'fromOutput' )
%
% Configure 'video' for reading. 
% 
% Input case (1):
%  - fileName: either of these
%              (a) Full path to one image of the sequence.
%              (b) 'fromOutput': convert output 'video' to input using
%                  'video.outputPath' and 'video.outputFile'.
%              (c) 'updateInput': update 'video' starting from file 
%                  'video.inputFile{1}' in directory 'video.inputPath'.
%  - maxLength: Enforce a maximum number of images
%  - start:     If >0, sequence start at the startImage^th frame.
%               If==0, sequence start at image fileName.
%
% In case (2), use the input  parameters and update List of image files.
% In case (3), use the output parameters of 'video'. The image sequences
% must have already been saved (with method 'saveImage' of CRVideo).
%
% Output:
%   set input parameters of 'video' ('video.input' = true if no error occurs)
%
% See also: CRVIDEO, CRVIDEOAVI, CRVIDEO.MAKEOUTPUT

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

this.input = false;

if nargin<3, maxLength  = 0;  end;
if nargin<4, startImage = 1;  end;

if strcmpi(fileName,'fromOutput') && this.output
	fileName   = this.imageFileName(1);
    startImage = 0;
elseif strcmpi(fileName,'updateInput') && this.input
    out = this.output;
    this.output = false;
	fileName    = this.imageFileName(1);
    this.output = out;
else
    fileName = sprintf(formatPath(fileName,'/'),1); % in case fileName is given in sprintf format
end


% decompose fileName and fill field 'this.inputPath'
[this.inputPath nStart digit nEnd] = this.parseImageName( fileName, '.' );

if isempty(digit)
    crError('incorrect format of file name: no numbering');
    return;
end;

% fill field 'this.inputFile'  (use own tool 'direxp', see direxp.m)
%this.inputFile = sort(direxp(this.inputPath, [nStart '\d+' nEnd]));
this.inputFile = direxp(this.inputPath, [nStart '\d+' nEnd]);
if isempty(this.inputFile)
    crError('No image found');
    return;
end

indices = sscanf([this.inputFile{:}],[nStart '%d' nEnd]);
[indices, order] = sort(indices);
this.inputFile = this.inputFile(order);


% fill field 'first'
this.first = startImage;
if this.first==0
    n = strcmp(this.inputFile,[nStart digit nEnd]);
    n = find(n~=0);
    this.first = n(1);
end

% fill field 'last' (if maxLength==0, last is the last image in sequence)
this.setLength(maxLength); 

this.input = true;

% test if first image of sequence is loadable
img = CRImage(this.imageFileName(1));
if isempty(img)
    this.input = false;
    crError('Cannot open file or not an image');
    return;
end
