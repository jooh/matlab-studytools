% Present images or videos in a figure window and ask subject to rate each
% stimulus by key presses.
% res = imagerate(stimstruct,itemstruct,options)
function res = stimrate(stimstruct,items,options)

nitems = length(items);
nstim = length(stimstruct);
ntrials = nitems*nstim*options.nrepeats;

stimorder = repmat(1:nstim,[1 nitems*options.nrepeats]);
itemorder = repmat(1:nitems,[1 nstim*options.nrepeats]);
randind = randperm(ntrials);

res.response = NaN([1 ntrials]);
% Store a scalar 'category' for each item based on scoring (so abs(1) for
% distinctiveness, abs(2) for attractiveness.
res.itemcat = NaN([1 ntrials]);
res.stimorder = stimorder(randind);
res.itemorder = itemorder(randind);

% Make a fullscreen figure and put the stimulus in the middle 3rd of screen.
F = figure('units','normalized','defaultaxesfontsize',12,...
    'menubar','none','numbertitle','off','position',[0 0 1 1],...
    'color',options.bgcolor);
ax = subplot(3,3,5);

validkeys = 1:options.noptions;

if options.dovideo
    stimfun = @showvid;
else
    stimfun = @showim;
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
