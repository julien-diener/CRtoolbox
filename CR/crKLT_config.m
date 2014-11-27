function ok = crKLT_config( varargin )
% Configuration GUI for tool 'crKLT'
% (1)  ok = crKLT_config( video        parameters, open_gui=true)
% (2)  ok = crKLT_config( video, mask, parameters, open_gui=true)
% (3)  ok = crKLT_config(    input,    parameters, open_gui=true)
%
% First crKLT_config assess parameters value for crKLT and fill missing
% ones by defaults (taken from either crKLT_tracking.param or
% crKLT_flow.param, depending on the method choosen).
% Then, if open_gui is true, erroneous parameter value are set
% to default ones and a configuration user interface is opened. 
%
% Input:
% ------
% - 'video'      the CRVideo to display in background
% - 'mask'       (optional) apply corner detection only inside CRImage mask
% - 'paramaters' a CRParam object that (can) contain initial values for the
%                parameters of tool crKLT:
%        > method       Either 'tracking' or 'flow'
%        > minDist      Minimum required distance between detected corners
%        > maxFeature   Maximum number of corner to detect
%        > winSize      Size of matching window
%        > dt           Time between 2 images
%        > overlap      in case method=flow, the size of flow array cells
%                       are winSize*(1-overlap)
%        * pyramid      Size of the pyramid
%        * maxIteration Max iteration per pyramid level for LK iteration
%        * threshold    Convergence threshold in pixel for LK iteration 
%                       can be a vector giving a different value for each
%                       pyramid level
%        * output       indicates where to store computation (see crKLT help)
%
% The parameters marked by a * are not configurable within the user interface. 
%
% - In case (3), input is a CRParam or a structure containing the fields
%   'video' and 'mask' (can be empty).
%
% Output:
% -------
% - input 'parameters' has been updated.
% - in case open_gui = true, 'ok' is true if the user has clicked the ok
%   button and false otherwise.
% - in case open_gui = false. 'ok' is false if any of the input
%   parameters were detected as incorrect.
%
% See also: crKLT

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

% manage input arguments
if nargin<3
    if nargin~=2 || ~isa(varargin{2},'CRParam')
        error('crKLT_config: Not enough input arguments');
    end
end
if isa(varargin{1},'CRVideo') % case (1) or (2)
    video = varargin{1};
    if isa(varargin{2},'CRParam')
        mask  = [];
        param = varargin{2};
    else
        mask  = varargin{2};
        param = varargin{3};
    end
else
    video = varargin{1}.video;
    mask  = varargin{1}.mask;
    param = varargin{2};
end
if islogical(varargin{end}) && numel(varargin{end})==1
    open_gui = varargin{end};
else
    open_gui = true;
end

ok = false;       % returned value

% test if input arguments are of correct class
if ~isa(video,'CRVideo')
    crError('input video must be a CRVideo object');
    return;
end
if ~isempty(mask) && ~isa(mask,'CRImage')
    crError('input mask must be a CRImage object');
    return;
end
if ~isa(param,'CRParam')
    crError('input parameter must be a CRParam object');
    return;
end

% assess crKLT parameters
incorrect_param = validate_parameter();

    
% if ~open_gui, return here
if ~open_gui
    ok = isempty(incorrect_param);
    return;  
end



% otherwise, start GUI
% --------------------

% if there are incorrect parameters, display which ones
if ~isempty(incorrect_param)
    crWarning('The following parameter(s) were incorrect: %s',[incorrect_param{:}])
    crMessage(4,'They were replaced by default value');
end

image = video(1);
if any(size(mask)~= [image.height,image.width])
    if ~isempty(mask), crWarning('crKLT_configUI: Incorrect mask size'); end
    mask  = ones(image.height,image.width);
end

h  = struct();    % store handles to graphical objects and data

% load default parameter set
mt = get(param,'method','');
if strcmp(mt,'tracking'), 
    p = CRParam('crKLT_tracking');
else                      p = CRParam('crKLT_flow');
end
p.merge(param,'overload');

p.assert('overlap',0);      % in case methods is tracking
p.assert('dt'     ,1);      % overlap and dt are not defined

p.overlap = 100*p.overlap;  % convert to percentage
p.fps     =   1/p.dt;       % convert to frequency

