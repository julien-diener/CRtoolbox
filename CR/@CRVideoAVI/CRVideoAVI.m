% class CRVideoAVI 
%
% CRVideoAVI is a (inherite from) Video object. It allows reading from an
% avi file. It uses aviread, thus is restricted to what aviread can do. 
%
%         *** To create a CRVideo, use createVideo() function ***
%
%
%******************************* Warning **********************************
%*             The class CRVideo inherites from class handle.             *
%*                Thus, a copy such as   video2 = video1;                 *
%*  is only a reference: all changes made to video2, apply to video1 !!!  *
%* To make an independant copy of a video object, see CRVideo constructors*
%**************************************************************************
%
% The constructors are the same as for CRVideo as well as the input
% parameters. However CRVideoAVI has the following specific properties: 
%  - inputFile:  The name of the avi file.
%  - readLength: It is either the number of image loaded at a time using 
%                aviread (and kept in memory at all time) or a string of
%                the approximate number of megabytes of memory that is
%                allocated (ex: '200' for 200MB).
% 
% Note: CRVideoAVI has the following properties and function which should 
% be considered private (i.e. should not be called directly)
%  - property 'aviObject':   object returned by aviread
%  - property 'loaded':      indices of frames loaded in avi object
%  - function 'loadFromAvi': call aviread (see help)
% 
% Each time getFrame(index) is called, a CRVideoAVI check first if the image
% is loaded in 'aviObject', otherwise aviread() is called to retrieve a set
% of images of length 'readLength' starting at image 'index' using function
% loadFromAvi(). This is done automatically. But if a better control over
% loading is needed, it can be done by tracking loaded image in 'loaded'
% and calling function loadFromAvi() as desired. However Function
% getFrame() should still be used to retrieve the image data. 
% 
% See also: CRVIDEO, CREATEVIDEO, CREATEVIDEOUI, CRVIDEO.MAKEINPUT,
% CRVIDEOAVI.MAKEINPUT, CRVIDEOAVI.GETFRAME 


% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

classdef CRVideoAVI < CRVideo
    % Class CRVideoAVI inherites from class handle in order for the method
    % 'delete' to be called automatically when object is cleared
    properties
        fileInfo   = struct('NumFrames',0);
        readLength = 0;
        aviObject  = [];
        loaded     = [];
    end
    methods
        % --------- Constructor ---------
        function this = CRVideoAVI( varargin )
            this@CRVideo( varargin{:} );
            if nargin
                rLength = get( this, 'readLength', '_EMPTY_');
                if isequal(rLength,'_EMPTY_')
                    this.readLength = 0;
                else
                    this.readLength = rLength;
                    this.remove('readLength');
                end
            else
                this.readLength = 0;
            end
            if this.first<1, this.first = 1; end;
        end
        
        % --------- overload CRVideo 'length' ---------
        function L = length( this, varargin )
            if nargin>1, L = this.fileInfo.NumFrames;
            else         L = this.last - this.first +1;
            end
        end;

        % --------- overload CRVideo 'display' and 'disp' ---------
        function display( this )
            if length(this) < 0
                crWarning(this.format)
                return;
            end;
            if ~this.input
                fprintf('%s = CRVideoAVI (not ready)\n', inputname(1));
                return;
            end
            fprintf('%s = CRVideoAVI, %d frames\n', inputname(1), length(this));
            fprintf('    input file: %s\n',fullfile(this.inputPath, this.inputFile));
            if this.output
                fprintf('   output files: %s\n', fullfile(this.outputPath,this.outputFile));
            end
            disp(' ');
        end
        function disp( this )
            if this.input
                fprintf('CRVideoAVI: %4d frames from file %s\n',...
                       length(this),formatPath(this.outputPath,this.inputFile,'/'));
            else
                fprintf('CRVideoAVI (not ready)\n');
            end
            if this.output
                fprintf('     (output: image saved as %s)\n',formatPath(this.outputPath,this.outputFile,'/'));
            end
        end;
              
        % --------- aviObject management function (private) ---------
        function img = readFromAvi( this, index )
        %    image = videoAvi.readFromAvi( index )
        % Return image 'index' from video file. Check first if it is 
        % already in aviObject, otherwise call loadFromAvi().
            if isempty(find(this.loaded==index-this.first+1,1))
                this.loadFromAvi( index, this.readLength )
            end
            ind = find(this.loaded==index-this.first+1,1);
            img = this.aviObject(ind).cdata;
        end
        
        function loadFromAvi( this, first, imageNumber)
        %    this.loadFromAvi( first, imageNumber)
        % Load from avi file the images set of size 'imageNumber' 
        % starting at image 'first'
            if imageNumber==0
                this.aviObject = aviread(fullfile(this.inputPath,this.inputFile));
                this.loaded    = 1:this.fileInfo.NumFrames;
            else
                if  imageNumber > length(this)-first+1
                    imageNumber = length(this)-first+1;
                end
                this.loaded    = this.first-1 + first +(0:imageNumber-1);
                this.aviObject = aviread(fullfile(this.inputPath,this.inputFile),this.loaded);
                this.loaded    = this.loaded - this.first +1;
            end
        end

        % --------- overload makeCRData ---------
        function data = makeCRData( this )
            data = CRData();
            data.type = 'CRVideo';
            data.data = this;
            if this.input
                data.inputFile = formatPath(this.inputPath,this.inputFile,'/');
                data.length    = this.length;
                data.start     = this.first;
            end
            data.readLength = this.readLength;
        end

    end;
end