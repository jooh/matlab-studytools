% Matlab shell wrapper for Aguirre's debruijn c command line app. Assumes
% that the debruijn code on your path (so probably only support for
% mac/linux).
%
% If called with k/n only, we get a 'pure' debruijn sequence without
% path-guiding. If you want path-guiding you must define soa and models -
% the remaining arguments can be inferred.
%
% MANDATORY INPUTS:
% k: number of conditions (max 36)
%
% OPTIONAL INPUTS:
% n: level of counterbalancing (default 2)
% models: a single dissimilarity matrix (-1 for null entries) or a cell
%   array of matrices (the guide function is determined by model 1, but
%   detection power is reported for the other two as well)
% soa: in ms
% B: bin size (we use k to find a sensible option if undefined)
% guidefun: default 'HRF'
% cachemodels: default 0. If 1, we save model text files with a SHA-1
%   hash'ed filename, and reuse the same files if they exist. This saves us
%   having to re-write the model matrices to disk, but the speedup looks a
%   bit more modest than I had hoped. One potential benefit is that once
%   the models have been initialised (ie, the function has been run once
%   with cachemodels=1), no further writing to disk takes place so it
%   becomes possible to execute the optimisation in parallel (see
%   optimisedebruijn)
%
% OUTPUTS:
% seq: a sequence of k^n length with condition indices in 1:k range
%
% CONDITIONAL OUTPUTS: (only returned if guidefun, soa and models are
% defined)
% r: correlation between guidefun (HRF) and distances in sequence
% dpow: relative detection power (proportion of variance in sequence that
% survives passing through an HRF and a .01 Hz high pass filter) for each
% input model
%
% [seq,[r],[dpow]] = debruijn(k,[n],varargin)
function [seq,r,dpow] = debruijn(k,n,varargin)

getArgs(varargin,{'B',[],'guidefun','HRF','models',[],...
    'soa',[],'cachemodels',0});

if ieNotDefined('n')
    n = 2;
end

if ~ieNotDefined('models') && ismat(models)
    models = {models};
end
nmodels = length(models);
assert(nmodels<=3,'only 3 models supported for now')

if nmodels
    basecmd = sprintf('debruijn -t %d %d %d %s',k,n,B,guidefun);
else
    basecmd = sprintf('debruijn -t %d %d',k,n);
end

% Aguirre suggests setting B to a number divisible by k^2 to achieve an
% even number of paths in each bin
if ieNotDefined('B') && nmodels
    if k<5
        B=k^2;
    else
        % Pick a number towards the middle of this range (10)
        cands = 5:15;
        inds = find(mod(k^2,cands)==0);
        B = cands(inds(ceil(length(inds)/2)));
    end
    assert(~isempty(B),'failed to find a suitable B')
end

% use system's tempdir if possible
td = tempdir;
if ieNotDefined('td')
    % if not, use function dir
    td = fileparts(which('debruijn'));
end

matpaths = cell(nmodels,1);

if cachemodels
    % only use expensive DataHash function if we are cacheing
    namefun = @(x) DataHash(models{x},struct('Method','SHA-1'));
else
    namefun = @(x) num2str(x,'%.0f');
end

for m = 1:nmodels
    % Save mat to text file (name either by m or hash)
    matpaths{m} = fullfile(td,sprintf('debruijn_model_%s.txt',...
        namefun(m)));
    % if the file exists and we are cacheing, save a write operation
    if ~exist(matpaths{m},'file') || ~cachemodels
        ocdwrite(matpaths{m},models{m});
    end
    % append filepath to basecmd
    basecmd = [basecmd ' ' matpaths{m}];
end

% Add final bits and run the beast
if nmodels
    basecmd = sprintf('%s -eval %f',basecmd,soa);
end
[err,res] = system(basecmd);
assert(~err,['command failed with message: ' res]);

% Extract data
lines = textscan(res,'%s','delimiter','\n');
lines = lines{1};
headerlines = strfindcell(lines,'Cycle found:');
lines = lines(headerlines+2:end);
seqstr = lines{1};
% Convert to numbers in 1:k range
alphabet = unique(seqstr);
seq = NaN([1 length(seqstr)]);
for a = 1:length(alphabet)
    seq(seqstr==alphabet(a)) = a;
end

% shortcircuit here if we're done
if ~nmodels
    r = [];
    dpow = [];
    return
end

% Extract sequence descriptives
r = textscan(lines{6},'%*s %*s %f');
r = r{1};
if nmodels==1
    dpow = textscan(lines{7},'%*s %*s %f');
    dpow = dpow{1};
else
    dpow = NaN([1 nmodels]);
    for m = 1:nmodels
        dpowcell = textscan(lines{6+m},'%*s %*s %*s %f');
        dpow(m) = dpowcell{1};
    end
end

% remove temp files (matpaths)
if ~cachemodels
    for m = 1:nmodels
        delete(matpaths{m});
    end
end

% need a truly ocd matwrite subfun to meet the requirements (only carriage
% return on line end is particularly tricky to get right in Matlab)
function ocdwrite(path,mat)

fid = fopen(path,'w');
[nrow,ncol] = size(mat);
form = repmat('%f ',[1 ncol]);
% strip last space
form(end) = [];
for n = 1:nrow
    fprintf(fid,form,mat(n,:));
    if n~=nrow
        fprintf(fid,'\r');
    end
end
fclose(fid);
