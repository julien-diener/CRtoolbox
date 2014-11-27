function loadFile( this, paramFile, eval )
%   param.loadScript( param_file, eval=true )
% 
% Load the parameters in file 'param_file'. 
%
% Main principle of CRParam file:
% -------------------------------
% 1) To add a parameter, simply write: "param_name = value"
% 2) Parameters can have a hierarchical structure:
%    - to add a new structure (or sub-structure), write "\nameOfStruct"
%    - and to end a (sub)structure, write:  \end
% 3) Inclusion of other parameter files can be done using:
%      \include path_to_file
%
% The parameter file is read one line at a time, thus only one action can
% be done in each line (parameter assignation, file inclusion, add or close
% (sub)structures).
% loadFile only reads the file, all parameters are charater arrays.
% If eval==true, call evalParam() to evaluate the loaded script.
%
% See also: CRParam, CRParam.evalParam, CRParam.printf

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


files = struct('fileName',{},'fid',{},'lineNumber',{});
iter  = this.iterator{end};

openFile(paramFile);    % see end of file
line = getLine();       % see end of file 
while iscell(line)
    
    % ----------- keywords and structure hierarchy -----------
    if(line{1}(1)=='\')
        line{1} = line{1}(2:end);
        if isempty(line{1}), line{1} = 'end'; end
        
        switch lower(line{1})
            case 'include'
                % Include a CRParam file
                if length(line) < 2
                    makeError('''\include'' without a file name')
                elseif isempty(strmatch(line{2},{files(:).fileName},'exact'))
                    % check first if the called file is in the same
                    % directory as the calling CRParam file
                    paramDir = files(find([files(:).fid],1,'last'));
                    paramDir = fileparts(paramDir.fileName);
                    if exist([paramDir '/' line{2}],'file')
                        file = [paramDir '/' line{2}];
                    else
                        file = line{2};
                    end
                    openFile( file );
                end
                
            case 'end'
                % ending a sub-structure (or template structure)
                iter = this.popIterator();
                
            otherwise
                % starting a new parameters sub-structure

                % In case new Strucure is a template structure
                isTemplate = strcmpi(line{1},'template');
                if isTemplate
                    line(1) = [];
                end

                varName = checkVarName(line{1});
                if length(line)>2 && strcmp(line{2},'<')
                    subclass = exist(line{3},'file')==2;
                    if subclass
                        constructor = str2func(line{3});
                        if ~isa(constructor(),'CRParam')
                            subclass = false;
                        else
                            this.set(varName,constructor());
                        end
                    end
                    if ~subclass
                        crWarning('Unrocognized CRParam subclass ''%s''',line{3});
                    end
                    line(2:3) = [];
                end
                iter = this.pushIterator(varName);

                if isTemplate
                    iter.data.template = true;    
                end
                if length(line)>2 && strcmp(line{2},':')
                    iter.data.overload = line{3}; 
                end
        end
    % ---------- end of start/end blocks ---------


    else
        % --- assignement of variables ---
        push = 0;
        while length(line)>3
            line{1} = checkVarName(line{1});
            iter = this.pushIterator(line{1});
            line = line(2:end);
            push = push+1;
        end
        
        line{1} = checkVarName(line{1});
        if strcmp(line{2},'=')
            % normal assignment
            iter.data.(line{1}) = line{3};
        elseif strcmp(line{2},':')
            % assign an existing paramemeter (':')
            % make a sub-structure with field 'overload'
            iter = this.pushIterator(line{1});
            iter.data.overload = line{3};
            iter = this.popIterator();
        end
        
        for i=1:push, iter = this.popIterator(); end
    end
    line = getLine();  % see below for function getLine
end
    

% call evalParam if asked to
if nargin<3 || eval
    this.evalParam();  
end



% ----------------------- sub-functions -----------------------
    % check if 'name' is a correct variable name 
function name = checkVarName(name)
    if ~isvarname(name)
        newName = genvarname(name);
        crWarning('Invalid name ''%s'', renamed by ''%s''',name,newName);
        name = newName;
    end
end
    
% ----------------------- getLine( ) -----------------------
function line = getLine()
% get next line in last opened file of list 'files'
% return the line parsed (without spaces)

    commentChar = '%';

    file_index = find([files(:).fid],1,'last');

    if isempty(file_index)
        line =  [];
        return,
    end;

    line = fgetl(files(file_index).fid);

    % if end of file, 'pop' back to previous file in file list
    if ~ischar(line),
        fclose(files(file_index).fid);
        files(file_index).fid = 0;
        line = getLine();
        return;
    end;

    files(file_index).lineNumber = files(file_index).lineNumber +1;

    % Remove comments
    c = strfind(line,commentChar);
    if ~isempty(c),   line = line(1:c-1);   end
    
    % detect empty line
    line = strtrim(line);
    if isempty(line)
        line = getLine();
        return,
    end;

    % Parse line
    % separate template and include keywork
    if strfind(line,'\template')==1
        parsedLineA{1} = '\template';
        line = strtrim(line(10:end));
    elseif strfind(line,'\include')==1
        parsedLineA{1} = '\include';
        line = strtrim(line( 9:end));
    else
        parsedLineA = {};
    end
    
    % parse variable assignement
    % = means =
    % : means inherite fields of given structure
    % < means inherite class (ex CRData)
    line = {line};
    L = line{end};
    k = [strfind(L,'<') strfind(L,'=') strfind(L,':')];
    if ~isempty(k)
        if L(k(1))~='<',    k = k(1);
        elseif length(k)>1, k(2) = k(2)-k(1)-1;
        end
        for j=1:min(2,length(k))
            K = k(j);
            L = line{end};
            L = strtrim({L(1:K-1) L(K) L(K+1:end)});
            line = [line(1:end-1) L];
            line(cellfun(@isempty,line)) = [];
            
        end
    end
    if length(line)==1
        line = [line '=' {''}];
    end

    % parse sub-structure field access (eg str.field=...)
    % and concatenate all parsed elements
    line = [parsedLineA, regexp(line{1},'[^.]*','match'), line(2:end)];
end
    

% ----- open script file -----
function openFile(fileName)
    % assess existence of file
    if ~exist(fileName,'file')
        makeError('CRParam file ''%s'' not found',fileName);
        return;
    end

    % open file 'fileName' 
    file  = fopen(fileName);
    if file == -1
        [fPath,fName,fExt] = fileparts(fileName);
        fName = [fName fExt];
        makeError('Error while opening script file ''%s''',fName);
        return;                  
    end;

    % append new file to the list
    files(end+1).fileName   = fileName;
    files(end)  .fid        = file;
    files(end)  .lineNumber = 0;
end

function makeError(msg,varargin)
    msg = sprintf(msg,varargin{:});
    file = files(find([files(:).fid],1,'last'));
    crWarning('%s (line %d of file %s)',msg,file.lineNumber,file.fileName);
end


end % end of main function
