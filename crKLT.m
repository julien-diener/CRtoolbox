function varargout = crKLT( varargin )
%  (1) tracking or [uFlow,vFlow] = crKLT(video,       parameters=[]);
%  (2) tracking or [uFlow,vFlow] = crKLT(video, mask, parameters=[]);
%  (3) tracking or [uFlow,vFlow] = crKLT(   input,    parameters);
%
% Apply KLT feature tracking on 'video' following the parameters given in
% 'parameters'. It either track a set of particles along the video or
% compute the optical flow for each image of the sequence.
%
% Input:
% ------
% >> Case (1) and (2)
% 'video'      the input CRVideo to extract motion from.
% 'mask'       if 'mask' is provided, track only where mask is not 0
% 'parameters' is a CRParam, a structure or any valid input of CRParam
%              constructor, containing the fields: 
%  - method        possible method used:
%                  'flow'    : Initialize and track particles in each frame
%                    (a)       of 'video', then compute a 2D flow array for
%                              each image of 'video' using fillImage().
%                  'tracking': Initialize particles in first image of
%                    (b)       'video' then track them iteratively along
%                              the sequence.
%                  'particle': Initialize and track particle in each frame
%                              of 'video' independantly. This option exist
%                              for debug purpose only. When computing flow,
%                              all data on tracked particles are saved in
%                              the output path too.
%
%  - minDist       Minimum distance between features
%  - maxFeature    Maximum number of features 
%
%  - winSize       size of the interrogation window
%  - pyramid       Size of the pyramid
%  - maxIteration  Max iteration per pyramid level for LK iteration
%  - threshold     Convergence threshold in pixel for LK iteration 
%                  can be a vector giving a different value for each pyramid 
%                  level
%
%  - overlap       In case method=flow (a), cell size of the output sequence 
%                  is (1-overlap)*winSize
%  - dt            Time in second between 2 images of the video 
%
%  - output:       A sub-structure containing the fields
%     * path       path where the extracted sequences are saved (optional)
%     * file:      a cell array of the file name of the first flow images (u & v)
%                  or a string of the file name of the first tracking images 
%     * name:      the name of the output tracking sequence, or a cell
%                  array of the output flow sequences.
%                  * each element of file is overloaded by [name{i} '_0001']
%                  * path must be provided
%
% If parameter is not provided, crKLT_config is called. It allows to
% configure most parameters manually.
% Otherwise, default parameter can be found in either crKLT_tracking.param
% or crKLT_flow.param. If any parameters are missing, defaults values are
% taken automatically. 
%
% >> Case(3) - defined for use within a CRProject -
%  - 'input'      a CRParam containing the fields 'video' and 'mask'
%  - 'parameters' same as in case (1) and (2)
%
%
% Output:
% -------
% Return either the computed 'tracking' or the 'uFlow' and 'vFlow'.
% 
% If 'parameters.output.name' is provided, add CRData with the given names
% that contain the computed tracking or u and v flow.
%
% In case method=flow (a)
%   Each image of the u or v flow sequence is a grid of the evaluated speed
%
% In case method=tracking (b)
%   Each image of the output sequence has size n*k where n is the number of
%   features tracked and k=3 such that, k=1 are the x-coordinates, k=2 are
%   the y-coordinates and k=3 is a failing statut (0 means tracking worked)
%
%
% Algorithmic Details:
% --------------------
% crKLT uses the following functions (stored in the CR private folder):
%  - goodEnoughCorners.m which mimic the goodFeaturesToTrack Algorithm
%  - pyrLK.m that implements the iterative pyramidal Lucas-Kanade algorithm:
%    "Pyramidal implementation of the lucas kanade feature tracker:
%     Description of the algorithm", Jean-Yves Bouguet, 2002.
%
%
% See also: CRVideo, CRProject, crKLT_config, private/pyrLK,
% private/goodEnoughCorners, private/cornerImage, private/localMax, private/fillImage

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


% initiate output variable(s)
for j=1:nargout, varargout{j} = []; end

% manage input arguments
if nargin==0 || (nargin==1 && ~isa(varargin{1},'CRVideo'))
        error('crKLT: Not enough input arguments');
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
        ok = crKLT_config(video,mask,param);
        if ~ok, return; end
    elseif ~isa(param,'CRParam')
        param = CRParam(param);
    end
else                          % case (3)
    video  = varargin{1}.video;
    mask   = varargin{1}.mask;
    param  = varargin{2};
end


% Start
printTitle('KLT');

% fill missing parameters and assess the others validity
ok = crKLT_config(video,mask,param,false);

