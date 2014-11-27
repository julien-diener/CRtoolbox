% class CRImage
%
% CRImage is a generic image object designed mainly to manage image of a 
% video sequence: the image index is stored in the corresponding attribute.
% It also provide a set of functions to simplify image management.
%
%
% Constructors:
% img = CRImage( heigth, width,           depth=1,  format='double' ) 
% img = CRImage( image_data,    index=0,  depth=[], format='' )
% img = CRImage( image_file,    index=[], depth=[], format='' )
% img = CRImage( CRImage i,     index=[], depth=[], format='' )
% img = CRImage( 'UI',          index=0,  depth=[], format='' )
%
% Input:
%  - image_data: 2D or 3D array (where the last dimension is the depth)
%  - image_file: file name of an image (use imread) or an M-file
%  - index:      index of image if it is part of a sequence
%                an empty array [] (default) means "same as input"
%  - depth:      3rd dimension of data (typically 1=gray, 3=rgb)
%                an empty array [] (default) means "same as input"
%  - format:     precision of data (uint8, single,...)
%                an empty array [] (default) means "same as input"
%  - 'UI':       start a Gui to browse for an image file
%
%
% Available methods:
%  - save(file_name)       Save image to file 'file_name'
%  - load(file_name)       Load image file 'file_name'
%                          For both save & load, the file can be an image 
%                          file (ex:*.bmp) or a mat-file. When saving to an
%                          image file, data precision can be lost !
%  - convert(depth,format) Convert image to 'depth' and 'format'
%                          if format=='', do not change it
%                          if depth ==0,  do not change it
%                          if depth ==1 & img.depth==3, do rgb2gray convertion
%  - scale()               map image data from [min,max] to [0,1]
%  - imshow()              overload image toobox function
%
% Attributs / accessing methods and operators for a CRImage 'img':
%  - img() or img.data gives the array of image data
%  - the following method can be called as method(img...) or img.method(...)
%     * size    * size(dimention)   * width  * height  * depth
%     * format  * index             * max    * min     * sum
%     * find    * isnan             * sqrt   * norm
%
%  - Access with indices, ex: img(1:end/2,:,3)
%  - Operators: + - .* ./ .^ '(transpose) < <= > >= == ~=
%
% In most cases, a CRImage can be used directly like an array for data access 
% and arithmetic operations. However, if necessary operator have not been 
% implemented or if a high number of operations (>1000s) are done, extract 
% data first (s.t. data = image.data or data = image()) and use them 
% directly (avoiding the additional computation time due to reading m-file)

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


classdef CRImage
    
    properties
        data  = [] % image array data
        index = 0  % index of image if used in a video sequence
    end;
    
    methods
        % constructor
        function this = CRImage(varargin)
            v = varargin;

            if nargin==0, return;           end
            if nargin>1,  this.index = v{2};  end
            
                
            if ischar(v{1}) || isa( v{1} , 'CRImage' )
                if ischar(v{1}), this = this.load( v{1} );
                else             this = v{1};
                end
                switch nargin
                    case 4, this = this.convert( v{3}, v{4} );
                    case 3, this = this.convert( v{3},  ''  );
                end
            elseif isscalar(v{1})
                switch nargin
                    case 4, this.data = zeros(v{1},v{2},v{3},  v{4}  );
                    case 3, this.data = zeros(v{1},v{2},v{3},'double');
                    case 2, this.data = zeros(v{1},v{2},   1,'double');
                    case 1, this.data = zeros(v{1},v{1},   1,'double');
                end
                this.index = 0; % default image index
            else
                this.data = v{1};
                switch nargin
                    case 4, this = this.convert( v{3},  v{4} );
                    case 3, this = this.convert( v{3},   ''  );
                end
            end
        end;
        
        % convert image to given format and depth
        function this = convert(this,new_depth,new_format)
            % Convert format
            if ~isempty(new_format) && ~strcmp(format(this),new_format)
                old_format = class(this.data);

                % var_max is an internal function, see end of convert()
                old = var_max(old_format); 
                new = var_max(new_format);

                if isfloat(old) && isinteger(new)
                    this.data = cast(this.data.*double(new),new_format);
                elseif isinteger(old) && isfloat(new)
                    this.data = cast(this.data,new_format)./double(old);
                else
                    this.data = cast(this.data,new_format); 
                end
            end
            % convert depth
            if ~isempty(new_depth)&& new_depth>0 && (new_depth ~= depth(this))
                if depth(this)==3 && new_depth==1
                    % conversion rgb to gray
                    this.data = 0.3 *this.data(:,:,1) ...
                              + 0.59*this.data(:,:,2) ...
                              + 0.11*this.data(:,:,3);
                else
                    % other cases: 
                    % if old>new, remove exceeding channels.
                    % if new>old, add new channels with same values as the
                    % 1st (i.e. does conversion gray-to-rgb automatically)
                    this.data = cat(3, this.data(:,:,1:min(new_depth,depth(this))), ...
                                       repmat(this.data(:,:,1),[1 1 new_depth-depth(this)]));
                end
            end

            function m = var_max( format )
                if strcmp(format,'logical')
                    m = true(1);
                else
                    m = ones(1,format);
                    if isinteger(m)
                        m = intmax(format);
                    end
                end;
            end
        end
        
        % Load image from either an image file (imread) or a mat-file (load)
        % does not produce error (return [] if failed)
        % If file='UI', ask user to select a file
        function this = load(this, file)
            if nargin<2 || strcmpi(file,'ui') || exist(file,'dir')
                % browse an image file
                [f{1:2}] = uigetfile({'*.*',  'All Files (*.*)'}, 'Select an image');
                if ischar(f{1}),  file = [f{[2 1]}];
                else              return
                end
            end
            try
                ext = find(file == '.');
                if isempty(ext), ext = '.';
                else             ext = file((ext(end) + 1):end);
                end
                
                if ~isempty(imformats(ext))
                    this.data = imread(file);
                    %! todo: manage indexed image
