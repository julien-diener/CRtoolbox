function createUIbox( this )
% private function that create the ui component of the CRUIbox and their
% layout manager.

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

% load default value and fill up missing values
this.assert('style','spinbox');

d = CRDefault();
def = get(d,'UIbox',[]);
if isempty(def)
    def = CRParam('CRUIbox');
    d.UIbox = def;
end
this.merge(def.data.(this.data.style));

b = this;  % to simplify the code
if isempty(b.data.parent), b.data.parent = gcf; end

% create UI components
b.data.panel = uipanel( 'Parent',b.data.parent,         'BorderType','none');

b.data.text = uicontrol('Parent',b.data.panel,          'ForegroundColor','k',...
                        'HorizontalAlignment','left',   'FontSize',10,...
                        'Style','text',                 'String', b.data.title );

switch b.data.style
    case 'edit'
        b.data.edit = uicontrol(...
            'Parent',b.data.panel,            'ForegroundColor','k',...
            'BackgroundColor','w',            'HorizontalAlignment','left',...
            'FontSize',10,                    'Style','edit',...
            'String', num2str(b.data.value),  'Callback',{@valueChanged,b});

        b.data.layout = GridBagLayout(b.data.panel, 'HorizontalWeights',[0 1], 'HorizontalGap',  2, 'VerticalGap', 2);
        b.data.layout.add(b.data.text, 1, 1, 'MinimumWidth', b.data.textWidth , 'Anchor', 'West');
        b.data.layout.add(b.data.edit, 1, 2, 'MinimumWidth', 40               , 'Fill','Horizontal');
    case 'popup'
        value = find(strcmp(b.data.string,b.data.value));
        if isempty(value), value = 1; end
        b.data.value = b.data.string{value};

        b.data.popup = uicontrol(...
            'Parent',b.data.panel,    'Style','popupmenu',...
            'String',b.data.string,   'Value',value,...
            'Callback',{@valueChanged,b});

        b.data.min = 1;
        b.data.max = length(b.data.string);

        b.data.layout = GridBagLayout(b.data.panel,'HorizontalWeights',[0 1]);
        b.data.layout.add(b.data.text, 1, 1, 'MinimumWidth',b.data.textWidth, 'Anchor', 'West');
        b.data.layout.add(b.data.popup,1, 2, 'MinimumWidth', 80             , 'Fill',   'Horizontal');
        
    case 'slider'
        if b.data.value<b.data.min, b.data.value = b.data.min; end;
        if b.data.value>b.data.max, b.data.value = b.data.max; end;
        b.data.edit = uicontrol(...
            'Parent',b.data.panel,            'ForegroundColor','k',...
            'BackgroundColor','w',            'HorizontalAlignment','right',...
            'FontSize',10,                    'Style','edit',...
            'String', num2str(b.data.value),  'Callback',{@valueChanged,b});
        b.data.slider = uicontrol(...
            'Parent',b.data.panel,            'Style','slider',...
            'min',b.data.min,'max',b.data.max,'Value',b.data.value,...
            'sliderStep',[1 1]*b.data.step/(b.data.max-b.data.min),...
            'Callback',  {@valueChanged,b});

        edit_width = ceil(log(b.data.max)/log(10))*8 + 10;
        if strcmpi(b.data.direction,'vertical')
            set(b.data.text,'HorizontalAlignment','center');
            b.data.layout = GridBagLayout(b.data.panel, 'VerticalWeights',[1 0 0]);
            b.data.layout.add(b.data.slider, 1, 1, 'MinimumHeight',b.data.sliderSize, 'Anchor', 'Center', 'Fill', 'Vertical');
            b.data.layout.add(b.data.edit  , 2, 1, 'MinimumWidth', edit_width       , 'Anchor', 'Center');
            b.data.layout.add(b.data.text  , 3, 1, 'MinimumWidth', b.data.textWidth , 'Anchor', 'Center');
        else
            b.data.layout = GridBagLayout(b.data.panel, 'HorizontalWeights',[0 0 1]);
            b.data.layout.add(b.data.text  , 1, 1, 'MinimumWidth', b.data.textWidth , 'Anchor', 'West');
            b.data.layout.add(b.data.edit  , 1, 2, 'MinimumWidth', edit_width       , 'Anchor', 'West');
            b.data.layout.add(b.data.slider, 1, 3, 'MinimumWidth', b.data.sliderSize, 'Anchor', 'West', 'Fill', 'Horizontal');
        end
    case 'spinbox'
        b.data.edit = uicontrol(...
            'Parent',b.data.panel,            'ForegroundColor','k',...
            'BackgroundColor','w',            'HorizontalAlignment','left',...
            'FontSize',10,                    'Style','edit',...
            'String', num2str(b.data.value),  'Callback',{@valueChanged,b});
        disp('b.data.spin')
        disp(b.data.value)
        b.data.spin = uicontrol(...
            'Parent',b.data.panel,            'Style','slider',...
            'min',b.data.min,'max',b.data.max,'Value',double(b.data.value),...
            'sliderStep',[1/(b.data.max-b.data.min) 0], ...
            'Callback',{@valueChanged,b});

        b.data.layout = GridBagLayout(b.data.panel, 'HorizontalWeights',[0 1 0]);
        b.data.layout.add(b.data.text, 1, 1, 'MinimumWidth',b.data.textWidth, 'Anchor', 'West');
        b.data.layout.add(b.data.edit, 1, 2, 'MinimumWidth', 50             ,   'Fill', 'Horizontal');
        b.data.layout.add(b.data.spin, 1, 3, 'MinimumWidth', 15             , 'Anchor', 'West');
end

% function called when user has changed the box value
function valueChanged( obj, evdt, box )
    if isfield(box,'edit') && obj==box.data.edit
        value = get(obj,'String');
    else
        value = get(obj,'Value');
    end
    set(box,'value',value);

    callFcn = get(box,'callback',0);
    if iscell(callFcn)
        arg = [ box.data.value callFcn(2:end) ];
        callFcn = callFcn{1};
    else
        arg = {box.data.value};
    end
    if isa(callFcn,'function_handle')
        callFcn(arg{:});
    end
end
end
