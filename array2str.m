function line = array2str( var, incell )
%  str = array2str( array )
%
% convert any 2D array to a string. It convert 2D cell array as well if it
% contains only 2D array and cell array too.
% if 'array' has more than 2 dimensions, it converts the first 2 dimensions only:
%     array2str( var ) is equivalent to array2str( var(:,:,1) )

% Author: Julien diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

% Note: this function has a 'incell' option only used for recursive call.

% manage input argument
if nargin<1, error('No input arguments');   end  % no input argument
if nargin<2, incell = false;                end  % default: incell = false
if isempty(var), var = '';                  end  % empty argument
if ndims(var)>2, var = var(:,:,1);          end  % more than 2D

% convert input to charater string
line = '';
if iscell(var)
    for i=1:size(var,1)
        if i==1,  line = cat(2,line,'{ ');
        else      line = cat(2,line,'; ');
        end
        for j=1:size(var,2)
            line = cat(2,line,array2str(var{i,j}, true));
        end
    end
    line = [ line '} '];
elseif ischar(var)
    % if value is a file or a directory, replace '\' by '/'
    % (useful only under windows)
    if exist(var,'file') || exist(var,'dir')
        var = regexprep( var, '\\', '/');
    else
        var = regexprep( var, '\\', '\\\\');
    end
    if incell, line = [ line ''''  ]; end
    line = [ line var ];
    if incell, line = [ line ''' ' ]; end
elseif isnumeric(var)
    line = [ line mat2str(var) ' ' ];
elseif  islogical(var)
    var  = 1*var; % convert to double
    line = [ line mat2str(var) ' ' ];
else
    line = [ line array2str(['[' class(var) ' object]'], incell) ];
end
