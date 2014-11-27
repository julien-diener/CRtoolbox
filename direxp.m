function [ fileList ] = direxp( directory, expression )
% List all file in 'directory' that match 'expression' using regexp
%
% fileList = direxp( directory , expression )

% Author: Julien diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if isempty(directory), directory = '.'; end;
fileList = dir(directory);
fileList = {fileList(:).name};

fileList = regexp(fileList,['^' expression '$'],'match','once');
fileList(cellfun(@isempty,fileList)) = [];
