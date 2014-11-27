function  play( video, varargin )
% play( video,                 param = [] )
% play( video, speed_vector,   param = [] )
% play( video, u_flow, v_flow, param = [] )
%
% display an image of 'video', then wait and respond to user input:
%  * enter        -> next image
%  * image_number -> goes to the corresponding image
%  * 'play'       -> play video until enter is pressed
%  * 'q'          -> quit
%  * 'h'          -> display this list
%
% In case 'speed_vector' is provided, if it is a CRVideo with image size
%   - n*2 or 3, display n dot (x,y) on top of 'video'
%   - n*4 or 5, display n speed vectors (x,y,u,v) on top of 'video'
% When size is either n*3 or n*5, the last column indicates errors (none 0
% value means tracking failure). Correct tracking are drawn in green and 
% failure in red.
%
% In case u_flow and v_flow (the u and v of a flow video) are provided, 
% display a vector flow on top of 'video'. 
%
% optional 'param' are parameters of the form (param1, value1, param2, value2,...)
% possible parameters are:
% - 'scale':  scales displayed flow speed vector by given value (default 1)
% - 'height': set window height at given value (default 400 pixels)
% - 'record': CRVideo object with output configured (see class CRVideo)

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


% manage varargin
i=1;
if nargin>i
    while i<nargin-1 && ~ischar(varargin{i}), i = i+1;    
    end
    argin = 1+i - ischar(varargin{i});
else
    argin = 1;
end

height = 400;
scale  = 1;
while i<nargin-1 && ischar(varargin{i})
    switch varargin{i}
        case 'scale',  scale  = varargin{i+1};
        case 'height', height = varargin{i+1};
        case 'record', recVid = varargin{i+1};
    end
    i = i+2;
end

if exist('recVid','var') && ~recVid.output
    crError('Video output is not configured -> cannot record.');
    clear recVid;
end;

spVec = [];
uFlow = [];
vFlow = [];
gridX = [];
gridY = [];

if argin==1
    vidLength = length(video);
    vidSize   = size(video.getFrame(1)); 
elseif argin==2
    spVec     = varargin{1};
    if isa(spVec,'CRData'), spVec = spVec.load(); end
    vidLength = min(length(video),length(spVec));
    vidSize   = size(video.getFrame(1));
elseif argin==3,
    uFlow     = varargin{1};
    vFlow     = varargin{2};
    if isa(uFlow,'CRData'), uFlow = uFlow.load(); end
    if isa(vFlow,'CRData'), vFlow = vFlow.load(); end
    
    vidLength = min(length(video),length(uFlow));
    flowSize  = size(uFlow.getFrame(1));
    
    vidSize  = size(video.getFrame(1));
    cellSize = vidSize([1 2])./flowSize;

    [gridX,gridY] = meshgrid([0.5:1:flowSize(2)]*cellSize(2),...
                             [0.5:1:flowSize(1)]*cellSize(1));
end


h = -1;%createFigure(height, vidSize);

% play the video
i=1;
play  = false;
while i<=vidLength
    % get data to display (video image and flow)
    img = video.getFrame(i);
    if length(vidSize)==3 && vidSize(3)==2 % if this is a flow sequence
        img(:,:,3) = 0;                    % add an empty blue channel
    end
    if ~isempty(uFlow)
        u = uFlow.getFrame(i).data;
        v = vFlow.getFrame(i).data;
    end

    % Display next image (scaled)
    % ---------------------------
    if ~ishandle(h), 
        h = createFigure(height,vidSize);
        a = NaN;
    else
        a = axis;
    end
    hold off
    imshow(img);
    if ~isnan(a), axis(a); end
    hold on;
    
    % Draw speeds on top of video (if provided)
    % -----------------------------------------------
    if ~isempty(spVec) 
        % Display speed vector
        features = spVec.getFrame(i);
        pt1 = features(:,1:2);                              % vector start
        if size(features,2)>=4
            pt2 = features(:,1:2) + scale.*features(:,3:4);  % vector end
        else
            pt2 = [];
        end
        if mod(size(features,2),2)  % if error vector is provided
            ind1 = find(features(:,end)==0);
            ind2 = find(features(:,end));
        else
            ind1 = 1:size(features,1);
            ind2 = [];
        end
        
            % display successful tracking (green)
        pt1 = pt1();
        pt2 = pt2();
        plot(pt1(ind1,2),pt1(ind1,1),'.g');
        if ~isempty(pt2)
            plot([pt1(ind1,2) pt2(ind1,2)]',[pt1(ind1,1) pt2(ind1,1)]','-g')
        end
        
            % display failed tracking (red)
        plot(pt1(ind2,2),pt1(ind2,1),'.r');
        if ~isempty(pt2)
            plot([pt1(ind2,2) pt2(ind2,2)]',[pt1(ind2,1) pt2(ind2,1)]','-r')
        end
        
    elseif ~isempty(video) && exist('u','var')
        % display u and v flow as a grid of vectors on top of video
        % Note: quiver automatically normalize vectors
        not_nan = ~isnan(u) & ~isnan(v);
        
        s = double(scale);%/sqrt(max(u(:).^2+v(:).^2)));  % has to be double to work
        q = quiver  (gridX( not_nan),gridY( not_nan),s*u(not_nan),s*v(not_nan),0);
        set(q,'AutoScale','off');
        l = plot(gridX(~not_nan),gridY(~not_nan),'.r');
        set(l,'MarkerSize',2);
    end
    hold off
    drawnow
    
    % Save displayed image to output video (if asked)
    % -----------------------------------------------
    if exist('recVid','var')
        imgUI = getframe;
        recVid.saveImage(imgUI.cdata,i);
    end

    
    % Continue playing, or ask user input
    % -----------------------------------
    if play
        k = '';
        if ~mod(i,10)
            fprintf('image %4d/%d - playing\n',i,vidLength);
        end
    else
        k = input(sprintf('image %4d/%d - (''h'': help)? ',i,vidLength),'s');
    end
    switch k
        case 'q', break;
        case 'h'
            disp('     * enter        -> next image');
            disp('     * image_number -> goes to the corresponding image');
            disp('     * ''play''       -> play video until enter is pressed');
            disp('     * ''q''          -> quit');
        case 'play'
            play = true;
            % Avoid a bug while using zoom and auto-play
            hManager = uigetmodemanager(h);
            set(hManager.WindowListenerHandles,'Enable','off');
            % --------------------------------------------
            set(h,'keypressfcn',@stopPlaying);
            disp('  *** press any key to stop playing ***');
            figure(h);  % force figure h to be the selected window

        otherwise
            if ~isnan(str2double(k))
                i = mod(abs(str2double(k)), vidLength);
                if i==0, i = vidLength; end
            else
                i = i +1;
                if i>vidLength
                    i = 1;
                    stopPlaying()
                end
            end
    end
end;

% quit
% ----
if ishandle(h), close(h); end

% function call to stop auto-play
% -------------------------------
function stopPlaying( varargin )
    play = false;
    set(h,'keypressfcn','');
end

% create figure with correct size
% -------------------------------
function h = createFigure(height, imageSize)
    width = height*imageSize(2)/imageSize(1);
    h     = figure();
    pos   = get(h,'Position');
    pos(1)   = pos(1) - width  + pos(3);
    pos(2)   = pos(2) - height + pos(4);
    pos(3:4) = [width height];
    set(h,  'Position',pos);
    set(gca,'Position',[0 0 1 1]);
end

end