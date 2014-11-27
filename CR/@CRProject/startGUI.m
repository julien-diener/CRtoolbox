function this = startGUI( this )
% project.startGUI()
%
% Start main user interface of CRProject.
%
% See also: CRProject, crMask, crKLT, crPIV, crBOD, crExport

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

%%! finish help

h = CRParam();                % store all data used in this GUI
h.toolName = fieldnames(this.data.tool); % list of tool names
        
max_io = 4;                 % maximum allowed input and output of crtool

createPanel();                   % make the GUI



% ----------------------- functions ----------------------- 
function quitUI(varargin)
    delete(h.fig);
end
function saveProject(varargin)
    this.saveProject();
end
function openPlayer(varargin)
    player(this);
end

% change project name, path and load project from a crproj file
function nameChanged(varargin)
    % update project path
    n = h.proj_name.value;
    p = h.proj_path.value;
    if strcmp(p(end-length(this.data.name)+1:end),this.data.name)
        p(end-length(this.data.name)+1:end) = [];
        p = [p n];
        set(h.proj_path,'value',p);
        this.data.path = p;
    end
    this.data.name = n;
end
function browsePath(varargin)
    outPath = uigetdir(h.proj_path.value, 'Select the directory to store results');
    if ischar(outPath)
        this.data.path = outPath;
        set(h.proj_path,'value',outPath);
    end
end
function loadProject(varargin)
    proj = CRProject( CRDefault('CRProjectPath') );
    if isempty(proj), return; end;
    
    this.data = [];
    this.merge(proj);

    set(h.proj_name,'value', this.data.name);
    set(h.proj_path,'value', formatPath(this.data.path));

    set(h.video_file, 'value' ,formatPath(this.data.video.inputFile));
    set(h.length,     'value' ,this.data.video.length);
    set(h.start ,     'value' ,this.data.video.start);
    set(h.avibuf,     'value' ,get(this.data.video,'readLength',20));
end

% browse for an input video
function browseFile(varargin)
    [f{1:2}] = uigetfile({'*.*',  'All Files (*.*)'}, ...
               'Select an avi file or an image from a sequence',...
               h.video_file.value);
    if ischar(f{1})
        video = createVideo('inputFile', [f{[2 1]}],    'length', h.length.value,...
                            'readLength',h.avibuf.value,'start',  h.start.value);
        if video.input
            set(h.video_file,'value',[f{[2 1]}]);
            this.data.video.inputFile = [f{[2 1]}];
            this.data.video.type = 'CRVideo';
            this.data.video.data = video;
            toolChanged();  % update tool panel
        end
    end
end
% callback to change input video length, start, and avi buffer size
function changeVideoLength(varargin)
    this.data.video.length = h.length.value;
    video = this.data.video.load('attempt');
    if ~isempty(video), video.setLength(h.length.value); end
end
function changeVideoStart(varargin)
    this.data.video.start = h.start.value;
    video = this.data.video.load('attempt');
    if ~isempty(video)
        video.setStart(h.start.value); 
        changeVideoLength();
    end
end
function changeVideoAviBuffer(varargin)
    this.data.video.readLength = h.avibuf.value;
    video = this.data.video.load('attempt');
    if ~isempty(video), video.readLength = h.avibuf.value; end
end

% tool selection changed
function toolChanged(varargin)
    if isempty(get(h.tool_lb,'value')), return;             end
    if ~isfield(h,'tool_run'),          createToolPanel();  end

    toolName = h.toolName{get(h.tool_lb,'value')};
    this.data.tool.assert(toolName);
    tool  = this.data.tool.(toolName);
        
    iName = fieldnames(tool.input);    
    oName = get(tool.parameters.output,'name',{});
    if ~iscell(oName), oName = {oName}; end
    
    for i=1:length(iName)
        hname = ['tool_input' num2str(i)];
        set(h.(hname),'visible','on');
        set(h.(hname),'title',  iName{i});
        set(h.(hname),'string', ['---' ; this.dataList()]);
        ind = strmatch(tool.input.(iName{i}),this.dataList(),'exact');
        if isempty(ind), ind = 0; end
        set(h.(hname),'value',ind+1);
    end
    for i=length(iName)+1:max_io
        set(h.(['tool_input'  num2str(i)]),'visible','off'); 
    end
    for i=1:length(oName)
        set(h.(['tool_output' num2str(i)]),'visible','on');  
        set(h.(['tool_output' num2str(i)]),'String', oName{i});  
    end
    for i=length(oName)+1:max_io
        set(h.(['tool_output' num2str(i)]),'visible','off'); 
    end
    
    updateToolButton(tool);
