function p = crPath()
% Return the path of this file (which is the path to toolbox CR)

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

p = fileparts(mfilename('fullpath'));
p = formatPath(p,'/');
