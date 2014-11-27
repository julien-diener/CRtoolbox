function [uFlow,vFlow] = crPIV( varargin )
%  (1) [uFlow,vFlow] = crPIV( video,       parameters=[])
%  (2) [uFlow,vFlow] = crPIV( video, mask, parameters=[])
%  (3) [uFlow,vFlow] = crPIV(     input,   parameters)
%
% Compute a the optical flow of 'video' using matPIV following the
% parameters given in 'parameters'. 
% (tha MatPIV toolbox should be installed, and in the matlab path)
%
% Input:
% ------
% case (1) and (2), 
%  'video' is the input video (CRVideo object). 
%  'mask'  if provided, flow is computed only where mask~=0
%            |Note:  if method='multi' or 'multin', the mask is only used
%                    after computing the flow to erase values where mask==0
%  'parameters' is a CRParam, a structure or any valid input of CRParam
%               constructor, containing the fields: 
%    - method:   MatPIV method, one of 'single' or 'multin' pass(es)
%    - winSize:  size of the interrogation regions
%    - dt:       time in second between 2 images of the video 
%    - overlap:  overlap of the interrogation regions
%    - output    CRParam or structure that contains the field
%       * path:  path to directory for saving results flow.
%       * file:  a cell array of the file name of the first flow images (u & v)
%       * name:  (optional) a cell array of the returned CRData names (see below)
%                 * each element of file is overloaded by [name{i} '_0001']
%                 * path must be provided
%
% If parameter is not provided, crPIV_config is called. It allows to
% configure all parameters but output manually. Otherwise, default
% parameter can be found in crPIV.param or by using crPIV_config
% previously. If some parameters are missing, defaults values are taken
% automatically. 
%
% case (3) - defined for use within a CRProject -
%    - 'input'      a CRParam containing a field 'video' and 'mask'
%    - 'parameters' a CRParam similar to (1)
%
% Output:
% -------
%  - Return the u and v part of the flow as CRVideo 'uFlow' and 'vFlow'.
%  - If input 'parameters' is a CRParam, it has been updated.
%  - If parameters.output.name is provided, add two CRData with the given
%    names that contain the computed u and v flow.
%
% See also: crPIV_config, CRProject, CRVideo, matpiv


% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

% test if matpiv is installed
if ~exist('matpiv','file')
    crError('The MatPIV toolbox can not be found in matlab PATH');
    return;
end

% initiate output variable(s)
uFlow = [];
vFlow = [];

% manage input arguments
if nargin==0 || (nargin==1 && ~isa(varargin{1},'CRVideo'))
        error('crPIV: Not enough input arguments');
end
if isa(varargin{1},'CRVideo') % case (1) or (2)
    video = varargin{1};
    if nargin==1
        mask  = [];
        param = [];
    elseif ~isnumeric(varargin{2})
        mask  = [];
        param = varargin(2:end);
    else
        mask  = varargin{2};
        param = varargin(2:end);
    end
    if length(param)==1, param = param{1}; end
    if isempty(param)
        param = CRParam();
        ok = crPIV_config(video,mask,param);
        if ~ok
            return; 
        end
    elseif ~isa(param,'CRParam')
        param = CRParam(param);
    end
else                          % case (3)
    video = get(varargin{1},'video');
    mask  = get(varargin{1},'mask');
    param = varargin{2};
end


% Start
printTitle('PIV');

% fill missing parameters and assess the others validity
ok = crPIV_config(video,mask,param,false);

% call the main function which compute the flow
if ~ok
    crMessage('PIV canceled'); 
else
    % if param.output.name is provide, it overload param.output.file s.t.:
    if isfield(param,'output') && isfield(param.output,'name')
        param.output.file = strcat(param.output.name, '_0001');
    end

    % call the main function which compute tracking or flow
    computePIV();
    % manage output and quit 
    uFlow = uSeq;
    vFlow = vSeq;
    if isfield(param,'output') && isfield(param.output,'name')
        name = get(param.output,'name',{'uFlow' 'vFlow'});
        param.output.(name{1}) = uFlow.makeCRData();
        param.output.(name{2}) = vFlow.makeCRData();
    end