end
function inputChanged(varargin)
    tname = h.toolName{get(h.tool_lb,'value')}; 
    iname = ['tool_input' num2str(varargin{end})];
    input = fieldnames(this.data.tool.(tname).input);
    input = input{varargin{end}};
    new_input = h.(iname).value;
    if ~isdata(this,new_input)
        new_input = '';
    end
    this.data.tool.(tname).input.(input) = new_input;
    set(h.(iname),'value',new_input);
end
function outputChanged(varargin)
    tname  = h.toolName{get(h.tool_lb,'value')}; 
    oname  = get(h.(['tool_output' num2str(varargin{end})]),'string');
    if ~isvarname(oname)
        oname = genvarname(oname);
        set(h.(['tool_output' num2str(varargin{end})]),'string',oname)
    end
    this.data.tool.(tname).parameters.output.name{varargin{end}} = oname;
end
function configTool(varargin)
    tname = h.toolName{get(h.tool_lb,'value')};
    this.configure(tname);
    updateToolButton(this.data.tool.(tname));
end
function runTool(varargin)
    tname = h.toolName{get(h.tool_lb,'value')}; 
    this.run(tname);
end
function runBatch(varargin)
    this.run_batched();
end
function add2batch(varargin)
    tname = h.toolName{get(h.tool_lb,'value')}; 
    this.add2batch(tname);
end
function updateToolButton(tool)
    configable = exist(get(tool,'configFunction',[]),'file')==2;
    configured = get(tool,'configured',false);
    batchable  = get(tool,'batchable', false);
    set(h.tool_config,'enable',onoff(  configable));
    set(h.tool_run   ,'enable',onoff( ~configable || configured));
    set(h.tool_batch ,'enable',onoff((~configable || configured) &&  batchable));
    
    function nf = onoff(bool)
        if bool, nf = 'on';
        else     nf = 'off';
        end
    end
