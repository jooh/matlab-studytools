% Insert n*c repeats into vector v, where c is the number of unique values
% in v. The resulting vector has the same number of repeats for each
% condition
% outv = insertrepeats(v,n);
function outv = insertrepeats(v,n);

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
        ind = hits(ascol(randperm(length(hits)),1));
        outv = [outv(1:ind) outv(ind:end)];
    end
end