% create GUI data
cornerImg = [];
corners   = [];
flowGrid  = [];
flowSize  = [];

makeGUI();        % construct graphical objects
init();           % init display image and GUI data
updateDisplay();  % update image to display


% Display figure
movegui(h.fig,'center');
set(h.fig,'Visible','on');
set(h.fig,'Units', 'pixels');
set(h.fig,'position',get(h.fig,'position')+[0 0 0 1]);  % force resize

uiwait(h.fig);
drawnow();
% end of crKLT_config



% Validate parameters and open GUI if necessary or open_gui = true
% ----------------------------------------------------------------
function incorrect = validate_parameter()
    % load default parameter set
    if strcmp(get(param,'method',''),'tracking')
         default = CRParam('crKLT_tracking');
    else default = CRParam('crKLT_flow');
    end
    param.merge(default);  % fill missing value

    mt = param.method;
    mD = param.minDist;
    mF = param.maxFeature;
    wS = param.winSize;
    py = param.pyramid;
    mI = param.maxIteration;
    th = param.threshold;
    if strcmp(mt,'flow')
        ol = param.overlap;
        dt = param.dt;
    end
    incorrect = {};

    if isempty(mt) || ~ischar(mt) || ~ismember(mt,{'tracking', 'flow'})
        if open_gui, param.method = default.method; end
        incorrect{end+1} = '''method'' ';
    end
    if ~isscalar(mD) || ~isnumeric(mD) || mD < 1
        if open_gui, param.minDist = default.minDist; end
        incorrect{end+1} = '''minDist'' ';
    end
    if ~isscalar(mF) || ~isnumeric(mF) || mF < 0
        if open_gui, param.maxFeature = default.maxFeature; end
        incorrect{end+1} = '''maxFeature'' ';
    end
    if ~isscalar(wS) || ~isnumeric(wS) || wS < 3
        if open_gui, param.winSize = default.winSize; end
        incorrect{end+1} = '''winSize'' ';
    end
    if strcmp(mt,'flow') 
        if(~isscalar(ol) || ~isnumeric(ol) || ol < 0 || ol>0.9)
            if open_gui, param.overlap = default.overlap; end
            incorrect{end+1} = '''overlap'' ';
        end
        if ~isscalar(dt) || ~isnumeric(dt) || dt <= 0
            if open_gui, param.dt = default.dt; end
            incorrect{end+1} = '''dt'' ';
        end
    end
    if ~isscalar(py) || ~isnumeric(py) || mD < 1
        if open_gui, param.pyramid = default.pyramid; end
        incorrect{end+1} = '''pyramid'' ';
    end
    if isempty(mI) || ~isnumeric(mI) || any(mI < 1)
        if open_gui, param.maxIteration = default.maxIteration; end
        incorrect{end+1} = '''maxIteration'' ';
    end
    if isempty(th) || ~isnumeric(th) || any(th < eps)
        if open_gui, param.threshold = default.threshold; end
        incorrect{end+1} = '''threshold'' ';
    end
end

% ------------------- Quit GUI ------------------- 
function quitUI(varargin)
    done = varargin{end};
    if done
        param.minDist    =   p.minDist;
        param.maxFeature =   p.maxFeature;
        param.winSize    =   p.winSize;
        param.method     =   p.method;
        if strcmp(p.method,'flow')
            param.overlap    =   p.overlap/100;
            param.dt         = 1/h.fps.value;
        end
        
        if strcmp(p.method,'flow'), output = get(CRParam('crKLT_flow'),    'output');
        else                        output = get(CRParam('crKLT_tracking'),'output');
        end
        param.assert('output',output);
        param.output.assert('file',output.file);
        param.output.assert('name',output.name);
    end
    ok = done;
    delete(h.fig);
end

% ---------- init function -----------\
function init()
    updateCornerImage();
    updateCorners();
    updateFlowArray()
    methodChanged(h.method.value);
%     updateDisplay();
end

% ---------- Callback functions ---------- 
function maxFeatureChanged(new_max)
    p.maxFeature = new_max;
    updateCornerImage();
    updateCorners();
    updateDisplay();
end
function minDistChanged(new_minDist)
    p.minDist = new_minDist;
    updateCorners();
    updateDisplay();
end
function winSizeChanged(new_winSize)
    p.winSize = new_winSize;
    updateFlowArray();
    updateDisplay();
end
function overlapChanged(new_overlap)
    p.overlap = new_overlap;
    updateFlowArray();
    updateDisplay();
end
function methodChanged(new_method)
    p.method = new_method;
    is_flow = strcmp(p.method,'flow');
    set(h.overlap,'enable',is_flow);
    set(h.fps,    'enable',is_flow);
    updateDisplay();
end

% ---------- Update functions ---------
function updateCornerImage()
    % create the matrix used for corner detection
    % from the input image converted to double gray scale
    cornerImg = cornerImage(image.convert(1,'double').data, p.minDist);
end
function updateCorners()
    corners = localMax(cornerImg,p.minDist,p.maxFeature,mask());
    corners(corners(:,2)<=0,:) = [];
    p.maxFeature = size(corners,1);
    set(h.maxFeature,'value',p.maxFeature);
end

function updateFlowArray()
    iw = image.width;
    ih = image.height;
    ic = round((1-p.overlap/100)*p.winSize);
    flowGrid(:,1) = [   0  ,  iw  ,  0, iw, ic, ic, iw-ic, iw-ic ];
    flowGrid(:,2) = [ ih-ic, ih-ic, ic, ic, ih,  0,  ih  ,   0  ];
    flowSize{1}   = num2str(floor(ih/ic));
    flowSize{2}   = num2str(floor(iw/ic));
end
function updateDisplay()
    axes(h.axe)
    hold off

    imshow(image);

    hold on
    [ind{1:2}] = ind2sub([image.height,image.width], corners);
    plot(ind{2},ind{1},'.r');
    
    if strcmp(p.method,'flow')
        for i=1:2:size(flowGrid(:,1))
            plot(flowGrid([i,i+1],1),flowGrid([i,i+1],2));
        end
        set(h.flowSize,'String', ['Flow size: ' flowSize{1} 'x' flowSize{2}]);
    else
        set(h.flowSize,'String', '');
   end
end

% ---------- contruct graphical objects ---------
function makeGUI()
    % sizes used to layout the UI panels
    h1 = 200;
    h2 = 130;
    h3 = 30;
    h0 = h1+h2+h3 +40; % UI panels and window menu
    w1 = 120;
    w2 = 80;
    w0 = w1+w2;

    h.fig = figure(...
        'Name','KLT parameters',...
        'NumberTitle','off', ...
        'Menubar','none',...
        'Toolbar','none',...
        'position',[0,0, image.width+w0, max(image.height, h0)],...
        'CloseRequestFcn',{@quitUI,0},...
        'Visible','off');%,...
%         'ResizeFcn',@resizeFunc);

    h.panel = uipanel('Parent',h.fig,'BorderType','none');

    % --- Create uicomponents ---
    h.axePanel = uipanel('Parent',h.panel,'BorderType','none');
    h.axe = axes('parent',h.axePanel);
    set(gca,'Units','normalized');
    set(gca,'Position',[0 0 1 1]);
    plot(sin(0:0.01:2*pi));
    % ----------------------------------------------------------------------- %
    h.slider_panel = uipanel('Parent',h.panel,'BorderType','none');
    h.maxFeature   = CRUIbox('parent',h.slider_panel,'style','slider',...
                             'title','number','min',1,'max',5000, ...
                             'value',p.maxFeature,'step',100,'textWidth',w2,...
                             'callback', @maxFeatureChanged);
    h.minDist      = CRUIbox('parent',h.slider_panel,'style','slider',...
                             'title','distance','min',1,'max',50,...
                             'value',p.minDist, 'step',1,'textWidth',w2,...
                             'callback', @minDistChanged);
    % ----------------------------------------------------------------------- %
    h.spin_panel = uipanel('Parent',h.panel,'BorderType','none');
    h.method = CRUIbox('parent',h.spin_panel,'style','popup',...
                       'title', 'KLT method:','string', {'tracking','flow'},...
                       'value', p.method, 'textWidth',w1,...
                       'callback', @methodChanged);
    h.winSize = CRUIbox('parent',h.spin_panel,'style','spinbox',...
                        'title','match window size:','textWidth',w1,...
                        'min',4,'max',512,'value',p.winSize,...
                        'callback', @winSizeChanged);
    h.overlap = CRUIbox('parent',h.spin_panel,'style','spinbox',...
                        'title', 'overlap (in %):','textWidth',w1,...
                        'min',0,'max',99,'value',p.overlap,...
                        'callback', @overlapChanged);
    h.fps     = CRUIbox('parent',h.spin_panel,'style','spinbox',...
                        'title','frame per second:','textWidth',w1,...
                        'min',1,'value',p.fps);
    h.flowSize = uicontrol('Parent',h.spin_panel,'Style','text','String', '');
    % ----------------------------------------------------------------------- %
    h.close_panel  = uipanel(  'Parent',h.panel,       'BorderType','none');
    h.close_cancel = uicontrol('Parent',h.close_panel, 'Style','pushbutton',...
                               'Callback',{@quitUI,0}, 'String','Cancel');
    h.close_ok     = uicontrol('Parent',h.close_panel, 'Style','pushbutton',...
                               'Callback',{@quitUI,1}, 'String','Ok');

    % --- Lay-out uicomponents ---
    h.layout        = GridBagLayout(h.panel,       'HorizontalGap', 2, 'VerticalGap', 3);
    h.slider_layout = GridBagLayout(h.slider_panel,'HorizontalGap', 2, 'VerticalGap', 1);
    h.spin_layout   = GridBagLayout(h.spin_panel,  'HorizontalGap', 1, 'VerticalGap', 4);
    h.close_layout  = GridBagLayout(h.close_panel, 'HorizontalGap', 2, 'VerticalGap', 1);

    h.slider_layout.add(h.maxFeature.panel,1,1,'MinimumWidth',w1, 'MinimumHeight',300, 'Anchor', 'Center');
    h.slider_layout.add(h.minDist   .panel,1,2,'MinimumWidth',w1, 'MinimumHeight',300, 'Anchor', 'Center');

    h.spin_layout.add(h.method .panel,1,1,'MinimumWidth',w0, 'MinimumHeight', 20, 'Anchor', 'North');
    h.spin_layout.add(h.winSize.panel,2,1,'MinimumWidth',w0, 'MinimumHeight', 20, 'Anchor', 'North');
    h.spin_layout.add(h.overlap.panel,3,1,'MinimumWidth',w0, 'MinimumHeight', 20, 'Anchor', 'North');
    h.spin_layout.add(h.fps    .panel,4,1,'MinimumWidth',w0, 'MinimumHeight', 20, 'Anchor', 'North');
    h.spin_layout.add(h.flowSize     ,5,1,'MinimumWidth',w0, 'MinimumHeight', 20, 'Anchor', 'South');
    h.spin_layout.VerticalWeights = [0 0 0 1];

    h.close_layout.add(h.close_cancel,1,1,'MinimumWidth',60, 'MinimumHeight',   25, 'Anchor', 'SouthEast');
    h.close_layout.add(h.close_ok    ,1,2,'MinimumWidth',60, 'MinimumHeight',   25, 'Anchor', 'SouthEast');

    h.layout.add(h.axePanel    ,1:3,1,'MinimumWidth',w0, 'MinimumHeight',h0, 'Anchor', 'West', 'Fill', 'Both');
    h.layout.add(h.slider_panel, 1 ,2,'MinimumWidth',w0, 'MinimumHeight',h1, 'Anchor', 'NorthEast');
    h.layout.add(h.spin_panel  , 2 ,2,'MinimumWidth',w0, 'MinimumHeight',h2, 'Anchor', 'NorthEast');
    h.layout.add(h.close_panel , 3 ,2,'MinimumWidth',w0, 'MinimumHeight',h3, 'Anchor', 'SouthEast');

    h.layout.HorizontalGap = 5;
    h.layout.VerticalGap   = 5;
    h.layout.VerticalWeights = [0 0 1];
    h.layout.HorizontalWeights = [1 0];
end

% function resizeFunc(varargin)
%     disp(['size: ' array2str(get(h.fig,'position'))]);
% end

end