function [ ] = crWarning( varargin )
% (1) crWarning(  msg,  var1, var2, ... ); 
% (2) crWarning( stack, ... ); 
% (3) crWarning( level, ... );
% (4) crWarning( stack, level, ... );
%
% Display a formated warning on the command line with message generated
% using sprintf( msg, var1, var2, ....);
%
% if a stack 'stack' (as returned by dbstack) is given, display the file
% name and line of the first stack elements.
% if an integer 'level' is provided, add this number of initial tab.

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


% manage input
stack = [];
level = 1;
if isstruct(varargin{1})
    stack = varargin{1};
    varargin(1) = [];
end
if isnumeric(varargin{1}) && isscalar(varargin{1})
    level = round(varargin{1});
    varargin(1) = [];
    if level<1, level = 1; end
end

tab = '   ';

% print header
fprintf( repmat(tab,1,level) );

% display header
if isempty(stack)
    stack = dbstack(1);
    if isempty(stack),  stack(1).file = '';    end
    fprintf('<a href = "error:%s,%d,1">Warning</a>: ', ...
             formatPath(which(stack(1).file)), stack(1).line);
else
    fprintf('<a href = "error:%s,%d,1">Warning (%s, line %d)</a>: ', ...
             formatPath(which(stack(1).file)), stack(1).line,...
             stack(1).file, stack(1).line);
end

% display message
fprintf([ varargin{1} '\n' ], varargin{2:end});
