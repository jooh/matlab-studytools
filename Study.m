classdef Study < hgsetget & dynamicprops
    % Master class for running cognitive experiments
    properties
        quietppt = 1;
        debug = 0; % shorthand for windowed=1, verbose=1
        verbose = 0;
        windowed = 0;
        screen = [];
        window = [];
        rect = [];
        totdist = 500;
        screenwidth = 380;
        keyboardkeys = {'v','b','n','m'};
        buttonboxkeys = 1:4;
        validkeys = [];
        location = 'pc';
        psychaudio = [];
        samplerate = [];
        naudiochannels= [];
        resolution = [];
        oldresolution = struct;
        px2deg = [];
        deg2px = [];
        bgcolor = [128 128 128];
        colors = struct('white',[],'black',[],'grey',[]);
        textpar = struct('font','tahoma','size',20,'style',0,...
            'vspacing',1.4,'color',[1 1 1],'txtwrap',50);
        xcenter = [];
        ycenter = [];
        conditions = Condition([]); % main events during runtrials
        precondition = Condition([]); % run before main trial loop
        postcondition = Condition([]); % run after main trial loop
        trials = []; % constructed by initialisetrials (can be subbed)
        printfun =[];
        logfile = '';
        timestart = []; % First scan/GetSecs time stamp in run
        timecontrol = []; % SecondTiming or ScanTiming instance 
        ET_serial = ''; % handle to eyetracking serial port object
        eyetrack = 0;
        rundur = []; % estimated run duration from initialisetrials
        feedback = 0; % flag for displaying performance feedback
        score;  % summary descriptives in subclass
        forcesync = 1;
    end

    methods
        function s = Study(varargin)
            if nargin==0
                % initialisation of inherited objects etc
                return
            end
            sout = varargs2structfields(varargin,s);
            for fn = fieldnames(sout)'
                s.(fn{1}) = sout.(fn{1});
            end
        end

        function openwindow(self)
            if self.debug
                self.verbose = 1;
                self.windowed = 1;
            end
            if self.verbose
                self.printfun = @display; %(x) fprintf([x '\n']);
            else
                self.printfun = @(x)x;
            end
            self.printfun('openwindow')
            if isempty(self.logfile)
                self.logfile = fullfile(tempdir,sprintf('study_%s.txt',...
                    datestr(now,'yyyy_mm_dd_HHMM')));
            end
            KbName('UnifyKeyNames');
            % always convert key presses to something recognisable
            self.keyboardkeys = KbName(self.keyboardkeys);
            switch self.location
                case {'pc','mba'}
                    screens = Screen('Screens');
                    self.screen = screens(ceil(length(screens)/2));
                    self.totdist = '500';
                    self.screenwidth = '380';
                    % assume you've entered a cell array of keys
                    self.validkeys = self.keyboardkeys;
                    self.printfun('running in PC mode');
                    % default to native for our Dells
                    if isempty(self.resolution)
                        if strcmp(self.location,'pc')
                            self.resolution = [1280 1024];
                        else
                            self.resolution = [1440 900];
                        end
                    end
                case 'mri'
                    self.screen = 0;
                    self.totdist = 913;
                    self.screenwidth = 268;
                    self.validkeys = self.buttonboxkeys;
                    self.printfun('running in scanner mode');
                    % default to projector native
                    if isempty(self.resolution)
                        self.resolution = [1024 768];
                    end
                case 'mrilcd'
                    self.screen = 0;
                    self.totdist = 1565; 
                    self.screenwidth = 698.4;
                    self.validkeys = self.buttonboxkeys;
                    self.printfun('running in scanner mode (new LCD)');
                    % default to lcd native
                    if isempty(self.resolution)
                        self.resolution = [1920 1080];
                    end
                case 'mrilcd43'
                    self.screen = 0;
                    self.totdist = 1565; 
                    self.screenwidth = 522;
                    self.validkeys = self.buttonboxkeys;
                    self.printfun('running in scanner mode (new LCD, 4:3 aspect)');
                    % I think we usually go with this res here
                    if isempty(self.resolution)
                        self.resolution = [1024 768];
                    end
                otherwise
                    error('unrecognised location: %s',self.location)
            end
            % make sure no one has hacked their way around sync problems
            Screen('Preference','SkipSyncTests',double(~self.forcesync));
            self.px2deg = (2 * atan(self.screenwidth/2/self.totdist) * ...
                (180/pi)) / self.resolution(1);
            % And the reciprocal
            self.deg2px = self.px2deg^-1;
            % you are probably entering greyscale values in [0 1] range
            if self.bgcolor <= 1
                self.bgcolor = uint8(self.bgcolor * 255);
            end
            % Figure out a text color
            if mean(self.bgcolor) > 200
                % black on light backgrounds
                self.textpar.color = [0 0 0];
            else
                % white on dark backgrounds
                self.textpar.color = [255 255 255];
            end
            if self.eyetrack
                self.ET_serial = serial('COM1','BaudRate',115200,...
                    'Databits',8);
                fopen(self.ET_serial);
                set(self.ET_serial,'timeout',.1);
                wstate=warning('off',...
                    'MATLAB:serial:fgetl:unsuccessfulRead');
                fprintf(self.ET_serial,'ET_STP');
                fprintf(self.ET_serial,'ET_CLR');
                fprintf(self.ET_serial,'ET_REC');
            end
            % open window
            if self.quietppt
                Screen('Preference','Verbosity',0);
            else
                self.printfun('---------- ---------- ----------')
                self.printfun('---------- PPT GOOBLEDEGOOK ----------')
                self.printfun('---------- ---------- ----------')
            end
            if self.windowed
                self.oldresolution = Screen('Resolution',self.screen);
                res = [0 0 self.resolution];
                [self.window self.rect] = Screen('OpenWindow',...
                    self.screen,self.bgcolor,res);
            else
                self.oldresolution = Screen('Resolution',self.screen,...
                    self.resolution(1),self.resolution(2));
                [self.window self.rect] = Screen('OpenWindow',...
                    self.screen,self.bgcolor);
            end
            if ~self.quietppt
                self.printfun('---------- ---------- ----------')
                self.printfun('---------- / PPT GOOBLEDEGOOK ----------')
                self.printfun('---------- ---------- ----------')
            end
            % set default bgcolor
            %Screen(self.window,'FillRect',self.bgcolor);
            % screen center
            self.xcenter = self.rect(3)/2;
            self.ycenter = self.rect(4)/2;
            % enable alpha blending
            Screen('BlendFunction',self.window,GL_SRC_ALPHA,...
                GL_ONE_MINUS_SRC_ALPHA);
            % priority (0 for normal, 2 locks all non-Matlab)
            Priority(1);
            % basic color
            self.colors.white = WhiteIndex(self.window); 
            self.colors.black = BlackIndex(self.window);
            self.colors.grey = ceil((...
                self.colors.white+self.colors.black)/2); 
            % and fonts
            Screen('TextFont',self.window,self.textpar.font);
            Screen('TextSize',self.window,self.textpar.size);
            Screen('TextStyle',self.window,self.textpar.style);
            Screen('TextColor',self.window,self.textpar.color);
            HideCursor;
            Screen(self.window,'Flip');
            % audio configuration
            InitializePsychSound;
            if PsychPortAudio('GetOpenDeviceCount') == 1
                PsychPortAudio('Close',0);
            end
            if ~isempty(self.samplerate)
                if ispc
                    audiodevices = PsychPortAudio('GetDevices',2);
                    outdevice = strcmp('Microsoft Sound Mapper - Output',{audiodevices.DeviceName});
                    hd.outdevice = 3;
                    self.psychaudio = PsychPortAudio('Open',audiodevices(outdevice).DeviceIndex,[],[],self.samplerate,self.naudiochannels);
                else
                    self.psychaudio = PsychPortAudio('Open',[],[],[],self.samplerate,self.naudiochannels);
                end
            end
        end

        function closewindow(self)
            % for some reason Screen('Close',self.window) doesn't work
            self.printfun('closewindow')
            Screen('CloseAll');
            if self.eyetrack
                fprintf(self.ET_serial,'ET_STP');
                outfile = sprintf('D:\\StudyData_%s.idf',...
                    datestr(now,'yyyymmdd_HHMM_SS')); 
                fprintf(self.ET_serial,['ET_SAV "' outfile '"']);
                if ~isempty(self.ET_serial)
                    fclose(self.ET_serial);
                end
            end
        end

        function runtrials(self,trialorder)
            self.printfun('runtrials')
            if ~isempty(self.trials)
                self.printfun('existing trials will be discarded')
            end
            ntrials = length(trialorder);
            self.printfun(sprintf('running %d trials',ntrials));
            self.initialisetrials(trialorder);
            self.printfun(sprintf('logfile: %s',self.logfile));
            diary(self.logfile);
            % run precon - instructions, calibration, wait trigger etc
            if ~isempty(self.precondition)
                self.printfun('running precondition')
                self.precondition.call;
            end
            self.printfun(sprintf(...
                'TRIAL\t\tTIME\t\tCYCLE\t\tCONDITION\t\tRESPONSE\t\t'));
            % start second / scan timer (maybe count dummies)
            self.timestart = self.timecontrol.begin;
            for t = 1:ntrials
                fprintf(self.ET_serial,sprintf('ET_REM %s.png',...
                    self.trials(t).condition.name));
                self.trials(t).starttime = self.timecontrol.check;
                self.trials(t).condition.call;
                % update the central trial log with the new result from
                % the condition instance
                self.trials(t) = catstruct(self.trials(t),...
                    self.trials(t).condition.result(...
                    self.trials(t).condition.ncalls));
                self.scoretrial(t);
                self.printfun(sprintf(...
                    '%04d\t %8.3f\t %8.3f\t %10s\t %10s',t,...
                    self.trials(t).time(1)-self.trials(1).time(1),...
                    self.trials(t).time(1)-...
                    self.trials(max([t-1 1])).time(1),...
                    self.trials(t).condition.name,...
                    mat2str(cell2mat(self.trials(t).response))));
                % if you have set the soa field to a value greater than the
                % sum total durations this will control lag
                self.timecontrol.waituntil(self.timestart + ...
                    self.trials(t).timing);
            end
            if ~isempty(self.postcondition)
                self.printfun('running postcondition')
                self.postcondition.call;
            end
            diary('off');
            self.printfun('finished log');
            self.printfun('DONE');
        end

        function initialisetrials(self,trialorder)
            self.printfun('initialisetrials')
            % initialise log files in each condition
            [coninds,counts] = count_unique(trialorder);
            % prepare log struct arrays inside each condition
            for c = 1:length(coninds)
                self.conditions(coninds(c)).preparelog(counts(c));
            end
            % and a global log file
            ntrials = length(trialorder);
            % NB must be in alphabetical order to work with catstruct
            self.trials = struct('condition',...
                num2cell(self.conditions(trialorder)),'endtime',[],...
                'response',[],'responsetime',[],'score',[],'starttime',[],...
                'time',[],'timing',...
                num2cell(cumsum([self.conditions(trialorder).soa])));
            % This loop sets up the cell arrays etc with appropriate
            % nevents for each trial
            for t = 1:length(self.trials)
                self.trials(t).response = self.trials(t).condition.response;
                self.trials(t).responsetime = self.trials(t).response;
                self.trials(t).time = self.trials(t).condition.time;
            end
            % And finally, a global global result file for broad
            % descriptives across trials (computed by scoretrial)
            self.initialisescore(trialorder);
            self.rundur = self.trials(end).timing;
            if isinf(self.rundur) || isnan(self.rundur)
                self.printfun('run duration estimate not possible');
            else
                self.printfun(sprintf('run duration: %.2f %s',...
                    self.rundur,self.timecontrol.units));
            end
        end

        function res = exportstatic(self)
            % export data in static struct form
            res = get(self);

            res.conditions = get(res.conditions);
            for t = 1:length(res.trials)
                res.trials(t).condition = get(res.trials(t).condition);
                res.trials(t).condition.studyfield = [];
                res.trials(t).condition.result = [];
                res.trials(t).condition.timecontrol = [];
            end
            if ~isempty(res.precondition)
                res.precondition = get(res.precondition);
            end
            if ~isempty(res.postcondition)
                res.postcondition = get(res.postcondition);
            end
            res.timecontrol = get(res.timecontrol);
            % strip function handles since these can cause crashes
            handles = structfun(@(x)isa(x,'function_handle'),res);
            if any(handles)
                fns = fieldnames(res)';
                for f = fns(handles)
                    res.(f{1}) = [];
                end
            end
            % serial port object also doesn't save well
            res.ET_serial = [];
        end

        function scoretrial(self,t)
            % do nothing
        end

        function initialisescore(self,trials)
            % no score
        end

    end

    %methods (Abstract)
        %scoretrial(self,t)
        %initialisescore(self)
    %end
end
