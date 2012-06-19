% Generate a random set of 1:x indices with a fixed n. If n>x, we go
% through the randomisation multiple times, ensuring that no indices
% repeat. If n<x, we pick a random subset. If allowrepeats==0 (default 1),
% we resample until we get a sequence with no direct repeats.  Note that I
% use a while loop to find a sequence without repeats, so if you enter
% sufficiently pathological values you can trigger an exception (try
% randpermrep(2,200,0)).
% v = randpermrep(x,n,[allowrepeats])
function v = randpermrep(x,n,allowrepeats)

if ieNotDefined('n')
    % Revert to stock randperm behaviour
    n = x;
end

if ieNotDefined('allowrepeats')
    allowrepeats = 1;
end

nrep = ceil(n/x);
niter = 0;
while niter<10e3
    % Repeat randperm however many times are needed
    v = cell2mat(arrayfun(@randperm,repmat(x,1,nrep),...
        'uniformoutput',false));
    % Trim off remainder
    v = v(1:n);
    % Return if sequence contained no direct repeats (or if repeats are
    % allowed)
    if ~any(diff(v)==0) || allowrepeats
        return
    end
    niter = niter+1;
end
error('iteration limit reached. No suitable non-repeat sequence found');
