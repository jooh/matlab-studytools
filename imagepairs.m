% Present 2 pairs of images, ask subject to rate which pair is more
% similar. Construct similarity matrix based on how often a given pair is
% preferred relative to all comparisons it is included in
% res = imagepairs(imagestruct,options)
% ABANDONED UNFINISHED - you need npairs(npairs(nimages)) trials to sample
% the dissimilarity space. This becomes completely infeasible with > 8 or 9
% images.
function res = imagepairs(imagestruct,options)

nimages = length(imagestruct);
np = npairs(nimages);
ntrials = np*options.nrepeats;

pairwins = zeros(1,np);

pairinds = 1:np;

tc = 0;
for r = 1:options.nrepeats
    pairorder = 
    randinds = randperm(np);
end
