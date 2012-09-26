% Present images or videos in a figure window and ask subject to rate each
% stimulus by key presses.
% res = stimrate(stimstruct,itemstruct,options)
function res = stimrate(stimstruct,items,varargin)

global printfun

if isempty(printfun)
    printfun = @disp;
end

getArgs(varargin,{'bgcolor',[128 128 128],'stimsize',7,'nreps',1,...
    'windowed',0,'verbose',0,'target','image','framerate',24,...
    'respkeys',{'1','2','3','4','5'},'rewind',1,'itidur',1});

nitems = length(items);
nstim = length(stimstruct);
ntrials = nitems * nstim * nrepeats;
noptions = length(respkeys);

frametime = 1/framerate;

% work out random stim/item order
stimorder = repmat(1:nstim,[1 nitems*nrepeats]);
itemorder = repmat(1:nitems,[1 nstim*nrepeats]);
randind = randperm(ntrials);

res.response = NaN([1 ntrials]);
% Store a scalar 'category' for each item based on scoring (so abs(1) for
% distinctiveness, abs(2) for attractiveness.
res.itemcat = NaN([1 ntrials]);
res.stimorder = stimorder(randind);
res.itemorder = itemorder(randind);

orgsize = size(stimstruct(1).(target));
ar = orgsize(1) / orgsize(2);
% will be 1 for images
nframes = size(stimstruct(1).(target),4);

% Setup basic study
% NB, construct is a property we need to add to each condition
st = RatingTask('conditionname','construct','keyboardkeys',respkeys);

try
    st.openwindow;
    st.timecontrol = SecondTiming('scanobj',st.scanobj);
    printfun('configuring events');
    stimrect = [0 0 st.deg2px * [stimsize ar*stimsize]];
    stimrect = CenterRectOnPoint(stimrect,st.xcenter,st.ycenter);
    texty = st.ycenter + stdeg2px*stimsize/2;
    % scrambled ISIs in random sequence with ntrials length
    % (can just keep calling to get new, random scrambles)
    ev.iti = VideoEvent(reshape([ss.stimulus.scramble],...
        [asrow(size(ss.stimulus(1).scramble),2) ...
            size(ss.stimulus(1).scramble,3) length(stimstruct)]),...
        st, randpermrep(nstim,nitems*nreps),'alpha',stimstruct(1).alpha,...
        'rect',stimrect);
    % base events
    ev.flip = FlipEvent(st);
    ev.resp_on = KeyboardCheck('duration',frametime,...
        'validkeys',st.validkeys);
    % no response log
    ev.resp_off = KeyboardCheck('duration',1,...
        'validkeys',[]);
    % text events
    nc = 0;
    offevents = {ev.iti,ev.flip,ev.resp_off};
    for t = 1:nitems
        ev.question(t) = TextEvent([items(t).question ...
            sprintf('\n(%s = %s, %s = %s)',respkeys{1},...
            items(t).label_low,respkeys{end},items(t).label_high)],...
            st,'y',texty);
        % stimuli
        for s = 1:nstim
            % NB, even if you wanted images we use the videoevent for
            % flexibility
            ev.stim(s) = VideoEvent(stimstruct(s).(target),...
                'alpha',stimstruct(s).alpha,'rect',stimrect,...
                'rewind',rewind);
            % now conditions are every perm of stim / item
            nc = nc+1;
            onevents = repmat({ev.stim(s),ev.flip,ev.resp_on},...
                [1 nframes]);
            % must set duration==inf to force looping
            st.conditions(nc) = Condition([offevents onevents],...
                'name',sprintf('stim%02d_item%02d',s,t),...
                'timecontrol',st.timecontrol,'duration',Inf);
            % need to add custom prop for underlying construct
            addprop(st.conditions(nc),'construct');
            st.conditions(nc).construct = items(t).scoring;
        end
    end
catch
    e = lasterror;
    st.closewindow;
    printfun('CRASH - debug in e variable')
    keyboard;
    error('crashed')
end

for t = 1:ntrials
    it = items(res.itemorder(t));
    try
        scramble = stimstruct(res.stimorder(t)).scramble;
    catch
        scramble = uint8(255*rand(size(im)));
    end
    % show stim (image or vid for now)
    stimfun(stimstruct,res.itemorder(t));

    title({it.question,sprintf('(1 = %s, %d = %s)',it.label_low,...
        options.noptions,it.label_high)})
    drawnow;
    ok = 0;
    while ~ok
        keydown = waitforbuttonpress;
        if keydown==1
            key = str2num(get(F,'currentcharacter'));
            if ~isempty(key) && any(key==validkeys)
                if it.scoring < 0
                    % reverse scoring
                    res.response(t) = options.noptions - (key-1);
                else
                    res.response(t) = key;
                end
                res.itemcat(t) = abs(it.scoring);
                ok = 1;
            end
        end
        % Give the CPU a break
        pause(1e-5);
    end
    cla;
    imshow(scramble);
    drawnow;
    % iti
    pause(1+rand(1));
    cla;
end
close(F);

% SUB FUNCTIONS

% show image
function showim(stimstruct,trial)

im = stimstruct(trial).image;
if isfield(stimstruct,'alpha')
    alpha = stimstruct(trial).alpha;
else
    alpha = 1;
end
h = imshow(im);
set(h,'alphadata',alpha);

return

% show vid at 24 fps
function showvid(stimstruct,trial)

frames = im2frame(stimstruct(trial).vid;
movie(frames,1,24);
return
