% class CRVideo
%
% Class that is used as a quick interface for reading and writing to image
% sequence (for reading from an avi file, use subclass 'CRVideoAVI').
%
%         *** To create a CRVideo, use createVideo() function ***
%
%
%******************************* Warning **********************************
%*             The class CRVideo inherites from class handle.             *
%*                Thus, a copy such as   video2 = video1;                 *
%*  is only a reference: all changes made to video2, apply to video1 !!!  *
%*   To make an independant copy of a video object, use constructor (2)   *
%**************************************************************************
%
% Constructor :
% -------------
%  (1)  video = CRVideo( parameters )
%  (2)  video = CRVideo( video2copy )
%
% (1) Use parameters given by the fields of CRParam or structure 'parameters' 
% (2) Make an independant copy of 'video2copy'
% 
% A CRVideo object can be 'input' (read) or 'output' (write). If it is both 
% input and output, it is considered as an input, but each time an image is
% loaded from the input video, the image is saved with memory format for
% quicker futur access. It is seldom useful.
%
% Suitable parameters should be provided for each input, output and data
% management as fields of 'parameters'. Any other field will be added to
% the video data (see functions set() and get() below).
% If some fields are missing, constructors use default values. 
% If 'parameters' is not given, return a default output CRVideo. 
%
% General parameters (for in-memory data management):
% ---------------------------------------------------
%  - format:       Format of image   (default is '', i.e. same as input file)
%  - depth:        Number of channel (default is [], i.e. same as input file)
%  - bufferLength: Number of image kept in memory (default is 2)
%
% -> Video frames can be accessed with function 'video.getFrame(index)' or 
%    directly with 'video(index)'. Images are read from file and then
%    automatically converted following 'format' and 'depth' and store in 
%    the buffer. (ie. in buffer(mod(index,bufferLength)). 
%    Each call to 'getFrame()' check first if the buffer already contain
%    the image and, otherwise, it loads it from file. This allows very quick
%    repetitive access to the latest few images.
%    Function 'setBufferLength(new_Length)' allows to change the buffer size.
%
% Input parameters:
% -----------------
%  - inputPath: directory containing video sequence
%               if not provided, 'inputFile' must contain it
%  - inputFile: any one of the images of the video sequence
%               --- required to make an input sequence ---
%  - length:    max number of image in the video sequence 
%               (default is 0 meaning all images found)
%  - start:     sequence start at the start^th frame. (default is 1) 
%               -> for image sequence (not avi file):
%                The sequence will contain all files with similar name as 
%                'inputFile'. For example, if inputFile='seq12_img013.bmp',
%                sequence will contain all file with name of the form
%                'seq12_img***.bmp'.
%                if start==0, sequence start at the file 'inputFile'.
%
% -> Constructors use the function 'makeInput()' to configure the CRVideo
%    object. It can be used later to update the object if it has changed or
%    convert an output CRVideo to input (see makeInput.m).
%
% Output parameters:
% ------------------
%  - outputPath:   directory to write image file (default is ./tmp)
%                  if not provided, 'outputFile' must contain it
%  - outputFile:   file name of the 1st image of the sequence
%                  --- required to make an output sequence ---
%
% -> Constructors use the function 'makeOutput()' to configure the CRVideo.
%    It can be used later to convert an input CRVideo to output.
% -> Images can be added (writen to file) with function 'saveImage()'
%    (which uses function 'save()' of class 'CRImage', see CRImage.m). It 
%    saves images following extension provided in 'outputFile'. if it is
%    an image file (ex: with extention '.bmp'), it uses function imwrite(), 
%    otherwise it uses function save() (with extention '.mat'). In the
%    first case, if format is not 'uint8' the precision of data might be
%    reduced (see imwrite()).
%
% Attaching data to a CRVideo:
% ----------------------------
% CRVideo provide the functions 'set' and 'get' that allows to attach and
% retrieve any other data to/from a CRVideo. Example with object 'video':
%  -> set(video,var_name,some_data)
% add/replace data called 'var_name' and store 'some_data'
%  -> (1) get(video)          
%     (2) get(video,var_name)
%     (3) get(video,var_name,default)
% (1) retrieve a structure containing all stored data
% (2) retrieve data call 'var_name' 
% (3) same as previous, but return default if var_name does not exist
%
% To remove data, use video.remove(var_name).
% To assert existence, use video.isfield(var_name)
%
% See also: CRVideoAVI, createVideo, CRVideo.saveImage, 
% CRVideo.makeInput, CRVideo.makeOutput

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)

