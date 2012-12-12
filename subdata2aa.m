% Find the correct subdata entries for a set of AA sessions
function data = subdata2aa(subdata,aap,sessiontarget,ndataperrun)

if ieNotDefined('ndataperrun')
    ndataperrun = 1;
end

% find the localiser sessions in aap
sessnames = {aap.acq_details.sessions.name};
selected = aap.acq_details.selected_sessions;
nselected = length(selected);
targetinds = findStrInArray(sessnames,sessiontarget);
% make sure we haven't selected sessions that weren't actually
% localiser
assert(isempty(setdiff(selected,targetinds)),...
    'found non-target sessions in selected_sessions')
% get relevant indices
[x,subdatinds] = intersect(targetinds,selected);
% upcast to make two subdatas per session
subup = upcastindices(subdatinds,ndataperrun);
data = subdata(subup);
