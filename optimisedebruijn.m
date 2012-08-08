% Wrapper for debruijn - detection power and r both vary widely across
% sequences. This function returns the nseq best sequences according to the
% chosen criterion out of nsim attempts. Effectively this is a wrapper for
% debruijn with 3 additional, nonoptional arguments that come before the
% named debruijn args: nseq, nsim and criterion.
%
% Compute time is almost exactly 1 s per simulation right now due to a bug
% in Aguirre's code.
%
% [seqs rs dpows] = optimisedebruijn(nseq,nsim,varargin)
function [seqs rs dpows] = optimisedebruijn(nseq,nsim,criterion,varargin)

assert(nsim>nseq,'must allow more nsim than nseq')

assert(any(strcmp(criterion,{'r','dpow'})),'criterion must be r or dpow')

getArgs(varargin,{'k',[],'n',2,'B',[],'guidefun','HRF','model',[],...
    'soa',[]});

% preallocate
rawseq = NaN([nsim k^n]);
rawr = NaN([1 nsim]);
rawdpow = NaN([1 nsim]);

% NB cannot parallelise this since debruijn writes to a standard file on
% disk
for n = 1:nsim
    tic;
    [rawseq(n,:) rawr(n) rawdpow(n)] = debruijn(varargin{:});
    % necessary since Aguirre code currently only reset randomisation once
    % per second
    while toc <= 1
        pause(0.001);
    end
end

switch criterion
    case 'r'
        [x,rawinds] = sort(rawr,'descend');
    case 'dpow'
        [x,rawinds] = sort(rawdpow,'descend');
    otherwise
        error('unknown criterion: %s',criterion)
end

inds = rawinds(1:nseq);
rs = rawr(inds);
dpows = rawdpow(inds);
seqs = rawseq(inds,:);
