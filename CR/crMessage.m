function [ ] = crMessage( level, varargin )
% (1) crMessage( level=1, msg, var1, var2, ... ); 
% (2) crMessage( level=1 );
% (3) crMessage( file_id )
%
% case (1)
% msg is a formated text such as used by fprintf with parameters var1, var2, ...
% level is the number of initial tab to add in front of the message.
% If level is 0, don't flush the line. It basically the same a fprintf.
%
% case (2)
% display only the start of the formated text, without fluching the line.
%
% case (3)
% file_id is a cell array containing one fid as returned by fopen, which is
% ready for writing.
% Redirect all further message to this file.
% do crMessage({'reset'}) to set it back to usual

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

persistent fid;
if isempty(fid), fid = 1; end

if nargin && iscell(level)
    if ~isnumeric(level{1})
        try fclose(fid); end
        fid = 1;
    else
        fid = level{1};
    end
    return
end

if nargin==0
    level = 1;
    isMessage = 0;
elseif ischar(level) 
    varargin = {level, varargin{:}};
    level = 1;
    isMessage = nargin>0;
else
    isMessage = nargin>1;
end


tab = '   ';

% print header
fprintf(fid, repmat(tab,1,level));
if level, fprintf(fid, '|-> '); end


% print message
if isMessage
    fprintf(fid,varargin{1}, varargin{2:end});
    if level, fprintf(fid,'\n'); end
end

