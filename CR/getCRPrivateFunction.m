function handle = getCRPrivateFunction( function_name )
% handle = getCRPrivateFunction( function_name );
%
% to display help of the returned function, do:
%   help(['private/' func2str(handle)])

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if exist(function_name,'file')==2
    handle = str2func( function_name );
else
    error('function ''%s'' does not exist', function_name);
end