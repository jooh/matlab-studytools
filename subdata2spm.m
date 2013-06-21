% 
% SPM = subdata2spm(subdata,SPM,duration,ignorenames,collapsenames,modelresponses)
function SPM = subdata2spm(subdata,SPM,duration,ignorenames,collapsenames,modelresponses)

if ieNotDefined('ignorenames')
    ignorenames = {'null'};
end

if ieNotDefined('duration')
    duration = [];
end

if ieNotDefined('collapsenames')
    collapsenames = struct('oldnames',{},'newname',[]);
end

if ieNotDefined('modelresponses')
    modelresponses = false;
elseif modelresponses
    error('not yet implemented')
end
    
nsub = length(subdata);
nspm = length(SPM.nscan);
assert(nsub==nspm,'different number of subdatas and SPM runs');

sessnames = {};
nreg = [];
for sess = 1:nsub
    sessres = subdata(sess).res;
    subcontrol = sessres.timecontrol.units;
    spmcontrol = SPM.xBF.UNITS;
    assert(isequal(subcontrol,spmcontrol),'different timings in subdata and SPM');
    assert(abs(SPM.xY.RT - sessres.timecontrol.tr/1e3)<.1, ...
        'greater than 100 ms deviation between subdata and SPM TRs');
    if strcmp(spmcontrol,'scans')
        time2scan = 1;
    else
        time2scan = spmcontrol;
    end
    % extract all names for this run
    ntrials = length(sessres.trials);
    names = arrayfun(@(n)sessres.trials(n).condition.name,1:ntrials,...
        'uniformoutput',false);
    % check if any of the names are to be collapsed
    for cn = 1:length(collapsenames)
        if ~iscell(collapsenames(cn).oldnames)
            collapsenames(cn).oldnames = {collapsenames(cn).oldnames};
        end
        for o = 1:length(collapsenames(cn).oldnames)
            thisname = collapsenames(cn).oldnames{o};
            if strfind(thisname,'*')
                % inexact match
                thisname = strrep(thisname,'*','');
                hits = findStrInArray(names,thisname,0);
            else
                % exact match
                hits = strfind(names,thisname);
            end
            % rescore the hits as newname
            for h = hits(:)'
                [names{h},sessres.trials(h).condition.name] = deal(...
                    collapsenames(cn).newname);
            end
        end
    end
        
    connames = {sessres.conditions.name};
    unames = intersect(connames,unique(names),'stable');
    
    if sess==1
        sessnames = unames;
        nreg = length(sessnames);
    else
        assert(length(unames)==nreg && all(strcmp(sessnames,unames)),...
            'the same conditions must appear in all runs');
    end
    validnames = setdiff(unames,ignorenames,'stable');

    if modelresponses
        validnames = [validnames {'responses'}];
    end
    nvalid = length(validnames);
    SPM.Sess(sess).U = struct('ons',cell(1,nvalid),'dur',[],'name',[],...
        'P',repmat({struct('name','none')},[1 nvalid]));
    for c = 1:nvalid
        SPM.Sess(sess).U(c).name = validnames(c);
    end
    for t = 1:ntrials
        targetreg = strcmp(sessres.trials(t).condition.name,validnames);
        if ~any(targetreg)
            continue
        end
        assert(sum(targetreg)==1,'more than one match for %s',...
            sessres.trials(t).condition.name);
        SPM.Sess(sess).U(targetreg).ons(end+1) = sessres.trials(t).starttime;
        if isempty(duration)
            SPM.Sess(sess).U(targetreg).dur(end+1) = sessres.trials(t).starttime - sessres.trials(t+1).starttime;
        else
            SPM.Sess(sess).U(targetreg).dur(end+1) = duration;
        end        
        assert(SPM.nscan(sess) > ((SPM.Sess(sess).U(targetreg).ons(end) + ...
            SPM.Sess(sess).U(targetreg).dur(end)) / time2scan),...
            'event outside scan duration');
    end
    % TODO: modelresponses here
    if ~isfield(SPM.Sess(sess),'C') || ~isstruct(SPM.Sess(sess).C)
        SPM.Sess(sess).C.C = [];
        SPM.Sess(sess).C.name = {};
    end
end