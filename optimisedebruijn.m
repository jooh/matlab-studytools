% Wrapper for debruijn to optimise detection power (dpow) or correlation
% between distances and guide function (r). Both vary
% widely across sequences. 
%
% Note that this function runs in parallel with matlabpool('local') if you
% set cachemodels=1 (without caching parallel isn't available).
%
% MANDATORY INPUTS:
% nseq: how many sequences you want returned
% nsim: how many sequences you want to run
% criterion: 'dpow' or 'r' - the top nseq sequences are returned in sorted
%   order
% 
% NAMED INPUTS:
% (see debruijn - k, soa and models are mandatory)
%
% OUTPUTS:
% seqs: n by k^2 matrix of sequences
% rs: n by 1 vector of correlations
% dpows: n by nmodels matrix of detection power estimates
%
% [seqs rs dpows] = optimisedebruijn(nseq,nsim,criterion,varargin)
function [seqs rs dpows] = optimisedebruijn(nseq,nsim,criterion,varargin)

assert(nsim>nseq,'must allow more nsim than nseq')

% check for typos before running long simulations rather than after...
assert(any(strcmp(criterion,{'r','dpow'})),'criterion must be r or dpow')

getArgs(varargin,{'k',[],'n',2,'B',[],'guidefun','HRF','models',[],...
    'soa',[],'cachemodels',0});

if ismat(models)
    models = {models};
end
nmodels = length(models);

% preallocate
rawseq = NaN([nsim k^n]);
rawr = NaN([nsim 1]);
rawdpow = NaN([nsim nmodels]);

if cachemodels
    if matlabpool('size')==0
        matlabpool('local');
    end
    % Call once to create model matrices in cache
    [x,x,x] = debruijn(varargin{:});
    parfor n = 1:nsim
        [rawseq(n,:) rawr(n) rawdpow(n,:)] = debruijn(varargin{:});
    end
else
    % NB cannot parallelise this since debruijn writes to a standard file
    % on disk
    for n = 1:nsim
        [rawseq(n,:) rawr(n) rawdpow(n,:)] = debruijn(varargin{:});
    end
end

% past versions of debruijn had a bug where identical sequences were
% returned on the same second of the system clock. So for historical
% reasons we make sure that this is no longer a problem (or that you aren't
% using an old version of the debruijn c app). This is also a good check
% for incorrect usage (ie, give me 1000 unique k=2 n=2 sequences...).
assert(size(unique(rawseq,'rows'),1)==nsim,...
    'duplicate sequences detected! Too small k?')

% already checked that criterion is one of these
switch criterion
    case 'r'
        [x,rawinds] = sort(rawr,'descend');
    case 'dpow'
        % sort by first model since this is the one we guide
        [x,rawinds] = sort(rawdpow(:,1),'descend');
end

inds = rawinds(1:nseq);
rs = rawr(inds);
dpows = rawdpow(inds,:);
seqs = rawseq(inds,:);
