function [ fileName ] = imageFileName( this, index, varargin )
% Return the file name of the corresponding video frame.
%   fileName = video.imageFileName( index, parameters=[] )
%
% Any or several of these parameters can be added:
%  - 'input':  check only input  file (if it is an input  video)
%  - 'output': check only output file (if it is an output video)
%  - 'exist':  check if the file exist, return '' otherwise

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

checkInput  = true;
checkOutput = true;
checkExist  = false;
fileName = '';

for i=1:(nargin-2);
    switch lower(varargin{i})
        case 'input',  checkOutput = false;
        case 'output', checkInput  = false;
        case 'exist',  checkExist  = true;
    end
end

% from output
if this.output && checkOutput
    fileName = formatPath(this.outputPath, ...
        sprintf(this.outputFile,index+this.outputFirst-1),'/');
    if checkExist && ~exist(fileName,'file'),
        fileName = '';
    else
        return
    end
end

% from input
if this.input && checkInput && index <= length(this)
    fileName = formatPath(this.inputPath,this.inputFile{index+this.first -1},'/');
    if checkExist && ~exist(fileName,'file'),
        fileName = '';
    end
end


