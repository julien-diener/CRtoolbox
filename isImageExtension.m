function [ isIt ] = isImageExtension( fileName )
% check if 'fileName' has extension of an image (to be saved with imwrite)
%   isIt = isImageExtension( fileName )

% Author: Julien diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

ext = find(fileName == '.');
if isempty(ext)
    isIt = false;
    return
end

ext  =  fileName((ext(end) + 1):end);
isIt = ~isempty(imformats(ext));

