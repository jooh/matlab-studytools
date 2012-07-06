% Present 2 pairs of stimuli (videos or images), ask subject to rate which
% pair is more similar. Construct similarity matrix based on how often a
% given pair is preferred relative to all comparisons it is included in.
% To figure out how many trials you need for a single pass, try
% nchoosek(nchoosek(nstim,2),2). For most applications, >8 stimuli is
% impractical.
%
% MANDATORY INPUTS:
% stimstruct: struct array or object array, for now of FaceFigure instances
% 
% NAMED, OPTIONAL INPUTS
% nrepeats (1) how many times to go through the cycle
% stimsize (7) degrees visual angle (remember that you need room for 4)
% location: (pc) or scanner (TODO: scanner triggers)
% windowed: (0)
% verbose: 0 if 1, print out various feedbacks on trials, response accuracy
% stimoptions: struct with defaults as follows:
%   stimtype : video
%   nframes : 96
%   framerate : 24
%   azilims : [-45 45]
%   elelims : [-22.5 22.5]
%
% res = stimpairs(stimstruct,varargin)
function res = stimpairs(stimstruct,varargin)

getArgs(varargin,{'nrepeats',1,'stimsize',9,'location','pc',...
    'windowed',0,'verbose',0,'stimoptions',struct('stimtype','video',...
    'nframes',96,'framerate',24,'azilims',[-45 45],'elelims',...
    [-22.5 22.5]),'trialinds',[],'ntrials',Inf});

nstr = sprintf('(%s) ',namepath);
% count up trials
nstim = length(stimstruct);
npairs = nchoosek(nstim,2);
npofp = nchoosek(npairs,2);
npossibletrials = npofp*nrepeats;
% figure out stim indices
% Construct xy indices for each pair
% get only upper off diagonals (so [2:15] : [1:14]). Note that this creates
% left-right dependencies (e.g., 1 never appears on the left, 15 never on
% the right)
stiminds = 1:nstim;
[stim.left, stim.right] = meshgrid(stiminds,stiminds);
for p = fieldnames(stim)'
    % upper triangular form
    stim.(p{1}) = nonzeros(tril(stim.(p{1}),-1));
end
% Construct indices for each pair of pairs
%get only upper off diagonals: this creates up/down dependencies (so the
%first pair only appears below fixation, the last pair only appears above,
%etc)
pairinds = 1:npairs;
[pair.above,pair.below] = meshgrid(pairinds,pairinds);
for p = fieldnames(pair)'
    % lower triangular
    pair.(p{1}) = nonzeros(tril(pair.(p{1}),-1));
end

%% Trial sequences
% randomise trial order (non-repeating)
if ieNotDefined('trialinds')
    res.trialinds = randpermrep(npofp,npossibletrials,0);
else
    res.trialinds = trialinds;
end

if verbose
    fprintf([nstr 'running %d trials\n'],ntrials)
end

% randomise left-right assignment in each pair (1 keep, 2 flip)
res.leftrightinds = reshape(randpermrep(2,ntrials*2,1),[2 ntrials]);
% randomise up-down assignment of the pairs (1 keep, 2 flip)
res.updowninds = randpermrep(2,ntrials,1);
% setup logs (here we log what was actually presented in each quadrant,
% after re-assignment)
res.trials.abovestim = NaN([2 ntrials]);
res.trials.belowstim = NaN([2 ntrials]);
% sum wins in lower triangle of this matrix (take max(y),min(x))
res.rdm = zeros(nstim);
% mainly for debugging - keep track of trial n
res.rdm_n = res.rdm;
% 1 above, 2 below (no rescoring - this is what the choice was)
res.trials.choseabove = NaN([1 ntrials]);
% not used but useful as I can't be trusted to score the above correctly.

% scramble ids 
res.trials.itiscrambles = reshape(stiminds(randpermrep(nstim,ntrials*4,...
    1)),[4 ntrials]);
res.trials.onset = NaN([1 ntrials]);
res.trials.resptime = NaN([1 ntrials]);
res.phase_off = 1;

