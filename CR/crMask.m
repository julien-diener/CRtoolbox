function mask = crMask( input, param, output )
%  (1) mask = crMask( video, parameters = [] )
%  (2) mask = crMask( input, parameters )
%
% Compute a mask for CRVideo 'video'. It opens a user interface that allows
% the user to make the mask manually.
% 
% Input:
% ------
% case (1)
%  'video' is a configured input CRVideo
%  'parameters' is an optional CRParam or structure that contain the fields:
%    - threshold: threshold to segment pixel color variance 'stdVideo'
%    - output   : (optional) a sub-structure containing
%      * maskFile  file to store the computed mask
%      * stdFile   file to store the variance of pixel color
%      * path      path to store the files 
%      * name      name of return CRData (see below)
%                  if provided, is overloaded by [name '.png']
%
% > If 'maskFile' is not empty, the computed mask will be saved when the
%   user quit. If 'stdFile' exist when crMask start, it is loaded at start
%   and if 'maskFile' exist, it is loaded as the manual_mask (see below).
% > If the path is not provided (or empty), the file names are considered
%   to contain the path (full or relative to pwd). 
% > Both file need to be image (*.bmp,*.png,...) or matlab matrix (*.mat) 
%   writable by CRImage (see CRImage constructors).
%
% case (2) - defined for use within a CRProject -
%    - 'input'      a CRParam containing a field 'video'
%    - 'parameters' a CRParam similar to (1)
%
% Output:
% -------
% 'mask' is a CRImage computed such that:
%    mask = (std_Video > threshold) .* manual_mask
%    where,
%       -> std_Video is the variance of pixel color
%       -> manual_mask is the user manually drawn mask
%
% If input 'parameters' is a CRParam, it has been updated.
%
% If parameters.output.name is given, a CRData containing the computed mask
% and called by the name given in output.name is added to 'output'. 

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

% manage input arguments
if nargin<1
    crError('not enough input');
    return;
elseif isa(input,'CRVideo')
    video = input;
else
    video = get(input,'video','');
    if ~isa(video,'CRVideo'), 
        crError('incorrect input data');
        return;
    end
end

if nargin<2,            param  = CRParam();
elseif isstruct(param), param  = CRParam(param); 
end

param.assert('threshold', 0);

p = CRParam(param);   % copy of param used in the following
p.assert('output');
p.output.assert('path'    ,'');
p.output.assert('name'    ,'');
p.output.assert('maskFile','');
p.output.assert('stdFile' ,'');

printTitle('Compute video mask');

% set video data format for computation
video.depth  = 1;
video.format = 'double';

    
p.maskFile = formatPath(p.output.path,p.output.maskFile);
p.stdFile  = formatPath(p.output.path,p.output.stdFile);

% start GUI and wait for user to be done
p.ok_button_pressed = false;  % to check if user has pressed ok button
computeMask_GUI();    
if p.ok_button_pressed
	 crMessage('mask computed');
else crMessage('crMask canceled by user');
end


% update return threshold parameter
param.threshold = p.threshold;

% if any file name have changed, update the returned param
if ~strcmp(p.maskFile,formatPath(p.output.path,p.output.maskFile)) 
    param.output.maskFile = p.maskFile;
end
if ~strcmp(p.stdFile ,formatPath(p.output.path,p.output.stdFile)) 
    param.output.stdFile  = p.stdFile;
end

% if param.output.name is given, 
% make the returned CRData and overload param.file
if isfield(param,'output') && isfield(param.output,'name')
    name = get(p.output,'name');
    if iscell(name), name = name{1}; end
    param.output.(name) = CRData(p.mask,p.maskFile,false);
    param.output.maskFile = [name '.png'];
end

% check if mask should be saved
if isfield(param,'output') && ~isempty(get(param.output,'maskFile',''))
    p.mask.save(formatPath(p.output.path,param.output.maskFile));
end

if nargout, mask = p.mask; end

