%
% class CRParam manages hierarchical structure of parameters.
%
%******************************* Warning **********************************
%*             The class CRParam inherites from class handle.             *
%*                Thus, a copy such as   param2 = param1;                 *
%*  is only a reference: all changes made to param2, apply to param1 !!!  *
%*  To make an independant copy of a CRParam object, use method 'copy'    *
%**************************************************************************
%
% Constructor :
% -------------
%  (1)  param = CRParam( file_name, eval=true )
%  (2)  param = CRParam( CRParam_object )
%  (3)  param = CRParam( param_structure )
%  (4)  param = CRParam( param_cell )
%  (5)  param = CRParam( some_path )
%  (6)  param = CRParam( any_number )
%
% (1) Load parameter file 'file_name'. If eval is true, evaluate loaded
%     value for macros and numeric value (see help of evalParam.m)
% (2) Make an idenpendent copy of CRParam_object (convert sub-classes to CRParam)
% (3) Convert a (scalar) structure of parameters to a CRParam object
% (4) 'param_cell' is a cell array containing pairs ('var_name','value')
%     For all pairs, set the field 'var_name' to 'value'
%     ex:  p = CRParam({'question', 'What is the answer to life...?', 'answer', 42})
% (5) Open a dialog window to select a file manually, starting at some_path
% (6) same as  CRParam( pwd )
%
%
% Reading / Writing from files:  (see the help of respective functions)
% -----------------------------
%  - param.loadFile(file_name,eval=true)  
%                              Read 'file_name'. Call evalParam if 'eval'
%                              is true. (loadFile is called by constructor (1))
%  - param.evalParam()         evaluate loaded parameters (evaluate value & macros)
%  - param.printf(file,option) Save parameters to 'file'
%
% CRParam has a specific way to write and read parameters to file (see any
% *.param file of CR toolbox for an example). It allows: 
%   1) inclusion of other file  (command \include, see help CRParam/loadFile) 
%   2) inheritance and macros   (script variables, see help CRParam/evalParam)
%   3) matlab evaluation to recognizes numerical value (see CRParam/evalParam)
%
%
% Accessing parameters:  (estimated where iterator points to, see below)
% ---------------------
%  - get(param, 'var_name')          retrieve variable 'var_name'
%  - get(param, 'var_name', default) same as above, but return 'default'
%                                    if 'var_name' does not exist
% 
%  - fieldnames(param)               list all stored parameters
%  - isfield(param, 'var_name')      return true if 'var_name' exist
%  - rmfield(param, 'var_name')      remove field 'var_name'
%  - merge(param, param2, overload)  merge param2 inside param.  
%  - length(this)                    Number of parameters
%  - isempty(this)                   true if no parameters are stored
%
%  - printf(file, permission)        write parameters to file or display
%                                    the whole structure on the command line
%
% Other methods:
% --------------
%  - p = copy( param_obj )           Make an independant copy of param_obj
%
% Iterator:
% ---------
% CRParam has an "iterator" which can point at any position in the
% hierarchy of parameters (as it can be hierarchical). This can be done by
% 'pushing' and 'poping' throught the parameters structure. The related
% functions are (all return the CRParam pointed by the iterator):
%  - param.pushIterator('name')  Go down and point to 'param.name'. It
%                                automatically create an empty parameter if
%                                'name' does not exist. 
%  - param.popIterator()         Go back to higher level
%  - param.resetIterator()       Make Iterator point to the structure root
%  - param.getIterator()         return the current iterator
%
%***All methods of class CRParam are evaluated where the iterator points***
%
% Discussion:
% -----------
% Most of the time it can be used as a matlab structure. However:
%  - array of CRParam is not allowed (i.e. my_param(2) don't work). 
%  - Due to some limitation of matlab subsref function, it is not possible
%    to generate coma-separeted list from a field storing a cell array: 
%       e.g  my_param.my_cell = {'answer_to_life', 42};
%            my_param.my_cell{:} 
%                  -> returns only 'answer_to_life'
%
% See also: CRProject, CRData, CRParam.printf, CRParam.loadFile, CRParam.evalParam

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

classdef CRParam < handle

    properties
        data = struct();   % store the data of this CRParam
        iterator = NaN;    % pointer to sub-structure
    end
    methods 
        % ---------------     constructor     --------------- 
        function this = CRParam( argin, eval)
            this.resetIterator();
            
            if nargin==0 || isempty(argin)
                return;
            end

            switch class(argin)
                case 'char'   % load file or start GUI to select file
                    if nargin<2, eval = true; end
                    
                    if exist([argin '.param'],'file')
                        argin = [argin '.param'];
                    end
                    if     exist(argin,'dir'),  this.browseFile(argin,eval);
                    elseif exist(argin,'file'), this.loadFile  (argin,eval);
                    else                        error('File or directory ''%s'' does not exist.', argin);
                    end
                case 'struct' % append structure
                    if numel(argin)>1
                        error('Cannot make a CRParam from a structure array.'); 
                    end
                    field = fieldnames(argin);
                    for i=1:length(field)
                        subsasgn(this,substruct('.',field{i}),argin.(field{i}));
                    end
                case 'cell'   % load all pairs (var_name,value)
                    for i=1:2:length(argin)
                        subsasgn(this,substruct('.',argin{i}),argin{i+1});
                    end
                otherwise
                    if isa(argin,'CRParam') % independent copy of another CRParam
                        this.merge(argin);
                    else
                        error(['Cannot create CRParam from a ' class(argin) '.']);
                    end
            end
        end
        
        % ask user which param file, then load it
        function browseFile(this, path, eval)
            [f{1:2}] = uigetfile(...
                {'*.param', 'CRParameter'; '*.*', 'All file'}, ...
                'Select parameter file', path);
            if ischar(f{1})
                this.loadFile([f{[2 1]}], eval);
            end
        end
         
        % --------------- access to field names --------------- 
        function names = fieldnames(this)
            names = fieldnames(this.iterator{end}.data);
        end
        function isIt = isfield(this, fieldName)
            isIt = isfield(this.iterator{end}.data,fieldName);
        end
        function rmfield(this,var_name)
            if isfield(this,var_name)
                this.iterator{end}.data = rmfield(this.iterator{end}.data,var_name);
            end
        end
        function l = length(this)
            l = length(fieldnames(this.iterator{end}.data));
        end
        function e = isempty(this)
            e = isempty(fieldnames(this.iterator{end}.data));
        end

        % --------------- manage iterator ---------------
        function resetIterator( this )
            this.iterator = {this};
        end
        function current = pushIterator( this, fieldName )
            it = this.iterator{end};
            if ~isfield(it,fieldName) || isempty(it.data.(fieldName))
                    it.data.(fieldName) = CRParam();
            elseif ~isa(it.data.(fieldName),'CRParam') 
                    crWarning('''%s'' was not a CRParam, it has been converted and data has been saved in subfield ''%s''',fieldName,fieldName);
                    data = it.data.(fieldName);
                    it.data.(fieldName) = [];
                    it.data.(fieldName) = CRParam({fieldName,data});
            end
            this.iterator{end+1} = it.data.(fieldName);
            if nargout, current  = this.iterator{end}; end
        end
        function [current, ok] = popIterator( this )
            if length(this.iterator)>1
                this.iterator(end) = [];
                ok = true;
            else
                ok = false;
            end
            current = this.iterator{end};
        end
        function it = getIterator(this)
            it = this.iterator{end};
        end

        % --------------- data access and assignment --------------- 
            % get field 'fieldName' if it exist
            % otherwise, return default (if provided)
        function value = get(this, fieldName, default)
            if isfield(this, fieldName), value = this.iterator{end}.data.(fieldName);
            elseif nargin>2,             value = default;
            else   error('Reference to non-existent field ''%s''',fieldName);
            end
        end
            % set field 'fieldName' to 'value'. This is the same as a dot
            % assignment, slightly quicker but not really useful.
        function this = set(this, fieldName, value)
            if isstruct(value) && numel(value)==1
                value = CRParam(value);
            end
            this.iterator{end}.data.(fieldName) = value;
        end
            % return field 'fieldName' if it exist
            % otherwise, set it to 'value' or empty CRParam if not provided
        function value = assert(this, fieldName, value)
            if ~isfield(this, fieldName)
                if nargin<3, value = CRParam(); end
                this.iterator{end}.data.(fieldName) = value;
            else
                value = this.iterator{end}.data.(fieldName);
            end
        end
            % convert this CRParam to a structure
            % !!! this CRParam should not contain "ancestor-loop" !!!
        function str = convert2struct( this )
            str   = this.data;
            field = fieldnames(str);
            for i=1:numel(field)
                if isa(str.(field{i}),'CRParam')
                    str.(field{i}) = str.(field{i}).convert2struct();
                end
            end
        end
            % make an independant copy of this object
            %%! copy: correct online documentation
        function cp = copy( this )
            constructor = str2func(class(this));
            cp = constructor(this);
        end
        
            %overload subsref methods
        function [varargout] = subsref(this,s)
%             try
            if strcmp(s(1).type,'.')
                if strmatch(s(1).subs,{'pushIterator','popIterator'},'exact')
                     it = this;
                else it = this.iterator{end};
                end
                if isfield(it,s(1).subs)
                    it = it.data.(s(1).subs); 
                    s(1) = [];
                end
            elseif strcmp(s(1).type,'()')
                it = this.iterator{end};
                if  length(it)<s(1).subs{1}
                    error('CRParan:subsref','Index exceeds the number of field of this CRParam object.');
                elseif length(s(1).subs)~=1 || numel(s(1).subs{1})~=1 || s(1).subs{1}<1
                    error('CRParan:subsref','CRParam indices must be scalar integers greater than 0.');
                else
                    field = fieldnames(it);
                    it = it.data.(field{s(1).subs{1}});
                    s(1) = [];
                end
            else
                % do not manage CRParam array or cell array
                error('CRParan:subsref','Invalid cell contents reference from CRParam objects');
            end
            
            if isequal(it,this), [varargout{1:nargout}] = builtin('subsref', it, s);
            elseif ~isempty(s),  [varargout{1:nargout}] = subsref(it,s);
            else                  varargout{1}          = it;
            end
%             catch
%                 rethrow(lasterror);
%             end
        end
            %overload subsasgn methods
        function this = subsasgn(this, s, B)
%             try
            if strcmp(s(1).type,'.')
                it = this.iterator{end};
                if isstruct(B) && numel(B)==1, B = CRParam(B); end
                if length(s)>1 
                    if ~isfield(it,s(1).subs)
                        if strcmp(s(2).type,'.'), it.data.(s(1).subs) = CRParam();
                        else                      it.data.(s(1).subs) = [];
                        end
                    end
                    it.data.(s(1).subs) = subsasgn(it.data.(s(1).subs),s(2:end),B);
                else
                    it.data.(s(1).subs) = B;
                end
            elseif strcmp(s(1).type,'()')
                it = this.iterator{end};
                if length(s(1).subs)~=1 || numel(s(1).subs{1})~=1 || length(it)<s(1).subs{1}
                    error('Index exceeds the number of field of this CRParam.');
                elseif  s(1).subs{1}<1
                    error('CRParam indices must be real positive integers.');
                else
                    field = fieldnames(it.data);
                    if length(s)>1
                        it.data.(field{s(1).subs{1}}) = subsasgn(it.data.(field{s(1).subs{1}}),s(2:end),B);
                    else
                        it.data.(field{s(1).subs{1}}) = B;
                    end
                end
            else
                error('CRParam array or cell array is not allowed');
            end
%             catch error(lasterror);
%             end
        end

        % --------------- display function ---------------
        function display(this)
            it = this.iterator{end};
            if ~isempty(it), 
                fprintf('%s:  class %s\n', inputname(1), class(it));
                disp(it.data); 
            else
                disp(it);
            end
        end
        function disp(this)
            it = this.iterator{end};
            if isempty(it), 
                fprintf('Empty %s object\n',class(it));
            elseif length(this.iterator)>1
                disp(it);
            else
                display(this.data);
            end
        end
        
    end
end