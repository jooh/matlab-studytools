% Find the correct subdata entries for a set of AA sessions
% data = subdata2aa(subdata,aap,sessiontarget,ndataperrun)
function data = subdata2aa(subdata,aap,sessiontarget,ndataperrun)

if ieNotDefined('ndataperrun')
    ndataperrun = 1;
end

% find the correct sessions in aap
sessnames = {aap.acq_details.sessions.name};
selected = aap.acq_details.selected_sessions;
nselected = length(selected);
targetinds = findStrInArray(sessnames,sessiontarget);
% make sure we haven't selected sessions that weren't actually in the
% session
assert(isempty(setdiff(selected,targetinds)),...
    'found non-target sessions in selected_sessions')
% get relevant indices
[x,subdatinds] = intersect(targetinds,selected);
% upcast to make n subdatas per session
subup = upcastindices(subdatinds,ndataperrun);
assert(max(subup)<=length(subdata),['Found %d sessions, %d subdatas. '...
    'Time to pull?'],length(subup),length(subdata));

data = subdata(subup);
