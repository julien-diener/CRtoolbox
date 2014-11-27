function path = formatPath( varargin )
%     path = formatPath( path_arguments )
% or  path = formatPath( path_arguments, filesep )
%
% Format the list of arguments (single argument is allowed) to a specific
% format. The following action are done
%  - Replace '\' and '/' by given 'filesep' (by default, use system filesep)
%  - remove directory '.'
%  - manage directory '..': remove previous directory if it is provided
%  - if the 1st directory is a microsoft device (ex: 'c:') convert it to
%    lower cases
% 
% formatPath is similar to 'fullfile' but single argument is allowed, it
% manage directories '.' and '..', and the file separation character
% (filesep) can be chosen. 
% 
% See also: fullfile

% Author: Julien diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

%%! to remove
%if nargin==0
%    error('formatPath requires at least one input');
%end

%%! is it usefull
% expand all input cells
%i=1;
%while i<=length(varargin)
%    if iscell(varargin{i})
%        varargin = [varargin(1:i-1) varargin{i} varargin(i+1:end)];
%    else
%        i = i+1;
%    end
%end

%%! to remove => no error, just strange behavior
% assert all input are char
%if ~all(cellfun(@ischar,varargin))
%    error('formatPath requires all inputs to be of class char');
%end

% use given file separator if given, or default one
if isequal(varargin{end},'/') || isequal(varargin{end},'\') %quicker than: ismember(varargin{end},{'/','\'})
    fsep  = varargin{end};
    varargin = varargin(1:end-1);
else
    fsep = filesep;
end

path  = [varargin ; repmat({fsep},size(varargin))];
path  = [ path{:} ];
parse = regexp(path,'[^\\/]+','match');
if isempty(parse)
    if isempty([varargin{:}]), path = ''; end
    return;
end

if ~isempty(path) && path(1)=='/'
    path = '/';   % unix full path
else
    path = '';
    if parse{1}(end)==':' && length(parse{1})==2
        parse{1} = lower(parse{1});    % windows full path
    end
end

% remove . and manage ..
i=1;
while i<=length(parse)
    if i>1
        if strcmp(parse{i}, '.')
            parse(i) = [];
        elseif strcmp(parse{i}, '..')
            parse([i-1,i]) = [];
            i = i-1;
        else
            i = i+1;
        end
    else
        i = i +1;
    end
end

parse = [parse ; repmat({fsep},size(parse))];
path  = [ path parse{1:end-1} ];

if isempty(varargin{end}), path = [ path fsep ]; end