% The End
printTitle();
disp(' ');

    
% --------------------------- GUI ---------------------------
function computeMask_GUI()
    % initialize mask and images
    p.manualMask = [];    % mask drawn by the user using crRoiPoly
    p.varImage   = [];    % variance of pixel color
    p.varMask    = [];    % mask obtained by thresholding varImage
    p.mask       = [];    % the final mask (manualMask.*varMask)
    
    % set video format for computation
    video.depth  = 0;
    p.videoImg   = video(1);  % image of video in full depth (typically rgb)
    video.depth  = 1;         % set video to gray

    % Create GUI
    makeGUI();

    % Load variance mask if exist
    loadImage();

    % Update image and histogram
    updateHistogram();
    updateImage();


    % Display figure
    movegui(p.fig,'center');
    set(p.fig,'Visible','on');
    set(p.fig,'Units', 'pixels');
    set(p.fig,'position',get(p.fig,'position')+[0 0 0 1]);  % force resize
    while ishandle(p.fig)
    % just in case it resumes for no reason (it should not append anymore)
        uiwait(p.fig)
    end
end

% Quit GUI  (done is 0 if user press cancel)
function quitUI(varargin)
    p.ok_button_pressed = varargin{end}>0;
    p.mask = CRImage(p.mask);
    delete(p.fig);
end


% ------------ callback function of ui-components (events) ------------ %

% --- Executed by p.thresh_sl (threshold) slider movement
function thresholdChanged(varargin)
    p.threshold = get(p.thresh_slid,'Value');
    computeStdMask();
    updateHistogram();
    updateImage();
end
 
% --- Executed by button p.var_save
function saveVarImage(varargin)
    saveImage('varImage','stdFile','Save image of pixel color variance',...
              'Yes', 'Choose an other file', 'Cancel', 'Cancel');
