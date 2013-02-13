% Store unique de bruijn sequences in a seq by trial matrix that gets saved
% to fundir. Requires debruijn.
% makesuniquedebruijnequences(k,n,nseq,outdir)
function makeuniquedebruijnsquences(k,n,nseq,outdir)

[fn, fundir] = namepath;
if ieNotDefined('outdir')
    outdir = fundir;
end

seqlen = k^n;

if matlabpool('size') == 0
    matlabpool;
end

sequences = [];
nfound = 0;
% rerun until we get nseq unique sequences
while size(sequences,1) < nseq
    seqiter = NaN([nseq seqlen]);
    parfor s = 1:nseq
        seqiter(s,:) = debruijn(k,n);
    end
    sequences = unique([sequences; seqiter],'rows');
end

% trim to exact size
sequences = sequences(1:nseq,:);

outfn = fullfile(outdir,sprintf('debruijnseq_k%02d_n%02d_nseq%04d.mat',...
    k,n,nseq));
fprintf('(%s) saving sequences to %s\n',fn,outfn);
save(outfn,'sequences');
