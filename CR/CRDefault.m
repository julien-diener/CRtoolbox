function def = CRDefault( name, substitute )
%  (1) default = CRDefault( name, [substitute] )
%  (2) default = CRDefault()
%  (3) default = CRDefault('reset')
%
% (1) Retrieve default parameter 'name' if it exists.
%     Otherwise returns 'substitute' if provided, or issue an error.
% (2) Retrieve the whole set of default parameters of CR toolbox.
% (3) Reset CRDefault parameter from file CRDefault.param (see below)
%
% In case (1), return the value of the default parameter 'name', if it exist.
% Otherwise returns 'substitute' if provided, or issue an error.
%
% In case (2) and (3), the returned 'default' variable is a persistent 
% CRParam: it is kept in memory until reset. Because a CRParam is a handle, 
% changes made to this returned variable, are also made to the variable kept 
% in memory. Thus all future retrieved 'default' will contain the same changes 
% until this CRDefault is reset. 
% To reset the loaded CRDefault, i.e to reset it from file, 
% call "CRDefault('reset')", "clear all", or restart matlab.
%
% Several functions of the CRToolbox (CRTool, CRProject, CRUIBox) use this
% persistent property by storing default data in CRDefault at first call 
% for quicker later access. But it should be completely transparent to the 
% user. 
%
% This property can also be used on purpose, but it should be done
% carefully:
%  ex 1: def = CRDefault()
%        def.my_data = 'data'
%        clear
%        CRDefault('my_data')  -> returns 'data'.
%        clear all
%        CRDefault('my_data')  -> generate an error.
%  ex 2: -temporarily overload default CRProjectPath (a bad idea...)-
%        def.CRProjectPath = pwd
%        CRDefault('CRProjectPath') -> current path (i.e pwd).
%        clear all
%        CRDefault('CRProjectPath') -> default project path of CR toolbox.
%
% To make an independant copy of CRDefault parameters, do 
%       default = CRParam(CRDefault())          to get a CRParam
%  or   default = CRDefault().convert2struct()  to get a matlab structure
%
% To make permanent changes to CRDefault, edit file 'CRDefault.param' then
% update persistent data by calling "CRDefault(0)"
%
% See also: CRTool

% Author: Julien diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


persistent default;

if isempty(default) || (nargin && isnumeric(name))
    default = CRParam('CRDefault.param',false); % evalParam need to call this function
    default.evalParam();                        % so 'default' should have already been created
end                                             % before evalParam is called.

if nargin && ischar(name)
    if isfield(default,name), def = get(default,name);
    elseif nargin>1,          def = substitute;
    else   error('CRDefault has no field ''%s''',name);
    end
else
    def = default;
end
