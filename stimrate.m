% Present images or videos in a figure window and ask subject to rate each
% stimulus by key presses. Function wrapper for lower-level RatingTask
% object.
% res = stimrate(stimstruct,itemstruct,options)
function res = stimrate(stimstruct,items,varargin)

global printfun

if isempty(printfun)
    printfun = @disp;
end

getArgs(varargin,{'bgcolor',[128 128 128],'stimsize',7,'nreps',1,...
    'windowed',0,'verbose',0,'target','image','framerate',24,...
    'respkeys',{'c','v','b','n','m'},'rewind',1,'itidur',1});

% counts
nitems = length(items);
nstim = length(stimstruct);
ntrials = nitems * nstim * nreps;
noptions = length(respkeys);

% we don't explicitly code event duration
frametime = 1/framerate;
nframes = size(stimstruct(1).(target),4);
orgsize = size(stimstruct(1).(target));
ar = orgsize(1) / orgsize(2);
% will be 1 for images

% Setup basic study
% NB, construct is a property we need to add to each condition
st = RatingTask('conditionname','construct','keyboardkeys',respkeys,...
    'windowed',windowed,'verbose',verbose,'bgcolor',bgcolor);

try
    st.openwindow;
    st.timecontrol = SecondTiming('scanobj',st.scanobj);
    printfun('configuring events');
    stimrect = [0 0 st.deg2px * [stimsize ar*stimsize]];
    stimrect = CenterRectOnPoint(stimrect,st.xcenter,st.ycenter);
    texty = st.ycenter + st.deg2px*stimsize * (2/3);
    % scrambled ISIs in random sequence with ntrials length
    % (can just keep calling to get new, random scrambles)
    ev.iti = VideoEvent(reshape([stimstruct.scramble],...
        [asrow(size(stimstruct(1).scramble),2) ...
            size(stimstruct(1).scramble,3) length(stimstruct)]),...
        st, 'frameind', randpermrep(nstim,nitems*nreps),...
        'alpha',stimstruct(1).alpha,'rect',stimrect);
    % base events
    ev.flip = FlipEvent(st);
    ev.resp_on = KeyboardCheck('duration',frametime,...
        'validkeys',st.validkeys);
    % no response log
    ev.resp_off = KeyboardCheck('duration',itidur,...
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
            ev.stim(s) = VideoEvent(stimstruct(s).(target),st,...
                'alpha',stimstruct(s).alpha,'rect',stimrect,...
                'rewind',rewind);
            % now conditions are every perm of stim / item
            nc = nc+1;
            onevents = repmat({ev.stim(s),ev.question(t),ev.flip,...
                ev.resp_on},[1 nframes]);
            % must set duration==inf to force looping
            st.conditions(nc) = Condition(onevents,...
                'name',sprintf('stim%02d_item%02d',s,t),...
                'timecontrol',st.timecontrol,'duration',Inf,...
                'skiponresponse',1);
            % need to add custom prop for underlying construct
            addprop(st.conditions(nc),'construct');
            st.conditions(nc).construct = items(t).scoring;
        end
    end
    % iti as separate event to enable continuouous video looping
    st.conditions(nc+1) = Condition(offevents,...
        'name','iti','timecontrol',st.timecontrol);
    addprop(st.conditions(nc+1),'construct');
    st.conditions(nc+1).construct = 0;
    % conditions intermixed with iti
    trialinds = asrow([randpermrep(nc,ntrials); ones(1,ntrials)*(nc+1)]);
    st.runtrials(trialinds);
catch
    e = lasterror;
    st.closewindow;
    printfun('CRASH - debug in e variable')
    keyboard;
    error('crashed')
end
res = st.exportstatic;
printfun('finished stimrate')
st.closewindow;
