function evalParam( this, macros )
%      param.evalParam( macros=CRDefault() )
%
% Parse recursively all fields of loaded script:
%  - 1st, manage inheritance of all structures
%  - 2nd, for all fields:
%       * find and replace all macros (ex: $variable_name$)
%       * try to evaluate field value (ex: if it is numerical)
%       * manage parameter assignment (if field start by ':')
%
% Inheritance:
%   Any structure can inherite from an other, or a CRParam file:
%     \some_structure : inherited_structure  (or path to a file)
%         .... (parameters and sub-structure)
%     \end
%
% Macros:
%   Macros are simple type of variables that can be used in a CRParam file.
%   Their value should be character strings or numeric. 
% 
%   Macro can either reference to a field of input arguments 'macros' or to
%   a "neighboring" field (i.e in the same structure)
%
%   Input arguments 'macros' must be a CRParam structure containing only
%   fields (no substructure). If macros is not given, CRDefault parameters
%   (found in 'CRDefault.param') is used.
%
% Evaluation:
%   if the name of parameters are not recognized by 'exist' (exception is
%   made for 'true', 'false' and directories), the parameters value is 
%   evaluated:
%   * Use 'eval' if the value is an array, a cell array or a number.
%   * formatPath of directories ending or not with a file name
%   If a call to a matlab function is wanted, add '()':
%     "param_name = CRVideo()"  adds an empty CRVideo as 'param_name'
%
% See also: CRParam, CRParam.loadFile, CRParam.printf

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


if nargin<2, macros = CRDefault(); end

checkInheritance();   % check inheritance   recursively (see below)
evaluateStructure();  % evaluate all fields recursively (see below)
removeTemplate();     % remove template structures recursively


% check and apply all inheritance recursively
% -------------------------------------------
function checkInheritance( )
    fields = fieldnames( this );
    for i=1:length(fields)
        field = get(this,fields{i});
        
        if ~isa(field,'CRParam' ) || get(field,'template',false)
            continue;
        end
        
        overload = get(field,'overload',[]);
        while ~isempty(overload) && ischar(field.data.overload)
            overload = inherite(field, overload);
        end

        this.pushIterator( fields{i} )
        checkInheritance();
        this.popIterator();
    end
end

% merge structure or CRParam file 'this.iterator{end}.(field).overload'
function next = inherite( field, overload )
    parent = evalString( overload );
    
    if ~isa(parent,'CRParam')
        if isfield(this.iterator{end}.data,parent) && isa(this.iterator{end}.data.(parent),'CRParam')
            parent = this.iterator{end}.data.(parent);
        elseif isfield(this.data,parent) && isa(this.data.(parent),'CRParam')
            parent = this.data.(parent);
        elseif exist(parent,'file')==2 && ~strncmp(fliplr(which(parent)),'m.',2)
            parent = CRParam(parent,false);
        end
    end

    if isa(parent,'CRParam')
        % if parent is of a subclass of field class
        % convert field to the class of parent
%         if ~strcmp(class(parent),class(field)) && isa(parent,class(field))
%             constructor = str2func(class(parent));
%             field = constructor(field);
%         end

        pf = fieldnames(parent);
        ff = setdiff(fieldnames(field),pf);
        field.merge(parent);
        field.data = orderfields(field.data,{pf{:},ff{:}});

        if isfield(parent,'template')
            field.rmfield('template');
            field.rmfield('overload');
        end
        next = get(parent,'overload',[]);
    else
        crWarning('Inheritance: parameter structure ''%s'' not found',parent);
        field.data.overload = [];
        next = [];
    end
end


% evaluate all fields recursively
% -------------------------------
function evaluateStructure( )
    if get(this,'template',false), return; end
    
    fields = fieldnames( this );
    for i=1:length(fields)
        field = get(this,fields{i});
        if isa(field, 'CRParam' )
            % if iterator point to a structure, iterate recursively
            this.pushIterator( fields{i} )
            evaluateStructure();
            this.popIterator();
        else
            % otherwise evaluate the field
            value = evalString( field );
            this.iterator{end}.data.(fields{i}) = value;

%             if isa(value,'CRParam')
%                 this.pushIterator(fields{i});
%                 this.evalParam();
%                 this.popIterator();
%             end
        end
    end
end

% evaluate string 'value' at current iterator position
function value = evalString( value )
    if isempty(value) || ~ischar(value)
        return
    end

    % ------------------------ manage macros ------------------------
    % replace them by the appropriate value: either a CRDefault parameter
    % or a field at the same level of 'this.data' (checked in this order)
    expression = '\$[^\(\$]*\$';
    while ischar(value) && ~isempty(regexp(value,expression,'once'))
        t1 = regexp(value,expression,'once');
        t2 = regexp(value,expression,'once','end');

        macro = sscanf(value(t1+1:t2-1),'%s');

        v = get(macros,macro,[]);
        if isempty(v), v = get(this, macro,[]); end
        if isempty(v),
            % not found, remove the '$'
            crWarning('variable ''%s'' not found',value(t1:t2));
            value([t1 t2]) = '';
        else
            try
                if ~ischar(v), v = array2str(v); end
                value = [value(1:(t1-1)) v value((t2+1):end)];
            catch
                crWarning('Failure while replacing macro ''%s''',value(t1:t2));
                value([t1 t2]) = '';
            end
        end
    end;

    % ------------- try to evaluate then store variable -------------
    % Try to evaluate string stored in 'value' (typically numericals
    % and arrays. They should not be recognized by 'exist' but for
    % 'true' and 'false' (which are recognized as functions)
    if ~exist(value)
        try 
            value = eval(value);   
        catch
        end
    elseif strcmp(value,'true'),  value = true;
    elseif strcmp(value,'false'), value = false;
    else
        value = formatPath(value,'/');
    end

    % ---------- check if it is a structure-assignment ----------
    % i.e "paramName : parent" (and value is a string starting by ':')
    % then, convert field to a CRParam with field 'overload' set
%     if ~isempty(value) && isequal(value(1),':')
%         value = CRParam();
%         value.overload = value(2:end);
%     end
end

function removeTemplate()
    fields = fieldnames( this );
    for i=1:length(fields)
        field = get(this,fields{i});
        if ~isa(field,'CRParam')
            continue;
        elseif isfield(field, 'template' )
            this.rmfield(fields{i});
        else 
            this.pushIterator( fields{i} )
            removeTemplate();
            this.popIterator();
        end
    end
end

end
