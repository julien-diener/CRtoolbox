function [ bod ] = crBOD( varargin )
% compute Bi-Orthogonal Decomposition of tracking or flow sequences
%  (1)  bod = crBOD(   tracking,   parameters=[] )
%  (2)  bod = crBOD( uFlow, vFlow, parameters=[] )
%  (3)  bod = crBOD(    input,     parameters )
%
% Input:
% ------
%  (1) 'tracking',        a tracking sequence computed by crKLT
%  (2) 'uFlow' & 'vFlow', the flow  sequences computed by crKLT or crPIV
%  (3) all arguments must be CRParam objects and input should contain
%      either a field 'tracking' or the fields 'uFlow' and 'vFlow' 
%
% 'parameters' is a CRParam, a structure, any input of CRParam constructor
%              or simply a list of <variable,value> paires. It can contain:
%     - 'precision'  either 'single' (default) or 'double'. This is
%                    the data precision used for computations.
%     - 'modeNumber' the number of mode to compute (default 'all')
%     - 'cellSize'   used to compute x & y coordinates (default 1) - flow only
%     - 'outlier',   replace obvious outlier (default 0)           - flow only
%     - 'output',    (optinal) a substructure which can contain
%         * path:    starting path (it can also be included in 'file') 
%         * file:    save the computed bod structure in this file
%         * name:    if provided, a CRData with the given name and
%                    containing returned structure is added. 
%                    * overload file, path must be provided
%
% for none zeros 'outlier', all data outside of mean +/- 'outlier'*std are
% removed, where 'mean' and 'std' are the mean and standard deviation of 
% all speed data over the whole input sequences. 
%
% Output:
% -------
% 'bod' is a structure containing the following fields:
%  - 'x'       coordinates of flow cells or initial position of tracked features
%  - 'y'       coordinates of flow cells or initial position of tracked features
%  - 'chronos' component   of the BOD decomposition - matrix  T-by-K
%  - 'topos'   component   of the BOD decomposition - matrix 2N-by-K
%  - 'alpha'   coefficient of the BOD decomposition - vector of length K
%  - 'trace'   of the correlation matrix (i.e. the total kinetic energy)
%
% where N is the number of flow cells or tracking features, K is the number
% of modes, and T is the number of time step.
%
% The speed matrix can be reconstructed (up to numerical error) by:
%  SPEED = bod.topos * diag(sqrt( bod.alpha )) * bod.chronos';
% 
% The modes are ordered by decreasing alpha.
%
%
% ******************************** WARNING ********************************
% * This function may use lots of memory. A lower bound can be estimated  *
% * by   2*T*(2N+T)*precision   (in bytes), where                         *
% * - 'N' is the number of flow cells or tracking points                  *
% * - 'T' is the number of frames of the sequence                         *
% * - 'precision' is 4 for single (default) and 8 for double              *
% *                                                                       *
% * Ex: 70*100 cells flow over 1 min sequence at 25Hz requires at least   *
% * 200 MBytes of memory using single precision (and 400 using double).   *
% *    -> This is a lower bound, twice this amount is recommended.        *
% *************************************************************************
%
% See also: crShowBOD, private/loadFlowMatrix, CRProject

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

%%! todo: add maxNaN option ?
%     - 'maxNaN',  maximum percentage of NaN (default 1, i.e. 100%)
%    param.assert('maxNaN'  ,1);

% returned value
bod = [];

% manage input arguments
if isa(varargin{1},'CRParam')                 % case (3)
    input = varargin{1};
    if isfield(input,'tracking') && ~isempty(input.tracking);
        trk  = input.tracking;
        type = 'tracking';
    elseif isfield(input,'uFlow') && isfield(input,'vFlow')
        uFlow = input.uFlow;
        vFlow = input.vFlow;
        type  = 'flow';
    else
        error('crBOD, not suitable input arguments');
    end
    param  = varargin{2};
elseif nargin>1 && isa(varargin{2},'CRVideo') % case (2)
    uFlow = varargin{1};
    vFlow = varargin{2};
    type  = 'flow';
    param = varargin(3:end);
elseif isa(varargin{1},'CRVideo')             % case (1)
    trk  = varargin{1};
    type = 'tracking';
    param = varargin(2:end);
else
    crError('not suitable input arguments');
    return;
end

% manage parameters
if isempty(param),            param = CRParam();
elseif ~isa(param,'CRParam')
    if length(param)==1,      param = param{1};       end
    if ~isa(param,'CRParam'), param = CRParam(param); end
end
param.assert('precision','single');
param.assert('modeNumber','all');
if strcmp(type,'flow')
    param.assert('cellSize',1);
    param.assert('outlier' ,0);
end

if ~isnumeric(param.modeNumber)
    param.modeNumber='all';
else
    option.issym = 1;  % to be used by eigs
    options.disp = 0;  % not too sure what this does...
end


p = CRParam(param); % local copy of input parameters
if strcmp(type,'tracking')
    bod.x = trk(1).data(:,2);
    bod.y = trk(1).data(:,1);
    
    trk.format = p.precision;
    numFrame   = length(trk)-1;
    numPoint   = numel(trk(1).data)*2/3;
