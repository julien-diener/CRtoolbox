function [dir, fileStart, digit, fileEnd] = parseImageName( this, file, defaultDir )
% (1) [dir, fileStart, digit, fileEnd] = video.parseImageName( file, defaultDir='.' )
% (2) [dir, fileName, extension]       = video.parseImageName( file, defaultDir='.' )
% (3) [dir, fileName]                  = video.parseImageName( file, defaultDir='.' )
%
% Case (1), decompose 'file' in:
%  - dir:       directory (if not provided, return defaultDir)
%  - fileStart: part of fileName before the last numbering found in it.
%  - digit:     the number of file.
%  - fileEnd:   part of fileName after it.
%
% Case (2), it does the same as fileparts(), but enforce a default directory
% Case (3), same as (2) but extension is included in 'fileName'

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<2, defaultDir = '.'; end

[dir, fileName, ext] = fileparts( file );

if isempty(dir), dir = defaultDir; end

if nargout<4
    if nargout==2, fileName = [fileName ext]; end
    fileStart = fileName;
    return; 
end;

% find start (s) and end (e) of the numbers found in 'inputFile' string
s = regexp(fileName,'\d+');
e = regexp(fileName,'\d+','end');

if(isempty(s))
    fileStart = fileName;
    digit     = '';
    fileEnd   = ext;
else
    fileStart = fileName(1:s(end)-1);
    digit     = fileName(s(end):e(end));
    fileEnd   = [fileName(e(end)+1:end) ext];
end;

