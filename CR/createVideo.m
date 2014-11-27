function video = createVideo( varargin )
% Create a CRVideo (reading/writing to image sequence or reading from avi file)
%
% Possible use:
% -------------
%  (1)  video = createVideo( )
%  (2)  video = createVideo( inputFile )
%  (3)  video = createVideo( 'input' or 1  or  'output' or 0 )
%  (4)  video = createVideo( varName1, value1, varName2, value2, ... )
%  (5)  video = createVideo( parameters )
%
% (1) start a GUI to configure the CRVideo manually
% (2) Create an 'input' video object from file 'inputFile' using default 
%     parameters.
% (3) start a GUI to configure the CRVideo with restriction:
%     if 'input'  or 1: allows to create an input  video only
%     if 'output' or 0: allows to create an output video only
% (4) Use the set of parameters defined by the pairs "varNamei" - "valuei"
% (5) Create a CRVideo where 'parameters' is a CRParam or a structure.
%     
%  
% See CRVideo.m for details on CRVideo objects and suitable parameters
%
% See also: CRVIDEO, CRVIDEOAVI

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

param = [];
video = CRVideo();
if nargin==0
    param = 'gui';
elseif nargin>1 && ischar(varargin{1})
    param = CRParam(varargin(:));
elseif isnumeric(varargin{1}),
    switch varargin{1}
        case 1,    param = 'input';
        case 0,    param = 'output';
        otherwise, param = 'gui';
    end
elseif ischar(varargin{1})
    switch lower(varargin{1})
        case 'gui',     param = 'gui';
        case 'input',   param = 'input';
        case 'output',  param = 'output';
        otherwise,      param = CRParam({'inputFile',varargin{1}});
    end
elseif isa(varargin{1}, 'CRParam')
    param = varargin{1};
else
    param = CRParam(varargin{1});
end

% Create a CRVideo or a CRVideoAVI w.r.t the input arguments
if isa(param,'CRParam')
    file = get(param,'inputFile','');
    if ~isempty(file) && strcmpi(file(end-2:end),'avi')
        video = CRVideoAVI(param);
    else
        video = CRVideo(param);
    end
    return;
end


% Otherwise, start a GUI to create the CRVideo object
%   If param = 'input',  provide creation GUI for input  video only
%   If param = 'output', provide creation GUI for output video only
%   otherwise, provide both


switch param
    case 'input',   io = {'Input'         };
    case 'output',  io = {        'Output'};
    otherwise,      io = {'Input','Output'};
end
clear param;

input  = [];   % to store handles to controls of the input  panel
output = [];   % to store handles to controls of the output panel
video  = [];   % to return

input.depth_table = { ...
'same as file', []; ...
'1 (gray)',      1; ...
'3 (rgb)',       3; ...
};
input.precision_table = { ...
'same as file',    '';    ...
   'uint8',     'uint8';  ...
  'single',     'single'; ...
  'double',     'double'; ...
};
output.precision_table = { ...
  'uint8  *.bmp', 'uint8',  '.bmp'; ...
  'uint8  *.png', 'uint8',  '.png'; ...
  'uint8  *.mat', 'uint8',  '.mat'; ...
  'single *.mat', 'single', '.mat'; ...
  'double *.mat', 'double', '.mat'; ...
};

hfig = figure(...
    'Name','Create Video',...
    'ResizeFcn' , @myResizeFcn,...
    'NumberTitle','off', ...
    'Menubar','none',...
    'Toolbar','none',...
    'position',[0 0 350   280],...
    'Visible','off');

movegui(hfig,'center');

bg_color = [0.92,0.91,0.84];
htab = uitabpanel(...
    'Parent',hfig,...
    'TabPosition','lefttop',...
    'Units','normalized',...
    'Position',[0,0,1,1],...
    'FrameBackgroundColor',[0.79,0.78,0.72],...
    'FrameBorderType','etchedin',...
    'Title',io,...
    'FontWeight','bold',...
    'TitleBackgroundColor',[0.6 ,0.6 ,0.6 ],...
    'TitleHighlightColor', bg_color,...
    'TitleForegroundColor',[0.1 ,0.1 ,0.1 ],...
    'PanelBackgroundColor',bg_color,...
    'PanelBorderType','line',...
    'CreateFcn',@CreateTab);

if length(io)>1
    if strcmpi(io{2},'input'), hpanel = input;
    else                       hpanel = output;
    end
    set(hpanel.panel,'Visible','on');
    hpanel.layout.update();
    set(hpanel.panel,'Visible','off');
end
set(hfig,'Visible','on')
uiwait(hfig)

