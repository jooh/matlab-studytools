classdef Study < hgsetget & dynamicprops
    % Master class for running cognitive experiments
    properties
        debug = 0; % shorthand for windowed=1, verbose=1
        verbose = 0;
        windowed = 0;
        screen = [];
        window = [];
        rect = [];
        totdist = 500;
        screenwidth = 380;
        keyboardkeys = {'v','b','n','m'};
        buttonboxkeys = [28 26 24 22];
        validkeys = [];
        location = 'pc';
        scanobj = ScanObjNull;
        resolution = [1024 768];
        oldresolution = struct;
        px2deg = [];
        deg2px = [];
        bgcolor = [128 128 128];
        colors = struct('white',[],'black',[],'grey',[]);
        textpar = struct('font','tahoma','size',14,'style',0,...
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
    end

    properties (Abstract)
        score;  % summary descriptives in subclass
    end


    methods
        function s = Study(varargin)
            if nargin==0
                % initialisation of inherited objects etc
                return
            end
            s = varargs2structfields(varargin,s);
        end

        function openwindow(self)
            warning('off','catstruct:DuplicatesFound');
            if self.debug
                self.verbose = 1;
                self.windowed = 1;
            end
            if self.verbose
                self.printfun = @(x) fprintf([x '\n']);
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
                case 'pc'
                    screens = Screen('Screens');
                    self.screen = screens(ceil(length(screens)/2));
                    self.totdist = '500';
                    self.screenwidth = '380';
                    % assume you've entered a cell array of keys
                    self.validkeys = self.keyboardkeys
                    self.printfun('running in PC mode');
                case 'mri'
                    self.screen = 0;
                    self.totdist = 913;
                    self.screenwidth = 268;
                    self.validkeys = self.buttonboxkeys;
                    self.scanobj = actxserver('MRISync.ScannerSync');
                    err = invoke(self.scanobj,'Initialize','');
                    assert(~err,'Keithley error')
                    invoke(self.scanobj,'SetTimeout',double(200000)); % 200
                    invoke(self.scanobj,'SetMSPerSample',2);
                    self.printfun('running in scanner mode');
                otherwise
                    error('unrecognised location: %s',self.location)
            end
            % On any recent Mac OS version, PPT works very poorly at the
            % moment
            if ismac
                Screen('Preference','SkipSyncTests',1);
            else
                Screen('Preference','SkipSyncTests',0);
            end
            self.px2deg = (2 * atan(self.screenwidth/2/self.totdist) * ...
                (180/pi)) / self.resolution(1);
            % And the reciprocal
            self.deg2px = self.px2deg^-1;
            % Figure out a text color
            if mean(self.bgcolor) > 200
                % black on light backgrounds
                self.textpar.color = [0 0 0];
            else
                % white on dark backgrounds
                self.textpar.color = [255 255 255];
            end
            % open window
            self.printfun('---------- ---------- ----------')
            self.printfun('---------- PPT GOOBLEDEGOOK ----------')
            self.printfun('---------- ---------- ----------')
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
            self.printfun('---------- ---------- ----------')
            self.printfun('---------- / PPT GOOBLEDEGOOK ----------')
            self.printfun('---------- ---------- ----------')
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
        end

        function closewindow(self)
            % for some reason Screen('Close',self.window) doesn't work
            self.printfun('closewindow')
            Screen('CloseAll');
        end

        function runtrials(self,trialorder)
            self.printfun('runtrials')
            if ~isempty(self.trials)
                self.printfun('existing trials will be discarded')
            end
            ntrials = length(trialorder);
            self.printfun(sprintf('running %d trials',ntrials));
            self.initialisetrials(trialorder);
            self.printfun(['logfile: ' self.logfile]);
            diary(self.logfile);
            self.printfun('TRIAL\t TIME\t CYCLE\t CONDITION\t RESPONSE\t');
            % run precon - instructions, calibration, wait trigger etc
            if ~isempty(self.precondition)
                self.printfun('running precondition')
                self.precondition.call;
            end
            % start second / scan timer (maybe count dummies)
            self.timestart = self.timecontrol.begin;
            for t = 1:ntrials
                self.trials(t).condition.call;
                % update the central trial log with the new result from
                % the condition instance
                self.trials(t) = catstruct(self.trials(t),...
                    self.trials(t).condition.result(...
                    self.trials(t).condition.ncalls));
                self.scoretrial(t);
                self.printfun(sprintf('%03d\t %04.3f\t %02.3f\t %s\t %s',...
                    t, self.trials(t).time(1)-self.trials(1).time(1),...
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
                'response',[],'responsetime',[],'score',[],'time',[],...
                'timing',...
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
            self.initialisescore(trialorder)
            t_end = self.trials(end).timing + ...
                self.trials(end).condition.soa;
            if isinf(t_end) || isnan(t_end)
                self.printfun('run duration estimate not possible')
            else
                self.printfun(sprintf('run duration: %.2f minutes',...
                    t_end/60));
            end
        end
    end

    methods (Abstract)
        scoretrial(self,t)
        initialisescore(self)
    end
end
