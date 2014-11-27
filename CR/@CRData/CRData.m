%
% Class CRData is a simple subclass of CRParam that provides an interface
% to store any data that cannot be save directly within a CRParam file
% (i.e using array2str) 
%
% A CRData is a CRParam structure that contains the following fields:
%   - type:    type of the data to store (its class)
%   - data:    the stored data
%
% It also contains one or more fields to allow reading and writing the data
% to the hard-disk. Usually, this is one field 'file' indicating the mat
% file to load and to save the data to.
%
% Constructors:
%  (1) obj = CRData();
%  (2) obj = CRData( data , filename, write=true)
%  (3) obj = CRData( fileName, variableName=1 )
%  (4) obj = CRData( crvideo_obj )
%  (5) obj = CRData( crparam_obj )
%
%  (1) Create an empty CRData object
%  (2) Create the CRData object linking 'data' and file 'fileName'
%      if write=true, write 'data' to file 'fileName'.
%  (3) Load data store in file 'fileName'. 
%      If 'variableName' is provided, it loads the variable with name given 
%      by 'variableName' from file. By default, it loads the first one.
%  (4) make a CRData object for the CRVideo 'crvideo_obj'
%  (5) make a CRData from CRParam (or any subclass s.t. CRData) 'crparam_obj'
%      if data and file is not provided, they are set to empty array.
%
%
% Methods: 
%   - save(file=[])   save the data to hard-disk. if file is given, change
%                     this crdata file field.
%   - load(force=0)   return the data. It loads data from hard-disc if data
%                     is empty or if force=true
%   - isvalid()       return true if type and file are defined and file exist
%
%   If this data is a CRVideo, then the CRVideo player can called
%   directly, see CRVideo/player.
%
% See also: CRParam, CRProject, CRVideo

% Author: Julien Diener
% Licence: CeCill-B (BSD-like under french law, see http://www.cecill.info)


classdef CRData < CRParam
    methods
        function this = CRData(data, fileName, write)
            this@CRParam();
            if nargin==0                                 % constructor (1)
                this.data.type = '';
                this.data.data = [];
            elseif isa(data,'CRParam')                   % constructor (5)
                % make an independant copy of data
                this.merge(data);
                this.assert('type','');
                this.assert('data',[]);
            elseif isa(data,'CRVideo')                   % constructor (4)
                this.merge(makeCRData(data));
            elseif ischar(data) && exist(data,'file')==2 % constructor (3)
                if nargin<2, var = 1;
                else         var = fileName;
                end
                this.data.file = data;
                data = load(data);
                f = fieldnames(data);
                if isempty(f) || (isnumeric(var) && var>length(f))
                    error('loaded file does not contain data or not enough');
                end
                if ischar(var),  
                    var = strmatch(var,f,'exact'); 
                    if isempty(var)
                        error('no variable ''%s'', found in file %s',filename,data);
                    end
                end
                data = data.(f{var});
                this.data.type = class(data);
                this.data.data = data;
            else                                         % constructor (2)
                if nargin<3, write=true; end
                this.data.type = class(data);
                this.data.file = fileName;
                this.data.data = data;
                if write, this.save(); end
            end
        end
        
        function data = load( this, param )
            % retrieve data if it is already stored
            data = this.data.data;
            if ~isempty(data) && (nargin<2 || ~strcmpi(param,'update'))
                return
            end
            % 
            
            % test if file exist
            switch this.data.type
                case ''
                    if nargin<2 || ~strcmp(param,'attempt')
                        error('invalid CRData: type is not defined');
                    end
                    return
                case 'CRVideo', f = 'inputFile';
                otherwise,      f = 'file';
            end
            if exist(this.data.(f),'file')~=2
                % generate an error if param ~= 'attempt'
                if nargin<2 || ~strcmp(param,'attempt')
                    error('data file does not exist'); 
                end
                return;
            end
            % load data
            switch this.data.type
                case 'CRImage'
                    this.data.data = CRImage(this.data.file);
                case 'CRVideo'
                    this.data.data = createVideo(this);
                otherwise
                    tmp = load(this.data.file);
                    f   = fieldnames(tmp);
                    this.data.data = tmp.(f{1});
            end
            data = this.data.data;
        end
        
        function save( this )
            if isa(this.data.data,'CRImage')
                this.data.data.save(this.data.file);
            elseif ~strcmp(this.data.type,'CRVideo')
                data = this.data.data;
                save(this.data.file,'data');
            end
        end
        
        %%! remove methods removePath and setPath
%   - removePath(dir) remove directory 'dir' from this data properties
%                     in case they contains it
        function removePath( this, path )
            if strcmp(this.data.type,'CRVideo'), f = 'inputFile';
            else                                 f = 'file';
            end
            path = formatPath(path,'/');
            lp  = length(path);
            var = formatPath(this.data.(f),'/');
            if strncmp(var,path,lp)
                this.data.(f) = var(lp+2:end);
            end
        end
        function setPath(this, path, test)
            if isfield(this,'inputFile'), f = 'inputFile';
            else                          f = 'file';
            end
            new_path = formatPath(path,this.data.(f));
            if ~test || exist(new_path,'file')==2
                this.data.(f) = new_path;
            end
        end

        % special case if this crdata is a crvideo,
        % provide a direct access to function player
        function h =  player( this, varargin )
            if ~strcmp(this.data.type,'CRVideo')
                error('play function only works with CRVideo data type');
            end
            this.load();
            h = player( this.data.data, varargin{:} );
        end
    end
end