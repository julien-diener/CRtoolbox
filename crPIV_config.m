function ok = crPIV_config( varargin )
% Configuration GUI for tool 'crPIV'
% (1)  ok = crPIV_config( video        parameters, open_gui=true)
% (2)  ok = crPIV_config( video, mask, parameters, open_gui=true)
% (3)  ok = crPIV_config(    input,    parameters, open_gui=true)
%
% First crPIV_config assess parameters value for crPIV and fill missing
% ones by defaults (taken from either crPIV.param).
% Then, if open_gui is true, erroneous parameter value are set
% to default ones and a configuration user interface is opened. 
%
% Input:
% ------
% - 'video' is a CRVideo to display in background
% - 'mask'  (optional) only display which are cells inside CRImage 'mask'
% - 'paramaters' is a CRParam object that can contain initial values for
%   the parameters of tool crPIV:
%    - method:   MatPIV method, one of 'single' or 'multin' pass(es)
%    - winSize:  size of the interrogation regions
%    - dt:       time in second between 2 images of the video 
%    - overlap:  overlap of the interrogation regions
%    - output    CRParam or structure that contains the field
%       * path:  path to directory for saving results flow. (optional)
%       * file:  a cell array of the file name of the first flow images (u & v)
%       * name:  a cell array of the names of the output flow (see below)
%
% output structure is not configurable within the user interface.
%
%
% Output:
% -------
%  - input 'parameters' is updated with user input.
%  - in case open_gui = true, 'ok' is true if the user has clicked the ok
%    button and false if he has clicked the cancel button.
%  - in case open_gui = false. 'ok' is false if any of the input
%    parameters were detected as incorrect.
%
% See also: crPIV

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


% manage input arguments
if nargin<3
    if nargin~=2 || ~isa(varargin{2},'CRParam')
        error('crPIV_config: Not enough input arguments');
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

ok = false;  % returned value

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
    

% if not open_gui, quit here
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

bgImage = video(1);  % background image
if ~isempty(mask) && ~isa(mask,'CRImage')
    mask = CRImage(mask); 
end

% intiate variables
p = CRParam(param);         % local copy of param.
p.merge(CRParam('crPIV'));  % fill missing parameters with default values
h  = struct();              % store handles to graphical objects

p.winSize =     p.winSize(1); % if winSize has more than one value
p.overlap = 100*p.overlap;    % convert to percentage
p.fps     =   1/p.dt;         % convert to frequency

% check p.method is one of 'single' or 'multin'
if ~strmatch(p.method,{'single','multin'},'exact'), 
    if strcmp(p.method,'multi') p.method = 'multin'; % use multin instead of multi
    else                        p.method = 'single'; % default
    end
end

minW = 120;        % some ui components minimum width

makeGUI();                % construct graphical objects
updateParam([],[],true);  % display bgImage and PIV grid

% Display figure
movegui(h.fig,'center');
set(h.fig,'Visible','on');
set(h.fig,'Units', 'pixels');
set(h.fig,'position',get(h.fig,'position')+[0 0 0 1]);  % force resize

uiwait(h.fig);
% end of crPIV_config


% Validate parameters and open GUI if necessary or open_gui = true
% ----------------------------------------------------------------
function incorrect = validate_parameter()
    default = CRParam('crPIV');
    param.merge(default);
    
    wS = param.winSize;
    ol = param.overlap;
    dt = param.dt;
    mt = param.method;
    incorrect = {};
    
    if ~isscalar(wS) || ~isnumeric(wS) || wS < 3
        param.winSize = default.winSize;
        incorrect{end+1} = '''winSize'' ';
    end
    if ~isscalar(ol) || ~isnumeric(ol) || ol < 0 || ol>0.9
        param.overlap = default.overlap;
        incorrect{end+1} = '''overlap'' ';
    end
    if ~isscalar(dt) || ~isnumeric(dt) || dt <= 0
        param.dt = default.dt;
        incorrect{end+1} = '''dt'' ';
    end
    if isempty(mt) || ~ischar(mt) || ~ismember(mt,{'single', 'multi', 'multin'})
        param.method = default.method;
        incorrect{end+1} = '''method'' ';
    end
