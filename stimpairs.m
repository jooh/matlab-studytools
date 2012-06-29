% Present 2 pairs of stimuli (videos or images), ask subject to rate which
% pair is more similar. Construct similarity matrix based on how often a
% given pair is preferred relative to all comparisons it is included in.
% To figure out how many trials you need for a single pass, try
% nchoosek(nchoosek(nstim,2),2). For most applications, >8 stimuli is
% impractical.
% TODO: randomly reassign stim pairs to above/below. Re-write randomisation
% code. Suspect weird dependencies.
%
% MANDATORY INPUTS:
% stimstruct: struct array or object array, for now of FaceFigure instances
% 
% NAMED, OPTIONAL INPUTS
% nrepeats (1) how many times to go through the cycle
% stimsize (4.5) degrees visual angle (remember that you need room for 4)
% location: (pc) or scanner (TODO: scanner triggers)
% windowed: (0)
% verbose: 0 if 1, print out various feedbacks on trials, response accuracy
% stimoptions: struct with defaults as follows:
%   stimtype : video
%   nframes : 24
%   framerate : 24
%   azilims : [-45 45]
%   elelims : [-22.5 22.5]
%
% res = stimpairs(stimstruct,varargin)
function res = stimpairs(stimstruct,varargin)

getArgs(varargin,{'nrepeats',1,'stimsize',9,'location','pc',...
    'windowed',0,'verbose',0,'stimoptions',struct('stimtype','video',...
    'nframes',96,'framerate',24,'azilims',[-45 45],'elelims',...
    [-22.5 22.5])});

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
    % lower triangular form
    stim.(p{1}) = nonzeros(tril(stim.(p{1}),-1));
end
% Construct xy indices for each pair of pairs
pairinds = 1:npairs;
[pair.above,pair.below] = meshgrid(pairinds,pairinds);
for p = fieldnames(pair)'
    % lower triangular
    pair.(p{1}) = nonzeros(tril(pair.(p{1}),-1));
end

% Construct non-repeating trial sequence
trialinds = randpermrep(npofp,ntrials,0);
% Setup logs
res.trials.abovestim = NaN([2 ntrials]);
res.trials.belowstim = NaN([2 ntrials]);
% sum wins in non-symmetrical stim by stim mat
res.wincount = zeros(nstim);
% 1 above, 2 below
res.trials.choseabove = NaN([1 ntrials]);
% scramble ids 
res.trials.itiscrambles = reshape(stiminds(randpermrep(nstim,ntrials*4,...
    1)),[4 ntrials]);
res.trials.onset = NaN([1 ntrials]);
res.phase_off = 2;

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
    timing = struct('tstart',0,'son',0,'soff',0,'prevtstart',-inf,...
        'expstart',0);
    ppt = startpptexp(location,windowed);
    ppt.respkeys = ppt.respkeys(1:2);
    timing.expstart = GetSecs;
    % Prepare ITI textures
    if verbose
        fprintf([nstr 'creating textures\n'])
    end
    tex.iti = NaN([1 nstim]);
    for n = 1:nstim
        % cat to get alpha blending in
        tex.iti(n) = Screen('MakeTexture',ppt.window,...
            cat(3,stimstruct(n).scramble,...
            uint8(255*stimstruct(n).alpha)));
    end
    % prepare texture - different approach here for images and vids
    tex.stim = prepfun(stimstruct,ppt,stimoptions);
    % Configure the stimulus rect
    orgsize = size(stimstruct(1).alpha);
    % Preserve aspect ratio (stimsize is the longer side, the shorter side
    % will be stimsize*ar)
    ar = orgsize(1) / orgsize(2);
    stimrect = [0 0 ppt.deg2px * [stimsize stimsize*ar]];
    % set locations for the 4 stims
    hspacing = 1;
    vspacing = 1.4;
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
        above = pair.above(trialinds(t));
        below = pair.below(trialinds(t));
        res.trials.abovestim(:,t) = [stim.x(above); stim.y(above)];
        res.trials.belowstim(:,t) = [stim.x(below); stim.y(below)];
        % present stimuli
        res.trials.onset(t) = GetSecs-timing.expstart;
        if verbose
            fprintf([nstr ...
                '%ds\t trial %d\t ul=%d\t ur=%d\t dl=%d\t dr=%d\n'],...
                res.trials.onset(t),t,res.trials.abovestim(1,t),...
                res.trials.abovestim(2,t),res.trials.belowstim(1,t),...
                res.trials.belowstim(2,t));
        end
        res.trials.choseabove(t) = stimfun(tex.stim(...
            [res.trials.abovestim(:,t); res.trials.belowstim(:,t)],:),...
            ppt,stimoptions) == ppt.respkeys(1);
        % score as dissimilarity
        if res.trials.choseabove(t)
            winner = 'belowstim';
        else
            winner = 'abovestim';
        end
        % add to win matrix
        res.wincount(res.trials.(winner)(1,t),...
            res.trials.(winner)(2,t)) = res.wincount(...
            res.trials.(winner)(1,t),res.trials.(winner)(2,t))+1;
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

% Save whatever we have
if ~finishedok
    keyboard;
end

% Score responses
% NB at the moment res.wincount is directly interpretable since each pair
% appears equally often in each config. It's just that it's a similarity
% measure, not dissimilarity. 

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
function resp = showvideo(bufinds,ppt,stimoptions)

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