end
function done = saveImage(dataField,fileField,title,varargin)
    options = varargin;
    fileName = formatPath(p.(fileField));
    if ~isempty(fileName) && fileName(end) == '#', fileName = fileName(1:end-1); end

    if exist(fileName,'file')==2 % file but not directory
        question = ['Overwrite '''    fileName '''?'];
    elseif isImageExtension(fileName) || ...
           (length(fileName)>4 && strcmp(fileName(end-3:end),'.mat'))
        question = ['Save in file ''' fileName '''?'];
    else
        question = [];
    end
    
    if ~isempty(question)
        answer = questdlg(question, title,options{:});
%                         'Yes', 'Choose an other file', 'No', 'Cancel', 'Cancel');
    else
        answer = 'Choose file';
    end
    
    switch answer
        case 'Yes',     file = p.(fileField);
        case 'No',      done = 1; return
        case 'Cancel',  done = 0; return
        otherwise,      file = 'ui';
    end
    
    try
        image = CRImage(p.(dataField));
        saveFile = image.save(file);
        if ~isempty(saveFile), p.(fileField) = saveFile; end
        saved = true;
    catch
        saved = false;
    end
    if saved, done = 1; return;
    else      saveImage(dataField,fileField,title,varargin);
    end
end
   

% --- Executed by checkbox p.manual_use (use manual mask)
function update_manual_use(varargin)
    use = get(p.manual_use,'Value');
    if use && isempty(p.manualMask)
        crWarning('Draw mask first to use it.');
        use = ~use;
        set(p.manual_use,'Value',use);
    end
    set(p.display_manual,'Value',use);
    updateImage();
end
% --- Executed by checkbox p.var_use (use variance mask)
function update_var_use(varargin)
    use = get(p.var_use,'Value');
    if use
        if isempty(p.varImage)
            crWarning('To use its mask, compute video variance first.');
            use = ~use;
            set(p.var_use,'Value',use);
        elseif ~isempty(p.stdFile) && p.stdFile(end)=='#'
            p.stdFile = p.stdFile(1:end-1);
        end
    elseif ~isempty(p.stdFile) && p.stdFile(end)~='#'
        p.stdFile = [p.stdFile '#'];
    end
    set(p.display_var,   'Value',use);
    set(p.display_varSeg,'Value',use);
    updateImage();
end

    
% --- Executed by button p.var_comp
function computeVarianceMask(varargin)
    p.varImage = videoVariance(video,'output');
    p.varImage = (p.varImage).^0.2;
    computeStdMask();
    set(p.var_use,'Value',true);
    update_var_use();
    updateHistogram();
    updateImage();
end

% --- Executed by button p.manual_draw
function drawMask(varargin)
    axes(p.axe)
    p.manualMask = crRoiPoly();
    updateImage();
    set(p.manual_use,'Value',true);
    update_manual_use();
end




% ------------------------- Own functions ------------------------- %

function loadImage()
    % try to load mask and, if possiblem, set it in manual mask
    if isempty(p.maskFile) || ~ischar(p.maskFile)
        file = '';
    else
        if p.maskFile(end)=='#', file = p.maskFile(1:end-1);
        else                     file = p.maskFile;
        end
    end
    if exist(file,'file')==2 % file but not directory
        p.manualMask = CRImage(file,0,1,'double').data;
        if size(p.manualMask,1)~=size(p.videoImg,1) && size(p.manualMask,2)~=size(p.videoImg,2)
            crWarning('Loaded mask has incorrect dimensions');
            p.manualMask = [];
        else
            enable = ~isempty(p.manualMask) && p.manualMask(end)~='#';
            set(p.manual_use,'Value',enable);
            update_manual_use();
        end
    end
    % (try to) load the pixel variance image
    if isempty(p.stdFile) || ~ischar(p.stdFile)
        file = '';
    else
        if p.stdFile(end)=='#', file = p.stdFile(1:end-1);
        else                    file = p.stdFile;
        end
    end
    if exist(file,'file')==2 % file but not directory
        p.varImage = CRImage(file,0,1,'double').data;
        if size(p.varImage,1)~=size(p.videoImg,1) && size(p.varImage,2)~=size(p.videoImg,2)
            crWarning('Loaded variance image has incorrect dimensions');
            p.varImage = [];
        else
            computeStdMask();
            enable = ~isempty(p.varImage) && p.stdFile(end)~='#';
            set(p.var_use,'Value',enable);
            update_var_use();
        end
    end
end

function computeStdMask()
    p.varMask = logical(p.varImage() >= p.threshold);
end
    
function updateImage(varargin)
    p.mask = ones(p.videoImg.height,p.videoImg.width);
    
    if nargin>= 3;
        varEnable    = get(p.var_use   ,'Value');
        manualEnable = get(p.manual_use,'Value');
    else
        varEnable    = get(p.display_var   ,'Value');
        manualEnable = get(p.display_manual,'Value');
    end

    if ~isempty(p.varImage) && varEnable
        if get(p.display_varSeg,'Value')
            p.mask = p.mask .* p.varMask();
        else
            p.mask = p.mask .* p.varImage();
        end
    end
    if ~isempty(p.manualMask) && manualEnable
        p.mask = p.mask .* p.manualMask;
    end

    if get(p.display_video,'Value')
        image2draw = p.videoImg;
        for i=1:image2draw.depth
            image2draw(:,:,i) = image2draw(:,:,i) .* p.mask;
        end
    else
        image2draw = CRImage(p.mask);
    end

    
    axes(p.axe)
    imshow( image2draw );
end

    
function updateHistogram()
    text = sprintf('Threshold: %1.3f',p.threshold);
    set(p.thresh_text,'String',text);

    axes(p.thresh_axe);
    if ~isempty(p.varImage)
        hold off
        [H, bins] = hist( p.varImage(:), 30 );
        bar(bins,H);
        hold on

        L = line([0 0],[0 0]);
        set(L,'Color','red');
        set(L,'LineWidth',5);
        t = p.threshold;
        set(L,'XData',[t t]);
        set(L,'YData',[0 max(H(:))]);
        set(p.thresh_axe,'visible','off');
    else
        set(p.thresh_axe,'visible','off');
    end;
end

% ----------------------------------------------------------------------- %
% create GUI graphical components
function makeGUI()
    pos = [0 0 0 0];
    pos(3) =     p.videoImg.width  +200;
    pos(4) = max(p.videoImg.height, 360);
    p.fig = figure(...
        'Name','Create Video Mask',...
        'NumberTitle','off', ...
        'Menubar','none',...
        'Toolbar','none',...
        'position',pos,...
        'CloseRequestFcn',{@quitUI,-1},...
        'Visible','off');
%         'ResizeFcn',@resizeFunc);

    p.panel = uipanel('Parent',p.fig,'BorderType','none');

    % --- Create uicomponents ---
    p.axe_panel     = uipanel('Parent',p.panel,'BorderType','none');
    p.display_panel = uipanel('Parent',p.panel,'Title', 'Display');
    p.manual_panel  = uipanel('Parent',p.panel);
    p.var_panel     = uipanel('Parent',p.panel);
    p.close_panel   = uipanel('Parent',p.panel,'BorderType','none');

    % -------- image axis -------- 
    p.axe = axes('parent',p.axe_panel);
    set(gca,'Units','normalized');
    set(gca,'Position',[0 0 1 1]);

    % -------- Display menu -------- 
    p.display_tmp = uipanel('Parent',p.display_panel,'Visible','off');
    p.display_video = uicontrol( 'Parent',p.display_panel,...
        'Style','checkbox',      'String', 'Video image',...
        'Value',true,            'Callback',@updateImage);
    p.display_var    = uicontrol( 'Parent',p.display_panel,...
        'Style','checkbox',      'String', 'Video variance',...
        'Value',false,           'Callback',@updateImage);
    p.display_varSeg = uicontrol( 'Parent',p.display_panel,...
        'Style','checkbox',      'String', 'segment',...
        'Value',false,           'Callback',@updateImage);
    p.display_manual = uicontrol( 'Parent',p.display_panel,...
        'Style','checkbox',      'String', 'Manual mask',...
        'Value',false,           'Callback',@updateImage);
    
    % -------- manual mask -------- 
    p.manual_use  = uicontrol( 'Parent',p.manual_panel,...
        'Style','checkbox',    'String', 'Use manual mask',...
        'Value',false,         'Callback',@update_manual_use);
    p.manual_draw = uicontrol( 'Parent',p.manual_panel,...
        'Style','pushbutton',  'String', 'Draw mask', 'Callback', @drawMask);
    
    % -------- variance mask -------- 
    p.var_use  = uicontrol(    'Parent',p.var_panel,...
        'Style','checkbox',    'String', 'Use variance mask',...
        'Value',false,         'Callback',@update_var_use);
    p.var_save = uicontrol(    'Parent',p.var_panel,...
        'Style','pushbutton',  'String', 'Save As',          'Callback', @saveVarImage);
    p.var_comp = uicontrol(    'Parent',p.var_panel,...
        'Style','pushbutton',  'String', 'Compute variance', 'Callback', @computeVarianceMask);
    p.thresh_text = uicontrol( 'Parent',p.var_panel,...
        'Style','text', 'String', ['Threshold: ' num2str(p.threshold)]);
    p.thresh_slid = uicontrol( 'Parent',p.var_panel,...
        'Style','slider', 'Min',0, 'Max', 1, 'SliderStep',[0.05 0.05], ...
        'Value', p.threshold,   'Callback', @thresholdChanged);
    p.thresh_panel= uipanel(  'Parent',p.var_panel, 'BorderType', 'none');
    p.thresh_axe  = axes(     'Parent',p.thresh_panel );
    set(gca,'Units','normalized');
    set(gca,'Position',[0 0 1 1]);
    
    % -------- close panel ---------
    p.close_cancel = uicontrol(...
        'Parent',p.close_panel,    'Style','pushbutton',...
        'Callback',{@quitUI,0},    'String','Cancel');
    p.close_ok     = uicontrol(...
        'Parent',p.close_panel,    'Style','pushbutton',...
        'Callback',{@quitUI,1},    'String','Ok');

    % --- Lay-out uicomponents ---
    p.layout         = GridBagLayout(p.panel,         'HorizontalGap', 2, 'VerticalGap', 4);
    p.display_layout = GridBagLayout(p.display_panel, 'HorizontalGap', 2, 'VerticalGap', 4);
    p.manual_layout  = GridBagLayout(p.manual_panel,  'HorizontalGap', 2, 'VerticalGap', 1);
    p.var_layout     = GridBagLayout(p.var_panel,     'HorizontalGap', 3, 'VerticalGap', 4);
    p.close_layout   = GridBagLayout(p.close_panel,   'HorizontalGap', 2, 'VerticalGap', 1);

    p.display_layout.add(p.display_tmp   , 1,1,'MinimumWidth',120, 'Anchor', 'SouthWest');
    p.display_layout.add(p.display_video , 2,1,'MinimumWidth',150, 'Anchor', 'SouthWest');
    p.display_layout.add(p.display_var   , 3,1,'MinimumWidth',150, 'Anchor', 'SouthWest');
    p.display_layout.add(p.display_varSeg, 3,2,'MinimumWidth',100, 'Anchor', 'SouthEast');
    p.display_layout.add(p.display_manual, 4,1,'MinimumWidth',150, 'Anchor', 'SouthWest');
    p.display_layout.VerticalGap   = 2;
    p.display_layout.HorizontalGap = 5;

    p.manual_layout.add(p.manual_use  , 1,1,'MinimumWidth',120, 'MinimumHeight',25, 'Anchor', 'West');
    p.manual_layout.add(p.manual_draw , 1,2,'MinimumWidth',100, 'MinimumHeight',25, 'Anchor', 'East');
    p.manual_layout.HorizontalGap = 5;

    p.var_layout.add(p.var_use     , 1,1:2,'MinimumWidth',120, 'MinimumHeight', 25, 'Anchor', 'NorthWest');
    p.var_layout.add(p.var_save    , 1, 3 ,'MinimumWidth', 80, 'MinimumHeight', 25, 'Anchor', 'NorthEast');
    p.var_layout.add(p.var_comp    , 2,2:3,'MinimumWidth',120, 'MinimumHeight', 25, 'Anchor', 'NorthEast');
    p.var_layout.add(p.thresh_text , 2, 1 ,'MinimumWidth',120, 'MinimumHeight', 20, 'Anchor', 'West');
    p.var_layout.add(p.thresh_slid , 3,1:3,'MinimumWidth',200, 'MinimumHeight', 20, 'Fill', 'Horizontal');
    p.var_layout.add(p.thresh_panel, 4,1:3,'MinimumWidth',200, 'MinimumHeight',120, 'Fill', 'Both');
    p.var_layout.HorizontalGap = 5;
    p.var_layout.VerticalWeights = [0 0 0 1];

    p.close_layout.add(p.close_cancel,1,1,'MinimumWidth',65, 'MinimumHeight',   25, 'Anchor', 'SouthEast');
    p.close_layout.add(p.close_ok    ,1,2,'MinimumWidth',65, 'MinimumHeight',   25, 'Anchor', 'SouthEast');

    p.layout.add(p.axe_panel    ,1:4,1,'MinimumWidth',300, 'MinimumHeight',290, 'Anchor', 'West', 'Fill', 'Both');
    p.layout.add(p.display_panel, 1 ,2,'MinimumWidth',230, 'MinimumHeight', 80, 'Anchor', 'NorthEast');
    p.layout.add(p.manual_panel , 2 ,2,'MinimumWidth',230, 'MinimumHeight', 35, 'Anchor', 'NorthEast');
    p.layout.add(p.var_panel    , 3 ,2,'MinimumWidth',230, 'MinimumHeight',150, 'Anchor', 'NorthEast');
    p.layout.add(p.close_panel  , 4 ,2,'MinimumWidth',130, 'MinimumHeight', 25, 'Anchor', 'SouthEast','Fill', 'Vertical');

    p.layout.HorizontalGap = 5;
    p.layout.VerticalGap   = 5;
    p.layout.VerticalWeights = [0 0 0 1];
    p.layout.HorizontalWeights = [1 0];
end

% function resizeFunc(varargin)
%     disp(['size: ' array2str(get(p.fig,'position'))]);
% end

end
