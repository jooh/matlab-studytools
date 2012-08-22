classdef Study < hgsetget & dynamicprops
    % Master class for running cognitive experiments
    properties
        units = 's'; % timing in s or scans (not yet supported)
        debug = 0; % shorthand for debug=1, verbose=1
        verbose = 0;
        windowed = 0;
        screen = [];
        window = [];
        rect = [];
        totdist = 500;
        screenwidth = 380;
        validkeys = {'v','b','n','m'};
        location = 'pc';
        TR = [];
        scanobj = [];
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
            switch self.location
                case 'pc'
                    screens = Screen('Screens');
                    self.screen = screens(ceil(length(screens)/2));
                    self.totdist = '500';
                    self.screenwidth = '380';
                    % assume you've entered a cell array of keys
                    self.validkeys = KbName(self.validkeys);
                    self.printfun('running in PC mode');
                case 'mri'
                    self.screen = 0;
                    self.totdist = 913;
                    self.screenwidth = 268;
                    self.validkeys = [28 26 24 22];
                    self.scanobj = actxserver('MRISync.ScannerSync');
                    err = invoke(f.scanobj,'Initialize','');
                    assert(~err,'Keithley error')
                    assert(isnumeric(self.TR),'must set TR for scanner sync!')
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
            assert(isempty(self.trials),'TODO: handle repeated runs')
            self.printfun('runtrials')
            ntrials = length(trialorder);
            self.printfun(sprintf('running %d trials',ntrials));
            self.initialisetrials(trialorder);
            self.printfun(['logfile: ' self.logfile]);
            % run precon - instructions, calibration, wait trigger etc
            if ~isempty(self.precondition)
                self.precondition.call;
            end
            diary(self.logfile);
            self.printfun('TRIAL\t TIME\t CYCLE\t CONDITION\t RESPONSE\t');
            for t = 1:ntrials
                self.trials(t).condition.call;
                % update the central trial log with the new result from
                % the condition instance
                self.trials(t) = catstruct(self.trials(t),...
                    self.trials(t).condition.result(...
                    self.trials(t).condition.ncalls));
                self.scoretrial(t);
                self.printfun(sprintf('%03d\t %.3f\t %.3f\t %s\t %s',...
                    t, self.trials(t).time(1)-self.trials(1).time(1),...
                    self.trials(t).time(1)-...
                    self.trials(max([t-1 1])).time(1),...
                    self.trials(t).condition.name,...
                    mat2str(cell2mat(self.trials(t).response))));
                % if you have set the soa field to a value greater than the
                % sum total durations this will control lag
                WaitSecs('UntilTime',...
                    self.trials(1).time(1)+self.trials(t).timing);
            end
            % postcon - score responses, display feedback, await scan stop
            % etc
            if ~isempty(self.postcondition)
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
            self.trials = struct('condition',...
                num2cell(self.conditions(trialorder)),'response',[],...
                'responsetime',[],'score',[],'time',[],'timing',...
                num2cell(cumsum([self.conditions(trialorder).soa])));
        end
    end

    methods (Abstract)
        scoretrial(self,t)
    end
end