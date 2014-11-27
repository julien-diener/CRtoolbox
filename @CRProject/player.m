function h = player( this )
% call CRVideo player on this project video.
%
% See also: CRVideo.player

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if isempty(this.data.video.type)
    crError('this project video is not ready');
    return;
else
    % load video data
    this.getData('video');
end

% create the GUI
h = createGUI(this);

end

function showFlow( varargin )
    h = varargin{end};
    u = h.ctrl_uflow.value;
    v = h.ctrl_vflow.value;
    if isdata(h.project,u) && isdata(h.project,v)
        h.player.showFlow(h.player,getData(h.project,u),getData(h.project,v));
    else
        h.player.showFlow(h.player,[]);
    end
    returnKeyboardFocus(h);
end
function setScale( varargin )
    h = varargin{end};
    scale = str2double(h.ctrl_scale.value);
    if isnan(scale)
        set(h.ctrl_scale,'value',num2str(h.player.data.scale));
    else
        set(h.ctrl_scale,'value',num2str(scale));
        h.player.setScale(h.player, scale);
    end
    returnKeyboardFocus(h);
end
function showTracking( varargin )
    h = varargin{end};
    t = h.ctrl_trk.value;
    if isdata(h.project,t)
        h.player.showTracking(h.player,getData(h.project,t));
    else
        h.player.showTracking(h.player,[]);
    end
    returnKeyboardFocus(h);
end
function showBOD( varargin )
    h = varargin{end};
    t = h.ctrl_bod.value;
    if isdata(h.project,t)
        h.player.showBOD(h.player,getData(h.project,t));
    else
        h.player.showBOD(h.player,[]);
    end
    returnKeyboardFocus(h);
end
function setVideoOut( varargin )
    h = varargin{end};
    h.video_out = createVideo('output');
    set(h.ctrl_rec,'value',0);
    returnKeyboardFocus(h);
end
function grabImage( varargin )
    h = varargin{end};
    axes(h.player.gui.axe);
    img = getframe;
    save(CRImage(img.cdata));
    returnKeyboardFocus(h);
end
function switchRecord( varargin )
    h = varargin{end};
    if ~isfield(h,'video_out') || isempty(h.video_out)
        set(h.ctrl_rec,'value',0)
        return;
    end
    if get(h.ctrl_rec,'value'), h.player.setVideoOut(h.player, h.video_out);
    else                        h.player.setVideoOut(h.player, []);
    end
    returnKeyboardFocus(h);
end