%                     [img,map] = imread(file);
%                     this.data = map(img(:)+1,:);
%                     this.data = reshape(this.data,[size(img) size(map,2)]);
                    
                else
                    img = load(file);
                    var = fieldnames(img);
                    img = img.(var{1});
                    if isa(img,'CRImage'), this = img;
                    else                  this.data = img;
                    end
                end
            catch this.data = [];
            end
        end

        % save image in 'file' in either image file (using imread) or
        % mat-file (using load) depending on the extension of 'file'
        function file = save(this, file, varargin)
            if nargin<2 || strcmpi(file,'ui')
                if ~isempty(varargin), file = varargin{1};
                else                   file = pwd;
                end
                % browse an image file
                [f{1:2}] = uiputfile({'*.*',  'All Files (*.*)'}, 'Select a file',file);
                if ischar(f{1}),  file = [f{[2 1]}];
                else              file = ''; return;
                end
            end
            % check if directory exist
            if ~exist(fileparts(file),'dir')
                mkdir(fileparts(file));
            end
            
            ext = find(file == '.');
            if isempty(ext), ext = '.';
            else             ext = file((ext(end) + 1):end);
            end

            if ~isempty(imformats(ext))
                imwrite(this.data,file);
            else
                img = this.data;
                save(file,'img');
            end
        end
    
        % -------- accessing data with subscript --------
        function var = subsref(this,s)
            try
            if strcmp(s(1).type,'.'), var = this;
            elseif ~isempty(s(1).subs)
                % allows direct access to images s.t: video(imageIndex)
                var = CRImage();
                var.data  = this.data( s(1).subs{:} );
                var.index = this.index;
                s(1) = [];
            else
                var = this.data;   % return the data array
                s(1) = [];
            end
            if ~isempty(s), var = builtin('subsref', var, s);
            end
            catch rethrow(lasterror);
            end
        end
        
        function A = subsasgn(A, s, B)
            if strcmp(s(1).type,'()') 
                if isa(B,'CRImage'), A.data( s(1).subs{:} ) = B.data;
                else                 A.data( s(1).subs{:} ) = B;
                end
            elseif strcmp(s(1).type,'.')
                switch s(1).subs
                    case 'index', A.index = B;
                    case 'data'
                        if length(s)==1,     A.data = B;
                        elseif length(s)==2, A.data(s(2).subs{:}) = B;
                        else
                            error('Incorrect assignement');
                        end
                    otherwise
                        error('No public field ''%s'' exists for class %s.',s(1).subs,class(A));
                end
            else
                error('Cell contents assignment to a non-cell array object.');
            end
        end
        
        % --------- accessing property and operators ---------
        function e = end(this,k,varargin)
            e = size(this,k);
        end
        
        function r = times(p,q)
            r = CRImage;
            if isa(p,'CRImage'), p = p.data; end;
            if isa(q,'CRImage'), q = q.data; end;
            r.data = p .* q;
        end
        function r = rdivide(p,q)
            r = CRImage;
            if isa(p,'CRImage'), p = p.data; end;
            if isa(q,'CRImage'), q = q.data; end;
            r.data = p ./ q;
        end
        function r = power(p,q)
            r = CRImage;
            if isa(p,'CRImage'), p = p.data; end;
            if isa(q,'CRImage'), q = q.data; end;
            r.data = p .^ q;
        end
        function r = plus(p,q)
            r = CRImage;
            if isa(p,'CRImage'), p = p.data; end;
            if isa(q,'CRImage'), q = q.data; end;
            r.data = p + q;
        end
        function r = minus(p,q)
            r = CRImage;
            if isa(p,'CRImage'), p = p.data; end;
            if isa(q,'CRImage'), q = q.data; end;
            r.data = p - q;
        end
        function r = ctranspose(this)
            r = CRImage();
            r.data = this.data';
            r.index  = this.index;
        end
        
        function i = lt( this, value )
            if isa(value,'CRImage'),  value = value.data;  end
            i = this.data <  value;
        end
        function i = le( this, value )
            if isa(value,'CRImage'),  value = value.data;  end
            i = this.data <= value;
        end
        function i = ge( this, value )
            if isa(value,'CRImage'),  value = value.data;  end
            i = this.data >= value;
        end
        function i = gt( this, value )
            if isa(value,'CRImage'),  value = value.data;  end
            i = this.data >  value;
        end
        function i = eq( this, value )
            if isa(value,'CRImage'),  value = value.data;  end
            i = this.data == value;
        end
        function i = ne( this, value )
            if isa(value,'CRImage'),  value = value.data;  end
            i = this.data ~= value;
        end
        
        function m = max(this)
            m = max(this.data);
        end
        function m = min(this)
            m = min(this.data);
        end
        function s = sum(this)
            s = sum(this.data);
        end
        function s = sqrt(this)
            s = CRImage(sqrt(this.data));
        end
        function s = norm(this)
            s = norm(this.data);
        end
                
        function [ varargout ] = size(this, varargin)
            [varargout{1:nargout}] = size(this.data,varargin{:});
        end
        function w = width(this)
            w = size(this.data,2);
        end
        function h = height(this)
            h = size(this.data,1);
        end
        function d = depth(this)
            d = size(this.data,3);
        end
        function e = isempty( this )
            e = isempty(this.data);
        end

        function f = format( this )
            f = class(this.data);
        end

        function this = setIndex( this, index )
            this.index = index;
        end
        
        function i = find( this )
            i = find(this.data);
        end
        function i = isnan( this )
            i = isnan(this.data);
        end
        
        % --------- overload imshow ---------
        function h = imshow(this, varargin)
        % h = imshow(image);
        % h = imshow(image, ...parameter_value_paires...)
        % 
        % call image processing toolbox 'imshow'
        % or provide an alternative if the toolbox is not installed
            if exist('imshow.m','file')
                hh = imshow(this.data);
            else
