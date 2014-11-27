%
% Class CRProject manages parameters of projects used by the CR toolbox.
%
% It inherites from class CRParam and has the same constructors. 
% A CRProject will always have the following fields:
%   - 'name':  Name of the project
%   - 'path':  Path of the project
%   - 'video': A CRData of the project input video
%   - 'tool':  Structure that contain the CRTools parameters of this project
%   - 'batch': cell array of tools to run in batch (the names of the tools)
%
% If not provided, default values are taken from '@CRProject/CRProject.param'. 
%
% - A CRProject has an associated project file 'path'/'name'.crproj 
% - Loading is done by the constructor or with (CRParam) function 'loadFile()'. 
%   Saving is done with function 'saveProject()'.
% - The parameter 'run' is a list of (the name of) all CRTool that function
%   run() should call (see below for suitable function to manage the list). 
% - For each CRTool, parameters can be provided as a sub-structure of 'tool'.
%   Otherwise, they are configured by the tool.
%
% Availaible methods (for CRProject 'proj'):
%  - proj.startGUI()               open the main user interface
%  - proj.fileName()               get project file name with full path
%  - proj.dataList()               return a cell array with the names of
%                                  all the project data.
%  - proj.isdata(dataname)         is true of data 'dataname' exist
%  - proj.getData(dataname=[])     retrieve 'dataname' (load it from file
%                                  if necessary). if dataname=[], return a 
%                                  CRParam containing all project data. 
%  - proj.configure(toolName)      call the configFunction  of tool toolName
%  - proj.run(toolName)            call the computeFunction of tool toolName
%  - proj.run_batched()            run all tools listed in cell array 'batch'
%  - proj.saveProject()            save project in project file.
%
% See also: CRParam, CRData, CRProject.startGUI

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

classdef CRProject < CRParam
    methods
        function this = CRProject( varargin )
            if nargin && ischar(varargin{1}) && exist(varargin{1},'file')~=2
                file = formatPath(CRDefault('CRProjectPath'),varargin{1},[varargin{1} '.crproj']);
                if exist(file,'file')==2
                    varargin{1} = file;
                end
            end
            this@CRParam( varargin{:} );
            
            this.merge( getDefaultProject(this) );
            
            data = this.dataList();
            for i=1:length(data)
                this.data.(data{i}).setPath(this.data.path,true);
            end
        end
        
        function proj = getDefaultProject(this)
            def  = CRDefault();
            proj = get(def,'CRProject',[]);
            if isempty(proj)
                proj = CRParam('CRProject.param');
                def.CRProject = proj;
            end
        end
        
        function browseFile(this, path, parse)
            if isempty(path), path = CRDefault('CRProjectPath'); end
            [f{1:2}] = uigetfile(...
                {'*.crproj', 'CRProject file (*.crproj)'; '*.*', 'All file'}, ...
                'Select project file',path);
            if ~ischar(f{1})
                this.data.name = 'EMPTY_PROJECT';
            else
                if nargin<2, parse = true; end
                this.loadFile([f{[2 1]}], parse);
            end
        end
        
        function evalParam( this, macros )
            if nargin<2, macros = CRDefault(); end
            macros.projectPath = this.data.path;
            evalParam@CRParam( this, macros );
        end
        
        function isIt = isempty( this )
            isIt = isequal(this.data.name,'EMPTY_PROJECT');
        end

        function f = fileName(this)
            f = formatPath(this.data.path,[this.data.name '.crproj'],'/');
        end
        
        function add2batch(this, toolName)
            if isfield(this.data.tool,toolName) && ~any(strcmp(toolName,this.data.batch));
                this.data.batch{end+1} = toolName;
            end
        end

        % list and access project data
        % ----------------------------
        function isIt = isdata( this, dataName )
            isIt = isfield(this,dataName) && isa(this.data.(dataName),'CRData');
        end
        function list = dataList( this )
            list = fieldnames(this);
            list(cellfun(@(x) ~isa(this.data.(x),'CRData'), list)) = [];
        end
        function data = getData( this, dataName )
            if nargin==1
                % return CRParam structure contin all project data
                fields = fieldnames(this);
                data   = CRParam;
                for i=1:length(fields)
                    if isa(this.data.(fields{i}),'CRData')
                        %%! this line should be removed
                        set(data,fields{i}, this.data.(fields{i}).load() );
                    end
                end
                return;
            elseif isdata(this,dataName)
                % return project data 'dataName'
                data = this.data.(dataName).load();
            else
                error('This project does not contain data called ''%s''',dataName);
            end
        end

        % configure or run a tool or run all listed batch tools
        % -----------------------------------------------------
        function configure(this, toolName)
            % get configuration function handle
            tool = this.data.tool.(toolName);
            configFct = get(tool,'configFunction','');
            if isempty(configFct) || exist(configFct,'file')~=2
                crError('Configuration function is not provided for tool %s.',toolName);
                return;
            end
            configFct = str2func(configFct);

            % set input data
            input  = CRParam(tool.input);
            inname = fieldnames(input);
            for i=1:length(inname)
                if ~isdata(this,input.(inname{i}))
                    input.(inname{i}) = [];
                else 
                    this.data.(input.(inname{i})).setPath(this.data.path,true);
                    input.(inname{i}) = this.data.(input.(inname{i})).load('attempt');
                    if isempty(input.(inname{i}))
                        crError('data ''%s'' is empty.',inname{i});
                        return
                    end
                end
            end

            % call the configuration function
            ok = configFct(input,tool.parameters);
            tool.configured = ok;
            this.saveProject();
        end
        function run(this, toolName)
            % get compute function handle
            tool = get(this.data.tool,toolName);
            computeFct = get(tool,'toolFunction','');
            if isempty(computeFct) || exist(computeFct,'file')~=2
                error('''%s'' is not a valid CRTool.',toolName);
            end
            computeFct = str2func(computeFct);

            % set input data
            input  = CRParam(tool.input);
            inname = fieldnames(input);
            for i=1:length(inname)
                if ~isdata(this,input.(inname{i}))
                    input.(inname{i}) = [];
                else 
                    this.data.(input.(inname{i})).setPath(this.data.path,true);
                    input.(inname{i}) = this.data.(input.(inname{i})).load('attempt');
                    if isempty(input.(inname{i}))
                        crError('data ''%s'' is empty.',inname{i});
                        return
                    end
                end
            end

            % set output data structure
            output = tool.parameters.output;
            output.path = formatPath(this.data.path,tool.name);
            
            % call the compute function
            computeFct(input,tool.parameters);
            
            % move CRData from output to project
            oname = output.name;
            if ischar(oname), oname={oname}; end
            
            oname(cellfun(@(x) ~isfield(output,x), oname)) = [];
            oname(cellfun(@(x) ~isa(get(output,x),'CRData'), oname)) = [];
            for i=1:length(oname)
                this.data.(oname{i}) = get(output,oname{i});
                output.rmfield(oname{i});
            end
            output.rmfield('path');
            this.saveProject();
        end
        function run_batched(this)
            % for all tool listed in batch array, call run.
            % catch and display any error but continue running
            for i=1:length(this.data.batch)
                try   this.run(this.data.batch{i}); 
                catch
                    stack = dbstack(1);
                    err = lasterror();
                    crError(stack,err.message);
                end
            end
            this.data.batch = {};
            this.saveProject();
        end
    end    
end
