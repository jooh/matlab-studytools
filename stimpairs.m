% Present 2 pairs of stimuli (videos or images), ask subject to rate which
% pair is more similar. Construct similarity matrix based on how often a
% given pair is preferred relative to all comparisons it is included in.
% To figure out how many trials you need for a single pass, try
% nchoosek(nchoosek(nstim,2),2). For most applications, >8 stimuli is
% impractical.
% res = stimpairs(stimstruct,varargin)
function res = stimpairs(stimstruct,varargin)

getArgs(varargin,{'nrepeats',1,'stimsize',9,'location','pc',...
    'windowed',0,'verbose',0,'grayscale',0,'matchtexhist',1,...
    'matchpixhist',0,'stimtype','image'});

nstr = sprintf('(%s) ',namepath);

% count up trials
nstim = length(stimstruct);
npairs = nchoosek(nstim,2);
npofp = nchoosek(npairs,2);
ntrials = npofp*nrepeats;
if verbose
    fprintf([nstr 'running %d trials\n'],ntrials)
end

% figure out stim indices
% Construct xy indices for each pair
% (so AB pairs are below the diagonal and BA pairs are above)
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

% Construct non-repeating trial sequence
trialinds = randpermrep(npofp,ntrials,0);
% Setup logs
res.trials.abovestim = NaN([2 ntrials]);
res.trials.belowstim = NaN([2 ntrials]);
% sum wins in non-symmetrical stim by stim mat
res.wincount = zeros(nstim,stim);
% 1 above, 2 below
res.trials.resp = NaN([1 ntrials]);
% scramble ids (no repeats within a single ITI)
res.trials.itiscrambles = reshape(stiminds(randpermrep(nstim,ntrials*4,...
    0)),[4 ntrials]);
par.trials.onset = NaN([1 ntrials]);
par.phase_on = Inf;
par.phase_off = 2;

instruct_txt = ['You will see one pair of faces in the upper half of '...
    'the screen, and one pair in the lower half. Use the response key '...
    'to indicate which pair contains faces that are more similar to ' ...
    'each other (upper or lower).\n\nThe experiment will begin soon.'];

switch stimtype
    case 'image'
        prepfun = @prepareimages;
        stimfun = @showimages;
    case 'video'
        prepfun = @preparevideos;
        stimfun = @showvideo;
    otherwise
        error('unknown stimtype: %s',stimtype)
end

try
    %% Start psychtoolbox
    for t = 1:ntrials
        % current trial stims
        above = pair.above(trialinds(t));
        below = pair.below(trialinds(t));
        res.trials.abovestim(:,t) = [stim.x(above); stim.y(above)];
        res.trials.belowstim(:,t) = [stim.x(below); stim.y(below)];
    end
catch
    fprintf('Experiment crashed! Manually save par?\n');
    e = lasterror;
    fprintf('%s\n',e.message);
    e.stack(:)
end
sca;

% Save whatever we have
if ~finishedok
    keyboard;
end

%TODO prepareimages
%TODO preparevideos
%TODO showimages
%TODO showvideo
