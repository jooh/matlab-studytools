% Matlab shell wrapper for Aguirre's debruijn c command line app. Assumes
% that the debruijn code on your path (so probably only support for
% mac/linux).
%
% IMPORTANT NOTE: Aguirre's app currently has a bug where all sequences for
% a given second on the system clock are identical. So if you want to
% generate multiple sequences you should include a check for this or a
% pause(1) somewhere in your code.
%
% MANDATORY INPUTS:
% k: number of conditions (max 36)
% model: a dissimilarity matrix (-1 for null entries)
%   (currently only 1 is supported. The app is meant to report detection
%   power for other models (optimisation is only done for the first) but
%   this doesn't seem to work at present)
% soa: in ms
%
% OPTIONAL INPUTS:
% n: level of counterbalancing (default 2)
% B: bin size (we use k to find a sensible option if undefined)
% guidefun: default 'HRF'
%
% OUTPUTS:
% seq: a sequence of k^n length with condition indices in 1:k range
% r: correlation between guidefun (HRF) and distances in sequence
% dpow: relative detection power (proportion of variance in sequence that
% survives passing through an HRF and a .01 Hz high pass filter)
%
% [seq,r,dpow] = debruijn(varargin)
function [seq,r,dpow] = debruijn(varargin)

getArgs(varargin,{'k',[],'n',2,'B',[],'guidefun','HRF','model',[],...
    'soa',[]});


% Aguirre suggests setting B to a number divisible by k^2 to achieve an
% even number of paths in each bin
if ieNotDefined('B')
    % Pick a number towards the middle of this range (10)
    cands = 5:15;
    inds = find(mod(k^2,cands)==0);
    B = cands(inds(ceil(length(inds)/2)));
    assert(~isempty(B),'failed to find a suitable B')
end

basecmd = sprintf('debruijn -t %d %d %d',k,n,B);

if ismat(model)
    model = {model};
end
nmodels = length(model);
assert(nmodels<=1,'only 1 model supported for now')
% use system's tempdir if possible
td = tempdir;
if ieNotDefined('td')
    % if not, use function dir
    td = fileparts(which('debruijn'));
end

matpaths = cell(nmodels,1);
for m = 1:nmodels
    % Save mat to text file
    matpaths{m} = fullfile(td,sprintf('debruijn_model_%d.txt',m));
    ocdwrite(matpaths{m},model{m});
    %dlmwrite(matpaths{m},model{m},'delimiter',' ','newline','pc');
    % append filepath to basecmd
    basecmd = [basecmd ' ' matpaths{m}];
end

% Add final bits and run the beast
basecmd = sprintf('%s %s -eval %f',basecmd,guidefun,soa);
[err,res] = system(basecmd);
assert(~err,['command failed with message: ' res]);

% Extract data
lines = textscan(res,'%s','delimiter','\n');
lines = lines{1};
headerlines = findStrInArray(lines,'Cycle found:');
lines = lines(headerlines+2:end);
seqstr = lines{1};
% Convert to numbers in 1:k range
alphabet = unique(seqstr);
seq = NaN([1 length(seqstr)]);
for a = 1:length(alphabet)
    seq(seqstr==alphabet(a)) = a;
end

% Extract sequence descriptives
r = textscan(lines{6},'%*s %*s %f');
r = r{1};
dpow = textscan(lines{7},'%*s %*s %f');
dpow = dpow{1};

% remove temp files (matpaths)
for m = 1:nmodels
    delete(matpaths{m});
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