%-----------------------------------------------------------
%                 % if float data, clamp values out of [0,1] 
%                 if isfloat(this.data)
%                     this.data(this.data<0) = 0;
%                     this.data(this.data>1) = 1;
%                 end
%! useless because of following convertion to uint8 rgb
%-----------------------------------------------------------
                
                % display image using 'image' function
                % (convert to rgb such that it don't require a colormap)
                hh = image(this.convert(3,'uint8').data,  ...
                           'BusyAction',   'cancel', ...
                           'CDataMapping', 'scaled', ...
                           'Interruptible', 'off');
                axe = ancestor(hh,'axes');

                % Set axes properties to display the image object correctly.
                set(axe, 'YDir','reverse',...
                         'DataAspectRatio', [1 1 1], ...
                         'PlotBoxAspectRatioMode', 'auto', ...
                         'Visible', 'off');
                set(get(axe,'Title') ,'Visible','on');
                set(get(axe,'XLabel'),'Visible','on');
                set(get(axe,'YLabel'),'Visible','on');
            end
            if nargout, h = hh; end
        end

        % --------- normalize image data ---------
        function img = scale(this)
            img = this;
            if ~isfloat(this.data)
                f = this.format;
                img.convert([],'single');
            end
            mi  = min(img.data(:));
            ma  = max(img.data(:));
            img.data = (img.data-mi)./(ma-mi);
            if ~isfloat(this.data)
                img.convert([],f);
            end
        end
        
        % --------- overload display and disp --------- 
        function display( this )
            fprintf('%7s: class ''CRImage''\n', inputname(1));
            fprintf('   size: %dx%d,\n',this.height,this.width);
            fprintf('  depth: %d,\n',   this.depth);
            fprintf(' format: %s\n',    this.format);
            fprintf('  index: %d\n',    this.index);
        end
        function disp( this )
            fprintf('CRImage: %dx%dx%d (%s)\n',this.height,this.width,this.depth,this.format)
        end
        
        
    end;
end