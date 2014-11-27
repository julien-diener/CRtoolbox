function crExport( varargin)
% Export tracking or flow sequence to ascii file
%
% (1) crExport( u_flow, v_flow, file=[])
% (2) crExport( tracking,       file=[])
% (3) crExport( ------"-------, parameters)
% (4) crExport(     input,      parameters)
%
% Case (1) and (2)
%   export the uFlow and vFlow or tracking to file 'file'
% Case (3)
%   'parameters' can be a CRParam, a structure, pairs <name,value> or any
%   input of CRParam constructors which can contain the following fields:  
%        NAME          PROPERTIE                       VALUE TYPE (DEFAULT)
%  - 'file'          file to store the data             char ([])
%  - 'delimiter'     set the delimiter                  char (' ', i.e. space)
%  - 'interpolate'   interpolate NaN (w.r.t time)       boolean (false)
%  - 'replace'       replace (not interpolated) NaN     scalar  (NaN)
%  - 'outlier'       filter detected outlier            number of std (0)
%
% Case (4) - for use within CRProject
%    - 'input'      a CRParam containing a either the field 'tracking' or
%                   the fields 'uFlow' & 'vFlow'
%    - 'parameters' same as in (3)
%
% > If file or parameters.file is not provided or empty, user is asked to
%   select a file manuallly.
% > for none zeros 'outlier', any speed outside of mean +/- 'outlier'*std
%   is replaced by NaNs. mean and std are the mean and standard deviation
%   of all speed data of the flows.
% > 'interpolate', 'replace' and 'outlier' are only used with flow sequence
%
% See also: private/loadFlowMatrix

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

% Manage input arguments
if nargin>1 && isa(varargin{2},'CRVideo') % case (1)
    type  = 'flow';
    uFlow = varargin{1};
    vFlow = varargin{2};
    numElmt  = size  (uFlow(1));
    numFrame = length(uFlow);
    varargin(1) = [];
elseif isa(varargin{1},'CRVideo')         % case (2)
    type = 'tracking';
    trk  = varargin{1};
    numElmt  = length(trk(1).data(:,1));
    numFrame = length(trk);
elseif isa(varargin{1},'CRParam')         % case (4)
    if isfield(varargin{1},'tracking')
        type = 'tracking';
        trk  = varargin{1}.tracking;
        numElmt  = length(trk(1).data(:,1));
        numFrame = length(trk);
    elseif isfield(varargin{1},'uFlow') && isfield(varargin{1},'vFlow')
        type  = 'flow';
        uFlow = varargin{1}.uFlow;
        vFlow = varargin{1}.vFlow;
        numElmt  = size  (uFlow(1));
        numFrame = length(uFlow);
    else
        error('crExport: Incorrect input arguments')
    end
else
    error('crExport: Incorrect input arguments')
end
    
p = CRParam();
if length(varargin)<2,              p.file = '';
elseif ischar(varargin{2}),         p.file = varargin{2};
elseif length(varargin)>2,          p = CRParam(varargin(2:end));
elseif ~isa(varargin(2),'CRParam'), p = CRParam(varargin{2});
else                                p = varargin{2};
end

% assert some parameters
p.assert('delimiter',  ' ');
p.assert('interpolate',false);
p.assert('replace',    NaN);
p.assert('outlier',    0);

% check if p.file is provided. Otherwise, ask user to select file
if isempty(get(p,'file','')) || exist(p.file,'file')==2
    [f,d] = uiputfile('*.*','Select export file');
    if ischar(f)
        p.file = formatPath(d,f);
    else
        return;
    end
end

% Construct fprintf line format
switch type
    case 'tracking'
        line    = [ repmat(['%+12.4e' p.delimiter '%+12.4e' p.delimiter '%d' p.delimiter ], 1, numElmt) '\n' ];
    case 'flow'
        line    = [ repmat(['%+12.4e' p.delimiter], 1, 2*prod(numElmt)) '\n' ];
end


% start export
% ------------

% open export file
f = fopen(p.file, 'w');


% Print header
fprintf(f,'%d\n',   numFrame);
if strcmp(type, 'tracking')
    fprintf(f,'%d\n', numElmt);
else
    fprintf(f,'%d\n', numElmt(2)); % width
    fprintf(f,'%d\n', numElmt(1)); % height
end
fprintf(f,'\n');


% load all data in one matrix if necessary (ie. interpolateNaN==true)
if p.interpolate==false || strcmp(type,'tracking')
     data = [];
else data = loadFlowMatrix(uFlow,vFlow,p);
end

% Print data
crMessage()
fprintf('Print data to file: ');
k = 0;
for j=1:numFrame
    fprintf(f, line, dataAtFrame(j,data));
    if k<floor(10*j/numFrame)
        k = floor(10*j/numFrame);
        fprintf('%d-',10*k);
    end
end
fprintf('\n');

fclose(f);

% ---- End of main function ----



function data_i = dataAtFrame(i,data)
    switch type
        case 'tracking'
            data_i = trk(i).data';
            data_i = data_i(:);
        case 'flow'
            if p.interpolate
                data_i = data(:,i);
            else
                data_i = [uFlow(i).data(:) vFlow(i).data(:)]';
                data_i = data_i(:);
            end
    end
    data_i(isnan(data_i)) = p.replace;
end
    
end