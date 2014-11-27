function layout(this)
%LAYOUT   Layout the container.

grid = this.Grid;
if isempty(grid)
    return;
end

panelpos    = this.PanelPosition;
ctag        = this.CONSTRAINTSTAG;
[rows cols] = size(grid);

hg = this.HorizontalGap;
vg = this.VerticalGap;
vw = this.VerticalWeights;
hw = this.HorizontalWeights;

% If all of the weights are zero convert them all to ones so that we can do
% easier math on them, because 0/sum([0 0 0]) doesn't work.
if all(hw == 0)
    hw = ones(size(hw));
end
if all(vw == 0)
    vw = ones(size(vw));
end

minheight = zeros(size(grid));
minwidth  = minheight;

% Get all the heights
for indx = 1:rows
    for jndx = 1:cols
        if ishandle(grid(indx,jndx))

            [n, m] = getComponentSize(this, indx, jndx);

            hC = getappdata(grid(indx,jndx), ctag);
            if isempty(hC)
                minh = 20;
                minw = 20;
            else
                % Each grid location has a minimum height of the insets +
                % the minimum dimension of the component.
                minh = (hC.MinimumHeight+hC.BottomInset+hC.TopInset)/n;
                minw = (hC.MinimumWidth+hC.LeftInset+hC.RightInset)/m;
            end

            % Remove the control from the grid.
            grid(indx:indx+n-1,jndx:jndx+m-1) = NaN;

            minheight(indx:indx+n-1,jndx) = minh;
            minwidth(indx,jndx:jndx+m-1)  = minw;
        end
    end
end

% The minimum height for each row is the max of all the minimum heights in
% each column.  Vice-versa for the minimum width.
minheight = max(minheight, [], 2);
minwidth  = max(minwidth,  [], 1);

% Calculate the final widths by determining the number of leftover pixels
% and dividing them according to the weights property for the given
% dimension.
if cols == 1

    % If the is just one column, the width is just the panel width minus
    % two horizontal gaps
    widths = panelpos(3)-2*hg;
else

    % Subtract the sum of the minimum widths from the panel width and then
    % one extra horizontal gap so that we have one on each side.
    leftoverwidth  = panelpos(3)-sum(minwidth)-hg*(cols+1);
    widths = minwidth+leftoverwidth*hw/sum(hw);
end

if rows == 1

    % If there is just one row, the height is the panel height minus two
    % vertical gaps.
    heights = panelpos(4)-2*vg;
else

    % Subtract the sum of the minimum heights from the panel height and
    % then one extra vertical gap so that we have one on each side.
    leftoverheight = panelpos(4)-sum(minheight)-vg*(rows+1);
    heights = minheight+leftoverheight*vw/sum(vw);
end

grid = this.Grid;
for indx = 1:rows
    for jndx = 1:cols
        if ishandle(grid(indx,jndx))

            [n m] = getComponentSize(this, indx, jndx);

            % Calculate the grid position given the grids width and height.
            gridpos = [ ...
                sum(widths(1:jndx-1))+hg*jndx+1 ...
                panelpos(4)-sum(heights(1:indx+n-1))-vg*(indx+n-1)+1 ...
                sum(widths(jndx:jndx+m-1))+hg*(m-1) ...
                sum(heights(indx:indx+n-1))+vg*(n-1)];

            if isappdata(grid(indx, jndx), ctag)
                hC = getappdata(grid(indx, jndx), ctag);

                % Add the insets to the grid position.
                gridpos = gridpos + [...
                    hC.LeftInset ...
                    hC.BottomInset ...
                    -hC.LeftInset-hC.RightInset ...
                    -hC.BottomInset-hC.TopInset];

                % Get the final width and height from the Fill and
                % Preferred Dimension constraints.
                pos = gridpos;
                switch lower(hC.Fill)
                    case 'none'
                        % Start with an anchor of southwest
                        if pos(3) > hC.PreferredWidth
                            pos(3) = hC.PreferredWidth;
                        end
                        if pos(4) > hC.PreferredHeight
                            pos(4) = hC.PreferredHeight;
                        end
                    case 'horizontal'
                        if pos(4) > hC.PreferredHeight
                            pos(4) = hC.PreferredHeight;
                        end
                    case 'vertical'
                        % Start with an anchor of southwest
                        if pos(3) > hC.PreferredWidth
                            pos(3) = hC.PreferredWidth;
                        end
                    case 'both'
                        % This is a no-op, let it fill the whole area.
                end

                % Get the x and y from the anchor.
                switch lower(hC.Anchor)
                    case 'southwest'
                        % NO OP, already at the origin of the grid area.
                    case 'west'
                        pos(2) = pos(2)+(gridpos(4)-pos(4))/2;
                    case 'northwest'
                        pos(2) = pos(2)+gridpos(4)-pos(4);
                    case 'north'
                        pos(1) = pos(1)+(gridpos(3)-pos(3))/2;
                        pos(2) = pos(2)+gridpos(4)-pos(4);
                    case 'northeast'
                        pos(1) = pos(1)+gridpos(3)-pos(3);
                        pos(2) = pos(2)+gridpos(4)-pos(4);
                    case 'east'
                        pos(1) = pos(1)+gridpos(3)-pos(3);
                        pos(2) = pos(2)+(gridpos(4)-pos(4))/2;
                    case 'southeast'
                        pos(1) = pos(1)+gridpos(3)-pos(3);
                    case 'south'
                        pos(1) = pos(1)+(gridpos(3)-pos(3))/2;
                    case 'center'
                        pos(1) = pos(1)+(gridpos(3)-pos(3))/2;
                        pos(2) = pos(2)+(gridpos(4)-pos(4))/2;
                end
            else

                % Without a constraints object use the defaults of 20/20
                % 'center' and 'none'.
                pos = gridpos;
                if pos(3) > 20
                    pos(3) = 20;
                end
                if pos(4) > 20
                    pos(4) = 20;
                end
                pos(1) = pos(1)+(gridpos(3)-pos(3))/2;
                pos(2) = pos(2)+(gridpos(4)-pos(4))/2;
            end

            % Make sure that we use 1 pixel for everything.  Avoid errors.
            pos(pos < 1) = 1;

            % Set the components new position.
            % **** convertion to matlab r13 ****
            %old: if ishghandle(grid(indx, jndx), 'axes') && ...
            if  ishghandle(grid(indx, jndx)) && ...
                    isequal(get(grid(indx, jndx),'type'),'axes') && ...
                    strcmp(get(grid(indx, jndx), 'ActivePositionProperty'), 'outerposition')
                oldUnits = get(grid(indx, jndx), 'Units');
                set(grid(indx, jndx), 'Units', 'Pixels', 'OuterPosition', pos);
                set(grid(indx, jndx), 'Units', oldUnits);
            else
                setpixelposition(grid(indx,jndx), pos);
            end

            % Remove the control from the grid.
            grid(indx:indx+n-1,jndx:jndx+m-1) = NaN;
        end
    end
end
end