end
% ----------------------------------------------------------------------- %
function createPanel()
    h1 = 60;
    h2 = 130;
    h3 = 50+25*length(h.toolName);
    h4 = 25;
    h0 = h1+h2+h3+h4;
    
    h.fig = figure(...
        'Name',       'Ch?ne-Roseau - Project GUI',...
        'NumberTitle','off'       ,...
        'Menubar',    'none'      ,...
        'Toolbar',    'none'      ,...
        'Position',   [0 0 450 h0],...
        'Visible',    'off'       ,...
        'CloseRequestFcn', {@quitUI,false});

    movegui(h.fig,'center');

    % ------------------------ create panels ------------------------ %
    h.panel       = uipanel('Parent',h.fig,  'BorderType','none');
    h.proj_panel  = uipanel('Parent',h.panel,'BorderType','none');
    h.video_panel = uipanel('Parent',h.panel,...%'BorderType','none',...
                            'Title',' input video ',...
                            'FontSize',10,'FontWeight','bold');
    h.tool_panel  = uipanel('Parent',h.panel,...%'BorderType','none',...
                            'Title',' tools ',...
                            'FontSize',10,'FontWeight','bold');
    h.close_panel = uipanel('Parent',h.panel,'BorderType','none');
                        
    % ------------------ Create project uicomponents ------------------ % 
    h.proj_name   = CRUIbox(  'parent',h.proj_panel,     'style','edit',...
                              'title', 'Project name:',  'textSize', 100, ...
                              'value',this.data.name,    'callback',@nameChanged);
    h.proj_load   = uicontrol('Parent',h.proj_panel,     'Style','pushbutton',...
                              'String','load Project',   'Callback',{@loadProject});
    h.proj_path   = CRUIbox(  'parent',h.proj_panel,     'style','edit',...
                              'title', 'Project path:',  'textSize', 100, ...
                              'value',formatPath(this.data.path));
    h.proj_browse = uicontrol('Parent',h.proj_panel,     'Style','pushbutton',...
                              'Callback',{@browsePath},  'String','...');

    set(h.proj_path.edit,'backgroundColor','default')
    set(h.proj_path.edit,'Enable','inactive');
    % ------------------ Create video uicomponents ------------------ % 
    h.video_file   = CRUIbox(  'parent',h.video_panel,     'style','edit',...
                               'title','Video Input file:','value',formatPath(this.data.video.inputFile));
    h.video_browse = uicontrol('Parent',h.video_panel,     'Style','pushbutton',...
                               'Callback',{@browseFile},   'String','Browse');
    h.length       = CRUIbox(  'parent', h.video_panel,    'style','spinbox',...
                               'textWidth',170,'min',0,    'value',this.data.video.length,...
                               'title','Max length (0=no limit):',...
                               'callback',@changeVideoLength);
    h.start        = CRUIbox(  'parent', h.video_panel,    'style','spinbox',...
                               'textWidth',170,'min',0,    'value',this.data.video.start,...
                               'title', 'start (0=input file,image only):',...
                               'callback',@changeVideoStart);
    h.avibuf       = CRUIbox(  'parent', h.video_panel,    'style','spinbox',...
                               'textWidth',170,'min',0,    'value',get(this.data.video,'readLength',0),...
                               'title','Avi buffer size (avi file only):',...
                               'callback',@changeVideoAviBuffer);

    set(h.video_file.edit,'backgroundColor','default')
    set(h.video_file.edit,'Enable','inactive');
    h.tmp_panel1   = uipanel(  'parent',h.video_panel,'visible','off');
    % ------------------ Create tool uicomponents ------------------ %
    h.tmp_panel2   = uipanel(  'parent',h.tool_panel, 'visible','off');
    h.tool_lb      = uicontrol('Parent',h.tool_panel, 'Style','listbox',...
                               'Value',[],            'String', h.toolName,...
                               'max',2,               'Callback',@toolChanged);

	% ------------------ Create close uicomponents ----------------- %
    h.player       = uicontrol('Parent',h.close_panel,   'Style','pushbutton',...
                               'Callback',{@openPlayer}, 'String','open player');
    h.batch        = uicontrol('Parent',h.close_panel,   'Style','pushbutton',...
                               'Callback',{@runBatch},   'String','Run batched tool');
    h.saveProj     = uicontrol('Parent',h.close_panel,   'Style','pushbutton',...
                               'Callback',{@saveProject},'String','Save');
	h.close_ok     = uicontrol('Parent',h.close_panel,   'Style','pushbutton',...
                               'Callback',{@quitUI},     'String','Quit');

    % -------------------- layout uicomponents --------------------- %

    h.layout        = GridBagLayout(h.panel,        'HorizontalGap', 5, 'VerticalGap', 5);
    h.proj_layout   = GridBagLayout(h.proj_panel,   'HorizontalGap', 5, 'VerticalGap', 1);
    h.video_layout  = GridBagLayout(h.video_panel,  'HorizontalGap', 5, 'VerticalGap', 1);
    h.tool_layout   = GridBagLayout(h.tool_panel,   'HorizontalGap', 5, 'VerticalGap', 1);
    h.close_layout  = GridBagLayout(h.close_panel,  'HorizontalGap', 5, 'VerticalGap', 1);

    h.proj_layout.add(h.proj_name.panel, 1, 1 , 'MinimumWidth',180, 'MinimumHeight', 50, 'Anchor', 'NorthWest');
    h.proj_layout.add(h.proj_load,       1,2:3, 'MinimumWidth', 80, 'MinimumHeight', 25, 'Anchor', 'NorthEast');
    h.proj_layout.add(h.proj_path.panel, 2,1:2, 'MinimumWidth',300, 'MinimumHeight', 25, 'Anchor', 'NorthWest', 'Fill',   'Horizontal');
    h.proj_layout.add(h.proj_browse,     2, 3 , 'MinimumWidth', 50, 'MinimumHeight', 25, 'Anchor', 'NorthEast');
    h.proj_layout.HorizontalWeights = [0 1 0];

    h.video_layout.add(h.tmp_panel1,       1, 1 , 'MinimumWidth',350, 'Anchor', 'North','Fill','Horizontal');
    h.video_layout.add(h.video_file.panel, 2,1:2, 'MinimumWidth',350, 'MinimumHeight', 25, 'Anchor', 'West', 'Fill','Horizontal');
    h.video_layout.add(h.video_browse,     3, 2 , 'MinimumWidth', 80, 'MinimumHeight', 25, 'Anchor', 'East');
    h.video_layout.add(h.length.panel,     3, 1 , 'MinimumWidth',300, 'MinimumHeight', 25, 'Anchor', 'West');
    h.video_layout.add(h.start.panel,      4, 1 , 'MinimumWidth',300, 'MinimumHeight', 25, 'Anchor', 'West');
    h.video_layout.add(h.avibuf.panel,     5, 1 , 'MinimumWidth',300, 'MinimumHeight', 25, 'Anchor', 'West');
    h.video_layout.HorizontalWeights = [0 1 ];

    h.tool_layout.add(h.tmp_panel2,  1,    1:4,'MinimumWidth',350, 'Anchor','North');
    h.tool_layout.add(h.tool_lb,2:max_io+2, 1 ,'MinimumWidth',120, 'Anchor','SouthWest','MinimumHeight',h3-50);
    h.tool_layout.HorizontalWeights = [ 1 0 0 0 ];
    
    h.close_layout.add(h.player,   1,1,'MinimumWidth',70, 'MinimumHeight',  h4, 'Anchor', 'West');
    h.close_layout.add(h.batch,    1,3,'MinimumWidth',95, 'MinimumHeight',  h4, 'Anchor', 'East');
    h.close_layout.add(h.saveProj, 1,4,'MinimumWidth',65, 'MinimumHeight',  h4, 'Anchor', 'East');
    h.close_layout.add(h.close_ok, 1,5,'MinimumWidth',65, 'MinimumHeight',  h4, 'Anchor', 'East');

    h.layout.add( h.proj_panel,  1,1,'Anchor', 'NorthWest', 'MinimumHeight', h1, 'Fill',   'Horizontal');
    h.layout.add( h.video_panel, 2,1,'Anchor', 'NorthWest', 'MinimumHeight', h2, 'Fill',   'Horizontal');
    h.layout.add( h.tool_panel,  3,1,'Anchor', 'SouthWest', 'MinimumHeight', h3, 'Fill',   'Horizontal');
    h.layout.add( h.close_panel, 4,1,'Anchor', 'SouthEast', 'MinimumHeight', h4, 'Fill',   'Horizontal');

    h.layout.VerticalWeights = [0 0 1 0];

    set(h.fig,'Visible','on')
    %uiwait(h.fig)
