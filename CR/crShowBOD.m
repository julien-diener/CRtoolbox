function crShowBOD( image, bod, scale )
% crShowBOD display the BOD modes computed by crBOD
%   crShowBOD(background, bod, scale=1)
%
% 'background' is the image to display in background. It can be either:
%   - a CRimage
%   - a CRVideo: the first image is displayed
%   - a CRData (typically from a CRProject) containing a CRVideo.
%   - an image data array (size = height*width*depth).
%   - a 2 elements array [height,width] of a black background to display
%
% 'bod' is a structure returned by crBOD, or a CRData containing that
% structure (as contained by a CRProject).
%
% 'scale', multiply all x and y coordinates of 'bod' by scale. If the bod
% has been computed on an optical flow data, scale should be the distance
% between the flow cells, i.e. the cell size times the overlap.
%
% See also: crBOD, crKLT, crPIV, crProject

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

%%! Todo: show chronos, pb: subfigure reduces displayed image size

if isnumeric(image)
    if numel(image)<4, image = CRImage(image(1),image(2)) +1;
    else               image = CRImage(image);
    end
elseif isa(image,'CRData') && strcmp(image.type,'CRVideo')
    image = image.load();
    image = image(1);
elseif isa(image,'CRVideo')
    image = image(1);
elseif ~isa(image,'CRImage')
    crError('crShowBOD: incorrect type of first argument');
    return;
end

if isa(bod,'CRData'), bod = bod.load(); end

if nargin<3, scale = 0; end

% display mode alphas

% display modes
h = figure;
mode = -1;
modeNumber = length(bod.alpha);

while mode <= modeNumber
    figure(h);
    if mode<0, 
        bar(bod.alpha./bod.trace);
    else
        imshow(image); 
        hold on;
        quiver(scale*bod.x(:),scale*bod.y(:),bod.topos(1:2:end,mode),bod.topos(2:2:end,mode))
        drawnow;
        hold off
    end
    
    if mode<0, k = input(sprintf('alpha    (''h'' for help) >')      ,'s');
    else       k = input(sprintf('modes %2d - energy %4.4f%%(''h'' for help) >',mode,bod.alpha(mode)./bod.trace),'s');
    end

    switch lower(k)
        case 'q', break;
        case 'h'
            disp('     * enter       -> next mode');
            disp('     * mode_number -> display the corresponding mode');
            disp('     * alpha       -> display a bar plot of mode coefficients');
            disp('     * ''q''         -> quit');
        case 'alpha'
            mode = -mode;
        otherwise
            if ~isnan(str2double(k))
                mode = mod(abs(str2double(k)), modeNumber);
                if mode==0, mode = modeNumber; end
            else
                if mode<0, mode = -mode;
                else       mode =  mode +1;
                end
                if mode>modeNumber,  mode = 1; end
            end
    end
end

if ishandle(h), close(h); end