end

% End
printTitle('End PIV');
disp(' ');



% Main function -> compute the optical flow using MatPIV
% ------------------------------------------------------
function computePIV()
    % set video data format
    video.depth  = 1;
    video.format = 'double';
    video.setBufferLength(2);

    % create output sequence
    outPath = get(param.output,'path','');
    uSeq = createVideo('outputPath',outPath, 'outputFile', param.output.file{1});
    vSeq = createVideo('outputPath',outPath, 'outputFile', param.output.file{2});


    % --------- manage issues using matpiv ---------
    % MatPIV generates this warning very often
    warning('off','Images:isrgb:obsoleteFunction');

    % Redirect MatPIV output to a log file, to keep workspace display "clean"
    if ~isempty(outPath) && ~exist(outPath,'dir'), mkdir(outPath); end
    logFile = fopen(formatPath(outPath,'piv.log'),'w');

    % method multi cannot be run on avi video
    % note: 'multin' should be used instead 
    if strcmp(get(param,'method'),'multi') && isa(video,'CRVideoAVI')
        crWarning('MatPIV cannot run method ''multi'' on avi video: set method to ''single''');
        set(param,'method','single');
    elseif strcmp(get(param,'method'),'multin')
        % for some (strange) reason, multipassx.m (called with 'multin')
        % first convert input images to uint8 (thus clearing float images)
        video.format = 'uint8';
    end

    % provide a mask suitable for matpiv
    % Note: method multi and multin cannot use mask (as an array) directly
    % In such case, the flow is erased where mask is 0 after being computed
    if ~isempty(mask) && strcmp(get(param,'method'),'single')
        m.msk  = ~(mask());
        pivArg{7} = [];
        pivArg{8} = m;
    end
    % -----------------------------------------

    t0 = clock;
    disp(' Parameters:');
    param.printf(1,1);
    disp(' ');

    % argument passed to matpiv
    pivArg{3} = param.winSize;
    pivArg{4} = param.dt;
    pivArg{5} = param.overlap;
    pivArg{6} = param.method;

    % In case multi and multin, matpiv automatically divide the winSize by 2
    % -> compensate this "strange approach"...
    if strncmp(param.method,'multi',5)
        pivArg{3} = 2*pivArg{3};
    end

    fprintf(logFile,'Compute PIV - %s\n\n', datestr(now));
    for i=1:length(video)-1
        t1 = clock;

        fprintf(logFile,...
            ' ------------- image %d/%d -------------\t', i,length(video)-1);
        crMessage(0,'image %4d/%d:\t', i,length(video)-1);

        if strcmp(param.method,'multi')
            pivArg{1} = video.imageFileName(i  , 'input');
            pivArg{2} = video.imageFileName(i+1, 'input');
        else
            pivArg{1} = video(i).data;
            pivArg{2} = video(i+1).data;
        end

        % Call matpiv
        % Use evalc to catch output of matpiv (and store them in 'log')
        [log,x,y,u,v,snr] = evalc('matpiv(pivArg{:})');             
        fprintf(logFile,log);
        % [x,y,u,v,snr] = matpiv(pivArg{:});

        % If mask is provided and method is not single
        % delete flow where mask==0
        if ~isempty(mask) && ~strcmp(param.method,'single')
            if ~exist('m','var')
                if ~isa(mask,'CRImage'), mask = CRImage(mask); end
                m = logical(mask.divSize(size(u),'sum'));
            end
            u(m) = NaN;
            v(m) = NaN;
        end

        uSeq.saveImage(u,i);
        vSeq.saveImage(v,i);

        crMessage(0,' time = %7.3f (total = %7.3f)\n',etime(clock,t1),etime(clock,t0));
        fprintf(logFile,' time = %7.3f (total = %7.3f)\n',etime(clock,t1),etime(clock,t0));
    end
    warning('on','Images:isrgb:obsoleteFunction');

    fclose(logFile);
    
    % convert computed flow sequence to input to allow reading
    uSeq.makeInput('fromOutput');
    vSeq.makeInput('fromOutput');
    uSeq.output = false;
    vSeq.output = false;
end

end