%--------------------------------------------------------------------------
    function CreateTab(htab,evdt,hpanel,hstatus)
        for i=1:length(hpanel)
            set(hpanel(i),'HighlightColor', get(htab,'BackgroundColor'));
            set(hpanel(i),'ShadowColor',    get(htab,'BackgroundColor'));

            if strcmpi(io(i),'input'),
                CreateTabInput (htab,evdt,hpanel(i),hstatus);
                input.layout.update();
                input.layout.update();
                input.layout.update();
            else
                CreateTabOutput(htab,evdt,hpanel(i),hstatus);
                output.layout.update();
                output.layout.update();
                output.layout.update();
            end
        end
        set(htab,'ResizeFcn',@TabResize);
    end


%--------------------------------------------------------------------------
    function browseFile(hobj,evdt)
        [f{1:2}] = uigetfile({'*.*',  'All Files (*.*)'}, ...
                             'Select an image from the sequence',...
                             get(input.file_edit,'String'));
        if ischar(f{1})
            set(input.file_edit,'String',[f{[2 1]}]);
        end
    end
    function browsePath(hobj,evdt)
        outPath = uigetdir(get(output.path_edit,'String'), ...
                             'Select the directory to store video images');
        if ischar(outPath)
            set(output.path_edit,'String',outPath);
        end
    end
    function quitUI(hobj,evdt,isInput,ok)
       if ~ok
           close(hfig);
           return;
       end
       if isInput % input
           param.inputFile    = get(input.file_edit,     'String');
           param.length       = get(input.length,        'value');
           param.start        = get(input.start,         'value');
           param.depth        = get(input.data_depth_pm, 'Value');
           param.bufferLength = get(input.data_bLength,  'value');
           param.readLength   = get(input.avibuf,        'value');
           param.format       = get(input.data_precision_pm,'Value');
           
           param.format = input.precision_table{param.format,2};
           param.depth  = input.depth_table    {param.depth ,2};
           
           video = createVideo(param);
           if video.input
               close(hfig);
               return;
           else
               errordlg('Video could not be created (%s).', video.format);
           end
       else  % output
           param.outputPath   = get(output.path_edit,'String');
           param.outputFile   = get(output.file_edit,'String');
           param.format       = get(output.format_precision_pm,'Value');

           param.outputFile = [param.outputFile,...
                          output.precision_table{param.format,3}];
           param.format = output.precision_table{param.format,2};
           
           video = createVideo(param);
           if video.output
               close(hfig);
               return;
           else
               errordlg('Video could not be created. Check if output path and file are correct.');
           end
       end
    end
%--------------------------------------------------------------------------
    function myResizeFcn(hobj,evdt)
        if exist('htab','var')
            set(htab,'units','normalized');
            set(htab,'position',[0 0 1 1]);%pos);
            % required for resize function to work 
            % otherwise, it stop working after the first resizing 
            %   wha' ever ...
            set(getappdata(htab,'status'),'position',get(hfig,'position'));
        end
    end
