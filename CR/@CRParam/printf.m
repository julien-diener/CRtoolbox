function printf( this, fileName, perm )
% Save CRParam 'parameter' in file 'file_name' or append to file 'fid'
%  (1)  parameter.printf( file_name, permission='update' )
%  (2)  parameter.printf( fid=1, current_depth=0 )
%
% Input:
%  - parameter:  CRParam to be saved
%
%  - file_name:  Name of the file where parameters should be saved
%  - permission:
%    'update'    load parameters in file 'file_name' and merge it inside
%                'parameters' before saving.
%    'overwrite' overwrite file
%
%  - fid:          file id of a file opened in write mode
%  - current_depth number of initial tabs that lines should start with.
%
% Note that using printf without argument displays the full structure tree
% on the command window. It can be used as a 'disp' to see the whole
% parameter tree.
%
% See also: CRParam, CRParam.loadFile, CRParam.evalParam

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<2, fileName = 1; end

if ~isnumeric(fileName)  % case (1)
    if nargin<3,                perm = 'update';    end
    if ~exist(fileName,'file'), perm = 'overwrite'; end

    % manage permission 'replace (and later, 'update')
    if strcmpi(perm,'update')
        p_old = CRParam(fileName, false);
        this.merge( p_old );
    end

    % open file for writing
    fid = fopen(fileName,'w');
    if fid<1,  error('Problem while opening file ''%s''',fileName);  end
    
    depth = 0;    % depth of current parameter structure
else
    fid = fileName;
    try   fprintf(fid,'');
    catch error('Provided file id is not valid');
    end
    
    if nargin>2, depth = perm;
    else         depth = 0;
    end
end


fields = fieldnames( this );
for i=1:length(fields)
    if strcmp(fields{i}, 'overload'), continue; end

    value = get(this,fields{i});

    if isa(value,'CRParam')
        if fid~=1, printLine(['\\' fields{i}], false);
        else       printLine([''  fields{i}], false);
        end
        % manage instance of CRParam subclass
        if ~strcmp(class(value),'CRParam')
            fprintf(fid,' < %s ',class(value));
        end

        % manage overload
        p = get(value,'overload', []);
        if ischar(p) && ~isempty(p), fprintf(fid,' : %s\n', p);
        else                         fprintf(fid,'\n');
        end

        % recursive call
        printf(this.data.(fields{i}),fid,depth+1);

        if fid~=1, printLine('\\end '); end
    else
        line = fields{i};
        if ischar(value) && ~isempty(value) && value(1)==':'
            line = cat(2,line,' : ',value(2:end));
        elseif ~isempty(value)
            line = cat(2, line, ' = ', array2str(value));
        end
        printLine(line);
    end
end

if ~isnumeric(fileName)
    fclose(fid);
end

function printLine(line, terminate_line)
    if nargin<2 || terminate_line 
        terminate_line = '\n';
    else
        terminate_line = '';
    end
    fprintf(fid, [repmat('    ',1,depth) line terminate_line]);
end

end % end of printf function
