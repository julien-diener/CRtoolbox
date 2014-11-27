function saveProject( this )
% Function saveProject saves a CRProject to project file

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

% load all default CR toolbox macros
% and add project path
macro = CRParam(CRDefault());
macro.projectPath = this.data.path;
macroName = fieldnames(macro);
macroName = flipud(macroName);
macroName(~cellfun(@(x) ischar(macro.(x)),macroName)) = [];

% recursively parse all parameters
% and replace recognized macros
proj = CRParam( this );
proj.resetIterator();
replaceMacro();

% put back project path that has been converted
proj.path = this.data.path;
macroName(strmatch('projectPath',macroName,'exact')) = [];
findMacro('path');

% save the project
if ~exist(get(this,'path'),'dir'), mkdir(get(this,'path')); end
fid = fopen(this.fileName(),'w');
if fid<0,  error('Could not open project file ''%s''',this.fileName());  end

proj.printf(fid);

fclose(fid);


function replaceMacro()
    fields = fieldnames(proj);
    for f=1:length(fields)
        value = get(proj, fields{f});
        if isa(value,'CRParam')
            proj.pushIterator( fields{f} );
            replaceMacro()
            proj.popIterator();
            continue;
        end

        if ischar(value)
            findMacro(fields{f});
        end
    end
end

function findMacro(field)
    value = get(proj, field);

    for j=1:length(macroName)
        value = strrep(formatPath(value,'/'),...
            macro.(macroName{j}),...
            ['$' macroName{j} '$']);
    end
    value = formatPath(value,'/');
    proj.(field) = value;
end
end % end of saveParam function
