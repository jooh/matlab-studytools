% Generate names/onsets/durations struct array and save (where?). You must
% provide the correct sessions, e.g. by branching. And all sessions must
% include 'visobjlocaliser' to help us find the correct session number
function [aap,resp]=aamod_firstlevel_subdata2spm(aap,task,subj)

resp = '';

switch task
    case 'report'
    case 'checkrequirements'

    case 'doit'
        % find subject name
        subname = aap.acq_details.subjects(subj).mriname;
        ts = aap.tasklist.currenttask.settings;
        % find exp dir
        expdir = fileparts(which(ts.experimentname));
        infile = fullfile(expdir,'subjects',subname,...
            ['data_' ts.experimentname],'subdata.mat');
        % load events (also load psychtoolbox to prevent crashes)
        oldpath = path;
        start_psychtoolbox;
        subdata = loadbetter(infile);
        path(oldpath);
        data = subdata2aa(subdata,aap,ts.sessiontarget,1);
        spmpath = aas_getfiles_bystream(aap,subj,'firstlevel_spm');
        load(spmpath);
        SPM = subdata2spm(data,SPM,ts.duration,ts.ignorenames,...
            ts.collapsenames,ts.modelresponses);
        % save and describe
        save(spmpath,'SPM');
        aap = aas_desc_outputs(aap,subj,'firstlevel_spm',spmpath);
    otherwise
        aas_log(aap,1,sprintf('Unknown task %s',task));
end
