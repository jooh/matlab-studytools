% save subdata, ensuring that the previous version is backed up.
% savesubdata(subdata)
function savesubdata(subdata)

if ~subdata(end).par.savedata
    fprintf('(savesubdata) savedata==0, data NOT SAVED\n')
    return
end

expdir = subdata(end).expdir;
outmat = fullfile(expdir,'subdata.mat');
if exist(outmat,'file')
    outmat_backup = fullfile(expdir,'subdata_backup.mat');
    success = movefile(outmat,outmat_backup,'f');
    assert(success==1,'backup move failed!');
    fprintf('(savesubdata) renamed old subdata as %s\n',outmat_backup)
end
save(outmat,'subdata','-v7.3');
fprintf('(savesubdata) saved subdata as %s\n',outmat)