end

function createToolPanel()    
    % set tool list box max selection to 1
    value = get(h.tool_lb,'value');
    set(h.tool_lb,'value', value(end));
    set(h.tool_lb,'max',1);
    drawnow;
    % -------------------- create uicomponents --------------------- %
	h.tool_ititle  = uicontrol('Parent',h.tool_panel, 'Style','text', 'String','input', 'FontSize',10);
	h.tool_otitle  = uicontrol('Parent',h.tool_panel, 'Style','text', 'String','output','FontSize',10);
    iname{max_io} = [];
    oname{max_io} = [];
    for i=1:max_io
        iname{i} = ['tool_input'  num2str(i)];
        oname{i} = ['tool_output' num2str(i)];
        h.(iname{i}) = CRUIbox('parent', h.tool_panel, 'style','popup',...
                               'textWidth',60,         'title','',...
                               'callback',{@inputChanged, i});  
        h.(oname{i}) = uicontrol('parent', h.tool_panel, 'style','edit', ...
                                 'String',{oname{i}},    'backgroundColor', 'white',...
                                 'callback',{@outputChanged, i});
    	set(h.(iname{i}),'visible','off');
    	set(h.(oname{i}),'visible','off');
    end
    h.tool_config  = uicontrol('Parent',h.tool_panel,   'Style','pushbutton',...
                               'Callback',@configTool,  'String','Config');
    h.tool_run     = uicontrol('Parent',h.tool_panel,   'Style','pushbutton',...
                               'Callback',@runTool,     'String','Run');
    h.tool_batch   = uicontrol('Parent',h.tool_panel,   'Style','pushbutton',...
                               'Callback',@add2batch,   'String','Batch');

    % -------------------- layout uicomponents --------------------- %
    h.tool_layout.add(h.tool_ititle, 2 ,2,'MinimumWidth',100, 'Anchor','NorthWest');
    h.tool_layout.add(h.tool_otitle, 2 ,3,'MinimumWidth',100, 'Anchor','NorthWest');

    for i=1:max_io
        h.tool_layout.add(h.(iname{i}).panel,2+i,2,'MinimumWidth',130, 'Anchor','NorthWest');
        h.tool_layout.add(h.(oname{i})      ,2+i,3,'MinimumWidth',100, 'Anchor','NorthWest');
    end
    
    h.tool_layout.add(h.tool_config, max_io   ,4,'MinimumWidth', 60, 'Anchor','SouthEast','MinimumHeight',25);
    h.tool_layout.add(h.tool_run,    max_io+1 ,4,'MinimumWidth', 60, 'Anchor','SouthEast','MinimumHeight',25);
    h.tool_layout.add(h.tool_batch,  max_io+2 ,4,'MinimumWidth', 60, 'Anchor','SouthEast','MinimumHeight',25);
end

end