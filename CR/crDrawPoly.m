function poly = crDrawPoly( axe )
% Allow user to input a polygon with mouse clicks
%   polygon = crDrawPoly( axe = gca )
%
% To delete the last point of the polygon, press delete or backspace 
% When finished double-click or prss enter or return
% Output 'polygon' is a N-by-2 matrix (for a N-points polygon)
%
% See also: crRoiPoly, crFillMask

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

if nargin==0, axe = gca; end
fig = ancestor(axe,'figure');


% Initiate data and UI objects
% ----------------------------
data = CRParam();
data.poly = [];
data.axe  = axe;

data.line1 = line('Parent', axe, ...
                  'Visible', 'off', 'Clipping', 'off', ...
                  'Color', 'k',     'LineStyle', '-');
data.line2 = line('Parent', axe, ...
                  'Visible', 'off', 'Clipping', 'off', ...
                  'Color', 'w',     'LineStyle', ':');
updateLines(data);

data.figMode  = get(fig, 'WindowStyle');
data.figState = uisuspend(fig);

set(fig, 'Pointer', 'crosshair', ...
         'WindowButtonDownFcn',   {@mouseDown, data}, ...
         'WindowButtonMotionFcn', {@mouseMove, data}, ...
         'KeyPressFcn',           {@keyPress,  data}, ...
         'WindowStyle', 'modal'); 

% Wait for double click or return pressed
% ---------------------------------------
waitfor(data.line1,'UserData','_DONE_');

% Return polygone and release figure
% ----------------------------------
poly = data.poly;
% set(gcf, 'Pointer',              get(data,'Pointer'),   ...
%          'WindowButtonDownFcn',  get(data,'mouseDown'), ...
%          'WindowButtonMotionFcn',get(data,'mouseMove'), ...
%          'KeyPressFcn',          get(data,'keyPress'),  ... 
uirestore(data.figState);
set(gcf, 'WindowStyle', data.figMode);

delete(data.line1)
delete(data.line2)
if size(poly,1)>1, poly(end,:) = []; end

end

function mouseDown(hobj, event, data)
    if gca ~= data.axe, axes(data.axe); end
    pts  = get(gca,'CurrentPoint');
    
    if ~isempty(data.poly) && all(data.poly(end-1,:)==pts(1,1:2))
        % click at same location than last click
        %  selectiontype = open <=> double click
        switch get(gcf,'selectiontype')
            case 'normal',  return;
            case 'open',    set(data.line1,'UserData','_DONE_');
        end
        return;
    elseif isempty(data.poly)
        data.poly(1,1:2) = [ NaN NaN ]; 
    end
    data.poly(end,  :) = pts(1,1:2);
    data.poly(end+1,:) = pts(1,1:2);
    
    updateLines(data);
end
function mouseMove(hobj, event, data)
    if isempty(data.poly), return; end
    if gca ~= data.axe,    return; end
    pts  = get(gca,'CurrentPoint');
    data.poly(end,:) = pts(1,1:2);
    updateLines(data);
end
function keyPress(hobj, event, data)
    switch event.Character
        case {char(8), char(127)}
        % delete or backspace: delete last point (if it exist)
            switch size(data.poly,1)
                case 0,    return;     
                case 2,    data.poly = [];
                otherwise, data.poly(end-1,:) = [];
            end
            updateLines(data);
            
        case {char(3), char(13)}
        % enter or return: quit drawPoly
            set(data.line1,'UserData','_DONE_');
    end
end

function updateLines(data)
    if size(data.poly,1)
        set(data.line1, ...
            'XData', [data.poly(:,1) ; data.poly(1,1)],     ...
            'YData', [data.poly(:,2) ; data.poly(1,2)], ...
            'Visible', 'on');
        set(data.line2, ...
            'XData', [data.poly(:,1) ; data.poly(1,1)], ...
            'YData', [data.poly(:,2) ; data.poly(1,2)], ...
            'Visible', 'on');
    else
        set(data.line1, 'XData', [], 'YData', [], 'Visible', 'off');
        set(data.line2, 'XData', [], 'YData', [], 'Visible', 'off');
    end
end
