% Present images in a figure window and ask subject to rate by key presses.
% res = imagerate(imagestruct,options)
function res = imagerate(imagestruct,options)

nitems = length(options.items);
nimages = length(imagestruct);
ntrials = nitems*nimages*options.nrepeats;

imageorder = repmat(1:nimages,[1 nitems*options.nrepeats]);
itemorder = repmat(1:nitems,[1 nimages*options.nrepeats]);
randind = randperm(ntrials);

res.response = NaN([1 ntrials]);
% Store a scalar 'category' for each item based on scoring (so abs(1) for
% distinctiveness, abs(2) for attractiveness.
res.itemcat = NaN([1 ntrials]);
res.imageorder = imageorder(randind);
res.itemorder = itemorder(randind);

% Make a fullscreen figure and put the stimulus in the middle 3rd of screen.
F = figure('units','normalized','defaultaxesfontsize',12,...
    'menubar','none','numbertitle','off','position',[0 0 1 1],...
    'color',options.bgcolor);
ax = subplot(3,3,5);

validkeys = 1:options.noptions;

for t = 1:ntrials
    item = options.items(res.itemorder(t));
    im = imagestruct(res.imageorder(t)).image;
    if isfield(imagestruct,'alpha')
        alpha = imagestruct(res.imageorder(t)).alpha;
    else
        alpha = 1;
    end

    if isfield(imagestruct,'scramble')
        scramble = imagestruct(res.imageorder(t)).scramble;
    else
        scramble = uint8(255*rand(size(im)));
    end

    h = imshow(im);
    set(h,'alphadata',alpha);
    title({item.question,sprintf('(1 = %s, %d = %s)',item.label_low,...
        options.noptions,item.label_high)})
    drawnow;
    ok = 0;
    while ~ok
        keydown = waitforbuttonpress;
        if keydown==1
            key = str2num(get(F,'currentcharacter'));
            if ~isempty(key) && any(key==validkeys)
                if item.scoring < 0
                    % reverse scoring
                    res.response(t) = options.noptions - (key-1);
                else
                    res.response(t) = key;
                end
                res.itemcat(t) = abs(item.scoring);
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
