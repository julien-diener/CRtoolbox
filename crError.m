function [ ] = crError( varargin )
% (1) crError(  msg,  var1, var2, ... ); 
% (2) crError( stack, ... ); 
% (3) crError( level, ... );
% (4) crError( stack, level, ... );
%
% Display a formated error message on the command line with message
% generated using sprintf( msg, var1, var2, ....)
% It does not stop m-file execution.
%
% If a debug stack (as returned by dbstack) is provided, display the stack.
% If an integer 'level' is provided, add this number of initial tab.

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

% manage input
if isstruct(varargin{1})
    stack = varargin{1};
    varargin(1) = [];
else
    stack = [];
end

if isnumeric(varargin{1}) && isscalar(varargin{1})
    level = round(varargin{1});
    varargin(1) = [];
    if level<1, level = 1; end
else
    level = 1;
end

tab = '   ';
header = repmat(tab,1,level);

% print header
%fprintf(2, repmat(tab,1,level) );

% display header
if isempty(stack)
    st = dbstack(1);
    if isempty(st),  st(1).file = '';    end
    msg = sprintf('%s<a href = "error:%s,%d,1">Error</a>: ',header,...
             formatPath(which(st(1).file),'/'), st(1).line);
else
    msg = sprintf('%s<a href = "error:%s,%d,1">Error (%s, line %d)</a>: ',header,...
             formatPath(which(stack(1).file),'/'), stack(1).line,...
             formatPath(      stack(1).file ,'/'), stack(1).line);
end
fprintf(2,msg);

% display message 
% display only last message line
msg = regexp(varargin{1},'.+','match','dotexceptnewline');
fprintf(2,[msg{end} '\n'], varargin{2:end});

% display stack
if ~isempty(stack)
    for i=2:length(stack)
        msg = sprintf('%s    In <a href = "error:%s,%d,1">%s, line %d</a>\n',header, ...
                 formatPath(which(stack(i).file),'/'), stack(i).line,...
                 formatPath(      stack(i).file ,'/'), stack(i).line);
        fprintf(2,msg);
    end
end

