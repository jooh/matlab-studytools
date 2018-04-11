% Setup basic files and variables for an experiment. Also defines the
% global printfun for use in output
% subdata = initexperiment(varargin)
function subdata = initexperiment(varargin)

% if the experiment crashes we want to dbstop so we can save any data
dbstop if error

% find the calling function's name, use this to define paths
[expname,studydir] = namepath(2);

% Set any non-standard parameters. NB adding new parameters here will raise
% an error. Use your studydefaults wrapper function if you want to add
% support for a new argument.  These are the stock settings
defs.expname = expname;
% print useful info
defs.parallel = 0;
defs.verbose = 1;
defs.windowed = 0;
defs.location = 'pc';
% print less useful info, run in windowed etc
defs.debug = 0;
defs.subject = [];
defs.randseed = [];
defs.redostims = 0;
defs.stim.size = [];
defs.studydir = studydir;
defs.savedata = 1;
defs.prefix = '';
defs.eyetrack = 0;
defs.feedback = 0;
defs.suffix = '';
defs.scantime = false;
defs.forcesync = true;
defs.tr = [];
par = varargs2structfields(varargin,defs);

if par.debug
    par.windowed = 1;
    par.savedata = 0;
    par.verbose = 1;
end

% print functionality depends on verbosity
global printfun
if par.verbose
    printfun = @(x) fprintf('(%s) %s\n',par.expname,x);
else
    % dummy function
    printfun = @(x) x;
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

if par.scantime
    if isempty(par.tr)
        par.tr = input('tr (s): ');
    end
end

% initialise experiment and session
expdir = fullfile(par.subdir,['data_' par.expname par.suffix]);
madedir = mkdirifneeded(expdir);
submat = fullfile(expdir,'subdata.mat');
if madedir || ~exist(submat,'file')
    printfun(sprintf('initialised new experiment in %s',expdir));
    par.sessionI = 1;
    subdata = struct('par',{},'testtime',{},...
        'res',{},'notes',{});
else
    % loading existing Study instances can fail unless keynames have been
    % unified first
    try
        KbName('UnifyKeyNames');
    catch
        printfun('no psychtoolbox?');
    end
    subdata = loadbetter(submat);
    par.sessionI = length(subdata)+1;
    printfun(sprintf('running experiment session %d',par.sessionI));
end

% Set randomisation
if isempty(par.randseed)
    par.randseed = sum(100*clock);
    printfun(sprintf('new randseed: %f',par.randseed));
else
    printfun(sprintf('predetermined randseed: %f',par.randseed));
end
s = RandStream.create('mt19937ar','seed',par.randseed);
RandStream.setGlobalStream(s);

subdata(par.sessionI).par = par;
subdata(par.sessionI).testtime = datestr(now);
subdata(par.sessionI).expdir = expdir;
% (res and notes get filled in at the end)

% try matlabpool
if par.parallel
    try
        if matlabpool('size') == 0
            % start default matlabpool config
            matlabpool;
        end
    catch
        printfun('parallel processing is not available')
    end
end
