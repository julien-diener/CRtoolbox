function printf( this, fid, depth )
%   data.printf( fid, current_depth )
%
% This method is an overload of the CRParam printf. It only temporarily
% empty this data before writing to file 'fid'.
%
%  - fid:          file id of a file opened in write mode
%  - current_depth number of initial tabs that lines should start with.
%
% See also: CRData, CRParam, CRParam.printf

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<3 || ~isnumeric(fid) || fid<3
    printf@CRParam(this,fid,depth);
else
    data = this.data.data;
    this.rmfield('data');
    printf@CRParam(this,fid,depth);
    this.data.data = data;
end
