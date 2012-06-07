classdef StimulusSpace < hgsetget
    % Store a set of images with arbitrary associated properties. Use
    % methods to generate RDMs according to properties.
    % attributes is a cell array of fieldnames for the
    % StimulusSpace.stimulus struct. Other instance properties can be set
    % through varargin - see properties(StimulusSpace) for options.
    % ss = StimulusSpace(attributes,varargin)
    properties
        stimulus = struct; % struct with arbitrary fields
        nstim = 0;
        mdscriterion = 'metricstress';
        doshepardplot = false;
        precision = 5; % rounding of pdist result to preserve ranks
        distfun = 'euclidean';
        referencehist = []; % histogram from e.g. makeaveragehistogram
        hasalpha = 0; % switches to 1 if ANY image has alpha
    end

    methods
        function f = StimulusSpace(attributes,varargin)
        % Initialise a StimulusSpace instance by defining the fieldnames of
        % the stimulus struct. image is initialised as empty, the rest is
        % upt to you.  Alternatively, simply pass a struct/object array in
        % place of the attributes cell array.
        % f = StimulusSpace([attributes],varargin)
            f.stimulus.image = [];
            if ~ieNotDefined('attributes')
                % support initialisation by simply passing a struct/obj arr
                % of stims. 
                if isobject(attributes) || isstruct(attributes)
                    f.stimulus = attributes;
                    f.nstim = length(attributes);
                    % this is incredibly ugly, but unbelievably, Matlab's
                    % builtin isfield doesn't work for object properties
                    try
                        attributes(1).alpha;
                        f.hasalpha = 1;
                    catch
                        f.hasalpha = 0;
                    end
                else
                    for a = asrow(attributes)
                        f.stimulus.(a{1}) = [];
                    end
                end
            end
            % Insert any other nonstandard parameters
            f = varargs2structfields(varargin,f);
        end

        function addstimulus(self,varargin)
        % Add a stimulus to self.stimulus, assigning any attributes as needed
        % based on varargin.
        % addstimulus(varargin)
            self.nstim = self.nstim+1;
            % this line is needed to initialise new entry in struct arr
            self.stimulus(self.nstim).image = [];
            % attempt direct assignment of a structure/object
            % perversely, matlab counts self in nargin but does not provide
            % self as varargin{1}...
            keyboard;
            if nargin==2 && (isstruct(varargin{1}) || ...
                isobject(varargin{1}))
                self.stimulus(self.nstim) = varargin{1};
            else
                % we probably got an argument list instead
                self.stimulus(self.nstim) = varargs2structfields(varargin,...
                    self.stimulus(self.nstim));
            end
            if isfield(self.stimulus(self.nstim),'alpha')
                self.hasalpha = 1;
            end
        end

        function removestimulus(self,ind)
        % Remove a stimulus from self.stimulus, update self.nstim.
        % removestimulus(ind)
            self.stimulus(ind) = [];
            self.nstim = length(self.stimulus);
        end

        function [attr,attrtype] = getattribute(self,attribute)
        % Return a stim by stimdim matrix (or cell if str) for
        % attribute, dealing intelligently with data stored as rows,
        % columns, scalars, matrices (get flattened). attrtype is a string
        % ('row','col','mat','str','scalar').
        % TODO - deal with missing values
        % [attr,attrtype] = getattribute(attribute)
            test = self.stimulus(1).(attribute);
            if isscalar(test)
                attr = cell2mat({self.stimulus.(attribute)})';
                attrtype = 'scalar';
            elseif ischar(test)
                attr = {self.stimulus.(attribute)};
                attrtype = 'str';
            elseif isrow(test)
                attr = {self.stimulus.(attribute)}';
                attrtype = 'row';
            elseif iscol(test)
                attr = {self.stimulus.(attribute)};
                attrtype = 'col';
            elseif ismat(test)
                % Need to flatten and then save
                attr = cellfun(@asrow,{self.stimulus.(attribute)},...
                    'uniformoutput',false)';
                attrtype = 'mat';
            else
                error('unknown data: %s',attribute)
            end
            if ~any([ischar(test) isscalar(test)])
                attr = cell2mat(attr);
            end
            if iscol(test)
                attr = attr';
            end
        end

        function sortbyattribute(self,attribute)
        % Sort self.stimulus in place according to an attribute (must be
        % str or scalar).
        % sortbyattribute(attribute)
            [data,dtype] = self.getattribute(attribute);
            assert(any([strcmp(dtype,'scalar') strcmp(dtype,'str')]),...
                'sortbyattribute works for str or scalars, got %s',dtype)
            [x,I] = sort(self.getattribute(attribute));
            self.stimulus = self.stimulus(I);
        end

        function rdm = rdmbyattribute(self,attribute,distfun)
        % Return a squareform RDM according to some distfun and attribute
        % combination. Wraps self.getattribute, pdist and reduceprecision.
        % Default distfun is taken from properties (self.precision is also
        % used).
        % rdm = rdmbyattribute(attribute,[distfun])
            if ieNotDefined('distfun')
                distfun = self.distfun;
            end
            if ieNotDefined('precision')
                precision = self.precision;
            end
            % ensure double to avoid irritating pdist convert warnings for uint8.
            data = double(self.getattribute(attribute));
            rdm = squareform(reduceprecision(pdist(data,distfun),...
                precision));
        end

        function rsm = rsmacrossattributes(self,attributes,adist,bdist)
        % Generate an RSM of RDMs summarising how different attribute RDMs
        % relate to one another. 
        % attributes - cell array of attributes to include in the comparison
        % adist - either string/fun handle for pdist (default corr) that is
        % applied to all attributes, or a cell array of same length as
        % attributes to vary distance metric across attributes.
        % bdist - the second-order distance function (default spearman).
        % Returns a SIMILARITY matrix, not a DISSIMILARITY matrix because this
        % form tends to make negative correlations between predictors more
        % obvious.
        % rsm = rsmacrossattributes(attributes,adist,bdist)
            if ieNotDefined('adist')
                adist = 'corr';
            end
            if ieNotDefined('bdist')
                bdist = 'spearman';
            end
            nattributes = length(attributes);
            if iscell(adist)
                assert(length(adist)==nattributes,...
                    ['adist must be either string/fun handle OR cell array '...
                    'of same length as attributes']);
            else
                % Make cell array for convenience
                adist = repmat({adist},1,nattributes);
            end
            % Compute RDMs for each attribute
            rdmat = NaN([self.nstim self.nstim nattributes]);
            for a = 1:nattributes
                rdmat(:,:,a) = self.rdmbyattribute(attributes{a},adist{a});
            end
            % And the second-order RSM
            rsm = 1-squareform(pdist(squeeze(vectorizeRDMs(rdmat))',bdist));
        end

        function plotstimulibyattribute(self,attribute,distfun,ax)
        % Return a 2D representation of the distance between the stimuli
        % according to some attribute. If the attribute is 1D/2D we simply use
        % these dims, if >2D we perform MDS and return the result. If
        % self.stimulus has an alpha field we use this to alpha blend before
        % plotting.
        % Wraps self.rdmbyattribute and mdscale.
        % plotstimulibyattribute(attribute,distfun,[ax])
            if ieNotDefined('ax')
                ax = gca;
            end
            if ieNotDefined('distfun')
                distfun = self.distfun;
            end
            data = self.getattribute(attribute);
            switch size(data,2)
                case 1
                    % plot stims on a line
                    Y = [zeros(1,self.nstim) data];
                case 2
                    % just plot
                    Y = data;
                otherwise
                    % need an MDS solution to get to 2D
                    rdm = self.rdmbyattribute(attribute,distfun);
                    [Y,stress,disparities] = mdscale(rdm,2,'Criterion',...
                        self.mdscriterion);
                    if self.doshepardplot
                        F = figurebetter(gcf+1,'medium');
                        distances = pdist(disparities);
                        shepardPlot(rdm,disparities,distances,F);
                    end
            end
            if self.hasalpha;
                alph = {self.stimulus.alpha};
            else
                alph = [];
            end
            imageaxes(ax,Y,{self.stimulus.image},alph);
        end

        function adjustcontrast(self,low,high)
        % Use Matlab's imadjust tool to adjust contrast of images. This tends
        % to make the intensities more homogeneous and is a useful first step
        % before histogram equalisation. low (default .05) and high (default .95)
        % defines clipping values (applied indiscriminately to each RGB
        % channel).
        % adjustcontrast(low,high)
            if ieNotDefined('low')
                low = .05;
            end
            if ieNotDefined('high')
                high = .95;
            end
            for im = 1:self.nstim
                self.stimulus(im).image = imadjust(...
                    self.stimulus(im).image,repmat([low; high],...
                    1,size(self.stimulus(im).image,3)),[]);
            end
        end

        function refhist = makeaveragehistogram(self,target)
        % Populate the referencehist property with the average of the
        % images (or optionally, some other stimulus field defined in
        % target).
        % avghist = makeaveragehistogram([target])
            if ieNotDefined('target')
                target = 'image';
            end
            sizes = cell2mat(cellfun(@size,{self.stimulus.(target)}',...
                'uniformoutput',false));
            assert(~any(logical(std(sizes,1))),'sizes must match')
            refhist = averageandscaleHistograms(...
                {self.stimulus.(target)});
            self.referencehist = refhist;
        end

        function imposehistogram(self,refhist,target)
        % apply a refhist (default self.referencehist) to each image in
        % stimulus.image, or another attribute as defined in target.
        % imposehistogram([refhist],[target])
            if ieNotDefined('refhist')
                assert(~isempty(self.referencehist),...
                    'no refhist supplied and no self.referencehist available.')
                refhist = self.referencehist;
            end
            if ieNotDefined('target')
                target = 'image';
            end
            for im = 1:self.nstim
                self.stimulus(im).(target) = imposeHistogram(...
                    self.stimulus(im).(target),self.referencehist,1:256);
            end
        end

        function imagestruct = exportimages(self,imsize)
        % export images to a struct array with an image field and (if present
        % in self.stimulus) an alpha field. Why not just do imagestruct =
        % self.stimulus? Because this way you can get the images out in a given
        % (consistent) size without changing the contents of self.stimulus.
        % imagestruct = exportimages([imsize])
            if self.hasalpha
                imagestruct = struct('image',{self.stimulus.image},'alpha',...
                    {self.stimulus.alpha});
            else
                imagestruct = struct('image',{self.stimulus.image});
            end
            ifn = fieldnames(imagestruct)';
            for im = 1:self.nstim
                for f = ifn
                    imagestruct(im).(f{1}) = imresize(imagestruct(im).(f{1}),...
                        imsize);
                end
            end
        end
    end
end