end

% ------------------- Quit GUI ------------------- 
function quitUI(varargin)
    done = varargin{end};
    if done
        param.winSize =   p.winSize;
        param.overlap =   p.overlap/100;
        param.dt      = 1/p.fps;
        param.method  =   p.method;
        param.output  =   p.output;
    end
    ok = done;
    delete(h.fig);
end
% ---------- Update matching window grid --------- 
function updateParam(varargin)
    lastSize  = p.winSize;
    lastOver  = p.overlap;
    p.winSize = h.winSize.value;
    p.overlap = h.overlap.value;
    p.method  = h.method .value;
    p.fps     = h.fps    .value;
    
    if nargin>2 || lastSize~=p.winSize || lastOver~=p.overlap
        axes(h.axe);
        hold off
        imshow(bgImage)
        hold on
        
        % set overlap s.t. overlap*winSize is an integer (as required by matpiv)
        p.overlap = 100*floor(p.overlap*p.winSize/100)/p.winSize;
        
        % draw grid  
        % inspired by matpiv code -> it (hopefully) gives the same grid
        N  = p.winSize;
        M  = N;
        ii = 1:((1-p.overlap/100)*M):bgImage.width -M+1 ;
        jj = 1:((1-p.overlap/100)*N):bgImage.height-N+1 ;
        x = repmat( ii+M/2  , length(jj), 1);
        y = repmat((jj+M/2)', 1, length(ii));   
%         [x,y] = meshgrid(ii,jj);
%         x = x+M/2;
%         y = y+M/2;

        % display grid cells (if mask find grid cells inside the mask)
        if ~isempty(mask)
            m = mask.divSize(floor(size(mask)./((1-p.overlap/100)*[N M])));
            m = logical(m());
            m = m(1:size(x,1),1:size(x,2)); %(round(x(:)/M),round(y(:)/N));
            plot(x( m(:)),y( m(:)),'.b');
            plot(x(~m(:)),y(~m(:)),'.r');
        else
            plot(x      ,y      ,'.b');
        end
        

        % draw 5 cells borders (in the center and in the four corners)
        x0 = 2*x(1,1);
        y0 = 2*y(1,1);
        plot([x0-M x0+M x0+M x0-M x0-M]/2,[y0-N y0-N y0+N y0+N y0-N]/2,'g',...
             'lineWidth',2)
        x0 = 2*x(floor((end+1)/2),floor((end+1)/2));
        y0 = 2*y(floor((end+1)/2),floor((end+1)/2));
        plot([x0-M x0+M x0+M x0-M x0-M]/2,[y0-N y0-N y0+N y0+N y0-N]/2,'g',...
             'lineWidth',2)
        x0 = 2*x(1,end);
        y0 = 2*y(1,end);
        plot([x0-M x0+M x0+M x0-M x0-M]/2,[y0-N y0-N y0+N y0+N y0-N]/2,'g',...
             'lineWidth',2)
        x0 = 2*x(end,1);
        y0 = 2*y(end,1);
        plot([x0-M x0+M x0+M x0-M x0-M]/2,[y0-N y0-N y0+N y0+N y0-N]/2,'g',...
             'lineWidth',2)
        x0 = 2*x(end,end);
        y0 = 2*y(end,end);
        plot([x0-M x0+M x0+M x0-M x0-M]/2,[y0-N y0-N y0+N y0+N y0-N]/2,'g',...
             'lineWidth',2)

        set(h.flowSize,'String',['Flow size: ' num2str(size(x,1)) 'x' num2str(size(x,2))]);
    end
end

% ---------- contruct graphical objects ---------
function makeGUI()
    pos = [0 0 0 0];   % position of the figure
    pos(3) =     bgImage.width  +200;
    pos(4) = max(bgImage.height, 300);

    h.fig = figure(...  % the main figure of the UI
        'Name','PIV parameters',...
        'NumberTitle','off', ...
        'Menubar','none',...
        'Toolbar','none',...
        'position',pos,...
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
    h.winSize = CRUIbox('parent',h.panel,'style','spinbox',...
                        'title','match window size:','textWidth',minW,...
                        'min',4,'value',p.winSize,'max',512, 'callback', @updateParam);
    h.overlap = CRUIbox('parent',h.panel,'style','spinbox',...
                        'title', 'overlap (in %):','textWidth',minW,...
                        'min',0,'value',p.overlap,'max', 99, 'callback', @updateParam);
    h.flowSize = uicontrol('Parent',h.panel, 'Style','text', 'String', 'Flow size: ');
    % ----------------------------------------------------------------------- %
    h.advanced_panel = uipanel('Parent',h.panel,'Title','Advanced setting');
    h.method = CRUIbox('parent',h.advanced_panel,'style','popup',...
                        'title', 'PIV method:','textWidth',minW,...
                        'string', {'single','multin'}, 'value',p.method,...
                        'callback', @updateParam);
    h.fps = CRUIbox('parent',h.advanced_panel,'style','spinbox',...
                    'title','frame per second:','textWidth',minW,...
                    'min',1,'value',p.fps, 'callback', @updateParam);
    % ----------------------------------------------------------------------- %
    h.close_panel  = uipanel('Parent',h.panel,'BorderType','none');
    h.close_cancel = uicontrol('Parent',h.close_panel,       'Style','pushbutton',...
                               'Callback',{@quitUI,false},   'String','Cancel');
    h.close_ok     = uicontrol('Parent',h.close_panel,       'Style','pushbutton',...
                               'Callback',{@quitUI,true},    'String','Ok');

    % --- Lay-out uicomponents ---
    h.layout          = GridBagLayout(h.panel,         'HorizontalGap', 2, 'VerticalGap', 4);
    h.advanced_layout = GridBagLayout(h.advanced_panel,'HorizontalGap', 1, 'VerticalGap', 2);
    h.close_layout    = GridBagLayout(h.close_panel,   'HorizontalGap', 1, 'VerticalGap', 2);

    h.advanced_layout.add(h.method.panel, 1, 1, 'MinimumWidth',minW+80,'Anchor', 'SouthWest');
    h.advanced_layout.add(h.fps.panel,    2, 1, 'MinimumWidth', 200,   'Anchor', 'West');
    h.advanced_layout.HorizontalGap = 5;
    h.advanced_layout.VerticalGap   = 5;
    h.advanced_layout.VerticalWeights = [0 0 1];

    h.close_layout.add(h.close_cancel,1,1,'MinimumWidth',65, 'MinimumHeight',   25, 'Anchor', 'NorthEast');
    h.close_layout.add(h.close_ok    ,2,1,'MinimumWidth',65, 'MinimumHeight',   25, 'Anchor', 'SouthEast');

    h.layout.add(h.axePanel      ,1:5,1,'MinimumWidth',200, 'MinimumHeight',200, 'Anchor', 'West', 'Fill', 'Both');
    h.layout.add(h.winSize.panel , 1 ,2,'MinimumWidth',200, 'MinimumHeight', 20, 'Anchor', 'South');
    h.layout.add(h.overlap.panel , 2 ,2,'MinimumWidth',200, 'MinimumHeight', 20, 'Anchor', 'South');
    h.layout.add(h.flowSize      , 3 ,2,'MinimumWidth',200, 'MinimumHeight', 20, 'Anchor', 'South');
    h.layout.add(h.advanced_panel, 4 ,2,'MinimumWidth',200, 'MinimumHeight', 80, 'Anchor', 'Center');
    h.layout.add(h.close_panel   , 5 ,2,'MinimumWidth',70,  'MinimumHeight', 60, 'Anchor', 'SouthEast');

    h.layout.HorizontalGap = 5;
    h.layout.VerticalGap   = 5;
    h.layout.VerticalWeights = [0 0 0 1 0];
    h.layout.HorizontalWeights = [1 0];
end

% function resizeFunc(varargin)
%     disp(['size: ' array2str(get(h.fig,'position'))]);
% end

end