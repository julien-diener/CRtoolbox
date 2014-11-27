function [ stdImage ] = videoVariance( video, output )
% stdImage = video.videoVariance( output )
%
% Compute the pixel color variance along the video 'video'
% if 'output' is any character(s), display advancement
% if 'output' is a function handle, call "ouput(percent)" at each image

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

video.depth = 1;
video.format = 'double';

meanImage = video.getFrame(1).data;
stdImage  = zeros(size(meanImage()));

if nargin==2
    if ~ischar(output), output(0) % if not char, must be a function handle
    else
        crMessage('Compute video variance (over %d images)', length(video));
        fprintf('*');
        last = 0;
    end;
end

for i=2:length(video)
    img  = video.getFrame(i).data;
    dImage = img - meanImage;
    
    meanImage = meanImage + dImage/i;
    stdImage  = stdImage  + (img - meanImage).*dImage;

    if nargin==2
        if ishandle(output), output(i-1);
        else
            fprintf('*');
            if(~mod(i,50))
                fprintf(' - %4d/%d images\n', 50*floor(i/50), length(video));
            end
        end
    end
end

if nargin==2 && ischar(output)
    j = mod(length(video),50);
    if j, fprintf('\n'); end
    crMessage(2,'Video variance computed.\n\n');
end
stdImage = stdImage ./ max(stdImage(:));
