function param1 = merge(param1, param2, varargin)
% param1 = param1.merge( param2, options=[])
%
% Merge param2 into param1. 
% param2 can be a CRParam object or any input of CRParam constructor.
% possible options are:
%  - 'overload',  parameters of param2 replace those of param even if
%                 they already exist.
%  - 'reference', When copying CRParam sub-structure, it will only make a
%                 reference copy: changes made to param1 sub-structure will
%                 also apply on the same sub-structure of param2.
%
% See also: CRParam

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

overload  = false;
reference = false;

if nargin>2,
    for j=1:length(varargin)
        switch lower(varargin{j})
            case 'overload',  overload  = true;
            case 'reference', reference = true;
            otherwise, crWarning('unrecognized options ''%s'' in methods CRParam.merge',varargin{i});
        end
    end
end

if ~isa(param2,'CRParam'), param2 = CRParam(param2);  end

% merge parameter recursively (see below)
recursive_merge();


function recursive_merge()
    paramName = fieldnames(param2);
    for i=1:length(paramName)
        value2 = get(param2,paramName{i});
        if isfield(param1,paramName{i})
            value1 = get(param1,paramName{i});
            if isa(value1,'CRParam') && isa(value2,'CRParam')
                param1.pushIterator(paramName{i});
                param2.pushIterator(paramName{i});
                recursive_merge();
                param1.popIterator();
                param2.popIterator();
            elseif overload
                param1.iterator{end}.data.(paramName{i}) = copy(value2);
            end
        else
            param1.iterator{end}.data.(paramName{i}) = copy(value2);
        end
    end
end

% make an idenpendant copy of p1
% WARNING: if p1 is a CRParam, it should not contain "ancestor-loop" !!!
function p2 = copy( p1 )
    if ~isa(p1,'CRParam') || reference
        p2 = p1;
        return;
    end
    constructor = str2func(class(p1));
    p2    = constructor();
    field = fieldnames(p1);
    for i=1:numel(field)
        if isa(p1.iterator{end}.data.(field{i}),'CRParam')
            p1.pushIterator(field{i});
            p2.data.(field{i}) = copy(p1);
            p1.popIterator();
        else
            p2.data.(field{i}) = p1.iterator{end}.data.(field{i});
        end
    end
end

end