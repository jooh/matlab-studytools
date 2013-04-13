% Insert n*c repeats into vector v, where c is the number of unique values
% in v. The resulting vector has the same number of repeats for each
% condition.
%
% By default, we insert an exact repeat, but if repcode is defined this
% value gets entered instead.
%
% outv = insertrepeats(v,n,repcode);
function outv = insertrepeats(v,n,repcode);

if ieNotDefined('repcode')
    repcode = [];
end

if n==0
    outv = v;
    return
end

vu = unique(v);
nu = length(vu);
totn = n*nu;
vl = length(v);
outlength = vl+totn;

outv = v;
for c = vu
    for r = 1:n
        % this needs to be inside the loop since outv length is changing on
        % every iteration
        hits = find(outv==c);
        inds = randperm(length(hits));
        ind = hits(inds(1));
        if isempty(repcode)
            extra = outv(ind);
        else
            extra = repcode;
        end
        outv = [outv(1:ind) extra outv(ind+1:end)];
    end
end