instruct_txt = ['You will see one pair of faces in the upper half of '...
    'the screen, and one pair in the lower half. Use the response key '...
    'to indicate which pair contains faces that are more similar to ' ...
    'each other (upper or lower).\n\nThe experiment will begin soon.'];

switch stimoptions.stimtype
    case 'image'
        error('not yet implemented!')
        prepfun = @prepareimages;
        stimfun = @showimages;
    case 'video'
        prepfun = @preparevideos;
        stimfun = @showvideo;
    otherwise
        error('unknown stimtype: %s',stimoptions.stimtype)
end

finishedok = 0;
try
    %% Start psychtoolbox
    timing = struct('tstart',0,'expstart',0);
    ppt = startpptexp(location,windowed);
    ppt.respkeys = ppt.respkeys(1:2);
    timing.expstart = GetSecs;
    % Prepare ITI textures
    if verbose
        fprintf([nstr 'creating ITI textures\n'])
    end
    tex.iti = NaN([1 nstim]);
    for n = 1:nstim
        % cat to get alpha blending in
        tex.iti(n) = Screen('MakeTexture',ppt.window,...
            cat(3,stimstruct(n).scramble,...
            uint8(255*stimstruct(n).alpha)));
    end
    % prepare texture - different approach here for images and vids
    if verbose
        fprintf([nstr 'creating stimulus textures (slow!) \n'])
    end
    tex.stim = prepfun(stimstruct,ppt,stimoptions);
    % Configure the stimulus rect
    orgsize = size(stimstruct(1).alpha);
    % Preserve aspect ratio (stimsize is the longer side, the shorter side
    % will be stimsize*ar)
    ar = orgsize(1) / orgsize(2);
    stimrect = [0 0 ppt.deg2px * [stimsize stimsize*ar]];
    % set locations for the 4 stims
    hspacing = 1;
    vspacing = 1.2;
    toploc = ppt.ycenter-ppt.deg2px*stimsize*vspacing;
    bottomloc = ppt.ycenter+ppt.deg2px*stimsize*vspacing;
    leftloc = ppt.xcenter-ppt.deg2px*stimsize*hspacing;
    rightloc = ppt.xcenter+ppt.deg2px*stimsize*hspacing;
    stimoptions.rects.topleft = round(CenterRectOnPoint(stimrect,...
        leftloc,toploc));
    stimoptions.rects.topright = round(CenterRectOnPoint(stimrect,...
        rightloc,toploc));
    stimoptions.rects.bottomleft = round(CenterRectOnPoint(stimrect,...
        leftloc,bottomloc));
    stimoptions.rects.bottomright = round(CenterRectOnPoint(stimrect,...
        rightloc,bottomloc));
    % vector for fast drawing with DrawTextures
    stimoptions.rects.vec = [stimoptions.rects.topleft; ...
        stimoptions.rects.topright; stimoptions.rects.bottomleft; ...
        stimoptions.rects.bottomright]';
    % instructions
    DrawFormattedText(ppt.window,instruct_txt,'center','center',...
        ppt.white,ppt.txtwrap, 0, 0, ppt.vspacing);
    Screen('Flip',ppt.window);
    waitResp(ppt.spacebar,ppt.esc);
    for t = 1:ntrials
        timing.tstart = GetSecs;
        % current trial stims
        % flip up/down locations
        switch res.updowninds(t)
            case 1
                above = pair.above(res.trialinds(t));
                below = pair.below(res.trialinds(t));
            case 2
                above = pair.below(res.trialinds(t));
                below = pair.above(res.trialinds(t));
        end
        res.trials.abovestim(:,t) = [stim.left(above); stim.right(above)];
        res.trials.belowstim(:,t) = [stim.left(below); stim.right(below)];
        % flip left/right in each pair
        if res.leftrightinds(1,t)==2
            res.trials.abovestim(:,t) = res.trials.abovestim([2 1],t);
        end
        if res.leftrightinds(2,t)==2
            res.trials.belowstim(:,t) = res.trials.belowstim([2 1],t);
        end
        % present stimuli
        res.trials.onset(t) = timing.tstart-timing.expstart;
        if verbose
            fprintf([nstr ...
                '%.1fs\t trial %d\t ul=%d\t ur=%d\t dl=%d\t dr=%d\n'],...
                res.trials.onset(t),t,res.trials.abovestim(1,t),...
                res.trials.abovestim(2,t),res.trials.belowstim(1,t),...
                res.trials.belowstim(2,t));
        end
        [rtime,rkey] = stimfun(tex.stim(...
            [res.trials.abovestim(:,t); res.trials.belowstim(:,t)],:),...
            ppt,stimoptions);
        res.trials.choseabove(t) = rkey==ppt.respkeys(1);
        res.trials.resptime(t) = rtime-timing.tstart;
        if verbose
            fprintf([nstr ...
                'rt=%.2f\t choseabove=%d\t chosenstims=[%d %d]\n'],...
                res.trials.resptime(t),res.trials.choseabove(t),...
                res.trials.abovestim(1,t),res.trials.abovestim(2,t));
        end
        % score as dissimilarity
        if res.trials.choseabove(t)
            winner = 'belowstim';
        else
            winner = 'abovestim';
        end
        inds = res.trials.(winner)(:,t);
        % add to rdm (now symmetrical)
        res.rdm(inds(1),inds(2)) = res.rdm(inds(1),inds(2)) + 1;
        res.rdm(inds(2),inds(1)) = res.rdm(inds(2),inds(1)) + 1;
        % NB, does not count n properly. Will need to fix
        % DEBUG DEBUG
        res.rdm_n(inds(1),inds(2)) = res.rdm_n(inds(1),inds(2)) + 1;
        res.rdm_n(inds(2),inds(1)) = res.rdm_n(inds(2),inds(1)) + 1;
        % iti 
        Screen('DrawTextures',ppt.window,tex.iti(...
            res.trials.itiscrambles(:,t)),[],stimoptions.rects.vec);
        itistart = Screen('Flip',ppt.window);
        WaitSecs('untiltime',itistart+res.phase_off);
    end
    finishedok = 1;