% ----------------- create GUI components -----------------
function h = createGUI(project)
    h = CRParam();
    h.project = project;
    
    % control panel size
    W = 180;
    H = max(size(getData(h.project,'video'),2)+50, 100);

    % -------------- create player figure and panel --------------
    h.fig = figure(...
        'Name','Project player',...
        'NumberTitle','off', ...
        'Menubar','none',...
        'Toolbar','none',...
        'position',[0,0, size(getData(h.project,'video'),3)+W, H],...
        'Visible','off');%,...

    h.panel       = uipanel('Parent',h.fig,  'BorderType','none'); % main panel
    h.video_panel = uipanel('Parent',h.panel,'BorderType','none'); % video player
    h.ctrl_panel  = uipanel('Parent',h.panel,'BorderType','none'); % control panel

    % create the video player
    h.player = player(getData(h.project,'video'), 'parent',h.video_panel);


    % -------------- controls --------------
    h.ctrl_uflow  = CRUIbox('parent'   , h.ctrl_panel,        'style','popup'     ,...
                            'textWidth', 60,                  'title','u flow'    ,'callback',{@showFlow,h});  
    h.ctrl_vflow  = CRUIbox('parent'   , h.ctrl_panel,        'style','popup'     ,...
                            'textWidth', 60,                  'title','v flow'    ,'callback',{@showFlow,h}); 
    h.ctrl_scale  = CRUIbox('parent'   , h.ctrl_panel,        'style','edit'      ,...
                            'textWidth', 60,                  'title','flow scale',...
                            'value'    , '1',                 'callback' ,{@setScale,h});  

    h.ctrl_trk    = CRUIbox('parent',    h.ctrl_panel,        'style','popup'     ,...
                            'textWidth', 60,                  'title','tracking'  ,'callback',{@showTracking,h});  

    h.ctrl_bod    = CRUIbox('parent',    h.ctrl_panel,        'style','popup'     ,...
                            'textWidth', 60,                  'title','BOD'       ,'callback',{@showBOD,h});  

    h.ctrl_grab   = uicontrol('parent',h.ctrl_panel,          'style','pushbutton',...
                              'String','grab image',          'callback',{@grabImage,    h});
    h.ctrl_vout   = uicontrol('parent',h.ctrl_panel,          'style','pushbutton',...
                              'String','select output video', 'callback',{@setVideoOut,  h});
    h.ctrl_rec    = uicontrol('parent',h.ctrl_panel,          'style','togglebutton',...
                              'String','record',              'callback',{@switchRecord, h});

    h.ctrl_tmp    = uipanel  ('parent',h.ctrl_panel,  'BorderType','none');
 
    h.ctrl_update = uicontrol('parent',h.ctrl_panel,               'style','pushbutton',...
                             'String','update project data list', 'callback',{@updateDataList, h});

    % -------------- layout -------------- 
    h.layout      = GridBagLayout(h.panel);
    h.ctrl_layout = GridBagLayout(h.ctrl_panel, 'VerticalGap',5,'HorizontalGap',5);

    h.ctrl_layout.add( h.ctrl_uflow.panel, 1,1:2,'Anchor', 'East', 'Fill','Horizontal');
    h.ctrl_layout.add( h.ctrl_vflow.panel, 2,1:2,'Anchor', 'East', 'Fill','Horizontal');
    h.ctrl_layout.add( h.ctrl_scale.panel, 3,1:2,'Anchor', 'East', 'Fill','Both',       'MinimumHeight', 50);
    h.ctrl_layout.add( h.ctrl_trk.panel  , 4,1:2,'Anchor', 'East', 'Fill','Horizontal', 'MinimumHeight', 50);
    h.ctrl_layout.add( h.ctrl_bod.panel  , 5,1:2,'Anchor', 'North', 'Fill','Horizontal', 'MinimumHeight', 50);
    h.ctrl_layout.add( h.ctrl_grab       , 6,1:2,'Anchor', 'East', 'Fill','Horizontal');
    h.ctrl_layout.add( h.ctrl_vout       , 7, 1 ,'Anchor', 'West', 'Fill','Horizontal', 'MinimumWidth', 120);
    h.ctrl_layout.add( h.ctrl_rec        , 7, 2 ,'Anchor', 'East',                      'MinimumWidth',  50);
    h.ctrl_layout.add( h.ctrl_tmp        , 8, 2 ,'Anchor', 'South','Fill','Both');
    h.ctrl_layout.add( h.ctrl_update     , 9,1:2,'Anchor', 'South','Fill','Both');
    h.ctrl_layout.VerticalWeights = [ 0 0 0 1 1 0 0 2 0 ];

    h.layout.add( h.video_panel, 1,1,'Anchor', 'West', 'Fill','Both');
    h.layout.add( h.ctrl_panel , 1,2,'Anchor', 'East', 'Fill','Vertical', 'MinimumWidth', W);
    h.layout.HorizontalWeights = [1 0];

    % ---------- figure is ready ---------- 
    updateDataList(h);
    movegui(h.fig,'center');
    set(h.fig,'visible','on');
    
    set(h.fig,'Units', 'pixels');  % force resize
    set(h.fig,'position',get(h.fig,'position')+[0 0 0 1]);  
end

% ----------------- update popup data list -----------------
function updateDataList( varargin )
    h = varargin{end};
    set(h.ctrl_uflow, 'string', ['---' ; h.project.dataList()] );  
    set(h.ctrl_vflow, 'string', ['---' ; h.project.dataList()] );  
    set(h.ctrl_trk  , 'string', ['---' ; h.project.dataList()] );  
    set(h.ctrl_bod  , 'string', ['---' ; h.project.dataList()] );  
end

% ----------------- return keyboard focus to main figure -----------------
function returnKeyboardFocus(h)
    try
        warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame
        javaFrame = get(h.fig,'JavaFrame');
        javaFrame.getAxisComponent.requestFocus;
    end
end