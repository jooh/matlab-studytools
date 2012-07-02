% Setup basic files and variables for an experiment
% [subdata pr] = initexperiment(varargin)
function [subdata pr] = initexperiment(varargin)

% if the experiment crashes we want to dbstop so we can save any data
dbstop if error

% find the calling function's name, use this to define paths
[expname,studydir] = namepath(2);
%st = dbstack;
%expname = st(2).name;
%studydir = fileparts(which(expname));

% Set any non-standard parameters. NB adding new parameters here will raise an
% error. Use your studydefaults wrapper function to re-define defaults.mat if
% you want to add support for a new argument.
% These are the stock settings
defs.expname = expname;
defs.verbose = 1;
defs.subject = [];
defs.randseed = [];
defs.stim_redo = 0;
defs.stim_size = [];
defs.studydir = studydir;
defs.savedata = 1;
par = varargs2structfields(varargin,defs,defs.verbose);

% print functionality depends on verbosity
if par.verbose
    pr = @(x) fprintf('(%s) %s\n',par.expname,x);
else
    % dummy function
    pr = @(x) x;
end

% initialise subject 
if isempty(par.subject)
    par.subject = input('subject code: ','s');
end
par.subdir = fullfile(par.studydir,'subjects',par.subject);
madedir = mkdirifneeded(par.subdir);
if madedir
    yn = input(sprintf('new subject %s, continue? (yn): ',par.subject),'s');
    assert(~strcmp(lower(yn),'n'),'aborted experiment.');
end

% initialise experiment and session
expdir = fullfile(par.subdir,['data_' par.expname]);
madedir = mkdirifneeded(expdir);
submat = fullfile(expdir,'subdata.mat');
if madedir || ~exist(submat,'file')
    pr(sprintf('initialised new experiment in %s',expdir));
    par.sessionI = 1;
    subdata = struct('par',{},'testtime',{},...
        'res',{},'notes',{});
else
    subdata = loadbetter(submat);
    par.sessionI = length(subdata)+1;
end

% Set randomisation
if isempty(par.randseed)
    par.randseed = sum(100*clock);
    pr(sprintf('new randseed: %f',par.randseed));
else
    pr(sprintf('predetermined randseed: %f',par.randseed));
end
s = RandStream.create('mt19937ar','seed',par.randseed);
RandStream.setDefaultStream(s);

subdata(par.sessionI).par = par;
subdata(par.sessionI).testtime = datestr(now);
subdata(par.sessionI).expdir = expdir;
% (res and notes get filled in at the end)