%--------------------------------------------------------------------------
    function CreateTabInput(htab,evdt,hpanel,hstatus)
        input.panel = hpanel;

        % --- Create uicomponents ---
        input.input_panel = uipanel('Parent',input.panel','BorderType','none');
        input.file_panel  = uipanel('Parent',input.input_panel,'BorderType','none');
        input.file_text = uicontrol(...
            'Parent',input.file_panel,      'ForegroundColor','k',...
            'HorizontalAlignment','left',   'FontSize',10,...
            'Style','text',                 'String', 'Video Input file:' );
        input.file_edit = uicontrol(...
            'Parent',input.file_panel,      'ForegroundColor','k',...
            'BackgroundColor','w',          'HorizontalAlignment','left',...
            'FontSize',10,                  'Style','edit',...
            'String', pwd );
        input.file_browse = uicontrol(...
            'Parent',input.file_panel,      'Style','pushbutton',...
            'Callback',{@browseFile},       'String','Browse');

        input.length = CRUIbox('parent',input.panel,'style','spinbox',...
                               'title','length  (0=all images):',...
                               'textWidth',150,'min',0,'value',0);
        input.start  = CRUIbox('parent',input.panel,'style','spinbox',...
                               'title', 'start    (0=at input file):',...
                               'textWidth',150,'min',0,'value',1);
        input.avibuf = CRUIbox('parent',input.panel,'style','spinbox',...
                               'title','Avi buffer size  (0=all):',...
                               'textWidth',150,'min',0,'value',20);
        % ----------------------------------------------------------------------- %
        input.data_panel = uipanel('Parent',input.panel,'Title','Data format (advanced)');
        input.data_precision_text = uicontrol(...
            'Parent',input.data_panel,    'FontSize',10,   'position', [0 0 130 10],...
            'Style','text',               'String', 'Precision:' );
        input.data_precision_pm = uicontrol(...
            'Parent',input.data_panel,    'Style','popupmenu',...
            'String',input.precision_table(:,1));
        input.data_depth_text = uicontrol(...
            'Parent',input.data_panel,    'FontSize',10,...
            'Style','text',               'String', 'Channel number:' );
        input.data_depth_pm = uicontrol(...
            'Parent',input.data_panel,    'Style','popupmenu',...
            'String',input.depth_table(:,1));
        input.data_bLength = CRUIbox('parent',input.panel,'style','spinbox',...
                                     'title','Buffer length:',...
                                     'textWidth', 80,'min',2,'value',2);
        % ----------------------------------------------------------------------- %
        input.close_panel  = uipanel('Parent',input.panel,'BorderType','none');
        input.close_cancel = uicontrol(...
            'Parent',input.close_panel,     'Style','pushbutton',...
            'Callback',{@quitUI,1,0},       'String','Cancel');
        input.close_ok     = uicontrol(...
            'Parent',input.close_panel,     'Style','pushbutton',...
            'Callback',{@quitUI,1,1},         'String','Ok');

        % --- Lay-out uicomponents ---
        input.layout        = GridBagLayout(input.panel,        'HorizontalGap', 3, 'VerticalGap', 5);
        input.input_layout  = GridBagLayout(input.input_panel,  'HorizontalGap', 5, 'VerticalGap', 3);
        input.file_layout   = GridBagLayout(input.file_panel,   'HorizontalGap', 3, 'VerticalGap', 1);
        input.data_layout   = GridBagLayout(input.data_panel,   'HorizontalGap', 3, 'VerticalGap', 3);
        input.close_layout  = GridBagLayout(input.close_panel,  'HorizontalGap', 1, 'VerticalGap', 2);

        input.file_layout.add(input.file_text,  1, 1, 'MinimumWidth',100, 'Anchor', 'West');
        input.file_layout.add(input.file_edit,  1, 2, 'MinimumWidth', 80, 'Anchor', 'West', 'Fill',   'Horizontal');
        input.file_layout.HorizontalWeights = [0 1 ];

        input.input_layout.add( input.file_panel,   2,1:3,'Anchor', 'NorthWest', 'Fill',   'Horizontal');
        input.input_layout.add( input.file_browse,  3, 3, 'Anchor', 'NorthEast', 'MinimumWidth', 50);
        input.input_layout.add( input.length.panel, 3,1:2,'Anchor', 'NorthWest', 'MinimumWidth',250);
        input.input_layout.add( input.start.panel,  4,1:2,'Anchor', 'NorthWest', 'MinimumWidth',250);
        input.input_layout.add( input.avibuf.panel, 5,1:2,'Anchor', 'NorthWest', 'MinimumWidth',250);
        input.input_layout.HorizontalGap = 5;
        input.input_layout.VerticalGap   = 0;
        input.layout.add( input.input_panel, 1,1:3,'Anchor', 'NorthWest', 'MinimumHeight',120, 'Fill',   'Horizontal');

        input.data_layout.add(input.data_precision_text, 1, 1, 'MinimumWidth',80, 'Anchor', 'West');
        input.data_layout.add(input.data_precision_pm,   1,2:3,'MinimumWidth',70, 'Fill',  'Horizontal');
        input.data_layout.add(input.data_depth_text,     2, 1, 'MinimumWidth',80, 'Anchor', 'West');
        input.data_layout.add(input.data_depth_pm,       2,2:3,'MinimumWidth',70, 'Fill',  'Horizontal');
        input.data_layout.add(input.data_bLength.panel,  3,1:3,'MinimumWidth',150, 'Anchor', 'West');
        input.data_layout.setConstraints(1,1,'TopInset',15);
        input.data_layout.setConstraints(1,2,'TopInset',15);
        input.data_layout.setConstraints(1,3,'RightInset',5);
        input.data_layout.setConstraints(2,3,'RightInset',5);
        input.layout.add(input.data_panel,4,1:2,'MinimumWidth',200, 'MinimumHeight', 100, 'Anchor', 'SouthWest');

        input.close_layout.add(input.close_cancel,1,1,'MinimumWidth',65, 'MinimumHeight',   25, 'Anchor', 'NorthEast');
        input.close_layout.add(input.close_ok    ,2,1,'MinimumWidth',65, 'MinimumHeight',   25, 'Anchor', 'SouthEast');
        input.layout.add(      input.close_panel,4,3, 'MinimumWidth',70, 'MinimumHeight',   60, 'Anchor', 'SouthEast');

        input.layout.HorizontalGap = 5;
        input.layout.VerticalGap   = 5;
        input.layout.VerticalWeights = [0 0 1 0 0];

    end
    function CreateTabOutput(htab,evdt,hpanel,hstatus)
        output.panel = hpanel;

        % --- Create uicomponents ---
        output.file_panel = uipanel('Parent',output.panel,'BorderType','none');
        output.path_text  = uicontrol(...
            'Parent',output.file_panel,     'ForegroundColor','k',...
            'HorizontalAlignment','left',   'FontSize',10,...
            'Style','text',                 'String', 'Output path:' );
        output.path_edit = uicontrol(...
            'Parent',output.file_panel,     'ForegroundColor','k',...
            'BackgroundColor','w',          'HorizontalAlignment','left',...
            'FontSize',10,                  'Style','edit',...
            'String', [pwd '\tmp']);
        output.file_text = uicontrol(...
            'Parent',output.file_panel,     'ForegroundColor','k',...
            'HorizontalAlignment','left',   'FontSize',10,...
            'Style','text',                 'String', 'file name of 1st image:' );
        output.file_edit = uicontrol(...
            'Parent',output.file_panel,     'ForegroundColor','k',...
            'BackgroundColor','w',          'HorizontalAlignment','left',...
            'FontSize',10,                  'Style','edit',...
            'String', 'img_0000');
        output.browse_bt = uicontrol(...
            'Parent',output.file_panel,     'Style','pushbutton',...
            'Callback',{@browsePath},       'String','Browse');
        % ----------------------------------------------------------------------- %
        output.format_panel = uipanel('Parent',output.panel,'BorderType','none');
        output.format_precision_text = uicontrol(...
            'Parent',output.format_panel,   'FontSize',10,   'position', [0 0 130 10],...
            'Style','text',                 'String', 'Precision:' );
        output.format_precision_pm = uicontrol(...
            'Parent', output.format_panel,   'Style','popupmenu',...
            'String', output.precision_table(:,1));
        % ----------------------------------------------------------------------- %
        output.close_panel  = uipanel('Parent',output.panel,'BorderType','none');
        output.close_cancel = uicontrol(...
            'Parent',output.close_panel,    'Style','pushbutton',...
            'Callback',{@quitUI,0,0},       'String','Cancel');
        output.close_ok     = uicontrol(...
            'Parent',output.close_panel,    'Style','pushbutton',...
            'Callback',{@quitUI,0,1},       'String','Ok');

        % --- Lay-out uicomponents ---
        output.layout        = GridBagLayout(output.panel,        'HorizontalGap', 4, 'VerticalGap', 5);
        output.file_layout   = GridBagLayout(output.file_panel,   'HorizontalGap', 4, 'VerticalGap', 2);
        output.format_layout = GridBagLayout(output.format_panel, 'HorizontalGap', 2, 'VerticalGap', 1);
        output.close_layout  = GridBagLayout(output.close_panel,  'HorizontalGap', 1, 'VerticalGap', 2);

        output.file_layout.add(output.path_text,  1, 1,  'MinimumWidth', 80, 'Anchor', 'NorthWest');
        output.file_layout.add(output.path_edit,  1,2:4, 'MinimumWidth', 80, 'Anchor', 'North', 'Fill',   'Horizontal');
        output.file_layout.add(output.file_text,  2,1:2, 'MinimumWidth',150, 'Anchor', 'NorthWest');
        output.file_layout.add(output.file_edit,  2, 3,  'MinimumWidth', 80, 'Anchor', 'NorthWest');
        output.file_layout.add(output.browse_bt,  2, 4,  'MinimumWidth', 50, 'Anchor', 'NorthEast');
        output.file_layout.HorizontalWeights = [ 0 0 1 0 ];
        output.layout.add(     output.file_panel,1:2,1:4,'MinimumHeight', 60, 'Fill',  'Horizontal');

        output.format_layout.add(output.format_precision_text, 1, 1, 'MinimumWidth', 80, 'Anchor', 'West');
        output.format_layout.add(output.format_precision_pm,   1, 2, 'MinimumWidth',100, 'Fill',  'Horizontal');
        output.layout.add(       output.format_panel,          4,1:2,'MinimumWidth',200, 'MinimumHeight', 100, 'Anchor', 'SouthWest');

        output.close_layout.add(output.close_cancel,1,  1,'MinimumWidth',65, 'MinimumHeight',   25, 'Anchor', 'NorthEast');
        output.close_layout.add(output.close_ok    ,2,  1,'MinimumWidth',65, 'MinimumHeight',   25, 'Anchor', 'SouthEast');
        output.layout.add(      output.close_panel ,4:5,4,'MinimumWidth',70, 'MinimumHeight',   60, 'Anchor', 'SouthEast');

        output.layout.HorizontalGap = 5;
        output.layout.VerticalGap   = 5;
        output.layout.VerticalWeights = [0 0 1 0 0];
    end

end