catch
    fprintf('Experiment crashed! Manually save res?\n');
    e = lasterror;
    fprintf('%s\n',e.message);
    e.stack(:)
end
sca;
close([stimstruct.fighand]);

% Save whatever we have
if ~finishedok
    keyboard;
end

%% SUB FUNCTIONS

%TODO prepareimages

% Assumes that stimstruct is an object array of FaceFigure instances
% tex = preparevideos(stimstruct,ppt,stimoptions)
function tex = preparevideos(stimstruct,ppt,stimoptions)

nstim = length(stimstruct);
tex = NaN([nstim stimoptions.nframes]);
for n = 1:nstim
    frames = stimstruct(n).rotateface(stimoptions.azilims,...
        stimoptions.elelims,stimoptions.nframes);
    for f = 1:stimoptions.nframes
        tex(n,f) = Screen('MakeTexture',ppt.window,...
            cat(3,frames(:,:,:,f),uint8(255*stimstruct(n).alpha)));
    end
end

% resp = showimages(bufinds,ppt,stimoptions,waitdur)
% UNTESTED
function resp = showimages(bufinds,ppt,stimoptions)

resp = NaN;
Screen('DrawTextures',ppt.window,bufinds,[],stimoptions.rects.vec);
Screen('Flip',ppt.window);
while isnan(resp)
    [resptime,resp] = ppt.logfun(0.02,ppt.respkeys,ppt.esc,ppt.ScanObj);
    if ~isnan(resp)
        return
    end
end

% show looping videos and collect responses. Return whenever we get one.
% resp = showvideo(bufinds,ppt,stimoptions)
function [resptime,resp] = showvideo(bufinds,ppt,stimoptions)

frametime = 1/stimoptions.framerate;
resp = NaN;
while isnan(resp)
    fstart = GetSecs;
    for f = [1:stimoptions.nframes stimoptions.nframes-1:-1:2]
        Screen('DrawTextures',ppt.window,bufinds(:,f),[],...
            stimoptions.rects.vec);
        % check for a response once per frame 
        [resptime,resp] = ppt.logfun(0.02,ppt.respkeys,ppt.esc,ppt.ScanObj);
        Screen('Flip',ppt.window,fstart+f*frametime);
        if ~isnan(resp)
            return
        end
    end
end
