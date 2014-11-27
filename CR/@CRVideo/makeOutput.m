function [ vid ] = makeOutput( this, fileName )
% (1) video.makeOutput(  fileName   )
% (2) video.makeOutput( 'fromInput' )
%
% Configure 'video' for writing. 
% 
% Input:
%  - fileName: (1) Full path to the first image of the sequence or the
%                  image file writen in a sprintf format (ex: img_%04d.mat).
%              (2) 'fromInput': convert input 'video' to output using
%                  'video.inputPath' and 'video.inputFile{1}'.
%
% Output:
%   Set output parameters of 'video' ('video.output' = true if no error occurs)
%
% *** Warning: the behaviour of case (2) is not garanty ***
%
% See also: CRVIDEO, CRVIDEOAVI, CRVIDEO.MAKEINPUT


% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

this.output = false;
default = CRVideo();

if strcmpi(fileName,'fromInput') && this.input
	fileName = formatPath(this.inputPath, this.inputFile{1});
end

[this.outputPath, this.outputFile, num, ext] = this.parseImageName( fileName,default.outputPath );

% enforce file separation character to be '/'
this.outputPath = formatPath(this.outputPath,'/');

if isempty(num), num = '0000'; this.outputFile = [this.outputFile '_']; end
if isempty(ext), ext = '.mat'; end

% convert name to a sprintf format
this.outputFile  = sprintf('%s%%0%dd%s', this.outputFile, length(num), ext);
this.outputFirst = str2double(num);

this.output = ~(isempty(this.outputPath) | isempty(this.outputFile));

