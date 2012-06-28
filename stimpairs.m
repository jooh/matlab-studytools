% Present 2 pairs of stimuli (videos or images), ask subject to rate which
% pair is more similar. Construct similarity matrix based on how often a
% given pair is preferred relative to all comparisons it is included in.
% To figure out how many trials you need for a single pass, try
% nchoosek(nchoosek(nstim,2),2). For most applications, >8 stimuli is
% impractical.
% res = stimpairs(stimstruct,options)
function res = stimpairs(stimstruct,options)

nstim = length(stimstruct);
npairs = nchoosek(nstim,2);
npofp = nchoosek(npairs,2);
ntrials = npofp*options.nrepeats;

% sum wins in non-symmetrical stim by stim mat
wincount = zeros(nstim,stim);

% Construct xy indices for each pair
stiminds = 1:nstim;
[stim.x, stim.y] = meshgrid(stiminds,stiminds);
for p = fieldnames(stim)'
    stim.(p{1}) = stim.(p{1})(logical(1-eye(nstim)));
end

% Construct xy indices for each pair of pairs
pairinds = 1:npairs;
[pair.above,pair.below] = meshgrid(pairinds,pairinds);
for p = fieldnames(pair)'
    pair.(p{1}) = pair.(p{1})(logical(1-eye(npairs)));
end

% So now we pull our 2 pairs from pair. For each index in pair we find the
% corresponding stimulus pairs by indexing stim.x and stim.y
% TODO

tc = 0;
for r = 1:options.nrepeats
    pairorder = 
    randinds = randperm(np);
end
