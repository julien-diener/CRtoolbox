function h = player( this, varargin )
%    h = player( video )
%    h = player( ..., 'tracking', tracking_sequence)
%    h = player( ..., 'flow',     u_flow_sequence, v_flow_sequence)
%    h = player( ..., 'scale',    flow_scaling_factor)
%    h = player( ..., 'bod',      bod_data_structure)
%    h = player( ..., 'record',   video_output)
%    h = player( ..., 'callback', callback_function_handle)
%    h = player( ..., 'parent',   handle_to_parent_ui_component)
%
% open a player to display "video". 
% Press space bar to start/stop playing and escape to close the player.
%
% Input:
% ------
% Additional arguments can be given through the player call, or by using
% the returned handle "h" (see the output section below):
%  - A tracking or two flow sequences can be displayed on top of the video, 
%  - the topos and chronos of a Bi-Orthogonal Decompostion
%  - an output CRVideo can be used to save displayed image sequence
%  - A callback function handle can be set to be called when the figure is
%    updated.
%
% Output:
% -------
% player return a handle "h" (a CRParam) that contains data used by the
% player. It also contains function handles to set, change or remove
% additional data as follow:
%  1) h.setImage    (h, image_index)
%  2) h.showTracking(h, tracking_sequence) 
%  3) h.showFlow    (h, u_flow_sequence, v_flow_sequence)
%  4) h.setScale    (h, flow_scaling_factor) 
%  5) h.showBOD     (h, bod_structure) 
%  6) h.setVideoOut (h, output_video) 
%  7) h.setCallback (h, function_handle) 
%
%  1) set image number "image_index"
%  2) display "tracking_sequence" (as computed by the tools crKLT)
%  3) display flow composed of "u_flow_sequence" and "u_flow_sequence"
%     (as computed by the tools crKLT or crPIV)
%  4) scale displayed flow vector by "flow_scaling_factor"
%  5) display the topos and chronos of a Bi-Orthogonal Decompotion
%  6) save each image displayed in the output CRVideo "output_video"
%  7) "function_handle" will be called each time the player image is updated
%
% To remove a displayed tracking or flow sequence, call the respective
% function with empty arguments. Ex: h.showTracking(h, [])
%
% See Also: CRVideo, CRParam, CRProject, crKLT, crPIV, crBOD

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

h = CRParam;

h.video    = this;
h.video.depth  = 0;
h.video.format = '';

h.image    =  1;    % index of the current image
h.playing  = false; % true mean automatic play
h.callback = [];    % function handle called each time a new image is displayed

h.data.scale    =  1;    % scaling coefficient of the flow vectors
h.data.uflow    = [];    % the u part of a flow sequence to display
h.data.vflow    = [];    % the v part of a flow sequence to display
h.data.tracking = [];    % a tracking sequence to display
h.data.record   = [];    % save diplayed image in this output video
h.data.bod      = [];    % a data structure containing a Bi-Orthogonal Decomposition

h.gui.parent   = [];    % parent figure or panel
h.gui.axe      = [];    % handle to the video axes

h.setImage     = @setImage;      % function handle to set displayed image index
h.showFlow     = @showFlow;      % function handle to set/change/remove flow data
h.setScale     = @setScale;      % function handle to change scaling of flow data
h.showTracking = @showTracking;  % function handle to set/change/remove tracking data
h.showBOD      = @showBOD;       % function handle to set/change/remove BOD data structure
h.setVideoOut  = @setVideoOut;   % function handle to set/change/remove output video
h.setCallback  = @setCallback;   % function handle to set/change/remove callback function

k = 1;
while k<length(varargin)
    if ~ischar(varargin{k})
        k = k+1;
        crError('incorrect arguments');
        continue
    end
    switch lower(varargin{k})
        case 'parent'
            h.gui.parent = varargin{k+1};
            k = k+2;
        case 'flow'
            showFlow(h,varargin{k+[1 2]});
            k = k+3;
        case 'scale'
            setScale(h,varargin{k+1});
            k = k+2;
        case 'tracking'
            showTracking(h,varargin{k+1});
            k = k+2;
        case 'bod'
            showBOD(h,varargin{k+1});
            k = k+2;
        case 'record'
            setVideoOut(h,varargin{k+1});
            k = k+2;
        case 'callback'
            setCallback(h, varargin{k+1});
            k = k+2;
        otherwise
            crError('unrecognized argument: %s',varargin{k});
            k = k+1;
    end
end

updateImage(h);

end


