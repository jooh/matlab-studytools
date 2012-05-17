% Setup basic files and variables for an experiment
% [subdata pr] = initexperiment(varargin)
function [subdata pr] = initexperiment(varargin)

% find the calling function's name, use this to define paths
st = dbstack;
keyboard;
expname = st.name;
studydir = fileparts(which(expname));

% load study defaults
defsfn = fullfile(studydir,'defaults.mat');
assert(exist(defsfn,'file'),sprintf('no defaults file %s',defsfn))
defs = loadbetter(defsfn);
% Set any non-standard parameters. NB adding new parameters here will raise an
% error. Use your studydefaults wrapper function to re-define defaults.mat if
% you want to add support for a new argument.
par = varargs2structfields(varargin,defs);

% print functionality depends on verbosity
if par.verbose
    pr = @(x) fprintf('(%s) %s\n',expname,x);
else
    % dummy function
    pr = @(x) x;
end

% initialise subject 
if isempty(par.subject)
    par.subject = input('subject code:','s');
end
par.subdir = fullfile(par.studydir,'subjects',par.subject);
madedir = mkdirifneeded(par.subdir);
if madedir
    yn = input(sprintf('new subject %s, continue? (yn)',par.subject));
    assert(~strcmp(lower(yn),'n'),'aborted experiment.');
end

% initialise experiment and session
expdir = fullfile(par.subdir,['data_' expname]);
madedir = mkdirifneeded(expdir);
submat = fullfile(expdir,'subdata.mat');
if madedir || ~exist(submat,'file')
    pr(sprintf('initialised new experiment in %s',expdir));
    par.sessionI = 1;
    subdata = struct('par',{},'testtime',{},...
        'randstate',{},'res',{},'notes',{});
else
    subdata = loadbetter(submat);
    par.sessionI = length(subdata)+1;
end
subdata(par.sessionI).par = par;
subdata(par.sessionI).testtime = datestr(now);
subdata(par.sessionI).randstate = par.randstate;
% (res and notes get filled in at the end)
