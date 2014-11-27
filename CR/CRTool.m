function tool = CRTool( varargin )
%  (1) tools = CRTool()          Retrieve all CRTools default parameter
%  (2) tools = CRTool('reset')   Update default tool set from file.
%  (3) names = CRTool('load')    Load tool(s) from a user selected file
%                                return the names of tools found (as a cell array)
%
% Retrieved 'tools' is also stored in CRDefault.
% Because a CRParam are handles, changes made to the returned variable 
% 'tools', are also made to the variable kept in memory. Thus all future 
% retrieved 'tools' will contain the same changes. 
%
% It is reloaded from file CRTool.param when "CRTool('reset')", 
% CRDefault('reset') or "clear all" is called or when matlab start. 
%
% To make an independant copy of CRTool parameters, do 
%       tools = CRParam(CRTool)             to get a CRParam
%  or   tools = CRTool().convert2struct()   to get a matlab structure
%
% To make permanent changes to CRTool, edit file 'CRTool.param' then update
% persistent data by calling "CRTool('reset')"
%
% See also: CRDefault

% Author: Julien diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

default = CRDefault();
if (nargin && ~strcmp(varargin{1},'load')) || ~isfield(default,'CRTool')
    tool = CRParam( 'CRTool.param' );
    default.CRTool = tool;
else
    tool = default.CRTool;
end

% if asked, open gui to select and load an external tool
if nargin && strcmp(varargin{1},'load')
    % open gui to select a param file
    t = CRParam(CRPath());
    
    if isempty(t)  % if canceled
        tool = {};
        return;
    end

    % remove all field which are not valid tool
    name = fieldnames(t);
    for i=1:length(name)
        if ~isa(t.(name{i}),'CRParam') || isempty(get(t.(name{i}),'toolFunction',[]))
           t.rmfield(name{i});
           name{i} = '';
        else
            % add loaded tool to default set
           tool.(name{i}) = t.(name{i});
        end
    end
    
    % return number of succesfully loaded tools
    name(cellfun(@isempty,name)) = [];
    tool = name;
end