function updateImage(varargin)
    % update video image
    h = varargin{end};
    checkFigure(h);
    axes(h.gui.axe);
    hold off
    imshow(h.video.getFrame(h.image));
    set(h.gui.slider,'value',h.image);
    set(h.gui.play_button,'value',h.playing);
    
    % update display of other data
    updateFlow(h);
    updateTracking(h);
    updateBOD(h);
    updateRecord(h);

    % call the callback function if necessary
    if ~isempty(h.callback)
        if iscell(h.callback)
            arg = [h.image h.callback(2:end)];
            callFcn = h.callback{1};
        else
            arg = {h.image};
            callFcn = h.callback;
        end
        if isa(callFcn,'function_handle')
            callFcn(arg{:});
        end
    end
    drawnow;
end
function updateFlow(h)
    % Note: quiver automatically normalize vectors
    if isempty(h.data.uflow) || h.image>length(h.data.uflow), return; end
    u = h.data.uflow.getFrame(h.image).data;
    v = h.data.vflow.getFrame(h.image).data;
    not_nan = ~isnan(v) & ~isnan(u);
    s = double(h.data.scale);  % has to be double to work
    
    hold on
    q = quiver(h.data.gridX(not_nan),h.data.gridY(not_nan),s*u(not_nan),s*v(not_nan),0);
    set(q,'AutoScale','off');
    l = plot(h.data.gridX(~not_nan),h.data.gridY(~not_nan),'.r');
    set(l,'MarkerSize',2);
end
function updateTracking(h)
    if isempty(h.data.tracking) || h.image>length(h.data.tracking), return; end
    % Display speed vector
    features = h.data.tracking.getFrame(h.image);
    pt1 = features(:,1:2);                              % vector start
    if size(features,2)>=4
        pt2 = features(:,1:2) + h.data.scale.*features(:,3:4);  % vector end
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
    hold on;
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
end
function updateBOD(h)
    if isempty(h.data.bod), return; end
    
    current = h.gui.bod.current.value;
    bod     = h.data.bod;
    scale   = 10* double(h.data.scale) ./ max(abs(bod.topos(:,current)));  % has to be double to work;
    if get(h.gui.bod.dynamic,'Value') && h.image < size(bod.chronos,1)
        scale = scale.* bod.chronos(h.image,current) ./ max(abs(bod.chronos(:,current)));
    end
    
    % show topos on top of video image
%     axes(h.gui.axe);
    hold on
    s = h.gui.bod.scale.value;
    q = quiver(s*bod.x(:),s*bod.y(:),scale*bod.topos(1:2:end,current),scale*bod.topos(2:2:end,current));
    set(q,'AutoScale','off');
    
    % show chronos in the respective axe
    axes(h.gui.bod.chronos);
    hold off
    plot(bod.chronos(:,current));
    if h.image < size(bod.chronos,1)
        hold on
        plot(h.image,bod.chronos(h.image,current),'.r');
    end
end
function bodChanged(varargin)
    h = varargin{end};
    current = h.gui.bod.current.value;
    axes(h.gui.bod.alpha);
    hold off
    bar(h.data.bod.alpha./h.data.bod.trace);
    hold on
    bar([ zeros(1,current-1) h.data.bod.alpha(current)./h.data.bod.trace],'r');
    updateImage(h);
end

function updateRecord(h)
    if isempty(h.data.record), return; end
    img = getframe;
    rec = get(h.data.record,'rec_image') +1;
    h.data.record.saveImage(img.cdata, rec);
    set(h.data.record,'rec_image', rec);
end

function play(varargin)
    h = varargin{end-1};
    h.playing = varargin{end};

    while h.playing
        h.image = h.image +1;
        if h.image>length(h.video)
            h.image = 1;
            h.playing = false;
        end
        updateImage(h);
    end
end
function setImage(varargin)
    if isa(varargin{end},'CRParam')
        h = varargin{end};
        h.image = varargin{end-1};
    else
        h = varargin{end-1};
        h.image = varargin{end};
    end
    
    if h.image < 1,               h.image = 1;               end
    if h.image > length(h.video), h.image = length(h.video); end
        
    h.playing = false;
    updateImage(h)
end

