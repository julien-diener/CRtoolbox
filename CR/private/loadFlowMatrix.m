function data = loadFlowMatrix(uFlow,vFlow, varargin)
% function flow_matrix = loadFlowMatrix( uFlow, vFlow, parameters=[])
%
% make one big matrix flow_matrix, containing all u and v speed data of
% sequences uFlow and vFlow. The matrix is 2NxT, where N is the number of
% flow cells, and T the length of flow sequences.
% Each column of flow_matrix has the form [u1, v1, u2, v2, ..., uN, vN]'
% 
% 'parameters' is an optional CRParam, structure or any set of input
% arguments of a CRParam object, which can contain the following fields:
%   - 'interpolate' if true, interpolate NaN (w.r.t time). Flow cells that
%                   are always NaN (over the whole videos) are not processed.
%   - 'outlier'     Remove obvious outlier. If none zeros, all speed data
%                   outside of mean +/- 'outlier'*std are replaced by NaNs
%                   (before the NaN interpolation). 'mean' and 'std' are
%                   the mean and standard deviation of all speed data. 
%
% See also: crExport, crBOD

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin<3,                       p = CRParam();
elseif isa(varargin{1},'CRParam'), p = CRParam(varargin{1});
elseif nargin==3,                  p = CRParam(varargin{1});
else                               p = CRParam(varargin);
end

p.assert('interpolate',false);
p.assert('outlier',    0);

numFrame = length(uFlow);
data = zeros(2*numel(uFlow(1).data),numFrame);

crMessage()
crMessage(0,'Loadind flow data, percent loaded: ');
k = 0;
for i=1:numFrame
    data_i = [uFlow(i).data(:) vFlow(i).data(:)]';
    data(:,i) = data_i(:);
    if k<floor(10*i/numFrame)
        k = floor(10*i/numFrame);
        crMessage(0,'%d-',10*k);
    end
end
crMessage(0,'\n');

data(isinf(data)) = NaN;   % replace Inf by NaN
nans = isnan(data);        % find nan cells

if p.outlier
    crMessage('remove obvious outliers');
    mS = mean(data(~nans));
    sS = std (data(~nans));
    data(data>mS+p.outlier*sS) = NaN;
    data(data<mS-p.outlier*sS) = NaN;
    nans = isnan(data);
end

if p.interpolate
    crMessage('interpolate NaNs (w.r.t time)');
    mask = ~all(nans,2);       % not NaN over the whole sequence
    data = data(mask,:);       % only interpolated on those
    nans = nans(mask,:);

    data(nans(:, 1 ), 1 ) = 0;  % replace NaNs at begining by 0
    data(nans(:,end),end) = 0;  % ------------ at end ---------
    nans(:, 1 ) = false;
    nans(:,end) = false;
    
    div_comp = 4;
    for i=1:div_comp
        s = floor((i-1)*size(data,1)/div_comp) +1;
        e = floor(  i  *size(data,1)/div_comp);
        d = data(s:e,:);
        n = nans(s:e,:);
        T = reshape(1:numel(d),fliplr(size(d)))';
        %data(nans(:)) = interp1(T(~nans(:)),data(~nans(:)),T(nans(:)),'linear','extrap');
        d(n(:)) = interp1(T(~n(:)),d(~n(:)),T(n(:)),'linear','extrap');
        data(s:e,:) = d;
    end
    data( mask,:) = data;
    data(~mask,:) = NaN;
end

% Note: to view interpolated video, do:
% Uout = createVideo('outputFile','tmp/tmpU_0000.mat');
% Vout = createVideo('outputFile','tmp/tmpV_0000.mat');
% flowSize = size(uFlow(1));
% for i=1:length(uFlow)
%     Uout.saveImage(reshape(data(1:2:end,i),flowSize),i);
%     Vout.saveImage(reshape(data(2:2:end,i),flowSize),i);
% end
% Uout.makeInput('fromOutput'); Uout.output = false;
% Vout.makeInput('fromOutput'); Vout.output = false;
% play(the_video,Uout,Vout);
