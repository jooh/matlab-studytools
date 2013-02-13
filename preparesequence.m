% Preprocess a given sequence for the study by inserting repeats and
% upcasting the ncharacter indices to nconditions  in a way that minimises
% the resulting imbalances in the transfer matrix.
%
% INPUTS:
% seq: vector of character indices. We assume this is a balanced sequence
%   with ncon repeats.
% nrep: desired total number of repeats (we take off 1 to allow for
%   existing repeat). 
% nlev: number of levels of upcasting (so final ncon will be ncon*nlev)
% tolerance: number of transfer matrix entries that may exceed 1.
% nullind: index for null trials (do not get upcasted)
%
% Note that for some nrep / nlev cases it is not possible to perfectly
% balance the number of trials in each of the upcasted conditions. The
% function will warn you if this happens but will attempt to get as close
% as possible nevertheless.
%
% OUTPUT:
% seq: The output seq will be (nrep-1)*nconditions longer than the input
% 
% seq = preparesequence(seq,nrep,nlev,tolerance,nullind);
function seq = preparesequence(seq,nrep,nlev,tolerance,nullind);

if ieNotDefined('nullind')
    nullind = NaN;
end
s = Inf;

nu = length(unique(seq));
if ~isnan(nullind)
    nu = nu-1;
end
% rescore nullind to 1 greater than rescored values
newnull =(nu*nlev)+1;
seq(seq==nullind) = newnull;

% figure out if we can balance out the number of trials per upcasted
% condition
nfinal = length(seq) + (nrep-1)*nu;
nconfinal = nu * nlev;
if rem(nfinal,nconfinal)>0
    warning(['impossible to divide %d trials evenly into %d ' ...
        'conditions. Consider different nrep'],nfinal,nconfinal)
end

niter = 0;
maxiter = 1e6;
% stop seq from changing across iterations
iterseq = seq;
while s > tolerance
    seq = iterseq;
    if nrep > 1
        % the sequence already has 1 repeat
        seq = insertrepeats(seq,nrep-1);
    end
    % upcast sequence to full set by inserting random views (equal n for each
    % original condition
    [cons,ns] = count_unique(seq);
    % clear out any null events before doing this
    ns(cons==newnull) = [];
    cons(cons==newnull) = [];
    for c = 1:length(cons)
        % number of repeats we are working with
        nc = sum(seq==cons(c));
        % how many will have to share?
        nperlev = floor(nc/nlev);
        % construct a multiplier to create offsets for each level
        mult = [];
        for lev = 1:nlev
            mult = [mult repmat(lev,[1 nperlev])];
        end
        % make sure that we don't confound level with trial order...
        mult = mult(randperm(length(mult)));
        % assign oddballs to random levels
        nrem = rem(nc,lev);
        inds = randperm(nlev);
        mult = [mult inds(1:nrem)];
        seq(seq==cons(c)) = seq(seq==cons(c))+ (nu .* (mult-1));
    end
    tm = transfermatrix(seq);
    if ~isnan(nullind)
        tm(newnull,:) = [];
        tm(:,newnull) = [];
    end
    s = sum(tm(:)>1);
    niter = niter + 1;
    assert(niter<maxiter,'max iteration limit reached')
end