% check if parent exist, otherwise create figure with correct size
function checkFigure(h)
    if isempty(h.gui.parent) || ~ishghandle(h.gui.parent) || ...
       ~any(strcmp(get(h.gui.parent, 'type'), {'uipanel', 'figure', 'uicontainer'}))
        h.gui.figure = figure();
        h.gui.parent = h.gui.figure;
        set(h.gui.parent,'closeRequestFcn',{@closeFigure,h});
        H = 400;
        W = size(h.video,3)*H/size(h.video,2);
        pos   = get(h.gui.parent,'Position');
        pos(1)   = pos(1) - W + pos(3);
        pos(2)   = pos(2) - H + pos(4);
        pos(3:4) = [W H];
        set(h.gui.parent,  'Position',pos);
        h.gui.axe = [];
    else
        h.gui.figure = h.gui.parent;
        while ~strcmp(get(h.gui.figure,'type'), 'figure'), h.gui.figure = get(h.gui.figure,'parent'); end
        figure(h.gui.figure);
    end
    
    % check existance of player UI components 
    % and create them if necessary
    if isempty(h.gui.axe) || get(h.gui.axe,'parent')~=h.gui.parent
        % set figure KeyPressFcn function 
        set(h.gui.figure,'KeyPressFcn',  {@keypressed, h});
        set(h.gui.figure,'KeyReleaseFcn',{@keyrelease, h});
        h.gui.autopress = false;
        
        h.gui.axe = axes('parent',h.gui.parent);
        set(h.gui.axe,'position',[0 0 1 1]);
        h.gui.play_button = uicontrol('parent',h.gui.parent,'style','togglebutton','String','|>',...
                                      'callback',{@switchPlay, h});
        h.gui.slider = CRUIbox('style','slider','direction','horizontal','textWidth',0,...
                               'min',1,'max',length(h.video),'value',1,...
                               'callback',{@setImage, h});
        h.gui.layout = GridBagLayout(h.gui.parent,'VerticalGap',5,'HorizontalGap',5,...
                                     'HorizontalWeights',[0 1],'VerticalWeights',[1 0]);
        h.gui.layout.add(h.gui.axe,          1,1:2, 'Fill', 'Both');
        h.gui.layout.add(h.gui.play_button , 2, 1 , 'Anchor', 'West');
        h.gui.layout.add(h.gui.slider.panel, 2, 2 , 'Fill', 'Horizontal');
    end
end

function switchPlay(varargin)
    h = varargin{end};
    play(h,~h.playing);
end
function closeFigure(varargin)
    h = varargin{end};
    if ~ishandle(h) || ~strcmp(get(h,'type'),'figure')
        delete(h.gui.figure);
        h.gui = [];
    end
    h.playing = false;
end

% ---------- manage key press and release event ----------
function keypressed(varargin)
    h   = varargin{end};
    evt = varargin{end-1};
    
    if h.gui.autopress, return;   end
    h.gui.autopress = true;
%     fprintf('evt Character, Key: %s %s\n',evt.Character, evt.Key);

    switch evt.Key
        case 'space',      play(h,~h.playing);
        case 'rightarrow', setImage(h,h.image+1);
        case  'leftarrow', setImage(h,h.image-1);
        case  'escape',    closeFigure(h);
    end
end
function keyrelease(varargin)
    h = varargin{end};
    h.gui.autopress = false;
end
% ---------- set flow, tracking and record video ----------
function showFlow(h,uFlow,vFlow)
    if nargin==1 || isempty(uFlow) || isempty(vFlow)
        h.data.uflow = [];
        h.data.vflow = [];
    else
        if isa(uFlow,'CRData'), uFlow = uFlow.load(); end
        if isa(vFlow,'CRData'), vFlow = vFlow.load(); end
        if ~isa(uFlow,'CRVideo') || ~isa(vFlow,'CRVideo')
            crError('uFlow and vFlow must be CRVideo objects or CRData containing CRVideos');
        elseif uFlow.getFrame(1).depth ~= 1
            crError('uFlow data is not a flow sequence');
        elseif vFlow.getFrame(1).depth ~= 1
            crError('vFlow data is not a flow sequence');
        else
            vidSize  = size(h.video.getFrame(1));
            flowSize = size(uFlow.getFrame(1));
            cellSize = vidSize([1 2])./flowSize([1 2]);

            [h.data.gridX,h.data.gridY] = ...
                meshgrid((0.5:1:flowSize(2))*cellSize(2),(0.5:1:flowSize(1))*cellSize(1));

            h.data.uflow = uFlow;
            h.data.vflow = vFlow;
        end
    end
    try updateImage(h);
    catch 
        h.data.uflow = [];
        h.data.vflow = [];
        err = lasterror;
        crError(err.stack(1),err.message);
    end
end
function setScale(h,scale)
    h.data.scale = scale;
    updateImage(h);
end
function showTracking(h,tracking)
    if nargin==1 || isempty(tracking)
        h.data.tracking = [];
    else
        if isa(tracking,'CRData'), tracking = tracking.load(); end
        if ~isa(tracking,'CRVideo')
            crError('tracking must be a CRVideo object or a CRData containing a CRVideo');
        elseif tracking.getFrame(1).depth ~= 1
            crError('Input data is not a tracking sequence');
        else
            h.data.tracking = tracking;
        end
    end
    try updateImage(h);
    catch 
        h.data.tracking = [];
        err = lasterror;
        crError(err.stack,err.message);
    end