if ~ok, crMessage('KLT canceled'); 
else
    % if param.output.name is provide, it overload param.output.file s.t.:
    if isfield(param,'output') && isfield(param.output,'name')
        param.output.file = strcat(param.output.name, '_0001');
    end
    
    % call the main function which compute tracking or flow
    computeKLT();

    % manage output and quit 
    if strcmp( param.method, 'flow' )
        varargout{1} = uSeq;
        varargout{2} = vSeq;
    else
        varargout{1} = uSeq;
    end
    if isfield(param,'output') && isfield(param.output,'name')
        if strcmp( param.method, 'flow' )
            name = get(param.output,'name',{'uFlow' 'vFlow'});
            param.output.(name{1}) = uSeq.makeCRData();
            param.output.(name{2}) = vSeq.makeCRData();
        else
            name = get(param.output,'name','tracking');
            if iscell(name), name = name{1}; end
            param.output.(name)   = uSeq.makeCRData();
        end
    end
end

% End    
printTitle('End KLT');
disp(' ');




% Main function -> compute tracking or optical flow 
% -------------------------------------------------
function computeKLT()
    % set video data format for computation
    video.depth  = 1;
    video.format = 'double';
    video.setBufferLength(2);

    % generate a default mask if it has not been provided
    if isempty(mask)
        mask = ones(size(video(1)));
    end

    % remove mask border
    b = floor(param.winSize/2) * 2^(param.pyramid-1);
    mask(1:b      ,:) = 0;
    mask(end-b:end,:) = 0;
    mask(:,1:b      ) = 0;
    mask(:,end-b:end) = 0;


    % Compute pyramid for first image (initially stored in second pyramid)
    pyr2 = makePyramid(video(1).data,param.pyramid);

    % initialize output sequences
    outPath = get(param.output,'path','');
    switch lower(param.method)
        case 'tracking'
            uSeq = createVideo('outputPath',outPath, 'outputFile', param.output.file);
            if ~exist('pts','var')
                pts = goodEnoughCorners(video(1).data,param, mask);
            end
            uSeq.saveImage([pts zeros(size(pts,1),1)],1);

        case 'particle'
            uSeq = createVideo('outputPath',outPath, 'outputFile', 'particle_0001');

        case 'flow'
            pSeq = createVideo('outputPath',outPath, 'outputFile', 'particle_0001');
            uSeq = createVideo('outputPath',outPath, 'outputFile', param.output.file{1});
            vSeq = createVideo('outputPath',outPath, 'outputFile', param.output.file{2});

            cellSize = floor((1-param.overlap)*param.winSize);
            flowSize = struct('x',ceil(size(pyr2(1).img(),1)/cellSize), ...
                'y',ceil(size(pyr2(1).img(),2)/cellSize));
    end

    % display selected parameters
    disp(' Parameters:');
    param.printf(1,1);
    disp(' ');

    % Apply KLT
    t0 = clock;
    for i=1:length(video)-1
        t1 = clock;
        crMessage(0,'image %4d/%d:\t', i,length(video)-1);

        % init features to track
        if ~strcmp( param.method , 'tracking' )
            pts = goodEnoughCorners(video(i).data,param, mask);
        end

        % set pyramids
        pyr1 = pyr2;
        pyr2 = makePyramid(video(i+1),param.pyramid);

        % do the tracking
        [sp warn] = pyrLK(pyr1, pyr2, pts, ...
                    param.winSize, param.maxIteration, param.threshold);
        warn = sum(warn,2);

        % Save data
        switch lower(param.method)
            case 'tracking'
                pts = pts + sp;
                uSeq.saveImage([pts warn],i+1);
            case 'particle'
                uSeq.saveImage([pts sp warn], i);
            case 'flow'
                % save particles
                pSeq.saveImage([pts sp warn], i);

                % adjust features position to flow size and clamp when necessary
                pts(logical(warn),:) = [];  % delete failed tracking particles
                sp (logical(warn),:) = [];
                pts = pts/cellSize;
                pts(pts<1) = 1;
                pts(pts(:,1)>flowSize.x,1) = flowSize.x;
                pts(pts(:,2)>flowSize.y,2) = flowSize.y;

                % Compute flow by propagating the features speed
                flow = fillImage(pts,sp,flowSize.x,flowSize.y,1,2);

                % save resulting flow arrays
                uSeq.saveImage(flow(:,:,2)/param.dt,i);
                vSeq.saveImage(flow(:,:,1)/param.dt,i);
        end

        crMessage(0,' time = %7.3f (total = %7.3f)',etime(clock,t1),etime(clock,t0));
        if sum(warn), crMessage(0,' - failed: %d\n',sum(logical(warn)));
        else          crMessage(0,'\n');
        end
    end
    
    % Convert tracking or flow sequences to input (for reading)
    if strcmp( param.method , 'flow' ),
        uSeq.makeInput('fromOutput');
        vSeq.makeInput('fromOutput');
        uSeq.output = false;
        vSeq.output = false;
    else
        uSeq.makeInput('fromOutput');
        uSeq.output = false;
    end
end

end