classdef CRVideo < handle
    
    properties
        % internal storage (used for computing)
        format   = ''   % format of images        ('' means same as input)
        depth    = 0    % number of image channel (0  means same as input)
        buffer   = {}   % buffer of images (for quick repetitive access)

        % for input
        inputFile       % name of a video file or cell array of image files
        inputPath       % directory of the video file or image sequence
        first   = 1     % indice of the first image 
        last    = 0     % indice of the last  image 
                        % from outside use 'video.length' or 'length(video)'

        % for output
        outputPath  = '.'            % directory to store computed image
        outputFile  = 'img_%04d.mat' % output file name as used by sprintf
        outputFirst = 0              % image file start at index 0

        % other
        input  = false;     % >0 if it is an input  sequence (1=images, 2=avi)
        output = false;     % >0 if it is an output sequence
        data   = []         % allows to store other data using set() and get()
    end;

    methods
        % --------- Constructor ---------
        function this = CRVideo( param )
            if nargin==0
                % default (output) video
                this.output = 1;
            elseif isa( param, 'CRVideo')
                % make an independant copy
                fields = fieldnames(this);
                for i=1:length(fields)
                    this.(fields{i}) = param.(fields{i});
                end
            else
                % Create the video
                if isstruct(param), param = CRParam(param); end
                
                % ---- parameter for internal data management ----
                this.format = get(param,'format'       ,this.format);
                this.depth  = get(param,'depth'        ,this.depth);
                bLength     = get(param,'bufferLength' , 2 );

                % ---- configure the image buffer ----
                if bLength < 2, bLength = 2; end
                this.setBufferLength(bLength);

                % ---- load sequence ----
                this.input  = false;
                this.output = false;

                inputPath   = get(param,'inputPath' ,'');
                inputFile   = get(param,'inputFile' ,'');
                outputPath  = get(param,'outputPath','');
                outputFile  = get(param,'outputFile','');
                maxLength   = get(param,'length'    , 0);
                startImage  = get(param,'start'     , 1);

                if ~isempty(inputFile)
                    this.makeInput( formatPath(inputPath,inputFile), maxLength, startImage );
                end
                if ~isempty(outputFile)
                    this.makeOutput(formatPath(outputPath,outputFile));
                end
                fields = setdiff(fieldnames(param), ...
                        {'format','depth','bufferLength','inputPath','inputFile',...
                         'outputPath','outputFile','length','start'});
                for i=1:length(fields)
                    set(this,fields{i},get(param,fields{i}));
                end
            end
        end;
        
        % --------------- function set and get ---------------
        % Allow to attach and retrieve other data to the video
        function set(this,var_name,value)
            this.data.(var_name) = value;
        end
        function value = get(this,var_name, default)
            if nargin==1
                value = this.data;
            elseif isfield(this.data,var_name)
                value = this.data.(var_name);
            elseif nargin>2
                value = default;
            else
                error('No appropriate data ''%s''',var_name);
            end
        end
        function remove(this,var_name)
            if isfield(this.data,var_name)
                this.data = rmfield(this.data,var_name);
            end
        end
        function isIt = isfield(this,var_name)
            isIt = isfield(this.data,var_name);
        end
        
        % --------- overload matlab 'length' and 'size' ---------
        function L = length( this, varargin )
            if nargin>1, L = length( this.inputFile );
            else         L = this.last - this.first +1;
            end
        end;
        function s = size( this, dim )
            if isa(this.buffer(1),'CRImage')
                s = [length(this) size(this.buffer(1))];
            else
                s = [length(this) size(this.getFrame(1))];
            end
            if nargin==2
                s = s(dim);
            end
        end;
        
        % --------- overload matlab 'display' and 'disp' ---------
        function display( this )
            if length(this) < 0
                crWarning(this.format)
                return;
            end;
            if this.input
                fprintf('%s = CRVideo, %d images\n', inputname(1), length(this));
            elseif this.output
                fprintf('%s = CRVideo (output)\n',   inputname(1));
            end
            if this.input
                fprintf('    input files: from %s to %s\n',this.imageFileName(1,'input'), this.inputFile{this.last});
            end
            if this.output
                fprintf('   output files: from %s\n', this.imageFileName(1,'output'));
            end
            disp(' ');
        end
        function disp( this )
            if this.input
                fprintf('CRVideo %4d images, starting at %s\n',...
                       length(this),this.imageFileName(1,'input'));
            end
            if this.output
                fprintf('CRVideo save image starting at %s\n',this.imageFileName(1,'output'));
            end
        end
        
        
        % --------- properties set functions ---------
        function set.depth( this, depth )
            if this.depth~=depth
                this.depth = depth;
                this.clearBuffer();
            end
        end
        function set.format( this, format )
            if ~strcmp(this.format,format)
                this.format = format;
                this.clearBuffer();
            end;
        end
        
        function this = setLength( this, maxLength )
            if maxLength==0, maxLength = Inf; end
            this.last = min(length(this,'all')-this.first+1, maxLength) + this.first -1;
        end
        function this = setStart( this, new_start)
            if ischar(new_start) && ismember(new_start,inputFile)
                new_start = strmatch(new_start,inputFile);
            end
            this.first = new_start;
        end
        function this = setBufferLength( this, bufferLength )
            if bufferLength ~= length(this.buffer)
                this.clearBuffer(bufferLength);
            end
        end
        
        % --------- buffer management function (private) ---------
        function clearBuffer( this, newBufferLength )
            if nargin<2, newBufferLength = length(this.buffer); end;
            this.buffer(1:newBufferLength)     = {[]};
            this.buffer(newBufferLength+1:end) =  [];
        end
        function img = bufferRead( this, index )
            ind = mod(index-1,length(this.buffer))+1;
            if isa( this.buffer{ind},'CRImage') && this.buffer{ind}.index == index
                img = this.buffer{ind};
            else
                img = [];
            end
        end
        function bufferWrite( this, image )
            this.buffer{mod(image.index-1,length(this.buffer))+1} = image;
        end
        
        
        
        % --------- manage access '.' '()' '{}' ---------
        function varargout = subsref( this, s )
            try
            if strcmp(s(1).type,'.'), var = this;
            elseif ~isempty(s(1).subs)
                % allows direct access to images s.t: video(imageIndex)
                var = this.getFrame( s(1).subs{:} );
                s(1) = [];
            else
                error('Missing image index');
            end
            if ~isempty(s), [varargout{1:nargout}] = builtin('subsref', var, s);
            else             varargout{1}          = var;
            end
            catch rethrow(lasterror);
            end
        end
        
        function e = end(this,varargin)
            e = length(this);
    end

        % --------- make a CRData for this video ---------
        % createVideo can retrieve this video using this CRData structure 
        function data = makeCRData( this )
            data = CRData();
            data.type = 'CRVideo';
            data.data = this;
            if this.input
                data.inputFile = formatPath(this.inputPath,this.inputFile{1},'/');
                data.length    = this.length;
                data.start     = this.first;
            end
            if this.output
                data.outputFile = this.imageFileName(1);
            end
        end
    end;
end