end
function setVideoOut(h,record)
    if nargin==1 || isempty(record)
        h.data.record = [];
    else
        if ~isa(record,'CRVideo') || ~record.output
            crError('record must be a CRVideo object configured for output');
        else
            h.data.record = record;
            if ~isfield(h.data.record,'rec_image')
                set(h.data.record,'rec_image',1);
            end
        end
    end
    try updateImage(h);
    catch 
        h.data.record = [];
        err = lasterror;
        crError(err.stack,err.message);
    end
end
function setCallback(h,callback)
    h.callback = callback;
end

% ------------------- set bod structure and gui -------------------
function showBOD(h, bod)
    if nargin==1 || isempty(bod)
        if ~isempty(h.gui.layout.getComponent(3,1))
            h.gui.layout.remove(3,1);
            clean(h.gui.layout);
        end
        if isfield(h.gui,'bod')
            if ishghandle(h.gui.bod.panel)
                set(h.gui.bod.panel,'Units','pixels');
                s = get(h.gui.bod.panel,'position');
                set(h.gui.figure,'position',get(h.gui.figure,'position')+[0 s(4) 0 -s(4)]);
                delete(h.gui.bod.panel); 
            end
            h.gui.rmfield('bod');
        end
        h.data.bod = [];
        return
    end
    if isa(bod,'CRData'), bod = bod.load(); end
    
    if ~isstruct(bod) || ~all(isfield(bod,{'x','y','alpha','chronos','topos','trace'}))
        crError('Invalide BOD data structure');
        h.data.bod = [];
        return;
    else
        h.data.bod = bod;
        gridScale = floor(min(size(h.video,2)./max(bod.y(:)), size(h.video,3)./max(bod.x(:))));
    end
    
    if ~isfield(h.gui,'bod')
        gui.panel    = uipanel  ('parent',h.gui.parent,       'BorderType','none');
        gui.current  = CRUIbox  ('parent',gui.panel,          'style',  'spinbox',   'value', 1, ...
                                 'title', 'current mode:',    'textWidth', 85, ...
                                 'Max',length(bod.alpha),     'callback',{@bodChanged, h});
        gui.scale    = CRUIbox  ('parent',gui.panel,          'style',  'spinbox',   'value', gridScale, ...
                                 'title', 'grid scale:',      'textWidth', 85, ...
                                 'callback',{@updateImage, h});
        gui.dynamic  = uicontrol('parent',gui.panel,          'style', 'checkbox',  'value', false,...
                                 'String','dynamic display',  'callback',{@updateImage, h});
        gui.axepanel = uipanel  ('parent',gui.panel,          'BorderType','none');

        gui.chronos = axes('parent',gui.axepanel); % subplot(2,1,1); %
        gui.alpha   = axes('parent',gui.axepanel); % subplot(2,1,2); %
        set([gui.chronos gui.alpha],'Units','normalized');
        set([gui.chronos gui.alpha],'Position',[0.1    0.1    0.8    0.8]);

        gui.layout    = GridBagLayout(gui.panel,    'HorizontalGap',5, 'VerticalGap',5);
        gui.axelayout = GridBagLayout(gui.axepanel, 'HorizontalGap',25, 'VerticalGap',25);

        gui.layout.add( gui.current.panel, 1, 1,  'Anchor', 'West', 'MinimumWidth', 150);
        gui.layout.add( gui.scale.panel,   1, 2,  'Anchor', 'West', 'MinimumWidth', 150);
        gui.layout.add( gui.dynamic,       2, 1 , 'Anchor', 'West', 'MinimumWidth', 100);
        gui.layout.add( gui.axepanel,      3,1:2, 'Anchor', 'West', 'MinimumHeight',200, 'Fill','Both');
        gui.layout.VerticalWeights = [ 0 0 1 ];

        gui.axelayout.add( gui.chronos,  1,1, 'Anchor', 'West', 'MinimumHeight',100, 'Fill','Both');
        gui.axelayout.add( gui.alpha,    2,1, 'Anchor', 'West', 'MinimumHeight', 90, 'Fill','Both');
        gui.axelayout.VerticalWeights = [ 1 0.2 ];

        h.gui.layout.add(gui.panel,3,1:2,'Fill', 'Both');
        h.gui.layout.VerticalWeights = [ 1 0 1 ];
        h.gui.bod = gui;
        set(h.gui.figure,'position',get(h.gui.figure,'position')+[0 -240 0 240]);
    else
        h.gui.bod.current.max = length(bod.alpha);
        set(h.gui.bod.current,'value',1);
        set(h.gui.bod.scale,  'value',gridScale);
    end
    % update graphics
    bodChanged(h);
end
