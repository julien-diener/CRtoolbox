% The CRUIbox are components for user interface. Currently there are three
% types: popup, slider and spinbox which contains:  
%  - a title followed by either one of:
%  - (popup)   a popup uicontrol
%  - (edit)    an editable text field
%  - (slider)  an editable text field and a slider 
%  - (spinbox) an editable spin box
%
% 
% Constructor:
% ------------
%   box = CRUIbox( parameters )
%
% parameters can be a CRParam, a structure or a set of paires <name,value>.
% The fields name (or the var_name's) can be any of the parameters found in
% file "@CRUIbox/CRUIbox.param" (do CRParam('CRUIbox')). In particular: 
% - style   : either 'popup', 'slider', 'spinbox' or 'edit' (default)
% - parent  : the parent panel or figure (default to current figure)
% - value   : the value of the box
% - callback: a function handle to call when 'value' is changed by the user
% and for slider:
% - direction: either vertical (default) or horizontal
%
% Output 'box' is a CRUIBox that contains the input parameters (or default),
% and the handles of the uicomponents that compose the UIbox: 'panel',
% 'text' and either
%   - 'popup'  (style=popup),
%   - 'edit'   (style=edit or spinbox or slider),
%   - 'spin'   (style=spinbox)
%   - 'slider' (style=slider). 
% 
% At any time, "box.value" returns the current value of the UIbox. 
%
% Methods:
% --------
%  - set(box,property,value) set property to value. property can be:
%                            'value', 'title, 'visible' or 'enable'
%                            and for popup only, 'string'.
%  - box.createUIbox()       create the box. if 'parent' is defined it 
%                            is automatically called by the constructor.

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

classdef CRUIbox < CRParam
    methods
        function this = CRUIbox( varargin )
            if nargin<1,                 argin = '';
            elseif ischar(varargin{1}),  argin = varargin;
            else                         argin = varargin{1};
            end
            this@CRParam( argin );
            this.createUIbox();
        end
        
        function this = set(this,property,value)
            switch lower(property)
                case 'value',   setValue (value);
                case 'title',   set(this.data.text,'String',value);
                case 'enable',  setEV('Enable', value);
                case 'visible', setEV('Visible',value);
                case 'string',  setString(value);
                otherwise,      error('Unrecognized CRUIbox property ''%s''',property);
            end

            function setValue( value )
                if ischar(value)
                    switch this.data.style
                        case 'edit'; % keep it as character string
                        case 'popup' % convert to popup list index
                            value = strmatch(value,this.data.string);
                            if isempty(value), value = 1;
                            else               value = value(1);
                            end
                        otherwise    % convert to numeric
                            value = str2double(value);
                            if isnan(value), value = this.data.value; end
                    end
                end

                if isnumeric(value)
                    if value<this.data.min,  value = this.data.min;  end
                    if value>this.data.max,  value = this.data.max;  end
                    value = round(value);
                end

                if isfield(this,'spin'),   set(this.data.spin,  'Value' ,value);           end
                if isfield(this,'slider'), set(this.data.slider,'Value' ,value);           end
                if isfield(this,'popup'),  set(this.data.popup, 'Value' ,value);           end
                if isfield(this,'edit'),   set(this.data.edit,  'String',num2str(value));  end

                if strcmp( this.data.style, 'popup')
                    this.data.value = this.data.string{value};
                else this.data.value = value;
                end
            end

            function setEV( prop, isEnable )
                if ischar(isEnable),  enable = isEnable;
                elseif isEnable,      enable = 'on';
                else                  enable = 'off';
                end
                set(this.data.text,  prop, enable);
                if isfield(this,'spin'),   set(this.data.spin,  prop, enable);  end
                if isfield(this,'slider'), set(this.data.slider,prop, enable);  end
                if isfield(this,'popup'),  set(this.data.popup, prop, enable);  end
                if isfield(this,'edit'),   set(this.data.edit,  prop, enable);  end
            end
            
            function setString( string )
                if ~strcmp(this.data.style,'popup')
                    error('Only popup type CRUIbox have a ''string'' parameter')
                end
                this.data.string = string;
                this.data.max    = length(this.data.string);
                set(this.data.popup,'String',this.data.string);
                this.data.value  = this.data.string{get(this.data.popup,'value')};
            end
        end
        function delete( this )
            if ishghandle(this.data.panel)
                delete( this.data.panel );
            end
        end
    end
end