else
    [bod.x,bod.y] = meshgrid(p.cellSize*(0.5:width (uFlow(1))),...
                             p.cellSize*(0.5:height(uFlow(1))));

    uFlow.format = p.precision;
    vFlow.format = p.precision;
    numFrame = length(uFlow);
    numPoint = 2*numel(uFlow(1).data);
end

printTitle('BOD');

% retrieve all speed data
% -----------------------
if strcmp(type,'tracking') 
    crMessage(0,'Retrieve speed data\n');
    crMessage(0,'percent: ');
    k = 0;
    S = zeros(numPoint,numFrame,p.precision);
    for i=1:numFrame,
        sp     = trk(i+1).data(:,[2 1]) - trk(i).data(:,[2 1]);
        S(:,i) = sp(:); %reshape(sp,numPoint,1);
        if k<floor(10*i/numFrame)
            k = floor(10*i/numFrame);
            crMessage(0,'%d-',10*k);
        end
    end
    crMessage(0,'\n');
else % type='flow'
    p.interpolate = true;
    S = loadFlowMatrix(uFlow,vFlow,p);
end
 

% remove all cells which are NaN over the whole sequence (e.g out of mask)
nanCell = all(isnan(S),2);
nanCell = nanCell(1:2:end) | nanCell(2:2:end); % NaN on both u and v
nanCell = [nanCell nanCell]';
nanCell = nanCell(:);
S(nanCell,:) = [];
bod.x(nanCell(1:2:end)) = [];
bod.y(nanCell(2:2:end)) = [];
numPoint = numPoint-sum(nanCell);

% remove cells that are NaN more than 10% of the frame
% nanCell = sum(isnan(S),2)>0.1*numFrame;
% nanCell = nanCell | nanCell([(1+end/2:end) (1:end/2)]); % NaN on any of u and v
% S(nanCell,:) = [];
% bod.x(nanCell(1:end/2)) = [];
% bod.y(nanCell(1:end/2)) = [];
% numPoint = numPoint-sum(nanCell);
% crMessage(0,'remove %d cells cuz their NaN\n',sum(nanCell(:)));


% this should not happen
if sum(isnan(S(:)))>0
    crError('DEBUG - Still %d NaNs, replaced by zeros.\n',sum(isnan(S(:))));
    S(isnan(S)) = 0;
end


% compute modes
% -------------
crMessage('Compute correlation matrix and BOD modes\n');
C = S'*S;
if isequal(p.modeNumber,'all')
    [chronos,alpha] = eig (C);
else
    if ~strcmp(p.precision,'double')
        C = double(C);
    end
    [chronos,alpha] = eigs(C,p.modeNumber,'lm',option);
    if ~strcmp(p.precision,'double')
        chronos = ones(1,p.precision)*chronos;
        alpha   = ones(1,p.precision)*alpha;
    end
end

alpha = diag(alpha);

topos = S*chronos./(ones(numPoint,1,p.precision)*sqrt(alpha)');



% create output 'bod' struct and sort modes by decreasing alpha
% -------------------------------------------------------------
[bod.alpha,order] = sort(alpha,'descend');
 bod.chronos = chronos(:,order);
 bod.topos   = topos  (:,order);
 bod.trace   = trace(C);


% add CRData if param.output.file or name is provided
p.assert('output');
if (isfield(p.output,'file') && ~isempty(p.output.file)) ||...
    isfield(p.output,'name')
    if isfield(p.output,'name'),  param.output.file = p.output.name; end
    if iscell(param.output.file), param.output.file = param.output.file{1}; end
    
    [d,f,e] = fileparts(param.output.file);
    if isempty(e), e = '.mat'; end;
    param.output.file = formatPath(d,[f e]);
    
    p.output.file = formatPath(get(p.output,'path',''), param.output.file);
    if ~exist(fileparts(p.output.file),'dir')
        mkdir(fileparts(p.output.file));
    end
    save(p.output.file,'bod');
end
% if param.output.name is provided, add CRData of bod structure
if isfield(param,'output') && isfield(param.output,'name')
    name = get(param.output,'name');
    if iscell(name), name = name{1}; end
    param.output.(name) = CRData(bod,p.output.file);
end

printTitle('End BOD');
disp(' ');


% Note: 
% after a test, this algorithm gives the same results as svd (up to a sign)
% but quicker and with less error after reconstruction : err1>err2 
%     [T,A,C] = svd(S,0);
%     S1   = T * A * C';
%     S2   = bod.topos * diag(sqrt(bod.alpha)) * bod.chronos';
%     err1 = sum(abs(S(:) - S1(:)))
%     err2 = sum(abs(S(:) - S2(:)))
% 
%     plot(diag(A) +1, 'r');  hold on    % shift the curve upward (+1) s.t. it 
%     plot(sqrt(bod.alpha));  hold off   % is not hidden by the bod.alpha curve
%
% The test has been done on one flow sequence with approximately 
% numPoint = 14000 and numFrame = 50
