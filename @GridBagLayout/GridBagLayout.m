classdef GridBagLayout < handle
%GridBagLayout - Constructs a GridBagLayout layout manager.
%   GridBagLayout(H) Constructs a GridBagLayout object to manage
%   the Handle Graphics object H.  H can be a figure, uicontainer or
%   uipanel.
%
%   GridBagLayout methods:
%       add            - Add a component to the layout.
%       clean          - Remove excess spacing.
%       insert         - Insert a row or column of empty space.
%       remove         - Remove a component.
%       setConstraints - Set various spacing constraints.
%       update         - Force an update.
%
%   GridBagLayout public fields:
%       VerticalGap       - Vertical gap between components.
%       HorizontalGap     - Horizontal gap between components.
%       VerticalWeights   - Vertical weights used for spacing.
%       HorizontalWeights - Horizontal weights used for spacing.
%       Grid              - Stores all the components in a matrix.
%       Panel             - Stores the parent of the components.
%
%   % Example
%       hl = GridBagLayout(figure);
%       hl.add(uicontrol, 1, [1 2], 'Fill', 'Both');
%       hl.add(uicontrol, 2, 1, 'Fill', 'Horizontal', ...
%           'Anchor', 'North');
%       hl.add(uicontrol, 2, 2, 'Fill', 'Vertical', ...
%           'Anchor', 'West');

    properties
        
        Panel;
        PanelPosition;
        Invalid = true;
        OldPosition;
        CONSTRAINTSTAG = 'Layout_Manager_Constraints';


        %VerticalGap The vertical gap between widgets.  This is the
        %   uniform gap between the widgets and the widgets and the edges
        %   of the frame.  To specify addition gap for specific widgets use
        %   the IPad or Inset constraints.
        VerticalGap = 0;

        %HorizontalGap The horizontal gap between widgets.  This is the
        %   uniform gap between the widgets and the widgets and the edges
        %   of the frame.  To specify addition gap for specific widgets use
        %   the IPad or Inset constraints.
        HorizontalGap = 0;

        %VerticalWeights The weights used to calculate where to use extra
        %   pixels among the rows.  The higher the weight for a specific
        %   row results in more extra pixels being given to the widgets in
        %   that row.  This value is always of length equal to size(H.Grid,
        %   1).  If additional rows are added to the Grid a value of 0 will
        %   be added to the end of the weights.  If the Grid is reduced,
        %   extra weights will be discarded.
        VerticalWeights = [];

        %HorizontalWeights The weights used to calculate where to use extra
        %   pixels among the columns.  The higher the weight for a specific
        %   column results in more extra pixels being given to the widgets
        %   in that column.  This value is always of length equal to
        %   size(H.Grid, 2).  If additional columns are added to the Grid a
        %   value of 0 will be added to the end of the weights.  If the
        %   Grid is reduced, extra weights will be discarded.
        HorizontalWeights = [];
    
        %Grid A matrix storing all of the widgets parented to the specified
        %   container.  NaN values are used for empty cells.
        Grid;
    end
            
    methods
        
        function this = GridBagLayout(hPanel, varargin)
            %GridBagLayout   Construct the GridBagLayout class.
            
            this.Panel = hPanel;
            
            for indx = 1:2:length(varargin)
                this.(varargin{indx}) = varargin{indx+1};
            end
        end
        
        function add(this, h, row, col, varargin)
            %add Add a component to the layout manager.
            %   add(H, HCOMP, ROW, COL) Add the HG object HCOMP to the
            %   layout manager H in the row (ROW) and column (COL)
            %   specified.  ROW and COL must be scalars or vectors of
            %   length two.  When specified as a scalar that exact position
            %   in the grid is used.  When specified as a vector of length
            %   two, they are used to determine the limits of the row or
            %   column span, e.g. a single component can be placed over
            %   multiple cells in the grid.
            %
            %   add(H, ..., CONSTRAINT1, VALUE1, etc.) Optional constraints
            %   can be passed as additional arguments.  See setConstraints
            %   for the complete list of constraints.
            %
            %   Children of the managed container are not automatically
            %   added to the layout.  They must be explicitly added via the
            %   add method.
            %
            %   See also setConstraints, remove.
            
            error(nargchk(4, inf, nargin, 'struct'));
            
            % Make sure there isn't already a component in the location.
            hOld = getComponent(this, row, col);
            if ~isempty(hOld)
                error('Cannot add a component to a location that is already occupied.');
            end
            
            if ~isnan(h)
                set(h, 'Parent', this.Panel);
            end
            
            g = this.Grid;
            
            g(min(row):max(row), min(col):max(col)) = h;
            
            if ~isappdata(h, this.CONSTRAINTSTAG)
                setappdata(h, this.CONSTRAINTSTAG, GridBagConstraints);
            end
            
            % Convert any added zeros to NaN.
            g(g == 0) = NaN;
            
            this.Grid = g;
            
            if nargin > 4
                setConstraints(this, row, col, varargin{:});
            end
        end
        function update(this, force)
            %UPDATE   Update the layout.
            
            if nargin < 2
                force = 'noforce';
            end
            
            % When UPDATE is called, we assume the layout is dirty.
            if this.Invalid || strcmpi(force, 'force')
                
                % Nothing to do if the panel is invisible, to avoid multiple updates.
                if strcmpi(get(this.Panel, 'Visible'), 'Off')
                    return;
                end
                
                layout(this);
                
                % The layout is now clean.
                this.Invalid = false;
            end
        end

        function insert(this, type, indx)
            %insert   Insert a row or a column at an index.
            %   insert(H, TYPE, INDX) Insert either a 'row' or 'column'
            %   (TYPE) of NaNs into the Grid at the row or column INDX.
            %
            %   See also add, remove.
            
            g = this.Grid;
            
            [rows cols] = size(g);
            
            switch lower(type)
                case 'row'
                    if indx > rows + 1
                        g = [g; NaN(indx-rows, cols)];
                    else
                        g = [g(1:indx-1,:); NaN(1, cols); g(indx:end,:)];
                    end
                case 'column'
                    if indx > cols + 1
                        g = [g NaN(rows, indx-cols)];
                    else
                        g = [g(:, 1:indx-1) NaN(rows, 1) g(:, indx:end)];
                    end
            end
            
            this.Grid = g;
        end

        function remove(this, indx, jndx)
            %remove   Remove the handle from the manager.
            %   remove(H, HCOMP) Removes the specified HG object HCOMP from
            %   the layout manager H.
            %
            %   remove(H, ROW, COL) Removes the object stored in the Grid
            %   at the ROW and COL specified.
            %
            %   See also add, insert.
            
            g = this.Grid;
            
            if nargin == 2
                h = indx;
                
                g(g == h) = NaN;
                
                % Reset the grid and clean up the listeners vector.
                this.Grid = g;
            else
                remove(this, g(indx, jndx));
            end
        end
        
        function clean(this)
            %clean   Remove Trailing rows/columns with only NaN values.
            %
            %   See also add, insert, remove.
            
            g = this.Grid;
            
            [rows cols] = size(g);
            
            % Clean up any extra rows in the grid.
            indx = rows;
            while indx > 0 && all(isnan(g(indx,:)))
                g(indx,:) = [];
                indx      = indx-1;
            end
            
            indx = cols;
            while indx > 0 && all(isnan(g(:,indx)))
                g(:,indx) = [];
                indx      = indx-1;
            end
            
            this.Grid = g;
        end
        
        function setConstraints(this, row, col, varargin)
            %setConstraints   Set the constraints for the specified component.
            %   setConstraints(HLAYOUT, LOCATION, PARAM1, VALUE1, etc.) Set the
            %   constraints for the component in LOCATION.
            %
            %   SETCONSTRAINTS(HLAYOUT, LOCATION, 'default') when the string 'default'
            %   is passed to SETCONSTRAINTS the stored constraints are reset to their
            %   default values.
            %
            %   Parameter Name      Valid Values        Default
            %   MinimumHeight       Positive Numbers    20
            %   MinimumWidth        Positive Numbers    20
            %   PreferredHeight     Positive Numbers    20
            %   PreferredWidth      Positive Numbers    20
            %   MaximumHeight       Positive Numbers    inf
            %   MaximumWidth        Positive Numbers    inf
            %   IPadX               Real Numbers        0
            %   IPadY               Real Numbers        0
            %   LeftInset           Real Numbers        0
            %   RightInset          Real Numbers        0
            %   TopInset            Real Numbers        0
            %   BottomInset         Real Numbers        0
            %   Fill                'None'              'None'
            %                       'Horizontal'
            %                       'Vertical'
            %                       'Both'
            %   Anchor              'Center'            'Center'
            %                       'Northwest'
            %                       'North'
            %                       'Northeast'
            %                       'East'
            %                       'Southeast'
            %                       'South'
            %                       'Southwest'
            %                       'West'
            
            error(nargchk(3, inf, nargin, 'struct'));
            
            % Do not error out if no constraints are passed.
            if nargin < 5
                return;
            end
            
            % Get the component from the subclass.
            hComponent = getComponent(this, row, col);
            
            % Get the old constraints.
            ctag           = this.CONSTRAINTSTAG;
            oldConstraints = getappdata(hComponent, ctag);
            
            if strcmpi(varargin{1}, 'default')
                % If the pv pairs is just 'default' remove all constraints.
                if ~isempty(oldConstraints)
                    rmappdata(hComponent, ctag);
                end
            else
                
                % If there are no old constraints, create a new object.
                if isempty(oldConstraints)
                    c = GridBagConstraints(varargin{:});
                    setappdata(hComponent, ctag, c);
                else
                    
                    % If there are old constraints, just set the object with the new
                    % constraints, don't throw away any old ones.
                    for indx = 1:2:length(varargin)-1
                        oldConstraints.(varargin{indx}) = varargin{indx+1};
                    end
                end
            end
            
            this.Invalid = true;
            
            % Force a call to update.
            update(this);
        end

        function component = getComponent(this, row, col)
            
            g = this.Grid;
            
            component = [];
            
            if max(row) <= size(g, 1) && max(col) <= size(g, 2)
                for indx = 1:length(row)
                    for jndx = 1:length(col)
                        if ~isnan(g(row(indx), col(jndx)))
                            component = [component; g(row(indx), col(jndx))];
                        end
                    end
                end
            end
            component = unique(component);
        end
                
        function [m, n] = getComponentSize(this, indx, jndx)
            %GETCOMPONENTSIZE   Get the componentsize.
            
            g = this.Grid;
            
            h = g(indx, jndx);
            
            if isnan(h)
                m = 0;
                n = 0;
            else
                m = find(g(:, jndx) == h, 1, 'last' ) - indx + 1;
                n = find(g(indx,:) == h, 1, 'last' )  - jndx + 1;
            end
            
            if nargout < 2
                m = [m n];
            end
        end
                
        function hWeights = get.HorizontalWeights(this)
            % Trim the weights to match the size of the Grid.  Add zeros if
            % the grid grows.
            hWeights = resizeWeights(this, this.HorizontalWeights, 2);
        end
        
        function vWeights = get.VerticalWeights(this)
            vWeights = resizeWeights(this, this.VerticalWeights, 1);
        end

        function panelPosition = get.PanelPosition(this)
            hp = this.Panel;
            
            oldResizeFcn = get(hp, 'ResizeFcn');
            set(hp, 'ResizeFcn', '');
            
            panelPosition = getpixelposition(hp);
            
            set(hp, 'ResizeFcn', oldResizeFcn);
            
        end

        function set.Panel(this, panel)
            
            % This is faster than STRCMPI
            if ~ishghandle(panel) && ...
                    any(strcmp(get(panel, 'type'), {'uipanel', 'figure', 'uicontainer'}))
                error('The panel property can only store a UIPANEL, UICONTAINER or a FIGURE object.');
            end
            
            % Do this before we create the listeners to avoid accidental firing.
            pos = getpixelposition(panel);
            this.OldPosition = pos(3:4);
                        
            set(panel, 'ResizeFcn', @(hsrc, ev) onResize(this));
            
            this.Panel = panel;
            
            function onResize(this)
                
                newPos = this.PanelPosition;
                newPos(1:2) = [];
                
                % Only resize if the panel position (width and height) actually changed.
                if ~all(this.OldPosition == newPos)
                    this.OldPosition = newPos;
                    this.Invalid = true;
                    update(this);
                end
            end
        end

        function set.VerticalGap(this, vGap)
            
            if ~isscalar(vGap) || ~isnumeric(vGap) || isnan(vGap) || isinf(vGap)
                error('VerticalGap must be a scalar numeric.');
            end
            
            this.VerticalGap = vGap;
            this.Invalid = true;
            update(this);
        end
        
        function set.HorizontalGap(this, hGap)
            
            if ~isscalar(hGap) || ~isnumeric(hGap) || isnan(hGap) || isinf(hGap)
                error('HorizontalGap must be a scalar numeric.');
            end
            
            this.HorizontalGap = hGap;
            this.Invalid = true;
            update(this);
        end
        
        function set.VerticalWeights(this, vWeights)
            if ~any(isnumeric(vWeights)) || any(isnan(vWeights)) || any(isinf(vWeights))
                error('VerticalWeights must be a scalar numeric.');
            end
            
            this.VerticalWeights = vWeights;
            this.Invalid = true;
            update(this);
        end
        
        function set.HorizontalWeights(this, hWeights)
            if ~any(isnumeric(hWeights)) || any(isnan(hWeights)) || any(isinf(hWeights))
                error('HorizontalWeights must be a scalar numeric.');
            end
            
            this.HorizontalWeights = hWeights;
            this.Invalid = true;
            update(this);
        end
        
        function set.Grid(this, grid)
            this.Grid = grid;
            this.Invalid = true;
            update(this);
        end
    end
end

function weights = resizeWeights(this, weights, dimension)
    nw = size(this.Grid, dimension);

    % Only return a number of weights equal to the width of the grid.
    weights = [weights zeros(1, nw-length(weights))];
    weights = weights(1:nw);

    weights = weights(:);
    if dimension == 2
        weights = weights';
    end
end    

% [EOF]
